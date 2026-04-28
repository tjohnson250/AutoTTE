# probe_discharge_date_recon.R --------------------------------------------
# Diagnostic for the inpatient DISCHARGE_DATE imputation issue documented in
# protocol_01.md limitations section: many IP encounters in this CDW have
# DISCHARGE_DATE set to ADMIT_DATE + 1 whenever the source DISCHARGE_DATE
# was missing. The actual stay length can be reconstructed from
# MAX(PX_DATE) over PROCEDURES rows tied to the same ENCOUNTERID, since
# inpatient procedure dates are correctly populated.
#
# This probe quantifies how widespread the imputation is and how much of
# it is recoverable. Output drives whether to implement reconstruction in
# the protocol's outcome ascertainment (Step 8).
#
# Run on the secure host in a fresh R session:
#   setwd("/path/to/AutoTTE")
#   source("tools/probe_discharge_date_recon.R")
# Output: discharge_date_recon_results.md in the working directory.
# Aggregate only; cells < 11 suppressed. Paste back into the thread.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(DBI)
  library(odbc)
})

con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")
DBI::dbExecute(con, "USE CDW")
stopifnot(DBI::dbIsValid(con))

SUPPRESS <- 11L
sup <- function(n) {
  ifelse(is.na(n) | n == 0, format(n, big.mark = ","),
         ifelse(n < SUPPRESS, "<11", format(n, big.mark = ",")))
}

out <- character()
ln  <- function(...) out <<- c(out, paste0(...))

STUDY_START <- "2005-01-01"
STUDY_END   <- "2026-03-31"

ln("# Discharge-date reconstruction diagnostic")
ln("")
ln("- Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
ln("- Study window: ", STUDY_START, " to ", STUDY_END,
   " (covers protocol_01 primary + sensitivity).")
ln("- Source: CDW.dbo.ENCOUNTER, CDW.dbo.PROCEDURES; ENC_TYPE='IP', RAW_ENC_TYPE != 'Legacy Encounter'.")
ln("")

# ---------------------------------------------------------------------------
# Q1: IP encounters classified by raw LOS pattern.
# ---------------------------------------------------------------------------
cat("[probe] Q1: IP encounter LOS class breakdown...\n")
q1 <- DBI::dbGetQuery(con, sprintf("
  SELECT
    CASE
      WHEN e.DISCHARGE_DATE IS NULL                                THEN '0_null_discharge'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) <  0      THEN '1_negative_los'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) =  0      THEN '2_same_day'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) =  1      THEN '3_admit_plus_1_SUSPECT_IMPUTED'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) BETWEEN 2 AND 7 THEN '4_los_2to7'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) BETWEEN 8 AND 14 THEN '5_los_8to14'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) > 14      THEN '6_los_gt_14'
      ELSE '7_other'
    END AS los_class,
    COUNT(*)             AS n_encounters,
    COUNT(DISTINCT e.PATID) AS n_patients
  FROM CDW.dbo.ENCOUNTER e
  WHERE e.ENC_TYPE = 'IP'
    AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
    AND e.ADMIT_DATE BETWEEN '%s' AND '%s'
  GROUP BY
    CASE
      WHEN e.DISCHARGE_DATE IS NULL                                THEN '0_null_discharge'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) <  0      THEN '1_negative_los'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) =  0      THEN '2_same_day'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) =  1      THEN '3_admit_plus_1_SUSPECT_IMPUTED'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) BETWEEN 2 AND 7 THEN '4_los_2to7'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) BETWEEN 8 AND 14 THEN '5_los_8to14'
      WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) > 14      THEN '6_los_gt_14'
      ELSE '7_other'
    END
  ORDER BY los_class
", STUDY_START, STUDY_END))
ln("## 1. IP encounters classified by raw LOS pattern")
ln("")
ln("| los_class | n_encounters | n_patients |")
ln("|---|---:|---:|")
for (i in seq_len(nrow(q1))) {
  ln(sprintf("| `%s` | %s | %s |", q1$los_class[i],
             sup(q1$n_encounters[i]), sup(q1$n_patients[i])))
}
ln("")
ln("Class `3_admit_plus_1_SUSPECT_IMPUTED` is the imputation-suspect bucket.",
   " Class `0_null_discharge` is also potentially recoverable. Other classes",
   " are presumed correct.")
ln("")

# ---------------------------------------------------------------------------
# Q2: Among IP encounters, how many have PROCEDURES rows with PX_DATE
#     >= ADMIT_DATE that could anchor a reconstructed discharge?
# ---------------------------------------------------------------------------
cat("[probe] Q2: PX_DATE coverage among IP encounters (this may take a few minutes)...\n")
q2 <- DBI::dbGetQuery(con, sprintf("
  WITH encs AS (
    SELECT e.ENCOUNTERID, e.PATID, e.ADMIT_DATE, e.DISCHARGE_DATE,
           CASE
             WHEN e.DISCHARGE_DATE IS NULL                                THEN '0_null_discharge'
             WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) =  1      THEN '3_admit_plus_1_SUSPECT_IMPUTED'
             WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) >  1      THEN '4plus_multi_day'
             ELSE '_other'
           END AS los_class
    FROM CDW.dbo.ENCOUNTER e
    WHERE e.ENC_TYPE = 'IP'
      AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
      AND e.ADMIT_DATE BETWEEN '%s' AND '%s'
  ),
  px_max AS (
    SELECT p.ENCOUNTERID, MAX(p.PX_DATE) AS max_px_dt
    FROM CDW.dbo.PROCEDURES p
    INNER JOIN encs e ON p.ENCOUNTERID = e.ENCOUNTERID
    WHERE p.PX_DATE IS NOT NULL
      AND p.PX_DATE >= e.ADMIT_DATE
    GROUP BY p.ENCOUNTERID
  ),
  joined AS (
    SELECT e.los_class,
           CASE
             WHEN p.max_px_dt IS NULL THEN -1
             WHEN e.DISCHARGE_DATE IS NULL THEN
               DATEDIFF(DAY, e.ADMIT_DATE, p.max_px_dt)
             WHEN p.max_px_dt > e.DISCHARGE_DATE THEN
               DATEDIFF(DAY, e.DISCHARGE_DATE, p.max_px_dt)
             ELSE 0
           END AS recon_extension_days
    FROM encs e
    LEFT JOIN px_max p ON e.ENCOUNTERID = p.ENCOUNTERID
  )
  SELECT los_class,
         COUNT(*) AS n_total,
         SUM(CASE WHEN recon_extension_days = -1 THEN 1 ELSE 0 END) AS n_no_px,
         SUM(CASE WHEN recon_extension_days =  0 THEN 1 ELSE 0 END) AS n_recon_no_change,
         SUM(CASE WHEN recon_extension_days BETWEEN 1 AND 7  THEN 1 ELSE 0 END) AS n_recon_1to7,
         SUM(CASE WHEN recon_extension_days BETWEEN 8 AND 14 THEN 1 ELSE 0 END) AS n_recon_8to14,
         SUM(CASE WHEN recon_extension_days BETWEEN 15 AND 30 THEN 1 ELSE 0 END) AS n_recon_15to30,
         SUM(CASE WHEN recon_extension_days > 30           THEN 1 ELSE 0 END) AS n_recon_gt30,
         CAST(AVG(CASE WHEN recon_extension_days > 0 THEN
                       CAST(recon_extension_days AS float) END)
              AS decimal(8,2)) AS mean_extension_days
  FROM joined
  GROUP BY los_class
  ORDER BY los_class
", STUDY_START, STUDY_END))
ln("## 2. PX_DATE-based reconstruction potential by LOS class")
ln("")
ln("`recon_extension_days` = how many days the reconstructed discharge",
   " (max PX_DATE) extends beyond the recorded DISCHARGE_DATE. -1 = no",
   " procedure data (cannot reconstruct). 0 = recorded discharge already",
   " covers all procedure dates. >0 = reconstructed discharge is later.")
ln("")
ln("| los_class | n_total | n_no_px | n_recon_no_change | n_recon_1to7 | n_recon_8to14 | n_recon_15to30 | n_recon_gt30 | mean_ext_days (when >0) |")
ln("|---|---:|---:|---:|---:|---:|---:|---:|---:|")
for (i in seq_len(nrow(q2))) {
  ln(sprintf("| `%s` | %s | %s | %s | %s | %s | %s | %s | %s |",
             q2$los_class[i],
             sup(q2$n_total[i]),
             sup(q2$n_no_px[i]),
             sup(q2$n_recon_no_change[i]),
             sup(q2$n_recon_1to7[i]),
             sup(q2$n_recon_8to14[i]),
             sup(q2$n_recon_15to30[i]),
             sup(q2$n_recon_gt30[i]),
             ifelse(is.na(q2$mean_extension_days[i]), "-",
                    format(q2$mean_extension_days[i], nsmall = 2))))
}
ln("")

# ---------------------------------------------------------------------------
# Q3: Same-day discharge (LOS=0) and admit_plus_1 trends by year (when did
# the imputation appear?). If admit_plus_1 fraction spikes in some years,
# that's the imputation-window evidence.
# ---------------------------------------------------------------------------
cat("[probe] Q3: admit_plus_1 fraction by calendar year...\n")
q3 <- DBI::dbGetQuery(con, sprintf("
  SELECT YEAR(e.ADMIT_DATE) AS yr,
         COUNT(*) AS n_total,
         SUM(CASE WHEN e.DISCHARGE_DATE IS NULL                              THEN 1 ELSE 0 END) AS n_null,
         SUM(CASE WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) = 1     THEN 1 ELSE 0 END) AS n_admit_plus_1,
         SUM(CASE WHEN DATEDIFF(DAY, e.ADMIT_DATE, e.DISCHARGE_DATE) > 1     THEN 1 ELSE 0 END) AS n_multi_day
  FROM CDW.dbo.ENCOUNTER e
  WHERE e.ENC_TYPE = 'IP'
    AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
    AND e.ADMIT_DATE BETWEEN '%s' AND '%s'
  GROUP BY YEAR(e.ADMIT_DATE)
  ORDER BY yr
", STUDY_START, STUDY_END))
ln("## 3. Imputation pattern by calendar year")
ln("")
ln("If `n_admit_plus_1` is implausibly high relative to `n_multi_day` in",
   " certain years, that's the imputation-window. A real-world IP cohort",
   " typically has 30-50% multi-day stays.")
ln("")
ln("| year | n_total | n_null | n_admit_plus_1 | n_multi_day | %admit_plus_1 |")
ln("|---|---:|---:|---:|---:|---:|")
for (i in seq_len(nrow(q3))) {
  pct <- if (q3$n_total[i] > 0) round(100 * q3$n_admit_plus_1[i] / q3$n_total[i], 1) else NA
  ln(sprintf("| %d | %s | %s | %s | %s | %s |",
             q3$yr[i],
             sup(q3$n_total[i]),
             sup(q3$n_null[i]),
             sup(q3$n_admit_plus_1[i]),
             sup(q3$n_multi_day[i]),
             ifelse(is.na(pct), "-", sprintf("%.1f%%", pct))))
}
ln("")

# ---------------------------------------------------------------------------
# Write report.
# ---------------------------------------------------------------------------
report_path <- file.path(getwd(), "discharge_date_recon_results.md")
writeLines(out, report_path)
cat(sprintf("\n[probe] Report written to: %s\n", report_path))
cat("[probe] Open the file, eyeball it, then paste it back into the thread.\n")

DBI::dbDisconnect(con)
