# databases/data/setup_omop.R
#
# On-demand fetch of OMOP test/demo databases via OMOPSynth (which wraps
# CDMConnector + Eunomia). The .duckdb files are NOT committed to the repo
# (databases/data/ is gitignored) — run the function below once after clone
# to materialize them locally.
#
# Usage:
#   source("databases/data/setup_omop.R")
#   setup_omop_test()  # ~6 MB download, GiBleed (fast tests)
#   setup_omop_demo()  # ~800 MB download, synthea-heart-10k (cardiac demos)
#
# Both are idempotent: if the target .duckdb already exists, the function
# returns immediately without re-downloading.

.ensure_omopsynth <- function() {
  if (!requireNamespace("OMOPSynth", quietly = TRUE)) {
    stop(
      "OMOPSynth is not installed. Install it with:\n",
      "  install.packages('devtools')\n",
      "  devtools::install_github('tjohnson250/OMOPSynth')"
    )
  }
  if (!requireNamespace("CDMConnector", quietly = TRUE)) {
    stop("CDMConnector not installed. install.packages('CDMConnector')")
  }
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("duckdb not installed. install.packages('duckdb')")
  }
}

# Internal: download dataset via CDMConnector and copy the resulting DuckDB
# file to a stable target path inside databases/data/. CDMConnector caches
# downloads in EUNOMIA_DATA_FOLDER (we point it at databases/data/eunomia_cache
# so the cache is reusable across both functions).
.fetch_omop_dataset <- function(dataset_name, cdm_version, target_path) {
  .ensure_omopsynth()

  if (file.exists(target_path)) {
    message("Already present: ", target_path)
    message("(Delete the file and re-run to refresh.)")
    return(invisible(target_path))
  }

  here_root <- if (requireNamespace("here", quietly = TRUE)) here::here() else getwd()
  cache_dir <- file.path(here_root, "databases", "data", "eunomia_cache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  Sys.setenv(EUNOMIA_DATA_FOLDER = cache_dir)

  message("Downloading ", dataset_name, " (CDM v", cdm_version, ")...")
  message("Cache: ", cache_dir)
  src_path <- CDMConnector::eunomiaDir(
    datasetName = dataset_name,
    cdmVersion  = cdm_version
  )

  if (!file.exists(src_path)) {
    stop("CDMConnector returned a path that does not exist: ", src_path)
  }

  dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)
  file.copy(src_path, target_path, overwrite = TRUE)
  message("Materialized: ", target_path,
          " (", round(file.info(target_path)$size / 1024 / 1024, 1), " MB)")
  invisible(target_path)
}

#' Set up the small OMOP test DB (GiBleed, ~6 MB download).
#'
#' Used by profilers/omop.qmd's default config and by AutoTTE's test suite.
#' Lands at databases/data/omop_test.duckdb.
setup_omop_test <- function() {
  here_root <- if (requireNamespace("here", quietly = TRUE)) here::here() else getwd()
  .fetch_omop_dataset(
    dataset_name = "GiBleed",
    cdm_version  = "5.3",
    target_path  = file.path(here_root, "databases", "data", "omop_test.duckdb")
  )
}

#' Set up the larger OMOP demo DB (synthea-heart-10k, ~800 MB download).
#'
#' Cardiac focus — useful for AutoTTE demos in cardiovascular therapeutic
#' areas. Lands at databases/data/omop_demo.duckdb.
setup_omop_demo <- function() {
  here_root <- if (requireNamespace("here", quietly = TRUE)) here::here() else getwd()
  .fetch_omop_dataset(
    dataset_name = "synthea-heart-10k",
    cdm_version  = "5.3",
    target_path  = file.path(here_root, "databases", "data", "omop_demo.duckdb")
  )
}
