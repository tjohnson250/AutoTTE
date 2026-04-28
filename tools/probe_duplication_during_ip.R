# probe_duplication_during_ip.R -------------------------------------------
# Diagnostic for the reverse-causation threat in protocol_01: a duplicate
# MRN created on the day of an inpatient admission (or during a stay) is
# almost certainly a downstream artifact of that admission's registration
# workflow, not an upstream cause of subsequent admissions. The protocol's
# 2-day induction window catches the same-day case but not mid-stay
# duplications when the IP stay extends past day 2.
#
# This probe quantifies how many duplications fall during an active IP
# stay (using PX_DATE-reconstructed discharge dates per
# probe_discharge_date_recon.R), broken down by:
#   - timing relative to the IP admission (day 0, day 1, mid-stay, etc.)
#   - the COALESCE rung that supplied t_zero (GECBI / MPI_LastEdit)
#   - calendar year
#
# If a non-trivial fraction (say >5%) of duplications occur during an
# active IP stay, the protocol should add a sensitivity that excludes
# those duplications' concurrent admission from outcome ascertainment
# (the duplication still counts as exposure, but the SAME admission is
# not counted as a downstream IP outcome event).
#
# Run on the secure host in a fresh R session:
#   setwd("/path/to/AutoTTE")
#   source("tools/probe_duplication_during_ip.R")
# Output: duplication_during_ip_results.md in the working directory.
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
STUDY_END   <- "2025-12-31"   # primary window per protocol_01.md
MPI_SRC     <- "ALLSCRIPTS"   # primary per protocol_01.md

ln("# Duplication-during-IP-stay diagnostic")
ln("")
ln("- Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
ln("- Study window: ", STUDY_START, " to ", STUDY_END,
   " (protocol_01 primary).")
ln("- MPI source filter: `Src='", MPI_SRC, "'` (protocol_01 primary).")
ln("- IP discharge date reconstructed from MAX(PX_DATE) per ENCOUNTERID",
   " when MAX(PX_DATE) > recorded DISCHARGE_DATE; otherwise recorded value used.")
ln("")

# ---------------------------------------------------------------------------
# Build a temp table of duplication events using the protocol Step 1
# logic (simplified: we only need PATID + raw_first_dup_dt + t_zero_source,
# not the full COALESCE ladder structure).
# ---------------------------------------------------------------------------
cat("[probe] Step 1: build #dup_event temp table (matches protocol Step 1)...\n")
DBI::dbExecute(con, "
  IF OBJECT_ID('tempdb..#dup_event_probe') IS NOT NULL DROP TABLE #dup_event_probe;
")
DBI::dbExecute(con, sprintf("
  WITH ranked AS (
    SELECT D.PATID,
           mpi.lid,
           ge_reg.RegistrationDTTM AS gecbi_reg_dttm,
           mpi.LastEditDTTM,
           ISNULL(ge_reg.RegistrationDTTM, mpi.LastEditDTTM) AS DuplicationDTTM,
           DENSE_RANK() OVER (
             PARTITION BY D.PATID
             ORDER BY ISNULL(ge_reg.RegistrationDTTM, mpi.LastEditDTTM)
           ) AS rnk
    FROM CDW.dbo.DEMOGRAPHIC D
    INNER JOIN MasterPatientIndex.dbo.vSourceRecordsUID mpi ON mpi.uid = D.PATID
    LEFT JOIN (
      SELECT dp.PtMrn AS MRN, dt.act_date AS RegistrationDTTM
      FROM cdwstaging.gecbi.dim_patient dp
      JOIN cdwstaging.gecbi.dim_date dt ON dt.date_id = dp.PtRegDtId
      LEFT JOIN CDWStaging.allscripts.Patient_Iorg iorg
        ON dp.PtMrn = iorg.OrganizationMrn AND iorg.InternalOrganization = 0
      LEFT JOIN cdwstaging.allscripts.Person P
        ON iorg.PersonID = P.ID
    ) ge_reg ON ge_reg.MRN = mpi.lid
    WHERE mpi.src = '%s'
  )
  SELECT PATID,
         CAST(MIN(DuplicationDTTM) AS DATE) AS raw_first_dup_dt,
         CASE
           WHEN MIN(CASE WHEN gecbi_reg_dttm IS NOT NULL THEN DuplicationDTTM END)
                = MIN(DuplicationDTTM) THEN 'GECBI_Registration'
           ELSE 'MPI_LastEdit'
         END AS t_zero_source
  INTO #dup_event_probe
  FROM ranked
  WHERE rnk > 1
    AND DuplicationDTTM BETWEEN '%s' AND '%s'
  GROUP BY PATID;

  CREATE INDEX ix_dup_event_probe ON #dup_event_probe (PATID);
", MPI_SRC, STUDY_START, STUDY_END))

n_dup <- DBI::dbGetQuery(con,
  "SELECT COUNT(*) AS n FROM #dup_event_probe")$n
cat(sprintf("[probe] %s duplication events in window.\n",
            format(n_dup, big.mark = ",")))
ln("Total duplication events in window: **", format(n_dup, big.mark = ","),
   "** (post-rnk>1 filter, restricted to MPI src=", MPI_SRC, ").")
ln("")

# ---------------------------------------------------------------------------
# Build #ip_recon: per-IP-encounter reconstructed discharge date.
# ---------------------------------------------------------------------------
cat("[probe] Step 2: build #ip_recon (this is the slow step -- ~minutes)...\n")
DBI::dbExecute(con, "
  IF OBJECT_ID('tempdb..#ip_recon') IS NOT NULL DROP TABLE #ip_recon;
")
DBI::dbExecute(con, sprintf("
  WITH ip_encs AS (
    SELECT e.ENCOUNTERID, e.PATID, e.ADMIT_DATE, e.DISCHARGE_DATE
    FROM CDW.dbo.ENCOUNTER e
    INNER JOIN (SELECT DISTINCT PATID FROM #dup_event_probe) du ON e.PATID = du.PATID
    WHERE e.ENC_TYPE = 'IP'
      AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
      AND e.ADMIT_DATE BETWEEN DATEADD(DAY, -30, '%s') AND DATEADD(DAY, 30, '%s')
  ),
  px_max AS (
    SELECT p.ENCOUNTERID, MAX(p.PX_DATE) AS max_px_dt
    FROM CDW.dbo.PROCEDURES p
    INNER JOIN ip_encs e ON p.ENCOUNTERID = e.ENCOUNTERID
    WHERE p.PX_DATE IS NOT NULL
      AND p.PX_DATE >= e.ADMIT_DATE
    GROUP BY p.ENCOUNTERID
  )
  SELECT e.ENCOUNTERID, e.PATID, e.ADMIT_DATE,
         e.DISCHARGE_DATE AS recorded_discharge,
         p.max_px_dt,
         CAST(
           CASE
             WHEN p.max_px_dt IS NULL THEN e.DISCHARGE_DATE
             WHEN e.DISCHARGE_DATE IS NULL THEN p.max_px_dt
             WHEN p.max_px_dt > e.DISCHARGE_DATE THEN p.max_px_dt
             ELSE e.DISCHARGE_DATE
           END AS date) AS recon_discharge
  INTO #ip_recon
  FROM ip_encs e
  LEFT JOIN px_max p ON e.ENCOUNTERID = p.ENCOUNTERID;

  CREATE INDEX ix_ip_recon_patid_admit ON #ip_recon (PATID, ADMIT_DATE);
", STUDY_START, STUDY_END))

n_ip <- DBI::dbGetQuery(con,
  "SELECT COUNT(*) AS n FROM #ip_recon")$n
cat(sprintf("[probe] %s IP encounters across duplicate-event patients.\n",
            format(n_ip, big.mark = ",")))
ln("IP encounters across duplicate-event patients (within +/- 30d of study window): **",
   format(n_ip, big.mark = ","), "**.")
ln("")

# ---------------------------------------------------------------------------
# Q1: Cross-tab duplication events with overlapping IP stays.
# Categorize each duplication by timing relative to the closest IP stay.
# ---------------------------------------------------------------------------
cat("[probe] Q1: classify each duplication event by IP-stay overlap...\n")
q1 <- DBI::dbGetQuery(con, "
  WITH dup_with_ip AS (
    SELECT d.PATID,
           d.raw_first_dup_dt,
           d.t_zero_source,
           ip.ADMIT_DATE,
           ip.recon_discharge,
           CASE
             WHEN ip.ADMIT_DATE IS NULL                                    THEN 'no_overlapping_ip'
             WHEN d.raw_first_dup_dt = ip.ADMIT_DATE                       THEN 'on_admit_day'
             WHEN d.raw_first_dup_dt = DATEADD(DAY, 1, ip.ADMIT_DATE)      THEN 'admit_plus_1d'
             WHEN d.raw_first_dup_dt BETWEEN DATEADD(DAY, 2, ip.ADMIT_DATE)
                                          AND ip.recon_discharge           THEN 'mid_stay_2_to_discharge'
             WHEN d.raw_first_dup_dt BETWEEN DATEADD(DAY, -7, ip.ADMIT_DATE)
                                          AND DATEADD(DAY, -1, ip.ADMIT_DATE) THEN 'pre_admit_within_7d'
             WHEN d.raw_first_dup_dt BETWEEN DATEADD(DAY, 1, ip.recon_discharge)
                                          AND DATEADD(DAY, 7, ip.recon_discharge) THEN 'post_discharge_within_7d'
             ELSE 'other'
           END AS timing_class
    FROM #dup_event_probe d
    LEFT JOIN #ip_recon ip
      ON d.PATID = ip.PATID
     AND d.raw_first_dup_dt BETWEEN DATEADD(DAY, -7, ip.ADMIT_DATE)
                                AND DATEADD(DAY,  7, ip.recon_discharge)
  ),
  best_class AS (
    -- one row per (PATID, raw_first_dup_dt): pick the most specific timing
    -- class if multiple IP stays overlap. Priority order encoded in the
    -- ORDER BY below.
    SELECT PATID, raw_first_dup_dt, t_zero_source, timing_class,
           ROW_NUMBER() OVER (
             PARTITION BY PATID, raw_first_dup_dt
             ORDER BY CASE timing_class
               WHEN 'on_admit_day'             THEN 1
               WHEN 'admit_plus_1d'            THEN 2
               WHEN 'mid_stay_2_to_discharge'  THEN 3
               WHEN 'pre_admit_within_7d'      THEN 4
               WHEN 'post_discharge_within_7d' THEN 5
               WHEN 'other'                    THEN 6
               WHEN 'no_overlapping_ip'        THEN 7
             END
           ) AS rn
    FROM dup_with_ip
  )
  SELECT timing_class, t_zero_source, COUNT(*) AS n_dup_events
  FROM best_class
  WHERE rn = 1
  GROUP BY timing_class, t_zero_source
  ORDER BY t_zero_source, timing_class
")
ln("## 1. Duplication events classified by IP-stay overlap, stratified by t_zero source")
ln("")
ln("`on_admit_day`, `admit_plus_1d`, `mid_stay_2_to_discharge` are the",
   " reverse-causation buckets (the duplication occurred while the patient",
   " was already in an IP stay). The 2-day induction window currently",
   " catches `on_admit_day` and `admit_plus_1d` but NOT `mid_stay_*`.")
ln("")
ln("| t_zero_source | timing_class | n_dup_events |")
ln("|---|---|---:|")
for (i in seq_len(nrow(q1))) {
  ln(sprintf("| `%s` | `%s` | %s |",
             q1$t_zero_source[i], q1$timing_class[i],
             sup(q1$n_dup_events[i])))
}
ln("")

# ---------------------------------------------------------------------------
# Q2: collapse to a simple "during IP" vs. "not during IP" breakdown,
# stratified by t_zero source. This is the headline number the protocol
# refinement decision rests on.
# ---------------------------------------------------------------------------
cat("[probe] Q2: headline overlap rate by t_zero source...\n")
q2 <- DBI::dbGetQuery(con, "
  WITH dup_with_ip AS (
    SELECT d.PATID, d.raw_first_dup_dt, d.t_zero_source,
           CASE
             WHEN EXISTS (
               SELECT 1 FROM #ip_recon ip
               WHERE ip.PATID = d.PATID
                 AND d.raw_first_dup_dt BETWEEN ip.ADMIT_DATE AND ip.recon_discharge
             ) THEN 1 ELSE 0
           END AS during_ip
    FROM #dup_event_probe d
  )
  SELECT t_zero_source,
         COUNT(*) AS n_total,
         SUM(during_ip) AS n_during_ip,
         SUM(1 - during_ip) AS n_not_during_ip
  FROM dup_with_ip
  GROUP BY t_zero_source
  ORDER BY t_zero_source
")
ln("## 2. Headline: % of duplications occurring during an IP stay, by t_zero source")
ln("")
ln("| t_zero_source | n_total | n_during_ip | n_not_during_ip | % during_ip |")
ln("|---|---:|---:|---:|---:|")
for (i in seq_len(nrow(q2))) {
  pct <- if (q2$n_total[i] > 0) round(100 * q2$n_during_ip[i] / q2$n_total[i], 1) else NA
  ln(sprintf("| `%s` | %s | %s | %s | %s |",
             q2$t_zero_source[i],
             sup(q2$n_total[i]),
             sup(q2$n_during_ip[i]),
             sup(q2$n_not_during_ip[i]),
             ifelse(is.na(pct), "-", sprintf("%.1f%%", pct))))
}
ln("")
ln("**Decision rule for protocol_01 refinement**:",
   " if `% during_ip` is < 1% across both t_zero sources, the existing 2/7/14-day",
   " induction window is sufficient and the refinement is not worth implementing.",
   " If 1-5%, implement as a sensitivity. If > 5%, escalate to a primary-protocol",
   " refinement (the during-IP duplications are excluded by construction; the",
   " duplication still counts as exposure but the concurrent admission is not",
   " counted as the outcome event).")
ln("")

# ---------------------------------------------------------------------------
# Q3: sanity-check break by year. Did the duplication-during-IP rate
# change over time?
# ---------------------------------------------------------------------------
cat("[probe] Q3: duplication-during-IP rate by year...\n")
q3 <- DBI::dbGetQuery(con, "
  WITH dup_with_ip AS (
    SELECT d.PATID, d.raw_first_dup_dt,
           YEAR(d.raw_first_dup_dt) AS yr,
           CASE
             WHEN EXISTS (
               SELECT 1 FROM #ip_recon ip
               WHERE ip.PATID = d.PATID
                 AND d.raw_first_dup_dt BETWEEN ip.ADMIT_DATE AND ip.recon_discharge
             ) THEN 1 ELSE 0
           END AS during_ip
    FROM #dup_event_probe d
  )
  SELECT yr, COUNT(*) AS n_total, SUM(during_ip) AS n_during_ip
  FROM dup_with_ip
  GROUP BY yr
  ORDER BY yr
")
ln("## 3. Duplication-during-IP rate by calendar year")
ln("")
ln("| year | n_total | n_during_ip | % |")
ln("|---|---:|---:|---:|")
for (i in seq_len(nrow(q3))) {
  pct <- if (q3$n_total[i] > 0) round(100 * q3$n_during_ip[i] / q3$n_total[i], 1) else NA
  ln(sprintf("| %d | %s | %s | %s |",
             q3$yr[i],
             sup(q3$n_total[i]),
             sup(q3$n_during_ip[i]),
             ifelse(is.na(pct), "-", sprintf("%.1f%%", pct))))
}
ln("")

# ---------------------------------------------------------------------------
# Cleanup + report.
# ---------------------------------------------------------------------------
DBI::dbExecute(con, "DROP TABLE IF EXISTS #ip_recon;")
DBI::dbExecute(con, "DROP TABLE IF EXISTS #dup_event_probe;")

report_path <- file.path(getwd(), "duplication_during_ip_results.md")
writeLines(out, report_path)
cat(sprintf("\n[probe] Report written to: %s\n", report_path))
cat("[probe] Open the file, eyeball it, then paste it back into the thread.\n")

DBI::dbDisconnect(con)
