# profilers/_helpers.R
#
# Shared scaffolding for AutoTTE database profilers. Engine-agnostic — only
# connection lifecycle, YAML config loading, and small-cell suppression. No SQL.
#
# Sourced by every profilers/<cdm>.qmd template and by the institution-specific
# CDW_DB_Profiler.qmd at the repo root.

# Null-coalescing operator (also exported by rlang/tidyverse; redefining is safe).
`%||%` <- function(a, b) if (is.null(a)) b else a

#' Open a DB connection from a YAML connection.r_code block, run body(con), and
#' guarantee dbDisconnect on exit (even if body errors).
#'
#' The r_code is evaluated in an isolated environment so it cannot clobber
#' globals. The block must assign a variable named `con`.
#'
#' @param r_code character; R code from cfg$connection$r_code (or similar).
#' @param body   function(con); runs against the live connection.
with_db_connection <- function(r_code, body) {
  if (is.null(r_code) || !nzchar(r_code))
    stop("connection.r_code is missing or empty in the YAML config")
  env <- new.env(parent = globalenv())
  eval(parse(text = r_code), envir = env)
  con <- env$con
  if (is.null(con)) stop("connection.r_code did not assign a variable named `con`")
  on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)
  body(con)
}

#' Load a YAML DB config from a project-relative path, resolve all declared
#' output paths via here::here(), and ensure parent directories exist.
#'
#' Returns a list with `cfg` (raw YAML) and `paths` (resolved absolute paths).
#' Missing optional fields (e.g. mpi_schema_dump) are returned as NULL.
load_profiler_config <- function(db_config_path) {
  cfg <- yaml::read_yaml(here::here(db_config_path))
  resolve <- function(p) if (!is.null(p) && nzchar(p)) here::here(p) else NULL
  paths <- list(
    schema       = resolve(cfg$schema_dump),
    mpi_schema   = resolve(cfg$mpi_schema_dump),
    data_profile = resolve(cfg$data_profile)
  )
  # Optional: cfg$staging_schema_dumps is a list of entries, each with its own
  # connection.r_code, schema_name, and schema_dump path. Resolve each path.
  staging <- cfg$staging_schema_dumps %||% list()
  for (i in seq_along(staging)) {
    staging[[i]]$schema_dump_resolved <- resolve(staging[[i]]$schema_dump)
  }
  paths$staging_schema_dumps <- vapply(staging,
    function(s) s$schema_dump_resolved %||% NA_character_, character(1))
  for (p in c(paths$schema, paths$mpi_schema, paths$data_profile,
              paths$staging_schema_dumps)) {
    if (!is.null(p) && !is.na(p)) {
      dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
    }
  }
  cfg$staging_schema_dumps <- staging
  list(cfg = cfg, paths = paths)
}

#' Resolve the schema name from cfg$schema_prefix (e.g. "CDW.dbo" -> "dbo").
#' Returns the default if no prefix is set.
schema_name_from_cfg <- function(cfg, default = "dbo") {
  if (is.null(cfg$schema_prefix) || !nzchar(cfg$schema_prefix)) return(default)
  sub("^.*\\.", "", cfg$schema_prefix)
}

#' Build a small-cell suppression function that replaces counts < threshold
#' with the literal string "<N". Used by every profile section to keep output
#' PHI-safe per the project's de-identification convention.
make_suppress <- function(threshold = 11) {
  function(n) {
    ifelse(is.na(n), NA_character_,
           ifelse(n < threshold, paste0("<", threshold), format(n, big.mark = ",")))
  }
}

#' Build a safe-query wrapper bound to a connection. Returns an empty data
#' frame and logs a [SKIP] message on error — this lets templates run against
#' DBs missing optional CDM tables/columns without crashing.
make_safe_query <- function(con) {
  function(sql, label = "") {
    tryCatch(
      DBI::dbGetQuery(con, sql),
      error = function(e) {
        message("  [SKIP] ", label, ": ", conditionMessage(e))
        data.frame()
      }
    )
  }
}

#' Preflight: open connection, list tables, close. Engine-agnostic. Surfaces
#' DSN/credentials problems immediately instead of after the long profile run.
preflight_check <- function(r_code, label = "preflight") {
  with_db_connection(r_code, function(con) {
    tables <- DBI::dbListTables(con)
    message("Preflight OK [", label, "]: ", length(tables), " tables visible")
    if (length(tables) == 0) {
      warning("No tables visible — check schema/USE statement in connection.r_code")
    }
  })
}

#' Done banner: print a uniform "what was written" summary.
done_banner <- function(...) {
  paths <- list(...)
  message(strrep("=", 62))
  for (nm in names(paths)) {
    if (!is.null(paths[[nm]])) message(sprintf("%-30s %s", paste0(nm, ":"), paths[[nm]]))
  }
  message(strrep("=", 62))
}
