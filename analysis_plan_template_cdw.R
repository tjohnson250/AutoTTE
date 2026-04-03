# =============================================================================
# Auto-Protocol Designer — R + SQL Analysis Plan Template (PCORnet CDW)
# =============================================================================
# This template generates T-SQL queries against a PCORnet Common Data Model
# hosted on MS SQL Server, pulls the analytic dataset into R, and runs the
# causal analysis. The agent fills in the {{PLACEHOLDERS}}.
#
# Framework: Target Trial Emulation (Hernán & Robins)
# Database: PCORnet CDM on MS SQL Server
# Connection: DBI + odbc
# =============================================================================

library(tidyverse)
library(DBI)
library(odbc)
library(dbplyr)       # for dplyr-to-SQL translation (optional)
library(WeightIt)     # propensity score weighting
library(cobalt)       # balance diagnostics
library(survival)     # time-to-event outcomes
library(sandwich)     # robust SEs
library(lmtest)       # coeftest with robust SEs
library(EValue)       # sensitivity analysis


# ─── 0. Configuration (filled by agent) ─────────────────────────────────────

config <- list(
  # Database connection
  server       = "{{SQL_SERVER}}",
  database     = "{{DATABASE_NAME}}",       # e.g., "CDW"
  driver       = "ODBC Driver 17 for SQL Server",

  # Study parameters
  question         = "{{CAUSAL_QUESTION}}",
  exposure_var     = "{{EXPOSURE_VAR}}",
  outcome_var      = "{{OUTCOME_VAR}}",
  time_var         = "{{TIME_VAR}}",        # NULL if not time-to-event
  estimand         = "{{ESTIMAND}}",        # ATE, ATT
  analysis_method  = "{{METHOD}}",          # ipw, gcomp, tmle

  # Date window for study
  study_start      = "{{STUDY_START}}",     # e.g., "2015-01-01"
  study_end        = "{{STUDY_END}}",       # e.g., "2023-12-31"
  followup_days    = {{FOLLOWUP_DAYS}}      # e.g., 365
)


# ─── 1. Database Connection ─────────────────────────────────────────────────

connect_cdw <- function(config) {
  con <- dbConnect(
    odbc::odbc(),
    Driver   = config$driver,
    Server   = config$server,
    Database = config$database,
    Trusted_Connection = "yes"   # Windows integrated auth
  )
  message(sprintf("Connected to %s.%s", config$server, config$database))
  return(con)
}


# ─── 2. Cohort SQL ──────────────────────────────────────────────────────────
# The agent writes T-SQL that defines the analytic cohort. This is the heart
# of the target trial emulation — every element of the protocol maps to SQL.

build_cohort_sql <- function(config) {
  # ── Step 1: Eligible population ──
  # Identifies patients meeting eligibility criteria at their index date (time zero).
  # The agent maps each protocol eligibility criterion to PCORnet tables/columns.

  eligibility_sql <- glue::glue_sql("
    -- =========================================================
    -- STEP 1: Eligible Population
    -- Protocol: {{ELIGIBILITY_DESCRIPTION}}
    -- =========================================================

    -- Index encounters: {{TIME_ZERO_DEFINITION}}
    SELECT DISTINCT
      e.PATID,
      e.ENCOUNTERID,
      e.ADMIT_DATE AS index_date,
      d.BIRTH_DATE,
      d.SEX,
      d.RACE,
      d.HISPANIC,
      DATEDIFF(year, d.BIRTH_DATE, e.ADMIT_DATE) AS age_at_index
    INTO #eligible
    FROM dbo.ENCOUNTER e
    INNER JOIN dbo.DEMOGRAPHIC d
      ON e.PATID = d.PATID
    WHERE e.ADMIT_DATE BETWEEN {config$study_start} AND {config$study_end}
      AND e.ENC_TYPE IN ({{ENC_TYPES}})        -- e.g., ('IP', 'EI') for inpatient
      -- {{ADDITIONAL_ELIGIBILITY_CRITERIA}}
      -- Example: patient must have a diagnosis of atrial fibrillation
      AND EXISTS (
        SELECT 1 FROM dbo.DIAGNOSIS dx
        WHERE dx.PATID = e.PATID
          AND dx.DX LIKE {{DX_PATTERN}}         -- e.g., 'I48%' for afib
          AND dx.DX_TYPE = '10'                  -- ICD-10-CM
          AND dx.ADMIT_DATE <= e.ADMIT_DATE
      )
      -- Age restriction
      AND DATEDIFF(year, d.BIRTH_DATE, e.ADMIT_DATE) >= {{MIN_AGE}}
      -- Exclude patients with prior outcome (clean window)
      -- {{EXCLUSION_CRITERIA_SQL}}
    ;
  ", .con = DBI::ANSI())

  # ── Step 2: Treatment assignment ──
  # Maps the protocol's treatment strategies to medication/procedure data.

  treatment_sql <- glue::glue_sql("
    -- =========================================================
    -- STEP 2: Treatment Assignment
    -- Protocol: {{TREATMENT_STRATEGY_DESCRIPTION}}
    -- =========================================================

    -- Option A: Using PRESCRIBING (ordered medications)
    SELECT
      elig.PATID,
      elig.index_date,
      CASE
        WHEN rx_trt.PATID IS NOT NULL THEN 1
        WHEN rx_ctl.PATID IS NOT NULL THEN 0
        ELSE NULL   -- exclude patients on neither
      END AS treatment
    INTO #treatment
    FROM #eligible elig
    LEFT JOIN (
      -- Treatment arm: {{TREATMENT_ARM_DESCRIPTION}}
      SELECT DISTINCT p.PATID
      FROM dbo.PRESCRIBING p
      WHERE p.RXNORM_CUI IN ({{TREATMENT_RXNORM_CUIS}})
        AND p.RX_ORDER_DATE BETWEEN DATEADD(day, -{{GRACE_PERIOD}}, elig.index_date)
                                AND DATEADD(day, {{GRACE_PERIOD}}, elig.index_date)
    ) rx_trt ON elig.PATID = rx_trt.PATID
    LEFT JOIN (
      -- Comparator arm: {{COMPARATOR_ARM_DESCRIPTION}}
      SELECT DISTINCT p.PATID
      FROM dbo.PRESCRIBING p
      WHERE p.RXNORM_CUI IN ({{COMPARATOR_RXNORM_CUIS}})
        AND p.RX_ORDER_DATE BETWEEN DATEADD(day, -{{GRACE_PERIOD}}, elig.index_date)
                                AND DATEADD(day, {{GRACE_PERIOD}}, elig.index_date)
    ) rx_ctl ON elig.PATID = rx_ctl.PATID
    WHERE COALESCE(rx_trt.PATID, rx_ctl.PATID) IS NOT NULL
    ;

    -- Alternative: Using MED_ADMIN for inpatient medication administration
    -- Alternative: Using DISPENSING for pharmacy dispensing data
    -- Alternative: Using PROCEDURES for procedural interventions
  ", .con = DBI::ANSI())

  # ── Step 3: Outcome ascertainment ──

  outcome_sql <- glue::glue_sql("
    -- =========================================================
    -- STEP 3: Outcome Ascertainment
    -- Protocol: {{OUTCOME_DEFINITION_DESCRIPTION}}
    -- Follow-up: {{FOLLOWUP_DAYS}} days from index_date
    -- =========================================================

    SELECT
      t.PATID,
      t.index_date,
      t.treatment,
      CASE
        WHEN dx_out.PATID IS NOT NULL THEN 1
        WHEN death.PATID IS NOT NULL THEN 1  -- if death is part of outcome
        ELSE 0
      END AS outcome,
      -- Time to event (for survival analysis)
      COALESCE(
        DATEDIFF(day, t.index_date, dx_out.first_outcome_date),
        DATEDIFF(day, t.index_date, death.DEATH_DATE),
        {config$followup_days}
      ) AS time_to_event,
      CASE
        WHEN dx_out.PATID IS NOT NULL OR death.PATID IS NOT NULL THEN 1
        ELSE 0
      END AS event_indicator
    INTO #outcomes
    FROM #treatment t
    LEFT JOIN (
      -- Outcome: {{OUTCOME_DX_DESCRIPTION}}
      SELECT
        dx.PATID,
        MIN(dx.ADMIT_DATE) AS first_outcome_date
      FROM dbo.DIAGNOSIS dx
      WHERE dx.DX LIKE {{OUTCOME_DX_PATTERN}}    -- e.g., 'I63%' for ischemic stroke
        AND dx.DX_TYPE = '10'
      GROUP BY dx.PATID
      HAVING MIN(dx.ADMIT_DATE) > t.index_date
         AND MIN(dx.ADMIT_DATE) <= DATEADD(day, {config$followup_days}, t.index_date)
    ) dx_out ON t.PATID = dx_out.PATID
    LEFT JOIN dbo.DEATH death
      ON t.PATID = death.PATID
      AND death.DEATH_DATE > t.index_date
      AND death.DEATH_DATE <= DATEADD(day, {config$followup_days}, t.index_date)
    ;
  ", .con = DBI::ANSI())

  # ── Step 4: Confounders ──

  confounders_sql <- glue::glue_sql("
    -- =========================================================
    -- STEP 4: Confounder Extraction
    -- =========================================================

    SELECT
      o.PATID,
      o.index_date,
      o.treatment,
      o.outcome,
      o.time_to_event,
      o.event_indicator,
      elig.age_at_index,
      elig.SEX,
      elig.RACE,
      elig.HISPANIC,

      -- Comorbidities (lookback window before index_date)
      {{COMORBIDITY_FLAGS_SQL}}
      -- Example:
      -- MAX(CASE WHEN cx.DX LIKE 'E11%' THEN 1 ELSE 0 END) AS diabetes,
      -- MAX(CASE WHEN cx.DX LIKE 'I10%' THEN 1 ELSE 0 END) AS hypertension,
      -- MAX(CASE WHEN cx.DX LIKE 'N18%' THEN 1 ELSE 0 END) AS ckd,

      -- Most recent vitals before index
      v.SYSTOLIC AS bp_systolic,
      v.DIASTOLIC AS bp_diastolic,
      v.ORIGINAL_BMI AS bmi,
      v.SMOKING,

      -- Most recent labs before index
      {{LAB_VALUES_SQL}}
      -- Example:
      -- lab_cr.RESULT_NUM AS creatinine,
      -- lab_hba1c.RESULT_NUM AS hba1c,
      -- lab_ldl.RESULT_NUM AS ldl,

      -- Enrollment / insurance
      enr.ENR_BASIS

    INTO #analytic_cohort
    FROM #outcomes o
    INNER JOIN #eligible elig ON o.PATID = elig.PATID
    LEFT JOIN (
      -- Most recent vitals in 1-year lookback
      SELECT v1.*
      FROM dbo.VITAL v1
      INNER JOIN (
        SELECT PATID, MAX(MEASURE_DATE) AS max_date
        FROM dbo.VITAL
        GROUP BY PATID
      ) v2 ON v1.PATID = v2.PATID AND v1.MEASURE_DATE = v2.max_date
    ) v ON o.PATID = v.PATID AND v.MEASURE_DATE <= o.index_date
           AND v.MEASURE_DATE >= DATEADD(year, -1, o.index_date)
    LEFT JOIN dbo.ENROLLMENT enr
      ON o.PATID = enr.PATID
      AND o.index_date BETWEEN enr.ENR_START_DATE AND COALESCE(enr.ENR_END_DATE, '9999-12-31')
    -- {{COMORBIDITY_JOINS}}
    -- {{LAB_JOINS}}
    GROUP BY
      o.PATID, o.index_date, o.treatment, o.outcome,
      o.time_to_event, o.event_indicator,
      elig.age_at_index, elig.SEX, elig.RACE, elig.HISPANIC,
      v.SYSTOLIC, v.DIASTOLIC, v.ORIGINAL_BMI, v.SMOKING,
      enr.ENR_BASIS
      -- {{ADDITIONAL_GROUP_BY}}
    ;

    -- =========================================================
    -- FINAL: Return the analytic cohort
    -- =========================================================
    SELECT * FROM #analytic_cohort;
  ", .con = DBI::ANSI())

  return(list(
    eligibility  = eligibility_sql,
    treatment    = treatment_sql,
    outcome      = outcome_sql,
    confounders  = confounders_sql
  ))
}


# ─── 3. Execute SQL and Pull Data ───────────────────────────────────────────

pull_analytic_cohort <- function(con, config) {
  sql_parts <- build_cohort_sql(config)

  message("Executing cohort SQL...")
  message("  Step 1: Building eligible population...")
  dbExecute(con, sql_parts$eligibility)

  message("  Step 2: Assigning treatment...")
  dbExecute(con, sql_parts$treatment)

  message("  Step 3: Ascertaining outcomes...")
  dbExecute(con, sql_parts$outcome)

  message("  Step 4: Extracting confounders and building analytic cohort...")
  cohort <- dbGetQuery(con, sql_parts$confounders)

  message(sprintf("Analytic cohort: %d patients (%d treated, %d control)",
                  nrow(cohort),
                  sum(cohort$treatment == 1, na.rm = TRUE),
                  sum(cohort$treatment == 0, na.rm = TRUE)))

  # Clean up temp tables
  try(dbExecute(con, "DROP TABLE IF EXISTS #eligible"), silent = TRUE)
  try(dbExecute(con, "DROP TABLE IF EXISTS #treatment"), silent = TRUE)
  try(dbExecute(con, "DROP TABLE IF EXISTS #outcomes"), silent = TRUE)
  try(dbExecute(con, "DROP TABLE IF EXISTS #analytic_cohort"), silent = TRUE)

  return(cohort)
}


# ─── 4. Data Preparation ────────────────────────────────────────────────────

prepare_cohort <- function(cohort) {
  cohort <- cohort |>
    mutate(
      # Recode PCORnet categorical variables
      sex = factor(SEX, levels = c("F", "M", "NI", "UN", "OT"),
                   labels = c("Female", "Male", "No info", "Unknown", "Other")),
      race = factor(RACE, levels = c("01", "02", "03", "04", "05", "06", "07", "NI", "UN", "OT"),
                    labels = c("AI/AN", "Asian", "Black", "NH/PI", "White",
                               "Multiple", "Other", "No info", "Unknown", "Refuse")),
      hispanic = factor(HISPANIC, levels = c("Y", "N", "NI", "UN", "OT", "R"),
                        labels = c("Yes", "No", "No info", "Unknown", "Other", "Refuse")),
      smoking = factor(SMOKING, levels = c("01", "02", "03", "04", "05", "06", "07", "08", "NI", "UN", "OT"),
                       labels = c("Current every day", "Current some day", "Former",
                                  "Never", "Smoker status unknown", "Unknown if ever",
                                  "Heavy tobacco", "Light tobacco",
                                  "No info", "Unknown", "Other")),
      treatment = as.integer(treatment)
    ) |>
    # Drop rows with missing treatment
    filter(!is.na(treatment))

  return(cohort)
}


# ─── 5. Causal Analysis (same as base template) ─────────────────────────────

# The confounder set — agent fills from protocol variable mapping
confounders <- c(
  # {{CONFOUNDER_LIST}}
  # Example:
  # "age_at_index", "sex", "race", "hispanic", "bmi",
  # "bp_systolic", "diabetes", "hypertension", "ckd",
  # "creatinine", "smoking"
)

ps_formula <- as.formula(
  paste("treatment ~", paste(confounders, collapse = " + "))
)


run_ipw_analysis <- function(cohort, ps_formula, config) {
  weights <- weightit(
    ps_formula,
    data     = cohort,
    method   = "glm",
    estimand = config$estimand
  )

  # Balance diagnostics
  bal <- bal.tab(weights, stats = c("m", "v"), thresholds = c(m = 0.1))
  print(bal)
  love.plot(weights, threshold = 0.1, abs = TRUE,
            title = "Covariate Balance (IPW)")

  cohort$ipw <- weights$weights

  if (is.null(config$time_var)) {
    fit <- glm(outcome ~ treatment,
               data = cohort, weights = ipw,
               family = binomial(link = "logit"))
    robust_results <- coeftest(fit, vcov = vcovHC(fit, type = "HC3"))
    print(robust_results)

    rd <- weighted.mean(cohort$outcome[cohort$treatment == 1],
                        cohort$ipw[cohort$treatment == 1]) -
          weighted.mean(cohort$outcome[cohort$treatment == 0],
                        cohort$ipw[cohort$treatment == 0])
    message(sprintf("Risk difference: %.4f", rd))
  } else {
    fit <- coxph(Surv(time_to_event, event_indicator) ~ treatment,
                 data = cohort, weights = ipw, robust = TRUE)
    print(summary(fit))
  }

  return(list(weights = weights, fit = fit, balance = bal))
}


run_gcomp_analysis <- function(cohort, ps_formula, config) {
  outcome_formula <- as.formula(
    paste("outcome ~ treatment *", paste(confounders, collapse = " + "))
  )
  fit <- glm(outcome_formula, data = cohort, family = binomial)

  p1 <- mean(predict(fit, newdata = cohort |> mutate(treatment = 1L), type = "response"))
  p0 <- mean(predict(fit, newdata = cohort |> mutate(treatment = 0L), type = "response"))
  rd <- p1 - p0
  rr <- p1 / p0

  message(sprintf("G-comp: RD = %.4f, RR = %.4f", rd, rr))

  boot_rd <- replicate(1000, {
    idx <- sample(nrow(cohort), replace = TRUE)
    b <- cohort[idx, ]
    bf <- glm(outcome_formula, data = b, family = binomial)
    mean(predict(bf, newdata = b |> mutate(treatment = 1L), type = "response")) -
    mean(predict(bf, newdata = b |> mutate(treatment = 0L), type = "response"))
  })
  ci <- quantile(boot_rd, c(0.025, 0.975))
  message(sprintf("95%% CI: [%.4f, %.4f]", ci[1], ci[2]))

  return(list(fit = fit, rd = rd, rr = rr, ci = ci))
}


# ─── 6. Sensitivity Analysis ────────────────────────────────────────────────

run_sensitivity <- function(results, config) {
  if (!is.null(results$rr)) {
    ev <- evalues.RR(results$rr, lo = results$ci[1], hi = results$ci[2])
    print(ev)
  }
}


# ─── 7. Run Pipeline ────────────────────────────────────────────────────────

main <- function() {
  con    <- connect_cdw(config)
  on.exit(dbDisconnect(con))

  cohort <- pull_analytic_cohort(con, config)
  cohort <- prepare_cohort(cohort)

  results <- switch(config$analysis_method,
    ipw   = run_ipw_analysis(cohort, ps_formula, config),
    gcomp = run_gcomp_analysis(cohort, ps_formula, config),
    stop(paste("Unknown method:", config$analysis_method))
  )

  run_sensitivity(results, config)
  message("Analysis complete.")
  return(results)
}

# Uncomment to run:
# results <- main()
