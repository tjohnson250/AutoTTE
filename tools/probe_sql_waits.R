# tools/probe_sql_waits.R
#
# One-shot / polling diagnostic for a long-running SQL Server session.
#
# Run from a SEPARATE R / RStudio session on the secure host (the R session
# running the protocol is blocked by its own dbExecute call, so a new
# session is required):
#
#   1. In RStudio Desktop:  Session -> New Session
#      (or launch a fresh R / Rscript from a second terminal)
#   2. setwd() to the AutoTTE checkout, then:
#      source("tools/probe_sql_waits.R")          # loads + one snapshot
#      probe_waits()                               # another snapshot
#      probe_waits_loop(interval_sec = 15)         # poll until Ctrl+C/Esc
#
# What it reports for every long-running user session on the same SQL
# Server (not just yours -- permissions permitting):
#   - session id, login, host, program
#   - elapsed time, CPU time, status, command
#   - wait_type / last_wait_type (the bottleneck signature)
#   - blocking session (if any)
#   - tempdb MB (user_objects + internal_objects) -- large internal_objects
#     mean hash-aggregate / sort spills
#   - row count processed so far
#   - first ~300 chars of the active SQL text
#
# Wait-type cheat sheet (what the bottleneck means):
#   CXPACKET / CXCONSUMER       -> parallelism wait, usually fine on its own
#   HTBUILD / HTMEMO / HTREPARTITION -> hash join is spilling
#   HTDELETE                    -> hash aggregate spill
#   SORT_WARNING / IO_COMPLETION + high internal tempdb -> sort is spilling
#   PAGEIOLATCH_SH/EX           -> disk read wait; table scan or cold cache
#   PAGELATCH_*                 -> tempdb contention (SGAM/PFS/GAM)
#   LCK_M_*                     -> blocking on a lock
#   ASYNC_NETWORK_IO            -> caller not draining; normally not a SQL
#                                  Server bottleneck
#
# Permissions: the querying account needs VIEW SERVER STATE to see other
# sessions' DMV rows. Without it the script still runs but only shows your
# OWN probe session (which is useless). If VIEW SERVER STATE is missing,
# ask your DBA for it or run this on a DB account that has it.

suppressPackageStartupMessages({
  library(DBI)
  library(odbc)
})

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

.probe_connect <- function(dsn) {
  tryCatch(
    DBI::dbConnect(odbc::odbc(), dsn),
    error = function(e) {
      stop(sprintf(
        "probe_sql_waits: could not connect via DSN '%s': %s\n  Is the DSN name correct? Is the R session on the secure host?",
        dsn, conditionMessage(e)
      ), call. = FALSE)
    }
  )
}

# ---------------------------------------------------------------------------
# Main snapshot function
# ---------------------------------------------------------------------------

#' Print one snapshot of long-running user sessions on the SQL Server.
#'
#' @param dsn              ODBC DSN to connect through. Defaults to the same
#'                         DSN the protocol scripts use.
#' @param min_elapsed_sec  Ignore sessions whose total_elapsed_time is below
#'                         this threshold (default 60s).
#' @param sql_text_chars   How much of the active SQL text to print per row.
#' @param include_all_users  TRUE = show every long-running session on the
#'                         server. FALSE = only your own login. Default TRUE.
#' @return Invisibly returns the data.frame so you can inspect columns.
probe_waits <- function(dsn = "SQLODBCD17CDM",
                        min_elapsed_sec = 60,
                        sql_text_chars = 300,
                        include_all_users = TRUE) {
  con <- .probe_connect(dsn)
  on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)

  user_filter <- if (include_all_users) {
    ""
  } else {
    "AND s.login_name = SUSER_SNAME()"
  }

  sql <- sprintf("
    SELECT
      r.session_id,
      s.login_name,
      s.host_name,
      s.program_name,
      r.status,
      r.command,
      r.wait_type,
      r.last_wait_type,
      r.wait_time AS wait_ms,
      r.cpu_time  AS cpu_ms,
      r.total_elapsed_time AS elapsed_ms,
      r.percent_complete,
      r.blocking_session_id,
      r.row_count,
      ISNULL(tsu.user_obj_mb, 0)      AS tempdb_user_mb,
      ISNULL(tsu.internal_obj_mb, 0)  AS tempdb_internal_mb,
      LEFT(t.text, %d)                AS sql_text_head
    FROM sys.dm_exec_requests r
    INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
    OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
    LEFT JOIN (
      SELECT session_id,
             CAST(SUM(user_objects_alloc_page_count) * 8.0 / 1024
                  AS decimal(10,1)) AS user_obj_mb,
             CAST(SUM(internal_objects_alloc_page_count) * 8.0 / 1024
                  AS decimal(10,1)) AS internal_obj_mb
      FROM sys.dm_db_session_space_usage
      GROUP BY session_id
    ) tsu ON r.session_id = tsu.session_id
    WHERE s.is_user_process = 1
      AND r.session_id <> @@SPID
      AND r.total_elapsed_time > %d
      %s
    ORDER BY r.total_elapsed_time DESC;
  ", sql_text_chars, min_elapsed_sec * 1000L, user_filter)

  df <- tryCatch(
    DBI::dbGetQuery(con, sql),
    error = function(e) {
      if (grepl("VIEW SERVER STATE", conditionMessage(e), ignore.case = TRUE) ||
          grepl("permission was denied",
                conditionMessage(e), ignore.case = TRUE)) {
        stop(
          "probe_sql_waits: VIEW SERVER STATE permission denied. Without it ",
          "this script cannot see other sessions' DMV rows. Ask your DBA to ",
          "grant VIEW SERVER STATE to your login.",
          call. = FALSE
        )
      }
      stop(e)
    }
  )

  ts <- format(Sys.time(), "%H:%M:%S")
  if (nrow(df) == 0) {
    cat(sprintf("[%s] No user sessions with elapsed > %ds on '%s'.\n",
                ts, min_elapsed_sec, dsn))
    return(invisible(df))
  }

  cat(sprintf("[%s] %d long-running request(s) on '%s':\n\n",
              ts, nrow(df), dsn))

  for (i in seq_len(nrow(df))) {
    r <- df[i, ]
    mins <- r$elapsed_ms / 60000

    cat(sprintf("  session %s  login=%s  host=%s  program=%s\n",
                r$session_id,
                r$login_name,
                if (is.na(r$host_name))    "-" else r$host_name,
                if (is.na(r$program_name)) "-" else r$program_name))

    cat(sprintf("    elapsed=%.1f min   cpu=%.1f s   status=%s   command=%s\n",
                mins,
                r$cpu_ms / 1000,
                r$status,
                r$command))

    wait_desc <- if (!is.na(r$wait_type) && nzchar(r$wait_type)) {
      sprintf("wait_type=%s (wait %sms)",
              r$wait_type, format(r$wait_ms, big.mark = ","))
    } else {
      sprintf("last_wait=%s (not currently waiting)", r$last_wait_type)
    }
    cat(sprintf("    %s\n", wait_desc))

    if (!is.na(r$blocking_session_id) && r$blocking_session_id > 0) {
      cat(sprintf("    *** BLOCKED BY session %s ***\n",
                  r$blocking_session_id))
    }

    cat(sprintf("    tempdb: user=%.1f MB  internal=%.1f MB   row_count=%s\n",
                r$tempdb_user_mb,
                r$tempdb_internal_mb,
                format(r$row_count, big.mark = ",")))

    if (!is.na(r$percent_complete) && r$percent_complete > 0) {
      cat(sprintf("    percent_complete=%.1f%%\n", r$percent_complete))
    }

    if (!is.na(r$sql_text_head) && nzchar(r$sql_text_head)) {
      head_one_line <- gsub("[[:space:]]+", " ", r$sql_text_head)
      cat(sprintf("    sql: %s%s\n",
                  head_one_line,
                  if (nchar(r$sql_text_head) >= sql_text_chars) " ..." else ""))
    }
    cat("\n")
  }

  invisible(df)
}

# ---------------------------------------------------------------------------
# Polling loop: keep calling probe_waits() every interval_sec until Ctrl+C.
# ---------------------------------------------------------------------------

#' Poll probe_waits() until interrupted. Ctrl+C (console) or Esc (RStudio)
#' to stop.
probe_waits_loop <- function(dsn = "SQLODBCD17CDM",
                             interval_sec = 15,
                             ...) {
  cat(sprintf("Polling every %ds. Ctrl+C / Esc to stop.\n\n", interval_sec))
  repeat {
    probe_waits(dsn = dsn, ...)
    cat(strrep("-", 72), "\n", sep = "")
    Sys.sleep(interval_sec)
  }
}

# ---------------------------------------------------------------------------
# Run one snapshot on source(). Suppress via `options(probe.autorun = FALSE)`.
# ---------------------------------------------------------------------------

.autorun <- isTRUE(getOption("probe.autorun", default = TRUE))
if (.autorun) {
  cat("probe_sql_waits.R loaded.\n")
  cat("  probe_waits()                  one snapshot\n")
  cat("  probe_waits_loop(15)           poll every 15s\n")
  cat("  probe_waits(include_all_users = FALSE)   only your login\n\n")
  tryCatch(
    probe_waits(),
    error = function(e) cat("Initial snapshot failed: ", conditionMessage(e), "\n")
  )
}
