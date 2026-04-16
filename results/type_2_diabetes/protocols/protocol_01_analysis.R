# =============================================================================
# Protocol 01: SGLT2i Class vs DPP-4i for 3-Point MACE in Type 2 Diabetes
# Target Trial Emulation — Active Comparator New-User Cohort Design
# =============================================================================
# Database: PCORnet CDW v6.1 (MS SQL Server)
# Schema:   CDW.dbo
# Mode:     OFFLINE (designed for future execution via Rscript)
# Study:    2016-01-01 to 2025-12-31
# =============================================================================

# ── 0. Libraries ─────────────────────────────────────────────────────────────

library(tidyverse)
library(DBI)
library(odbc)
library(WeightIt)
library(cobalt)
library(survival)
library(survminer)
library(sandwich)
library(lmtest)
library(EValue)
library(jsonlite)
library(gtsummary)
library(gt)
library(MatchIt)

# ── 1. Configuration ─────────────────────────────────────────────────────────

config <- list(
  protocol_id       = "protocol_01",
  protocol_title    = "SGLT2i Class vs DPP-4i for 3P-MACE in Type 2 Diabetes",
  db_id             = "secure_pcornet_cdw",
  db_name           = "PCORnet CDW v6.1 (MSSQL)",
  study_start       = "2016-01-01",
  study_end         = "2025-12-31",
  washout_days      = 180L,
  baseline_days     = 365L,
  grace_period_days = 30L,
  rx_duration_default = 90L,
  max_followup_days = 1825L,
  estimand          = "ATO",
  smd_threshold     = 0.10
)

# ── 2. Database Connection ───────────────────────────────────────────────────

con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")
on.exit(DBI::dbDisconnect(con))

# ── 3. Results Accumulator ───────────────────────────────────────────────────

results <- list(
  protocol_id    = config$protocol_id,
  protocol_title = config$protocol_title,
  database       = list(id = config$db_id, name = config$db_name),
  execution_timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
  execution_status    = "running"
)

script_path <- tryCatch({
  args <- commandArgs(trailingOnly = FALSE)
  normalizePath(dirname(sub("--file=", "", args[grep("--file=", args)])))
}, error = function(e) ".")
output_dir <- script_path

# ── 4. RxCUI Code Lists (validated in 03_feasibility.md Appendix A) ──────────

# 4a. SGLT2 Inhibitors ----

rxcui_canagliflozin <- c(
  "1373463", "1373471",   # canagliflozin 100mg, 300mg SCD
  "1373469", "1373473"    # canagliflozin 100mg, 300mg SBD [Invokana]
)
rxcui_canagliflozin_combo <- c(
  "1545150", "1545157", "1545161", "1545164",   # Invokamet SCD
  "1545156", "1545159", "1545163", "1545166",   # Invokamet SBD
  "1810997", "1810999", "1811003", "1811007", "1811011"  # Invokamet XR SCD+SBD
)
rxcui_empagliflozin <- c(
  "1545653", "1545658",   # empagliflozin 10mg, 25mg SCD
  "1545655", "1545660"    # empagliflozin 10mg, 25mg SBD [Jardiance]
)
rxcui_empagliflozin_combo <- c(
  "1602108", "1602112", "1602118", "1602122",   # Synjardy SCD
  "1602110", "1602114", "1602120", "1602124"    # Synjardy SBD
)
rxcui_dapagliflozin <- c(
  "1488564", "1488569",   # dapagliflozin 5mg, 10mg SCD
  "1488566", "1488571"    # dapagliflozin 5mg, 10mg SBD [Farxiga]
)
rxcui_dapagliflozin_combo <- c(
  "1598392", "1598396",   # Xigduo XR SCD (5mg dapa)
  "1598394", "1598398"    # Xigduo XR SBD (5mg dapa)
)

rxcui_sglt2i_all <- unique(c(
  rxcui_canagliflozin, rxcui_canagliflozin_combo,
  rxcui_empagliflozin, rxcui_empagliflozin_combo,
  rxcui_dapagliflozin, rxcui_dapagliflozin_combo
))
rxcui_canagliflozin_all <- c(rxcui_canagliflozin, rxcui_canagliflozin_combo)
rxcui_empagliflozin_all <- c(rxcui_empagliflozin, rxcui_empagliflozin_combo)
rxcui_dapagliflozin_all <- c(rxcui_dapagliflozin, rxcui_dapagliflozin_combo)

# 4b. DPP-4 Inhibitors ----

rxcui_sitagliptin <- c(
  "665033", "665038", "665042",                  # sitagliptin SCD
  "2709603", "2709608", "2709612",               # sitagliptin phosphate SCD
  "665036", "665040", "665044",                  # Januvia SBD
  "2670447", "2670449", "2670451"                # Zituvio SBD
)
rxcui_linagliptin <- c("1100702", "1100706")
rxcui_saxagliptin <- c("858036", "858042", "858040", "858044")
rxcui_alogliptin  <- c("1368006", "1368018", "1368034",
                        "1368012", "1368020", "1368036")

rxcui_dpp4i_all <- c(rxcui_sitagliptin, rxcui_linagliptin,
                     rxcui_saxagliptin, rxcui_alogliptin)

# 4c. 2nd-Generation Sulfonylureas ----

rxcui_glipizide <- c(
  "310488", "310490", "379804", "2737151",       # glipizide IR SCD
  "315107", "314006", "310489",                  # glipizide ER SCD
  "205828",                                       # Glucotrol SBD
  "865568", "865571", "865573"                   # Glucotrol XL SBD
)
rxcui_glimepiride <- c(
  "199245", "199246", "199247", "153842",        # glimepiride SCD
  "1361493", "1361495",                          # glimepiride 6mg, 8mg SCD
  "153843", "153591", "153845"                   # Amaryl SBD
)
rxcui_glyburide <- c(
  "197737", "310534", "310537",                  # glyburide SCD
  "314000", "310536", "310539",                  # glyburide micronized SCD
  "252960", "430102", "430103",                  # glyburide other doses SCD
  "881407", "881409", "881411"                   # Glynase SBD
)

rxcui_su_all <- c(rxcui_glipizide, rxcui_glimepiride, rxcui_glyburide)

# ── 5. Helper Functions ──────────────────────────────────────────────────────

sql_in <- function(codes) {
  paste0("('", paste(codes, collapse = "','"), "')")
}

count_temp <- function(con, tbl) {
  res <- DBI::dbGetQuery(con, sprintf("SELECT COUNT(DISTINCT PATID) AS n FROM %s", tbl))
  res$n[1]
}

build_ps_formula <- function(confounders, data) {
  keep <- vapply(confounders, function(v) {
    x <- data[[v]]
    if (is.null(x)) return(FALSE)
    if (all(is.na(x))) return(FALSE)
    if (is.factor(x) || is.character(x)) return(length(unique(na.omit(x))) >= 2)
    return(sd(x, na.rm = TRUE) > 0)
  }, logical(1))
  kept <- confounders[keep]
  dropped <- confounders[!keep]
  if (length(dropped) > 0) {
    message(sprintf("  PS formula: dropped %d zero-variance/single-level vars: %s",
                    length(dropped), paste(dropped, collapse = ", ")))
  }
  as.formula(paste("treatment ~", paste(kept, collapse = " + ")))
}

# CONSORT text table
print_consort_table <- function(consort) {
  steps <- tibble::tibble(
    Step     = names(consort),
    N        = as.integer(unlist(consort)),
    Excluded = c(NA_integer_, -diff(as.integer(unlist(consort))))
  )
  message("\n=== CONSORT Flow ===")
  print(steps, n = Inf)
  invisible(steps)
}

# CONSORT visual diagram
render_consort_diagram <- function(consort, title = "CONSORT Flow Diagram") {
  grid::grid.newpage()
  box_w  <- grid::unit(0.55, "npc")
  box_h  <- grid::unit(0.06, "npc")
  excl_w <- grid::unit(0.30, "npc")
  excl_h <- grid::unit(0.045, "npc")
  steps  <- names(consort)
  vals   <- as.integer(unlist(consort))
  n_steps <- length(steps)
  y_pos   <- seq(0.92, 0.92 - 0.15 * (n_steps - 1), length.out = n_steps)
  x_main  <- 0.40
  x_excl  <- 0.82

  draw_box <- function(x, y, w, h, label, fill = "white") {
    grid::grid.rect(x = grid::unit(x, "npc"), y = grid::unit(y, "npc"),
                    width = w, height = h,
                    gp = grid::gpar(fill = fill, col = "grey30", lwd = 1.5))
    grid::grid.text(label, x = grid::unit(x, "npc"), y = grid::unit(y, "npc"),
                    gp = grid::gpar(fontsize = 9, fontface = "bold"))
  }
  draw_arrow <- function(x1, y1, x2, y2) {
    grid::grid.lines(x = grid::unit(c(x1, x2), "npc"),
                     y = grid::unit(c(y1, y2), "npc"),
                     arrow = grid::arrow(length = grid::unit(0.015, "npc"), type = "closed"),
                     gp = grid::gpar(fill = "grey30", col = "grey30"))
  }

  grid::grid.text(title, x = 0.5, y = 0.98,
                  gp = grid::gpar(fontsize = 13, fontface = "bold"))

  for (i in seq_along(steps)) {
    fill <- if (i == n_steps) "#F0FFF0" else "white"
    draw_box(x_main, y_pos[i], box_w, box_h,
             sprintf("%s\nn = %s", steps[i], format(vals[i], big.mark = ",")), fill)
    if (i < n_steps) {
      draw_arrow(x_main, y_pos[i] - 0.03, x_main, y_pos[i + 1] + 0.03)
      excl <- vals[i] - vals[i + 1]
      if (excl > 0) {
        mid_y <- mean(c(y_pos[i] - 0.03, y_pos[i + 1] + 0.03))
        draw_arrow(x_main + 0.275, mid_y, x_excl - 0.15, mid_y)
        draw_box(x_excl, mid_y, excl_w, excl_h,
                 sprintf("Excluded: %s", format(excl, big.mark = ",")), fill = "#FFF3F3")
      }
    }
  }
  invisible(NULL)
}

# ── 6. SQL: Identify New Users ───────────────────────────────────────────────

# 6a. SGLT2i new users
sql_sglt2i_new_users <- paste0("
;WITH first_in_study AS (
  SELECT p.PATID, MIN(p.RX_ORDER_DATE) AS index_date
  FROM CDW.dbo.PRESCRIBING p
  WHERE p.RXNORM_CUI IN ", sql_in(rxcui_sglt2i_all), "
    AND p.RX_ORDER_DATE BETWEEN '", config$study_start, "' AND '", config$study_end, "'
  GROUP BY p.PATID
),
new_users AS (
  SELECT s.PATID, s.index_date
  FROM first_in_study s
  WHERE NOT EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p2
    WHERE p2.PATID = s.PATID
      AND p2.RXNORM_CUI IN ", sql_in(rxcui_sglt2i_all), "
      AND p2.RX_ORDER_DATE >= DATEADD(day, -", config$washout_days, ", s.index_date)
      AND p2.RX_ORDER_DATE < s.index_date
      AND p2.RX_ORDER_DATE >= '2005-01-01'
  )
),
tagged AS (
  SELECT nu.PATID, nu.index_date, p.RXNORM_CUI AS index_rxcui,
    ROW_NUMBER() OVER (PARTITION BY nu.PATID ORDER BY p.RXNORM_CUI) AS rn
  FROM new_users nu
  INNER JOIN CDW.dbo.PRESCRIBING p ON nu.PATID = p.PATID
    AND p.RX_ORDER_DATE = nu.index_date
    AND p.RXNORM_CUI IN ", sql_in(rxcui_sglt2i_all), "
)
SELECT PATID, index_date, index_rxcui
INTO #sglt2i_new_users
FROM tagged WHERE rn = 1;
")

# 6b. DPP-4i new users
sql_dpp4i_new_users <- paste0("
;WITH first_in_study AS (
  SELECT p.PATID, MIN(p.RX_ORDER_DATE) AS index_date
  FROM CDW.dbo.PRESCRIBING p
  WHERE p.RXNORM_CUI IN ", sql_in(rxcui_dpp4i_all), "
    AND p.RX_ORDER_DATE BETWEEN '", config$study_start, "' AND '", config$study_end, "'
  GROUP BY p.PATID
),
new_users AS (
  SELECT s.PATID, s.index_date
  FROM first_in_study s
  WHERE NOT EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p2
    WHERE p2.PATID = s.PATID
      AND p2.RXNORM_CUI IN ", sql_in(rxcui_dpp4i_all), "
      AND p2.RX_ORDER_DATE >= DATEADD(day, -", config$washout_days, ", s.index_date)
      AND p2.RX_ORDER_DATE < s.index_date
      AND p2.RX_ORDER_DATE >= '2005-01-01'
  )
),
tagged AS (
  SELECT nu.PATID, nu.index_date, p.RXNORM_CUI AS index_rxcui,
    ROW_NUMBER() OVER (PARTITION BY nu.PATID ORDER BY p.RXNORM_CUI) AS rn
  FROM new_users nu
  INNER JOIN CDW.dbo.PRESCRIBING p ON nu.PATID = p.PATID
    AND p.RX_ORDER_DATE = nu.index_date
    AND p.RXNORM_CUI IN ", sql_in(rxcui_dpp4i_all), "
)
SELECT PATID, index_date, index_rxcui
INTO #dpp4i_new_users
FROM tagged WHERE rn = 1;
")

# 6c. SU new users
sql_su_new_users <- paste0("
;WITH first_in_study AS (
  SELECT p.PATID, MIN(p.RX_ORDER_DATE) AS index_date
  FROM CDW.dbo.PRESCRIBING p
  WHERE p.RXNORM_CUI IN ", sql_in(rxcui_su_all), "
    AND p.RX_ORDER_DATE BETWEEN '", config$study_start, "' AND '", config$study_end, "'
  GROUP BY p.PATID
),
new_users AS (
  SELECT s.PATID, s.index_date
  FROM first_in_study s
  WHERE NOT EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p2
    WHERE p2.PATID = s.PATID
      AND p2.RXNORM_CUI IN ", sql_in(rxcui_su_all), "
      AND p2.RX_ORDER_DATE >= DATEADD(day, -", config$washout_days, ", s.index_date)
      AND p2.RX_ORDER_DATE < s.index_date
      AND p2.RX_ORDER_DATE >= '2005-01-01'
  )
),
tagged AS (
  SELECT nu.PATID, nu.index_date, p.RXNORM_CUI AS index_rxcui,
    ROW_NUMBER() OVER (PARTITION BY nu.PATID ORDER BY p.RXNORM_CUI) AS rn
  FROM new_users nu
  INNER JOIN CDW.dbo.PRESCRIBING p ON nu.PATID = p.PATID
    AND p.RX_ORDER_DATE = nu.index_date
    AND p.RXNORM_CUI IN ", sql_in(rxcui_su_all), "
)
SELECT PATID, index_date, index_rxcui
INTO #su_new_users
FROM tagged WHERE rn = 1;
")

# ── 7. SQL: Combine Initiators & Assign Arms ────────────────────────────────

sql_combine_initiators <- "
SELECT PATID, index_date, 'sglt2i' AS drug_class, index_rxcui
INTO #all_first_dates
FROM #sglt2i_new_users
UNION ALL
SELECT PATID, index_date, 'dpp4i', index_rxcui FROM #dpp4i_new_users
UNION ALL
SELECT PATID, index_date, 'su', index_rxcui FROM #su_new_users;
"

sql_assign_arms <- "
SELECT fi.PATID, fi.first_index_date AS index_date, afd.drug_class, afd.index_rxcui
INTO #all_initiators
FROM (
  SELECT PATID, MIN(index_date) AS first_index_date
  FROM #all_first_dates
  GROUP BY PATID
) fi
INNER JOIN (
  SELECT PATID, index_date, drug_class, index_rxcui,
    ROW_NUMBER() OVER (PARTITION BY PATID ORDER BY index_date, drug_class) AS rn
  FROM #all_first_dates
) afd ON fi.PATID = afd.PATID AND afd.index_date = fi.first_index_date AND afd.rn = 1
WHERE (
  SELECT COUNT(DISTINCT drug_class)
  FROM #all_first_dates afd2
  WHERE afd2.PATID = fi.PATID AND afd2.index_date = fi.first_index_date
) = 1;
"

# ── 8. SQL: Apply Eligibility Criteria ───────────────────────────────────────

sql_eligible <- paste0("
SELECT
  ai.PATID,
  ai.index_date,
  ai.drug_class,
  ai.index_rxcui,
  d.BIRTH_DATE,
  d.SEX,
  d.RACE,
  d.HISPANIC,
  DATEDIFF(year, d.BIRTH_DATE, ai.index_date) AS age_at_index
INTO #eligible
FROM #all_initiators ai
INNER JOIN CDW.dbo.DEMOGRAPHIC d ON ai.PATID = d.PATID
-- T2D diagnosis on or before index
WHERE EXISTS (
  SELECT 1 FROM CDW.dbo.DIAGNOSIS dx
  WHERE dx.PATID = ai.PATID
    AND dx.DX LIKE 'E11%' AND dx.DX_TYPE = '10'
    AND dx.ADMIT_DATE <= ai.index_date
    AND dx.ADMIT_DATE >= '2005-01-01'
)
-- Age >= 18
AND DATEDIFF(year, d.BIRTH_DATE, ai.index_date) >= 18
-- 180-day continuous enrollment
AND EXISTS (
  SELECT 1 FROM CDW.dbo.ENROLLMENT e
  WHERE e.PATID = ai.PATID
    AND e.ENR_START_DATE <= DATEADD(day, -", config$washout_days, ", ai.index_date)
    AND (e.ENR_END_DATE >= ai.index_date OR e.ENR_END_DATE IS NULL)
)
-- Exclude T1D
AND NOT EXISTS (
  SELECT 1 FROM CDW.dbo.DIAGNOSIS dx
  WHERE dx.PATID = ai.PATID AND dx.DX LIKE 'E10%' AND dx.DX_TYPE = '10'
    AND dx.ADMIT_DATE <= ai.index_date AND dx.ADMIT_DATE >= '2005-01-01'
)
-- Exclude gestational diabetes
AND NOT EXISTS (
  SELECT 1 FROM CDW.dbo.DIAGNOSIS dx
  WHERE dx.PATID = ai.PATID AND dx.DX LIKE 'O24%' AND dx.DX_TYPE = '10'
    AND dx.ADMIT_DATE >= '2005-01-01'
)
-- Exclude ESRD / dialysis
AND NOT EXISTS (
  SELECT 1 FROM CDW.dbo.DIAGNOSIS dx
  WHERE dx.PATID = ai.PATID AND dx.DX_TYPE = '10'
    AND (dx.DX = 'N18.6' OR dx.DX = 'Z99.2')
    AND dx.ADMIT_DATE <= ai.index_date AND dx.ADMIT_DATE >= '2005-01-01'
)
AND NOT EXISTS (
  SELECT 1 FROM CDW.dbo.PROCEDURES px
  WHERE px.PATID = ai.PATID AND px.PX_TYPE = 'CH'
    AND px.PX IN ('90935','90937','90940','90945','90947')
    AND px.PX_DATE <= ai.index_date AND px.PX_DATE >= '2005-01-01'
)
-- Exclude active cancer (C00-C97 in 12 months before index)
AND NOT EXISTS (
  SELECT 1 FROM CDW.dbo.DIAGNOSIS dx
  WHERE dx.PATID = ai.PATID AND dx.DX_TYPE = '10'
    AND dx.DX LIKE 'C%' AND dx.DX >= 'C00' AND dx.DX < 'C98'
    AND dx.ADMIT_DATE BETWEEN DATEADD(day, -365, ai.index_date) AND ai.index_date
    AND dx.ADMIT_DATE >= '2005-01-01'
)
-- Valid birth date
AND d.BIRTH_DATE BETWEEN '1900-01-01' AND ai.index_date
;
")

# ── 9. SQL: Ascertain Outcomes ───────────────────────────────────────────────

sql_outcomes <- "
SELECT
  e.PATID,
  e.index_date,
  e.drug_class,
  e.index_rxcui,
  e.age_at_index,
  e.SEX,
  e.RACE,
  e.HISPANIC,
  -- MI: first I21.x (excl type 2) on IP/EI/ED after index
  mi.mi_date,
  -- Stroke: first I63.x on IP/EI/ED after index
  stroke.stroke_date,
  -- Death (deduplicated)
  death.death_date,
  -- CV death flag
  CASE WHEN cv_cause.PATID IS NOT NULL THEN 1 ELSE 0 END AS cv_death_flag,
  -- Enrollment end
  enr.ENR_END_DATE AS enr_end_date
INTO #outcomes
FROM #eligible e
-- Nonfatal MI (join #eligible first to filter post-index before aggregating)
LEFT JOIN (
  SELECT sub.PATID, MIN(sub.mi_date) AS mi_date
  FROM (
    SELECT dx.PATID, enc.ADMIT_DATE AS mi_date
    FROM CDW.dbo.DIAGNOSIS dx
    INNER JOIN CDW.dbo.ENCOUNTER enc ON dx.ENCOUNTERID = enc.ENCOUNTERID
    INNER JOIN #eligible e2 ON dx.PATID = e2.PATID
    WHERE (dx.DX LIKE 'I21%' OR dx.DX LIKE 'I22%')
      AND dx.DX NOT IN ('I21.A1','I21.A9','I21.B')
      AND dx.DX_TYPE = '10'
      AND enc.ENC_TYPE IN ('IP','EI','ED')
      AND enc.RAW_ENC_TYPE <> 'Legacy Encounter'
      AND enc.ADMIT_DATE > e2.index_date
      AND enc.ADMIT_DATE >= '2005-01-01'
  ) sub
  GROUP BY sub.PATID
) mi ON e.PATID = mi.PATID
-- Nonfatal ischemic stroke (join #eligible first to filter post-index before aggregating)
LEFT JOIN (
  SELECT sub.PATID, MIN(sub.stroke_date) AS stroke_date
  FROM (
    SELECT dx.PATID, enc.ADMIT_DATE AS stroke_date
    FROM CDW.dbo.DIAGNOSIS dx
    INNER JOIN CDW.dbo.ENCOUNTER enc ON dx.ENCOUNTERID = enc.ENCOUNTERID
    INNER JOIN #eligible e2 ON dx.PATID = e2.PATID
    WHERE dx.DX LIKE 'I63%'
      AND dx.DX_TYPE = '10'
      AND enc.ENC_TYPE IN ('IP','EI','ED')
      AND enc.RAW_ENC_TYPE <> 'Legacy Encounter'
      AND enc.ADMIT_DATE > e2.index_date
      AND enc.ADMIT_DATE >= '2005-01-01'
  ) sub
  GROUP BY sub.PATID
) stroke ON e.PATID = stroke.PATID
-- Death (deduplicated)
LEFT JOIN (
  SELECT d.PATID, d.DEATH_DATE,
    ROW_NUMBER() OVER (PARTITION BY d.PATID ORDER BY d.DEATH_DATE) AS rn
  FROM CDW.dbo.DEATH d
  WHERE d.DEATH_DATE >= '2005-01-01'
) death ON e.PATID = death.PATID AND death.rn = 1 AND death.DEATH_DATE > e.index_date
-- CV death cause
LEFT JOIN (
  SELECT DISTINCT dc.PATID
  FROM CDW.dbo.DEATH_CAUSE dc
  WHERE dc.DEATH_CAUSE_CODE = '10'
    AND (dc.DEATH_CAUSE LIKE 'I2[0-5]%'
         OR dc.DEATH_CAUSE LIKE 'I46%'
         OR dc.DEATH_CAUSE LIKE 'I50%'
         OR dc.DEATH_CAUSE LIKE 'I6%'
         OR dc.DEATH_CAUSE LIKE 'I71%')
) cv_cause ON death.PATID = cv_cause.PATID
-- Enrollment (for censoring)
LEFT JOIN (
  SELECT en.PATID, en.ENR_END_DATE,
    ROW_NUMBER() OVER (PARTITION BY en.PATID ORDER BY en.ENR_START_DATE DESC) AS rn
  FROM CDW.dbo.ENROLLMENT en
) enr ON e.PATID = enr.PATID AND enr.rn = 1
;
"

# ── 10. SQL: Extract Confounders ─────────────────────────────────────────────

# 10a. Most recent vitals in 365-day lookback
sql_vitals <- "
;WITH vital_ranked AS (
  SELECT v.PATID, v.ORIGINAL_BMI, v.SYSTOLIC, v.DIASTOLIC,
    ROW_NUMBER() OVER (PARTITION BY v.PATID ORDER BY v.MEASURE_DATE DESC) AS rn
  FROM CDW.dbo.VITAL v
  INNER JOIN #outcomes oc ON v.PATID = oc.PATID
  WHERE v.MEASURE_DATE BETWEEN DATEADD(day, -365, oc.index_date) AND oc.index_date
    AND v.MEASURE_DATE >= '2005-01-01'
)
SELECT PATID, ORIGINAL_BMI, SYSTOLIC, DIASTOLIC
INTO #latest_vitals
FROM vital_ranked WHERE rn = 1;
"

# 10b. Most recent labs in 365-day lookback (pivoted to wide format)
sql_labs <- "
;WITH lab_ranked AS (
  SELECT lr.PATID, lr.LAB_LOINC, lr.RESULT_NUM,
    ROW_NUMBER() OVER (PARTITION BY lr.PATID, lr.LAB_LOINC
                       ORDER BY lr.RESULT_DATE DESC) AS rn
  FROM CDW.dbo.LAB_RESULT_CM lr
  INNER JOIN #outcomes oc ON lr.PATID = oc.PATID
  WHERE lr.LAB_LOINC IN ('4548-4','2160-0','48642-3','33914-3',
                          '2093-3','13457-7','2085-9','2571-8',
                          '718-7','2823-3','1742-6')
    AND lr.RESULT_DATE BETWEEN DATEADD(day, -365, oc.index_date) AND oc.index_date
    AND lr.RESULT_DATE >= '2005-01-01'
    AND lr.RESULT_NUM IS NOT NULL
)
SELECT PATID,
  MAX(CASE WHEN LAB_LOINC = '4548-4'  THEN RESULT_NUM END) AS hba1c,
  MAX(CASE WHEN LAB_LOINC = '2160-0'  THEN RESULT_NUM END) AS creatinine,
  COALESCE(
    MAX(CASE WHEN LAB_LOINC = '48642-3' THEN RESULT_NUM END),
    MAX(CASE WHEN LAB_LOINC = '33914-3' THEN RESULT_NUM END)
  ) AS egfr,
  MAX(CASE WHEN LAB_LOINC = '2093-3'  THEN RESULT_NUM END) AS total_cholesterol,
  MAX(CASE WHEN LAB_LOINC = '13457-7' THEN RESULT_NUM END) AS ldl,
  MAX(CASE WHEN LAB_LOINC = '2085-9'  THEN RESULT_NUM END) AS hdl,
  MAX(CASE WHEN LAB_LOINC = '2571-8'  THEN RESULT_NUM END) AS triglycerides,
  MAX(CASE WHEN LAB_LOINC = '718-7'   THEN RESULT_NUM END) AS hemoglobin,
  MAX(CASE WHEN LAB_LOINC = '2823-3'  THEN RESULT_NUM END) AS potassium,
  MAX(CASE WHEN LAB_LOINC = '1742-6'  THEN RESULT_NUM END) AS alt_lab
INTO #latest_labs
FROM lab_ranked WHERE rn = 1
GROUP BY PATID;
"

# 10c. Comorbidities + concomitant medications (binary flags)
sql_patient_flags <- "
SELECT
  oc.PATID,
  -- Comorbidities (any time <= index_date)
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND (dx.DX LIKE 'I10%' OR dx.DX LIKE 'I11%' OR dx.DX LIKE 'I12%'
           OR dx.DX LIKE 'I13%' OR dx.DX LIKE 'I15%' OR dx.DX LIKE 'I16%')
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS htn,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND dx.DX LIKE 'I50%'
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS hf,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND dx.DX LIKE 'I48%'
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS afib,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND dx.DX LIKE 'N18%' AND dx.DX <> 'N18.6'
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS ckd,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND (dx.DX LIKE 'I21%' OR dx.DX = 'I25.2')
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS prior_mi,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND (dx.DX LIKE 'I63%' OR dx.DX = 'Z86.73' OR dx.DX LIKE 'I69.3%')
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS prior_stroke,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND dx.DX LIKE 'J44%'
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS copd,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND dx.DX LIKE 'E66%'
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS obesity,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND dx.DX LIKE 'E78%'
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS dyslipidemia,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND (dx.DX LIKE 'I70%' OR dx.DX = 'I73.9')
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS pad,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND (dx.DX LIKE 'I26%' OR dx.DX LIKE 'I82%')
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS vte,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND (dx.DX LIKE 'F17%' OR dx.DX = 'Z72.0' OR dx.DX = 'Z87.891')
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS tobacco_use,
  -- ASCVD composite flag (for subgroup analysis)
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.DIAGNOSIS dx WHERE dx.PATID = oc.PATID AND dx.DX_TYPE = '10'
      AND (dx.DX LIKE 'I25%' OR dx.DX LIKE 'I21%' OR dx.DX LIKE 'I70%'
           OR dx.DX = 'I73.9' OR dx.DX = 'Z86.73')
      AND dx.ADMIT_DATE <= oc.index_date AND dx.ADMIT_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS ascvd,
  -- Concomitant medications (180-day lookback via RAW_RX_MED_NAME)
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p WHERE p.PATID = oc.PATID
      AND LOWER(p.RAW_RX_MED_NAME) LIKE '%metformin%'
      AND p.RX_ORDER_DATE BETWEEN DATEADD(day, -180, oc.index_date) AND oc.index_date
      AND p.RX_ORDER_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS conmed_metformin,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p WHERE p.PATID = oc.PATID
      AND LOWER(p.RAW_RX_MED_NAME) LIKE '%insulin%'
      AND p.RX_ORDER_DATE BETWEEN DATEADD(day, -180, oc.index_date) AND oc.index_date
      AND p.RX_ORDER_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS conmed_insulin,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p WHERE p.PATID = oc.PATID
      AND (LOWER(p.RAW_RX_MED_NAME) LIKE '%atorvastatin%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%rosuvastatin%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%simvastatin%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%pravastatin%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%lovastatin%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%fluvastatin%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%pitavastatin%')
      AND p.RX_ORDER_DATE BETWEEN DATEADD(day, -180, oc.index_date) AND oc.index_date
      AND p.RX_ORDER_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS conmed_statin,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p WHERE p.PATID = oc.PATID
      AND (LOWER(p.RAW_RX_MED_NAME) LIKE '%lisinopril%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%enalapril%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%ramipril%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%benazepril%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%captopril%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%losartan%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%valsartan%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%irbesartan%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%candesartan%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%olmesartan%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%telmisartan%')
      AND p.RX_ORDER_DATE BETWEEN DATEADD(day, -180, oc.index_date) AND oc.index_date
      AND p.RX_ORDER_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS conmed_acei_arb,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p WHERE p.PATID = oc.PATID
      AND (LOWER(p.RAW_RX_MED_NAME) LIKE '%metoprolol%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%atenolol%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%carvedilol%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%propranolol%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%bisoprolol%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%nebivolol%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%labetalol%')
      AND p.RX_ORDER_DATE BETWEEN DATEADD(day, -180, oc.index_date) AND oc.index_date
      AND p.RX_ORDER_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS conmed_beta_blocker,
  CASE WHEN EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p WHERE p.PATID = oc.PATID
      AND (LOWER(p.RAW_RX_MED_NAME) LIKE '%clopidogrel%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%ticagrelor%'
           OR LOWER(p.RAW_RX_MED_NAME) LIKE '%prasugrel%')
      AND p.RX_ORDER_DATE BETWEEN DATEADD(day, -180, oc.index_date) AND oc.index_date
      AND p.RX_ORDER_DATE >= '2005-01-01'
  ) THEN 1 ELSE 0 END AS conmed_antiplatelet
INTO #patient_flags
FROM #outcomes oc;
"

# ── 11. SQL: Build Final Analytic Cohort ─────────────────────────────────────

sql_analytic_cohort <- "
SELECT
  oc.PATID,
  oc.index_date,
  oc.drug_class,
  oc.index_rxcui,
  oc.age_at_index,
  oc.SEX,
  oc.RACE,
  oc.HISPANIC,
  oc.mi_date,
  oc.stroke_date,
  oc.death_date,
  oc.cv_death_flag,
  oc.enr_end_date,
  -- Vitals
  vit.ORIGINAL_BMI AS bmi,
  vit.SYSTOLIC AS bp_systolic,
  vit.DIASTOLIC AS bp_diastolic,
  -- Labs
  labs.hba1c,
  labs.creatinine,
  labs.egfr,
  labs.total_cholesterol,
  labs.ldl,
  labs.hdl,
  labs.triglycerides,
  labs.hemoglobin,
  labs.potassium,
  labs.alt_lab,
  -- Comorbidities
  pf.htn, pf.hf, pf.afib, pf.ckd, pf.prior_mi, pf.prior_stroke,
  pf.copd, pf.obesity, pf.dyslipidemia, pf.pad, pf.vte, pf.tobacco_use,
  pf.ascvd,
  -- Concomitant meds
  pf.conmed_metformin, pf.conmed_insulin, pf.conmed_statin,
  pf.conmed_acei_arb, pf.conmed_beta_blocker, pf.conmed_antiplatelet
INTO #analytic_cohort
FROM #outcomes oc
LEFT JOIN #latest_vitals vit ON oc.PATID = vit.PATID
LEFT JOIN #latest_labs labs ON oc.PATID = labs.PATID
LEFT JOIN #patient_flags pf ON oc.PATID = pf.PATID;
"

# ── 12. Execute SQL Pipeline ────────────────────────────────────────────────

run_cohort_pipeline <- function(con) {
  consort <- list()

  message("=== Step 1: Identifying SGLT2i new users ===")
  DBI::dbExecute(con, sql_sglt2i_new_users)
  consort[["1a_sglt2i_new_users"]] <- count_temp(con, "#sglt2i_new_users")
  message(sprintf("  SGLT2i new users: %d", consort[["1a_sglt2i_new_users"]]))

  message("=== Step 2: Identifying DPP-4i new users ===")
  DBI::dbExecute(con, sql_dpp4i_new_users)
  consort[["1b_dpp4i_new_users"]] <- count_temp(con, "#dpp4i_new_users")
  message(sprintf("  DPP-4i new users: %d", consort[["1b_dpp4i_new_users"]]))

  message("=== Step 3: Identifying SU new users ===")
  DBI::dbExecute(con, sql_su_new_users)
  consort[["1c_su_new_users"]] <- count_temp(con, "#su_new_users")
  message(sprintf("  SU new users: %d", consort[["1c_su_new_users"]]))

  message("=== Step 4: Combining initiators ===")
  DBI::dbExecute(con, sql_combine_initiators)
  DBI::dbExecute(con, sql_assign_arms)
  consort[["2_all_initiators"]] <- count_temp(con, "#all_initiators")
  message(sprintf("  All initiators (deduplicated): %d", consort[["2_all_initiators"]]))

  message("=== Step 5: Applying eligibility criteria ===")
  DBI::dbExecute(con, sql_eligible)
  consort[["3_eligible"]] <- count_temp(con, "#eligible")
  message(sprintf("  Eligible: %d", consort[["3_eligible"]]))

  message("=== Step 6: Ascertaining outcomes ===")
  DBI::dbExecute(con, sql_outcomes)
  consort[["4_outcomes"]] <- count_temp(con, "#outcomes")
  message(sprintf("  With outcomes: %d", consort[["4_outcomes"]]))

  message("=== Step 7: Extracting vitals ===")
  DBI::dbExecute(con, sql_vitals)

  message("=== Step 8: Extracting labs ===")
  DBI::dbExecute(con, sql_labs)

  message("=== Step 9: Extracting comorbidities & concomitant meds ===")
  DBI::dbExecute(con, sql_patient_flags)

  message("=== Step 10: Building analytic cohort ===")
  DBI::dbExecute(con, sql_analytic_cohort)
  consort[["5_analytic_cohort"]] <- count_temp(con, "#analytic_cohort")
  message(sprintf("  Analytic cohort: %d", consort[["5_analytic_cohort"]]))

  # Pull into R
  cohort <- DBI::dbGetQuery(con, "SELECT * FROM #analytic_cohort")
  names(cohort) <- tolower(names(cohort))

  # Arm counts
  arm_counts <- table(cohort$drug_class)
  message(sprintf("  Arms: %s",
                  paste(names(arm_counts), arm_counts, sep = "=", collapse = ", ")))

  # Clean up temp tables
  temp_tables <- c("#sglt2i_new_users", "#dpp4i_new_users", "#su_new_users",
                   "#all_first_dates", "#all_initiators", "#eligible",
                   "#outcomes", "#latest_vitals", "#latest_labs",
                   "#patient_flags", "#analytic_cohort")
  for (tt in temp_tables) {
    try(DBI::dbExecute(con, paste("DROP TABLE IF EXISTS", tt)), silent = TRUE)
  }

  attr(cohort, "consort") <- consort
  return(cohort)
}

# ── 13. Data Preparation ────────────────────────────────────────────────────

prepare_cohort <- function(cohort) {
  cohort <- cohort %>%
    mutate(
      # Factor coding for demographics
      sex_cat = factor(sex, levels = c("F", "M", "NI", "UN", "OT"),
                       labels = c("Female", "Male", "No info", "Unknown", "Other")),
      race_cat = factor(race,
                        levels = c("01","02","03","04","05","06","07","NI","UN","OT"),
                        labels = c("AI/AN","Asian","Black","NH/PI","White",
                                   "Multiple","Other","No info","Unknown","Refuse")),
      hispanic_cat = factor(hispanic, levels = c("Y","N","NI","UN","OT","R"),
                            labels = c("Yes","No","No info","Unknown","Other","Refuse")),

      # SGLT2i molecule classification
      sglt2i_molecule = case_when(
        drug_class != "sglt2i" ~ NA_character_,
        index_rxcui %in% rxcui_canagliflozin_all ~ "canagliflozin",
        index_rxcui %in% rxcui_empagliflozin_all ~ "empagliflozin",
        index_rxcui %in% rxcui_dapagliflozin_all ~ "dapagliflozin",
        TRUE ~ "unknown_sglt2i"
      ),

      # Date conversions
      index_date   = as.Date(index_date),
      mi_date      = as.Date(mi_date),
      stroke_date  = as.Date(stroke_date),
      death_date   = as.Date(death_date),
      enr_end_date = as.Date(enr_end_date),

      # CV death date
      cv_death_date = if_else(cv_death_flag == 1L & !is.na(death_date),
                              death_date, as.Date(NA)),

      # 3P-MACE composite: first of MI, stroke, CV death
      mace_date = pmin(mi_date, stroke_date, cv_death_date, na.rm = TRUE),

      # Censoring date (non-MACE reasons)
      admin_censor = pmin(
        enr_end_date,
        as.Date(config$study_end),
        index_date + config$max_followup_days,
        na.rm = TRUE
      ),
      non_cv_death_date = if_else(
        !is.na(death_date) & (is.na(cv_death_date) | death_date != cv_death_date),
        death_date, as.Date(NA)
      ),
      censor_date = pmin(non_cv_death_date, admin_censor, na.rm = TRUE),

      # Event indicator and time-to-event
      event = case_when(
        !is.na(mace_date) & !is.na(censor_date) & mace_date <= censor_date ~ 1L,
        !is.na(mace_date) & is.na(censor_date) ~ 1L,
        TRUE ~ 0L
      ),
      time_to_event = as.numeric(if_else(
        event == 1L, mace_date - index_date, censor_date - index_date
      )),
      time_to_event = pmax(time_to_event, 1)
    ) %>%
    # Impute missing continuous confounders with median
    mutate(across(
      c(bmi, bp_systolic, bp_diastolic, hba1c, creatinine, egfr,
        total_cholesterol, ldl, hdl, triglycerides, hemoglobin, potassium, alt_lab),
      ~ if_else(is.na(.), median(., na.rm = TRUE), .)
    ))

  return(cohort)
}

# ── 14. Analysis Functions ───────────────────────────────────────────────────

confounder_vars <- c(
  "age_at_index", "sex_cat", "race_cat", "hispanic_cat",
  "bmi", "bp_systolic", "bp_diastolic",
  "hba1c", "creatinine", "egfr", "total_cholesterol", "ldl", "hdl",
  "triglycerides", "hemoglobin", "potassium", "alt_lab",
  "htn", "hf", "afib", "ckd", "prior_mi", "prior_stroke",
  "copd", "obesity", "dyslipidemia", "pad", "vte", "tobacco_use",
  "conmed_metformin", "conmed_insulin", "conmed_statin",
  "conmed_acei_arb", "conmed_beta_blocker", "conmed_antiplatelet"
)

run_iptw_analysis <- function(analysis_cohort, confounders, label) {
  message(sprintf("\n=== Running IPTW analysis: %s ===", label))
  message(sprintf("  N = %d (treated: %d, control: %d)",
                  nrow(analysis_cohort),
                  sum(analysis_cohort$treatment == 1),
                  sum(analysis_cohort$treatment == 0)))

  # Guard: need both arms
  n_arms <- length(unique(analysis_cohort$treatment))
  if (n_arms < 2) {
    warning(sprintf("Cannot run IPW for %s: only %d arm(s)", label, n_arms))
    return(NULL)
  }

  # Dynamic PS formula
  ps_formula <- build_ps_formula(confounders, analysis_cohort)
  message(sprintf("  PS formula: %s", deparse(ps_formula)))

  # Fit overlap weights
  w <- WeightIt::weightit(
    ps_formula,
    data     = analysis_cohort,
    method   = "glm",
    estimand = config$estimand
  )

  # Balance diagnostics
  bal <- cobalt::bal.tab(w, stats = c("m", "v"), thresholds = c(m = 0.1), un = TRUE)
  message("  Balance summary:")
  print(bal)

  # PS and weights
  analysis_cohort$ps  <- w$ps
  analysis_cohort$ipw <- w$weights

  # Weighted Cox model with robust SEs
  cox_fit <- survival::coxph(
    Surv(time_to_event, event) ~ treatment,
    data    = analysis_cohort,
    weights = ipw,
    robust  = TRUE
  )
  cox_summary <- summary(cox_fit)
  message(sprintf("  HR = %.3f (%.3f - %.3f), p = %.4f",
                  exp(coef(cox_fit)),
                  exp(confint(cox_fit))[1],
                  exp(confint(cox_fit))[2],
                  cox_summary$coefficients[, "Pr(>|z|)"][1]))

  # Pre/post weighting max SMDs
  pre_smds  <- bal$Balance$Diff.Un
  post_smds <- bal$Balance$Diff.Adj
  max_pre   <- max(abs(pre_smds), na.rm = TRUE)
  max_post  <- max(abs(post_smds), na.rm = TRUE)
  message(sprintf("  Max SMD: pre=%.3f, post=%.3f (threshold=%.2f)",
                  max_pre, max_post, config$smd_threshold))

  list(
    weights = w,
    fit     = cox_fit,
    balance = bal,
    cohort  = analysis_cohort,
    hr      = exp(coef(cox_fit))[1],
    ci_lo   = exp(confint(cox_fit))[1],
    ci_hi   = exp(confint(cox_fit))[2],
    p_value = cox_summary$coefficients[, "Pr(>|z|)"][1],
    max_pre_smd  = max_pre,
    max_post_smd = max_post
  )
}

run_subgroup_analysis <- function(cohort_pair, confounders, subgroup_var, subgroup_label) {
  levels <- unique(cohort_pair[[subgroup_var]])
  levels <- levels[!is.na(levels)]
  sub_results <- tibble::tibble(
    subgroup = character(), level = character(),
    n = integer(), events = integer(),
    hr = numeric(), ci_lower = numeric(), ci_upper = numeric()
  )
  for (lev in levels) {
    sub_data <- cohort_pair %>% filter(.data[[subgroup_var]] == lev)
    if (sum(sub_data$treatment == 1) < 20 || sum(sub_data$treatment == 0) < 20) {
      sub_results <- bind_rows(sub_results, tibble::tibble(
        subgroup = subgroup_label, level = as.character(lev),
        n = nrow(sub_data), events = sum(sub_data$event),
        hr = NA_real_, ci_lower = NA_real_, ci_upper = NA_real_
      ))
      next
    }
    tryCatch({
      res <- run_iptw_analysis(sub_data, confounders,
                               sprintf("%s = %s", subgroup_label, lev))
      sub_results <- bind_rows(sub_results, tibble::tibble(
        subgroup = subgroup_label, level = as.character(lev),
        n = nrow(sub_data), events = sum(sub_data$event),
        hr = res$hr, ci_lower = res$ci_lo, ci_upper = res$ci_hi
      ))
    }, error = function(e) {
      message(sprintf("  Subgroup %s=%s failed: %s", subgroup_label, lev, e$message))
      sub_results <<- bind_rows(sub_results, tibble::tibble(
        subgroup = subgroup_label, level = as.character(lev),
        n = nrow(sub_data), events = sum(sub_data$event),
        hr = NA_real_, ci_lower = NA_real_, ci_upper = NA_real_
      ))
    })
  }
  sub_results
}

# ── 15. Publication Output Functions ─────────────────────────────────────────

save_table1 <- function(cohort_pair, confounders, protocol_id, output_dir, suffix = "") {
  fname <- paste0(protocol_id, "_table1", suffix, ".html")
  tbl_data <- cohort_pair %>%
    mutate(treatment_label = if_else(treatment == 1, "SGLT2i", "Comparator")) %>%
    select(treatment_label, all_of(confounders))
  tbl <- tbl_data %>%
    tbl_summary(
      by = treatment_label,
      statistic = list(all_continuous() ~ "{mean} ({sd})",
                       all_categorical() ~ "{n} ({p}%)"),
      missing = "ifany"
    ) %>%
    add_overall() %>%
    add_difference() %>%
    bold_labels() %>%
    as_gt() %>%
    gt::tab_header(title = "Table 1: Baseline Characteristics")
  gt::gtsave(tbl, file.path(output_dir, fname))
  message(sprintf("  Saved: %s", fname))
  fname
}

save_love_plot <- function(weights, protocol_id, output_dir, suffix = "") {
  fname_pdf <- paste0(protocol_id, "_loveplot", suffix, ".pdf")
  fname_png <- paste0(protocol_id, "_loveplot", suffix, ".png")
  p <- cobalt::love.plot(weights, threshold = 0.1, abs = TRUE, un = TRUE,
                         var.order = "unadjusted",
                         title = "Covariate Balance: Before & After Weighting")
  ggplot2::ggsave(file.path(output_dir, fname_pdf), p, width = 8, height = 6)
  ggplot2::ggsave(file.path(output_dir, fname_png), p, width = 8, height = 6, dpi = 300)
  message(sprintf("  Saved: %s", fname_pdf))
  fname_pdf
}

save_ps_distribution <- function(cohort_pair, protocol_id, output_dir, suffix = "") {
  fname_pdf <- paste0(protocol_id, "_ps_dist", suffix, ".pdf")
  fname_png <- paste0(protocol_id, "_ps_dist", suffix, ".png")
  cohort_pair <- cohort_pair %>%
    mutate(treatment_label = if_else(treatment == 1, "SGLT2i", "Comparator"))
  p <- ggplot(cohort_pair, aes(x = ps, fill = treatment_label)) +
    geom_density(alpha = 0.5) +
    labs(x = "Propensity Score", y = "Density",
         title = "Propensity Score Distribution", fill = "Treatment") +
    theme_minimal() + theme(legend.position = "bottom")
  ggplot2::ggsave(file.path(output_dir, fname_pdf), p, width = 7, height = 5)
  ggplot2::ggsave(file.path(output_dir, fname_png), p, width = 7, height = 5, dpi = 300)
  message(sprintf("  Saved: %s", fname_pdf))
  fname_pdf
}

save_km_curves <- function(cohort_pair, protocol_id, output_dir, suffix = "") {
  fname_pdf <- paste0(protocol_id, "_km", suffix, ".pdf")
  fname_png <- paste0(protocol_id, "_km", suffix, ".png")
  cohort_pair <- cohort_pair %>%
    mutate(treatment_label = if_else(treatment == 1, "SGLT2i", "Comparator"))
  km_fit <- survfit(Surv(time_to_event, event) ~ treatment_label,
                    data = cohort_pair, weights = cohort_pair$ipw)
  p <- ggsurvplot(km_fit, data = cohort_pair, risk.table = TRUE, pval = TRUE,
                  xlab = "Days from Time Zero", ylab = "MACE-Free Probability",
                  palette = c("#E7B800", "#2E9FDF"),
                  title = paste("Kaplan-Meier: 3P-MACE", suffix))
  pdf(file.path(output_dir, fname_pdf), width = 8, height = 7)
  print(p)
  dev.off()
  png(file.path(output_dir, fname_png), width = 2400, height = 2100, res = 300)
  print(p)
  dev.off()
  message(sprintf("  Saved: %s", fname_pdf))
  fname_pdf
}

save_forest_plot <- function(subgroup_results, protocol_id, output_dir) {
  fname_pdf <- paste0(protocol_id, "_forest.pdf")
  fname_png <- paste0(protocol_id, "_forest.png")
  df <- subgroup_results %>% filter(!is.na(hr))
  if (nrow(df) < 2) {
    message("  Skipped forest plot: fewer than 2 estimable subgroups")
    return(NULL)
  }
  df <- df %>% mutate(label = paste0(subgroup, ": ", level))
  p <- ggplot(df, aes(x = hr, y = forcats::fct_rev(label))) +
    geom_point(size = 3) +
    geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper), height = 0.2) +
    geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
    scale_x_log10() +
    labs(x = "Hazard Ratio (95% CI)", y = NULL,
         title = "Subgroup Analysis: SGLT2i vs DPP-4i for 3P-MACE") +
    theme_minimal()
  ggplot2::ggsave(file.path(output_dir, fname_pdf), p, width = 8, height = 5)
  ggplot2::ggsave(file.path(output_dir, fname_png), p, width = 8, height = 5, dpi = 300)
  message(sprintf("  Saved: %s", fname_pdf))
  fname_pdf
}

save_consort_figure <- function(consort, protocol_id, output_dir) {
  fname_pdf <- paste0(protocol_id, "_consort.pdf")
  fname_png <- paste0(protocol_id, "_consort.png")
  pdf(file.path(output_dir, fname_pdf), width = 10, height = 12)
  render_consort_diagram(consort)
  dev.off()
  png(file.path(output_dir, fname_png), width = 3000, height = 3600, res = 300)
  render_consort_diagram(consort)
  dev.off()
  message(sprintf("  Saved: %s", fname_pdf))
  fname_pdf
}

# ── 16. Main Analysis Pipeline ───────────────────────────────────────────────

tryCatch({

  # ── A. Build Cohort ──
  cohort <- run_cohort_pipeline(con)
  consort <- attr(cohort, "consort")
  print_consort_table(consort)

  results$consort <- consort

  # ── B. Guard: empty cohort ──
  if (nrow(cohort) == 0) {
    message("*** STOPPING: Analytic cohort has 0 patients. ***")
    results$execution_status <- "error"
    results$errors <- list(list(message = "Empty analytic cohort"))
    jsonlite::write_json(results, file.path(output_dir, "protocol_01_results.json"),
                         pretty = TRUE, auto_unbox = TRUE)
    stop("Empty cohort")
  }

  # ── C. Prepare Data ──
  cohort <- prepare_cohort(cohort)

  # ── D. Primary Analysis: SGLT2i vs DPP-4i ──
  primary_cohort <- cohort %>%
    filter(drug_class %in% c("sglt2i", "dpp4i")) %>%
    mutate(treatment = as.integer(drug_class == "sglt2i"))

  n_arms_primary <- length(unique(primary_cohort$treatment))
  if (n_arms_primary < 2) {
    stop("Primary comparison has < 2 arms")
  }

  primary_result <- run_iptw_analysis(primary_cohort, confounder_vars,
                                      "Primary: SGLT2i vs DPP-4i")

  results$primary_analysis <- list(
    comparison     = "SGLT2i vs DPP-4i",
    method         = "IPW-weighted Cox PH (overlap weights)",
    estimand       = config$estimand,
    effect_measure = "HR",
    point_estimate = primary_result$hr,
    ci_lower       = primary_result$ci_lo,
    ci_upper       = primary_result$ci_hi,
    p_value        = primary_result$p_value,
    n_treated      = sum(primary_cohort$treatment == 1),
    n_control      = sum(primary_cohort$treatment == 0),
    events_treated = sum(primary_cohort$event[primary_cohort$treatment == 1]),
    events_control = sum(primary_cohort$event[primary_cohort$treatment == 0])
  )

  results$balance_diagnostics <- list(
    pre_weighting_max_smd  = primary_result$max_pre_smd,
    post_weighting_max_smd = primary_result$max_post_smd,
    all_below_threshold    = primary_result$max_post_smd < config$smd_threshold,
    threshold              = config$smd_threshold
  )

  results$outcome_summary <- list(
    total_events    = sum(primary_cohort$event),
    events_treated  = sum(primary_cohort$event[primary_cohort$treatment == 1]),
    events_control  = sum(primary_cohort$event[primary_cohort$treatment == 0]),
    median_followup_days = median(primary_cohort$time_to_event)
  )

  # ── E. Secondary Analysis: SGLT2i vs SU ──
  secondary_cohort <- cohort %>%
    filter(drug_class %in% c("sglt2i", "su")) %>%
    mutate(treatment = as.integer(drug_class == "sglt2i"))

  secondary_result <- NULL
  if (length(unique(secondary_cohort$treatment)) >= 2) {
    secondary_result <- run_iptw_analysis(secondary_cohort, confounder_vars,
                                          "Secondary: SGLT2i vs SU")
    results$secondary_analysis <- list(
      comparison     = "SGLT2i vs SU",
      method         = "IPW-weighted Cox PH (overlap weights)",
      estimand       = config$estimand,
      effect_measure = "HR",
      point_estimate = secondary_result$hr,
      ci_lower       = secondary_result$ci_lo,
      ci_upper       = secondary_result$ci_hi,
      p_value        = secondary_result$p_value,
      n_treated      = sum(secondary_cohort$treatment == 1),
      n_control      = sum(secondary_cohort$treatment == 0)
    )
  } else {
    message("  Secondary comparison skipped: < 2 arms")
  }

  # ── F. Sensitivity: Canagliflozin Subgroup ──
  cana_cohort <- cohort %>%
    filter(drug_class == "dpp4i" |
           (drug_class == "sglt2i" & sglt2i_molecule == "canagliflozin")) %>%
    mutate(treatment = as.integer(drug_class == "sglt2i"))

  cana_result <- NULL
  if (sum(cana_cohort$treatment == 1) >= 20 &&
      sum(cana_cohort$treatment == 0) >= 20) {
    cana_result <- tryCatch(
      run_iptw_analysis(cana_cohort, confounder_vars,
                        "Sensitivity: Canagliflozin vs DPP-4i"),
      error = function(e) {
        message(sprintf("  Canagliflozin subgroup failed: %s", e$message))
        NULL
      }
    )
    if (!is.null(cana_result)) {
      results$sensitivity_canagliflozin <- list(
        comparison     = "Canagliflozin vs DPP-4i (descriptive)",
        n_canagliflozin = sum(cana_cohort$treatment == 1),
        point_estimate  = cana_result$hr,
        ci_lower        = cana_result$ci_lo,
        ci_upper        = cana_result$ci_hi,
        note            = "Underpowered; interpret with caution"
      )
    }
  } else {
    message(sprintf("  Canagliflozin subgroup too small (N=%d); skipping formal analysis",
                    sum(cana_cohort$treatment == 1)))
    results$sensitivity_canagliflozin <- list(
      comparison      = "Canagliflozin vs DPP-4i (not estimable)",
      n_canagliflozin = sum(cana_cohort$treatment == 1),
      note            = "Insufficient sample size for formal analysis"
    )
  }

  # ── G. Sensitivity Analyses ──
  message("\n=== Sensitivity Analyses ===")
  results$sensitivity_analyses <- list()

  # ── G1. E-value ──
  tryCatch({
    hr  <- primary_result$hr
    lo  <- primary_result$ci_lo
    hi  <- primary_result$ci_hi
    ev  <- EValue::evalues.HR(hr, lo = lo, hi = hi, rare = TRUE)
    results$sensitivity_analyses$e_value <- list(
      point    = ev[2, "point"],
      ci_bound = ev[2, "lower"]
    )
    message(sprintf("  E-value: point=%.2f, CI bound=%.2f",
                    ev[2, "point"], ev[2, "lower"]))
  }, error = function(e) {
    message(sprintf("  E-value computation failed: %s", e$message))
  })

  # ── G2. All-cause mortality MACE (replace CV death with all-cause death) ──
  tryCatch({
    message("\n--- Sensitivity: All-cause mortality MACE ---")
    sa_allcause <- primary_result$cohort %>%
      mutate(
        mace_date_ac = pmin(mi_date, stroke_date, death_date, na.rm = TRUE),
        admin_censor_ac = pmin(
          enr_end_date,
          as.Date(config$study_end),
          index_date + config$max_followup_days,
          na.rm = TRUE
        ),
        event_ac = case_when(
          !is.na(mace_date_ac) & !is.na(admin_censor_ac) &
            mace_date_ac <= admin_censor_ac ~ 1L,
          !is.na(mace_date_ac) & is.na(admin_censor_ac) ~ 1L,
          TRUE ~ 0L
        ),
        time_to_event_ac = as.numeric(if_else(
          event_ac == 1L, mace_date_ac - index_date, admin_censor_ac - index_date
        )),
        time_to_event_ac = pmax(time_to_event_ac, 1)
      )
    cox_ac <- coxph(Surv(time_to_event_ac, event_ac) ~ treatment,
                    data = sa_allcause, weights = ipw, robust = TRUE)
    cox_ac_s <- summary(cox_ac)
    results$sensitivity_analyses$allcause_mace <- list(
      description = "3P-MACE with all-cause mortality replacing CV death",
      hr       = exp(coef(cox_ac))[1],
      ci_lower = exp(confint(cox_ac))[1],
      ci_upper = exp(confint(cox_ac))[2],
      p_value  = cox_ac_s$coefficients[, "Pr(>|z|)"][1],
      n_events = sum(sa_allcause$event_ac)
    )
    message(sprintf("  All-cause MACE HR: %.3f (%.3f-%.3f), events=%d",
                    exp(coef(cox_ac))[1], exp(confint(cox_ac))[1],
                    exp(confint(cox_ac))[2], sum(sa_allcause$event_ac)))
  }, error = function(e) {
    message(sprintf("  All-cause MACE sensitivity failed: %s", e$message))
  })

  # ── G3. Include type 2 MI (add I21.A1 to MI definition) ──
  tryCatch({
    message("\n--- Sensitivity: Include type 2 MI (I21.A1) ---")
    sql_type2mi <- "
    SELECT sub.PATID, MIN(sub.mi_date) AS type2_mi_date
    FROM (
      SELECT dx.PATID, enc.ADMIT_DATE AS mi_date
      FROM CDW.dbo.DIAGNOSIS dx
      INNER JOIN CDW.dbo.ENCOUNTER enc ON dx.ENCOUNTERID = enc.ENCOUNTERID
      INNER JOIN #analytic_cohort ac ON dx.PATID = ac.PATID
      WHERE dx.DX = 'I21.A1'
        AND dx.DX_TYPE = '10'
        AND enc.ENC_TYPE IN ('IP','EI','ED')
        AND enc.RAW_ENC_TYPE <> 'Legacy Encounter'
        AND enc.ADMIT_DATE > ac.index_date
        AND enc.ADMIT_DATE >= '2005-01-01'
    ) sub
    GROUP BY sub.PATID
    "
    type2mi_data <- dbGetQuery(con, sql_type2mi)
    names(type2mi_data) <- tolower(names(type2mi_data))
    type2mi_data$type2_mi_date <- as.Date(type2mi_data$type2_mi_date)

    sa_type2mi <- primary_result$cohort %>%
      left_join(type2mi_data, by = "patid") %>%
      mutate(
        mi_date_broad = pmin(mi_date, type2_mi_date, na.rm = TRUE),
        mace_date_t2 = pmin(mi_date_broad, stroke_date, cv_death_date, na.rm = TRUE),
        event_t2 = case_when(
          !is.na(mace_date_t2) & !is.na(censor_date) &
            mace_date_t2 <= censor_date ~ 1L,
          !is.na(mace_date_t2) & is.na(censor_date) ~ 1L,
          TRUE ~ 0L
        ),
        time_to_event_t2 = as.numeric(if_else(
          event_t2 == 1L, mace_date_t2 - index_date, censor_date - index_date
        )),
        time_to_event_t2 = pmax(time_to_event_t2, 1)
      )
    cox_t2 <- coxph(Surv(time_to_event_t2, event_t2) ~ treatment,
                    data = sa_type2mi, weights = ipw, robust = TRUE)
    cox_t2_s <- summary(cox_t2)
    results$sensitivity_analyses$include_type2_mi <- list(
      description = "3P-MACE with type 2 MI (I21.A1) included",
      hr       = exp(coef(cox_t2))[1],
      ci_lower = exp(confint(cox_t2))[1],
      ci_upper = exp(confint(cox_t2))[2],
      p_value  = cox_t2_s$coefficients[, "Pr(>|z|)"][1],
      n_events = sum(sa_type2mi$event_t2),
      n_type2_mi_events = sum(!is.na(type2mi_data$type2_mi_date))
    )
    message(sprintf("  Type 2 MI MACE HR: %.3f (%.3f-%.3f), events=%d (type 2 MI events=%d)",
                    exp(coef(cox_t2))[1], exp(confint(cox_t2))[1],
                    exp(confint(cox_t2))[2], sum(sa_type2mi$event_t2),
                    sum(!is.na(type2mi_data$type2_mi_date))))
  }, error = function(e) {
    message(sprintf("  Type 2 MI sensitivity failed: %s", e$message))
  })

  # ── G4. Exclude saxagliptin from DPP-4i arm ──
  tryCatch({
    message("\n--- Sensitivity: Exclude saxagliptin ---")
    sa_no_saxa <- cohort %>%
      filter(drug_class %in% c("sglt2i", "dpp4i")) %>%
      filter(!(index_rxcui %in% rxcui_saxagliptin)) %>%
      mutate(treatment = as.integer(drug_class == "sglt2i"))

    n_saxa_excluded <- sum(cohort$drug_class == "dpp4i" &
                           cohort$index_rxcui %in% rxcui_saxagliptin)
    message(sprintf("  Excluded %d saxagliptin patients from DPP-4i arm", n_saxa_excluded))

    if (length(unique(sa_no_saxa$treatment)) >= 2 &&
        sum(sa_no_saxa$treatment == 0) >= 20) {
      sa_no_saxa_result <- run_iptw_analysis(sa_no_saxa, confounder_vars,
                                             "Sensitivity: Exclude saxagliptin")
      results$sensitivity_analyses$exclude_saxagliptin <- list(
        description = "SGLT2i vs DPP-4i excluding saxagliptin users",
        hr       = sa_no_saxa_result$hr,
        ci_lower = sa_no_saxa_result$ci_lo,
        ci_upper = sa_no_saxa_result$ci_hi,
        p_value  = sa_no_saxa_result$p_value,
        n_excluded = n_saxa_excluded,
        n_remaining_dpp4i = sum(sa_no_saxa$treatment == 0)
      )
      message(sprintf("  Excl. saxagliptin HR: %.3f (%.3f-%.3f)",
                      sa_no_saxa_result$hr, sa_no_saxa_result$ci_lo,
                      sa_no_saxa_result$ci_hi))
    } else {
      message("  Too few patients after excluding saxagliptin; skipping")
      results$sensitivity_analyses$exclude_saxagliptin <- list(
        description = "Not estimable — insufficient DPP-4i patients after exclusion",
        n_excluded = n_saxa_excluded
      )
    }
  }, error = function(e) {
    message(sprintf("  Exclude saxagliptin sensitivity failed: %s", e$message))
  })

  # ── G5. As-treated analysis (censor at discontinuation + 30-day grace) ──
  tryCatch({
    message("\n--- Sensitivity: As-treated analysis ---")

    # Pull all post-index prescriptions for primary cohort drug classes
    rxcui_primary <- paste0("'", c(rxcui_sglt2i_all, rxcui_dpp4i_all), "'",
                            collapse = ",")
    sql_rx_duration <- sprintf("
    SELECT p.PATID, p.RX_ORDER_DATE,
           COALESCE(p.RX_END_DATE,
                    DATEADD(day, COALESCE(p.RX_DAYS_SUPPLY, %d),
                            p.RX_ORDER_DATE)) AS rx_end_est
    FROM CDW.dbo.PRESCRIBING p
    INNER JOIN #analytic_cohort ac ON p.PATID = ac.PATID
    WHERE p.RXNORM_CUI IN (%s)
      AND p.RX_ORDER_DATE >= ac.index_date
      AND p.RX_ORDER_DATE >= '2016-01-01'
      AND p.RX_ORDER_DATE <= GETDATE()
    ORDER BY p.PATID, p.RX_ORDER_DATE
    ", config$rx_duration_default, rxcui_primary)

    rx_data <- dbGetQuery(con, sql_rx_duration)
    names(rx_data) <- tolower(names(rx_data))
    rx_data <- rx_data %>%
      mutate(rx_order_date = as.Date(rx_order_date),
             rx_end_est    = as.Date(rx_end_est))

    # Chain prescriptions: find discontinuation date per patient
    compute_discont <- function(pat_rx, grace_days) {
      pat_rx <- pat_rx %>% arrange(rx_order_date)
      current_end <- pat_rx$rx_end_est[1]
      for (i in seq_len(nrow(pat_rx))[-1]) {
        gap <- as.numeric(pat_rx$rx_order_date[i] - current_end)
        if (gap > grace_days) break
        current_end <- max(current_end, pat_rx$rx_end_est[i])
      }
      current_end + grace_days
    }

    discont <- rx_data %>%
      group_by(patid) %>%
      summarise(discont_date = compute_discont(pick(everything()),
                                              config$grace_period_days),
                .groups = "drop")

    sa_at <- primary_result$cohort %>%
      left_join(discont, by = "patid") %>%
      mutate(
        at_censor = pmin(discont_date, censor_date, na.rm = TRUE),
        event_at = case_when(
          !is.na(mace_date) & !is.na(at_censor) & mace_date <= at_censor ~ 1L,
          !is.na(mace_date) & is.na(at_censor) ~ 1L,
          TRUE ~ 0L
        ),
        time_to_event_at = as.numeric(if_else(
          event_at == 1L, mace_date - index_date, at_censor - index_date
        )),
        time_to_event_at = pmax(time_to_event_at, 1)
      )

    cox_at <- coxph(Surv(time_to_event_at, event_at) ~ treatment,
                    data = sa_at, weights = ipw, robust = TRUE)
    cox_at_s <- summary(cox_at)
    results$sensitivity_analyses$as_treated <- list(
      description = "As-treated: censored at discontinuation + 30-day grace",
      hr       = exp(coef(cox_at))[1],
      ci_lower = exp(confint(cox_at))[1],
      ci_upper = exp(confint(cox_at))[2],
      p_value  = cox_at_s$coefficients[, "Pr(>|z|)"][1],
      n_events = sum(sa_at$event_at),
      median_treatment_days = median(as.numeric(
        sa_at$discont_date - sa_at$index_date), na.rm = TRUE)
    )
    message(sprintf("  As-treated HR: %.3f (%.3f-%.3f), events=%d, median Tx=%.0f days",
                    exp(coef(cox_at))[1], exp(confint(cox_at))[1],
                    exp(confint(cox_at))[2], sum(sa_at$event_at),
                    median(as.numeric(sa_at$discont_date - sa_at$index_date),
                           na.rm = TRUE)))
  }, error = function(e) {
    message(sprintf("  As-treated sensitivity failed: %s", e$message))
  })

  # ── G6. PS matching (1:1 nearest-neighbor) ──
  tryCatch({
    message("\n--- Sensitivity: PS matching (1:1 nearest-neighbor) ---")
    m <- MatchIt::matchit(
      build_ps_formula(confounder_vars, primary_result$cohort),
      data    = primary_result$cohort,
      method  = "nearest",
      ratio   = 1,
      caliper = 0.2,
      std.caliper = TRUE
    )
    matched_data <- MatchIt::match.data(m)
    message(sprintf("  Matched: %d treated, %d control (of %d/%d original)",
                    sum(matched_data$treatment == 1),
                    sum(matched_data$treatment == 0),
                    sum(primary_result$cohort$treatment == 1),
                    sum(primary_result$cohort$treatment == 0)))

    cox_match <- coxph(Surv(time_to_event, event) ~ treatment,
                       data = matched_data, robust = TRUE)
    cox_match_s <- summary(cox_match)
    results$sensitivity_analyses$ps_matching <- list(
      description = "1:1 nearest-neighbor PS matching (caliper 0.2 SD)",
      hr       = exp(coef(cox_match))[1],
      ci_lower = exp(confint(cox_match))[1],
      ci_upper = exp(confint(cox_match))[2],
      p_value  = cox_match_s$coefficients[, "Pr(>|z|)"][1],
      n_matched_treated = sum(matched_data$treatment == 1),
      n_matched_control = sum(matched_data$treatment == 0),
      n_unmatched       = nrow(primary_result$cohort) - nrow(matched_data)
    )
    message(sprintf("  PS matching HR: %.3f (%.3f-%.3f)",
                    exp(coef(cox_match))[1], exp(confint(cox_match))[1],
                    exp(confint(cox_match))[2]))
  }, error = function(e) {
    message(sprintf("  PS matching sensitivity failed: %s", e$message))
  })

  # ── H. Subgroup Analyses ──
  message("\n=== Subgroup Analyses ===")
  primary_cohort_prepped <- primary_result$cohort

  primary_cohort_prepped <- primary_cohort_prepped %>%
    mutate(
      age_group = if_else(age_at_index >= 65, ">=65", "<65"),
      ckd_flag  = if_else(ckd == 1 | (!is.na(egfr) & egfr < 60), "CKD", "No CKD"),
      ascvd_flag = if_else(ascvd == 1, "ASCVD", "No ASCVD")
    )

  subgroup_results <- bind_rows(
    run_subgroup_analysis(primary_cohort_prepped, confounder_vars,
                          "age_group", "Age"),
    run_subgroup_analysis(primary_cohort_prepped, confounder_vars,
                          "sex_cat", "Sex"),
    run_subgroup_analysis(primary_cohort_prepped, confounder_vars,
                          "ascvd_flag", "Prior ASCVD"),
    run_subgroup_analysis(primary_cohort_prepped, confounder_vars,
                          "ckd_flag", "CKD Status")
  )

  results$subgroup_analyses <- subgroup_results %>%
    purrr::transpose() %>%
    lapply(as.list)

  message("\n  Subgroup results:")
  print(subgroup_results, n = Inf)

  # ── I. Mark success and save JSON ──
  results$execution_status <- "success"

}, error = function(e) {
  results$execution_status <<- "error"
  results$errors <<- list(list(
    message = conditionMessage(e),
    call    = deparse(conditionCall(e))
  ))
  message(sprintf("PIPELINE ERROR: %s", conditionMessage(e)))
})

# ── 17. Save Results JSON (always, even on error) ───────────────────────────

results$execution_timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
results_path <- file.path(output_dir, "protocol_01_results.json")
jsonlite::write_json(results, results_path, pretty = TRUE, auto_unbox = TRUE)
message(sprintf("\nResults saved to: %s", results_path))

# ── 18. Publication Outputs (non-fatal) ──────────────────────────────────────

tryCatch({
  message("\n=== Generating Publication Outputs ===")

  # CONSORT
  if (exists("consort") && !is.null(consort)) {
    save_consort_figure(consort, config$protocol_id, output_dir)
  }

  # Primary comparison outputs
  if (exists("primary_result") && !is.null(primary_result)) {
    save_table1(primary_result$cohort, confounder_vars,
                config$protocol_id, output_dir)
    save_love_plot(primary_result$weights, config$protocol_id, output_dir)
    save_ps_distribution(primary_result$cohort, config$protocol_id, output_dir)
    save_km_curves(primary_result$cohort, config$protocol_id, output_dir)
  }

  # Secondary comparison outputs
  if (exists("secondary_result") && !is.null(secondary_result)) {
    save_table1(secondary_result$cohort, confounder_vars,
                config$protocol_id, output_dir, suffix = "_vs_su")
    save_love_plot(secondary_result$weights, config$protocol_id, output_dir,
                   suffix = "_vs_su")
    save_km_curves(secondary_result$cohort, config$protocol_id, output_dir,
                   suffix = "_vs_su")
  }

  # Forest plot
  if (exists("subgroup_results")) {
    save_forest_plot(subgroup_results, config$protocol_id, output_dir)
  }

  # Update JSON with figure paths and re-save
  results$figure_paths <- list(
    consort         = paste0(config$protocol_id, "_consort.pdf"),
    table1          = paste0(config$protocol_id, "_table1.html"),
    love_plot       = paste0(config$protocol_id, "_loveplot.pdf"),
    ps_distribution = paste0(config$protocol_id, "_ps_dist.pdf"),
    km_curve        = paste0(config$protocol_id, "_km.pdf"),
    forest_plot     = paste0(config$protocol_id, "_forest.pdf")
  )
  jsonlite::write_json(results, results_path, pretty = TRUE, auto_unbox = TRUE)

  message("=== Publication outputs complete ===")
}, error = function(e) {
  message(sprintf("WARNING: Publication output generation failed: %s",
                  conditionMessage(e)))
  message("JSON results were already saved successfully.")
})

message("\n=== Protocol 01 analysis complete ===")
