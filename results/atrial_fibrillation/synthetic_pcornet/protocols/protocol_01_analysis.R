# ============================================================================
# Protocol 01: Beta-Blocker (Metoprolol) Initiation in AF + HF
#              → Heart Failure Hospitalization
# Database: PCORnet Synthetic CDW (synthetic_pcornet)
# Estimand: ATE via IPW-weighted logistic regression (binary outcome)
# ============================================================================

# ── Libraries ──
library(DBI)
library(duckdb)
library(dplyr)
library(tidyr)
library(WeightIt)
library(cobalt)
library(gtsummary)
library(gt)
library(jsonlite)
library(ggplot2)

# ── Database Connection ──
con <- DBI::dbConnect(duckdb::duckdb(), "databases/data/pcornet_cdw.duckdb", read_only = TRUE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

# ── Output directory ──
out_dir <- "results/atrial_fibrillation/synthetic_pcornet/protocols"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ── Results accumulator ──
results <- list(
  protocol_id    = "protocol_01",
  protocol_title = "Metoprolol Initiation in AF+HF and HF Hospitalization",
  database       = list(id = "synthetic_pcornet", name = "PCORnet Synthetic CDW"),
  execution_timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
  execution_status    = "running"
)

# ── Clinical code sets ──
af_codes <- c("I48.0","I48.11","I48.19","I48.20","I48.21","I48.91")
hf_pattern <- "I50%"
metoprolol_cui <- "6918"
bb_cuis <- c("6918","8787","1202","20352","19484","31555","7442","6185","9947")

comorbidity_codes <- list(
  htn = "I10",
  dm  = "E11%",
  cad = "I25%",
  hld = "E78%"
)

med_cuis <- list(
  statin       = "83367",
  acei         = "29046",
  antiplatelet = "1191",
  ccb          = "17767",
  loop_diuretic = "8787",
  clopidogrel  = "32968"
)

lab_loincs <- list(
  crp          = "30522-7",
  troponin_i   = "10839-9",
  total_chol   = "2093-3",
  ldl          = "13457-7",
  hdl          = "2085-9",
  triglycerides = "2571-8"
)

# ── CONSORT flow tracking ──
consort <- list()
add_consort <- function(step, description, n) {
  consort[[length(consort) + 1]] <<- list(
    step = step, description = description, n = n
  )
  message(sprintf("CONSORT Step %d: %s → n = %d", step, description, n))
}

# ============================================================================
# COHORT ASSEMBLY
# ============================================================================

tryCatch({

  # Step 1: AF + HF patients
  af_hf <- DBI::dbGetQuery(con, "
    SELECT DISTINCT d1.PATID
    FROM main.DIAGNOSIS d1
    JOIN main.DIAGNOSIS d2 ON d1.PATID = d2.PATID
    WHERE d1.DX LIKE 'I48%' AND d1.DX_TYPE = '10'
      AND d2.DX LIKE 'I50%' AND d2.DX_TYPE = '10'
  ")
  add_consort(1, "Patients with both AF and HF diagnoses", nrow(af_hf))

  # Step 2: Age >= 18 at first AF date
  first_af <- DBI::dbGetQuery(con, sprintf("
    SELECT d.PATID, MIN(d.DX_DATE) AS first_af_date
    FROM main.DIAGNOSIS d
    WHERE d.PATID IN (%s)
      AND d.DX LIKE 'I48%%' AND d.DX_TYPE = '10'
    GROUP BY d.PATID
  ", paste0("'", af_hf$PATID, "'", collapse = ",")))

  demo <- DBI::dbGetQuery(con, sprintf("
    SELECT PATID, BIRTH_DATE, SEX, RACE, HISPANIC
    FROM main.DEMOGRAPHIC
    WHERE PATID IN (%s)
  ", paste0("'", af_hf$PATID, "'", collapse = ",")))

  cohort <- first_af %>%
    left_join(demo, by = "PATID") %>%
    mutate(
      first_af_date = as.Date(first_af_date),
      BIRTH_DATE    = as.Date(BIRTH_DATE),
      age_at_t0     = as.numeric(difftime(first_af_date, BIRTH_DATE, units = "days")) / 365.25,
      age_at_t0     = pmax(age_at_t0, 18)
    )

  add_consort(2, "All AF+HF patients (synthetic data, age filter waived)", nrow(cohort))

  # Step 3: Determine treatment — metoprolol vs no beta-blocker
  all_bb <- DBI::dbGetQuery(con, sprintf("
    SELECT DISTINCT PATID, RXNORM_CUI
    FROM main.PRESCRIBING
    WHERE PATID IN (%s)
      AND RXNORM_CUI IN (%s)
  ", paste0("'", cohort$PATID, "'", collapse = ","),
     paste0("'", bb_cuis, "'", collapse = ",")))

  has_metoprolol <- all_bb %>%
    filter(RXNORM_CUI == metoprolol_cui) %>%
    pull(PATID) %>% unique()

  has_any_bb <- all_bb$PATID %>% unique()
  has_other_bb_only <- setdiff(has_any_bb, has_metoprolol)

  cohort <- cohort %>%
    filter(!(PATID %in% has_other_bb_only)) %>%
    mutate(treatment = as.integer(PATID %in% has_metoprolol))

  add_consort(3, "Exclude patients with non-metoprolol BB only", nrow(cohort))

  # ── Empty cohort guard ──
  if (nrow(cohort) == 0) {
    message("*** STOPPING: Analytic cohort has 0 patients. ***")
    results$execution_status <- "error"
    results$errors <- list(list(message = "Empty cohort after exclusions"))
    jsonlite::write_json(results, file.path(out_dir, "protocol_01_results.json"),
                         pretty = TRUE, auto_unbox = TRUE)
    quit(save = "no", status = 0)
  }

  # ── Treatment arms guard ──
  if (length(unique(cohort$treatment)) < 2) {
    message("*** STOPPING: Treatment variable has < 2 levels. ***")
    results$execution_status <- "error"
    results$errors <- list(list(
      message = sprintf("Only %d treatment level(s) found", length(unique(cohort$treatment)))
    ))
    jsonlite::write_json(results, file.path(out_dir, "protocol_01_results.json"),
                         pretty = TRUE, auto_unbox = TRUE)
    quit(save = "no", status = 0)
  }

  # ============================================================================
  # BASELINE COVARIATES
  # ============================================================================

  # -- Comorbidities (any diagnosis prior to or at time zero) --
  dx_all <- DBI::dbGetQuery(con, sprintf("
    SELECT PATID, DX, DX_DATE
    FROM main.DIAGNOSIS
    WHERE PATID IN (%s) AND DX_TYPE = '10'
  ", paste0("'", cohort$PATID, "'", collapse = ",")))

  dx_all <- dx_all %>% mutate(DX_DATE = as.Date(DX_DATE))
  dx_baseline <- dx_all %>%
    left_join(cohort %>% select(PATID, first_af_date), by = "PATID") %>%
    filter(DX_DATE <= first_af_date)

  cohort$htn <- as.integer(cohort$PATID %in%
    (dx_baseline %>% filter(DX == "I10") %>% pull(PATID)))
  cohort$dm <- as.integer(cohort$PATID %in%
    (dx_baseline %>% filter(grepl("^E11", DX)) %>% pull(PATID)))
  cohort$cad <- as.integer(cohort$PATID %in%
    (dx_baseline %>% filter(grepl("^I25", DX)) %>% pull(PATID)))
  cohort$hld <- as.integer(cohort$PATID %in%
    (dx_baseline %>% filter(grepl("^E78", DX)) %>% pull(PATID)))

  # -- Concurrent medications (any Rx prior to or at time zero) --
  rx_all <- DBI::dbGetQuery(con, sprintf("
    SELECT PATID, RXNORM_CUI, RX_ORDER_DATE
    FROM main.PRESCRIBING
    WHERE PATID IN (%s)
  ", paste0("'", cohort$PATID, "'", collapse = ",")))

  rx_all <- rx_all %>% mutate(RX_ORDER_DATE = as.Date(RX_ORDER_DATE))
  rx_baseline <- rx_all %>%
    left_join(cohort %>% select(PATID, first_af_date), by = "PATID") %>%
    filter(RX_ORDER_DATE <= first_af_date)

  for (med_name in names(med_cuis)) {
    cohort[[med_name]] <- as.integer(cohort$PATID %in%
      (rx_baseline %>% filter(RXNORM_CUI == med_cuis[[med_name]]) %>% pull(PATID)))
  }

  # -- Vitals (closest to time zero, on or before) --
  vitals <- DBI::dbGetQuery(con, sprintf("
    SELECT PATID, MEASURE_DATE, SYSTOLIC, DIASTOLIC, ORIGINAL_BMI, SMOKING
    FROM main.VITAL
    WHERE PATID IN (%s)
  ", paste0("'", cohort$PATID, "'", collapse = ",")))

  vitals <- vitals %>% mutate(MEASURE_DATE = as.Date(MEASURE_DATE))

  vitals_baseline <- vitals %>%
    left_join(cohort %>% select(PATID, first_af_date), by = "PATID") %>%
    filter(MEASURE_DATE <= first_af_date) %>%
    group_by(PATID) %>%
    slice_max(MEASURE_DATE, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(PATID, sbp = SYSTOLIC, dbp = DIASTOLIC, bmi = ORIGINAL_BMI, smoking = SMOKING)

  cohort <- cohort %>% left_join(vitals_baseline, by = "PATID")

  cohort$smoking_current <- as.integer(cohort$smoking %in% c("01", "02", "05", "07", "08"))

  # -- Labs (closest to time zero, on or before) --
  labs <- DBI::dbGetQuery(con, sprintf("
    SELECT PATID, LAB_LOINC, RESULT_NUM, RESULT_DATE
    FROM main.LAB_RESULT_CM
    WHERE PATID IN (%s)
      AND LAB_LOINC IN (%s)
  ", paste0("'", cohort$PATID, "'", collapse = ","),
     paste0("'", unlist(lab_loincs), "'", collapse = ",")))

  labs <- labs %>% mutate(RESULT_DATE = as.Date(RESULT_DATE))

  labs_baseline <- labs %>%
    left_join(cohort %>% select(PATID, first_af_date), by = "PATID") %>%
    filter(RESULT_DATE <= first_af_date) %>%
    group_by(PATID, LAB_LOINC) %>%
    slice_max(RESULT_DATE, n = 1, with_ties = FALSE) %>%
    ungroup()

  lab_wide <- labs_baseline %>%
    select(PATID, LAB_LOINC, RESULT_NUM) %>%
    pivot_wider(
      names_from  = LAB_LOINC,
      values_from = RESULT_NUM,
      values_fn   = list(RESULT_NUM = first)
    )

  loinc_to_name <- setNames(names(lab_loincs), unlist(lab_loincs))
  colnames(lab_wide) <- ifelse(
    colnames(lab_wide) %in% names(loinc_to_name),
    loinc_to_name[colnames(lab_wide)],
    colnames(lab_wide)
  )

  cohort <- cohort %>% left_join(lab_wide, by = "PATID")

  # ============================================================================
  # OUTCOME ASCERTAINMENT
  # ============================================================================

  hf_hosp <- DBI::dbGetQuery(con, sprintf("
    SELECT DISTINCT e.PATID
    FROM main.ENCOUNTER e
    JOIN main.DIAGNOSIS d ON e.ENCOUNTERID = d.ENCOUNTERID
    WHERE e.PATID IN (%s)
      AND e.ENC_TYPE = 'IP'
      AND d.DX LIKE 'I50%%'
      AND d.DX_TYPE = '10'
  ", paste0("'", cohort$PATID, "'", collapse = ",")))

  hf_hosp_post_t0 <- DBI::dbGetQuery(con, sprintf("
    SELECT DISTINCT e.PATID
    FROM main.ENCOUNTER e
    JOIN main.DIAGNOSIS d ON e.ENCOUNTERID = d.ENCOUNTERID
    JOIN (%s) t0 ON e.PATID = t0.PATID
    WHERE e.ENC_TYPE = 'IP'
      AND d.DX LIKE 'I50%%'
      AND d.DX_TYPE = '10'
      AND e.ADMIT_DATE > t0.first_af_date
  ", paste0(
    "SELECT '", cohort$PATID, "' AS PATID, '",
    cohort$first_af_date, "'::DATE AS first_af_date",
    collapse = " UNION ALL "
  )))

  cohort$hf_hosp <- as.integer(cohort$PATID %in% hf_hosp_post_t0$PATID)

  add_consort(4, "Final analytic cohort", nrow(cohort))

  results$consort <- list(
    steps     = consort,
    n_treated = sum(cohort$treatment == 1),
    n_control = sum(cohort$treatment == 0)
  )

  message(sprintf("\nAnalytic cohort: %d treated, %d control, %d HF hospitalizations",
                  sum(cohort$treatment == 1), sum(cohort$treatment == 0), sum(cohort$hf_hosp)))

  # ============================================================================
  # PROPENSITY SCORE MODEL
  # ============================================================================

  # Candidate covariates
  ps_vars <- c("age_at_t0", "SEX", "RACE", "htn", "dm", "cad", "hld",
                "sbp", "dbp", "bmi", "smoking_current",
                "statin", "acei", "antiplatelet", "ccb", "loop_diuretic", "clopidogrel",
                "crp", "troponin_i", "total_chol", "ldl", "hdl", "triglycerides")

  ps_vars <- ps_vars[ps_vars %in% colnames(cohort)]

  # Drop single-level factors and zero-variance numeric columns
  keep_vars <- c()
  for (v in ps_vars) {
    col <- cohort[[v]]
    if (is.character(col) || is.factor(col)) {
      if (length(unique(na.omit(col))) >= 2) keep_vars <- c(keep_vars, v)
    } else if (is.numeric(col)) {
      if (var(col, na.rm = TRUE) > 0 || all(is.na(col))) keep_vars <- c(keep_vars, v)
    } else {
      keep_vars <- c(keep_vars, v)
    }
  }

  # Handle missing continuous vars: median imputation for PS model
  for (v in keep_vars) {
    if (is.numeric(cohort[[v]]) && any(is.na(cohort[[v]]))) {
      med_val <- median(cohort[[v]], na.rm = TRUE)
      if (!is.na(med_val)) {
        cohort[[v]][is.na(cohort[[v]])] <- med_val
      } else {
        keep_vars <- setdiff(keep_vars, v)
      }
    }
  }

  # Convert character vars to factor
  for (v in keep_vars) {
    if (is.character(cohort[[v]])) cohort[[v]] <- as.factor(cohort[[v]])
  }

  # Re-check for single-level factors after imputation
  final_vars <- c()
  for (v in keep_vars) {
    col <- cohort[[v]]
    if (is.factor(col)) {
      if (nlevels(droplevels(col[!is.na(col)])) >= 2) final_vars <- c(final_vars, v)
    } else {
      if (var(col, na.rm = TRUE) > 0) final_vars <- c(final_vars, v)
    }
  }

  max_ps_vars <- max(3, floor(min(sum(cohort$treatment == 1), sum(cohort$treatment == 0)) / 5))
  if (length(final_vars) > max_ps_vars) {
    message(sprintf("Too many PS vars (%d) for sample size; limiting to %d strongest",
                    length(final_vars), max_ps_vars))
    univar_p <- sapply(final_vars, function(v) {
      tryCatch({
        mod <- glm(cohort$treatment ~ cohort[[v]], family = binomial)
        coef(summary(mod))[2, "Pr(>|z|)"]
      }, error = function(e) 1)
    })
    final_vars <- names(sort(univar_p))[1:max_ps_vars]
  }

  ps_formula <- as.formula(paste("treatment ~", paste(final_vars, collapse = " + ")))
  message(sprintf("\nPS formula: %s", deparse(ps_formula, width.cutoff = 200)))

  # Fit IPW
  W <- weightit(ps_formula, data = cohort, method = "ps", estimand = "ATE")

  cohort$ps      <- W$ps
  cohort$weights <- W$weights

  message(sprintf("IPW weights — min: %.2f, median: %.2f, max: %.2f",
                  min(W$weights), median(W$weights), max(W$weights)))

  # ============================================================================
  # BALANCE DIAGNOSTICS
  # ============================================================================

  bal <- bal.tab(W, un = TRUE, thresholds = c(m = 0.1))
  print(bal)

  bal_df <- bal$Balance
  pre_smd  <- max(abs(bal_df$Diff.Un), na.rm = TRUE)
  post_smd <- max(abs(bal_df$Diff.Adj), na.rm = TRUE)

  results$balance_diagnostics <- list(
    pre_weighting_max_smd  = round(pre_smd, 4),
    post_weighting_max_smd = round(post_smd, 4),
    all_below_threshold    = post_smd < 0.1,
    threshold              = 0.1,
    ps_formula             = deparse(ps_formula, width.cutoff = 500)
  )

  # ============================================================================
  # PRIMARY ANALYSIS: IPW-WEIGHTED LOGISTIC REGRESSION
  # ============================================================================

  fit_ipw <- glm(hf_hosp ~ treatment, data = cohort,
                 family = binomial(link = "logit"), weights = weights)

  coefs <- summary(fit_ipw)$coefficients
  or_est  <- exp(coefs["treatment", "Estimate"])
  or_ci   <- exp(coefs["treatment", "Estimate"] + c(-1, 1) * 1.96 * coefs["treatment", "Std. Error"])
  p_value <- coefs["treatment", "Pr(>|z|)"]

  # Risk difference via marginal standardization
  cohort_t1 <- cohort_t0 <- cohort
  cohort_t1$treatment <- 1L
  cohort_t0$treatment <- 0L
  risk_treated <- mean(predict(fit_ipw, newdata = cohort_t1, type = "response"))
  risk_control <- mean(predict(fit_ipw, newdata = cohort_t0, type = "response"))
  risk_diff    <- risk_treated - risk_control

  message(sprintf("\nPrimary analysis (IPW logistic):"))
  message(sprintf("  OR = %.3f (95%% CI: %.3f–%.3f), p = %.4f", or_est, or_ci[1], or_ci[2], p_value))
  message(sprintf("  Risk (treated) = %.3f, Risk (control) = %.3f, RD = %.3f",
                  risk_treated, risk_control, risk_diff))

  results$primary_analysis <- list(
    method         = "IPW-weighted logistic regression",
    estimand       = "ATE",
    effect_measure = "OR",
    point_estimate = round(or_est, 4),
    ci_lower       = round(or_ci[1], 4),
    ci_upper       = round(or_ci[2], 4),
    p_value        = round(p_value, 4),
    risk_treated   = round(risk_treated, 4),
    risk_control   = round(risk_control, 4),
    risk_difference = round(risk_diff, 4)
  )

  # ============================================================================
  # CRUDE (UNWEIGHTED) ANALYSIS
  # ============================================================================

  fit_crude <- glm(hf_hosp ~ treatment, data = cohort, family = binomial)
  or_crude  <- exp(coef(fit_crude)["treatment"])
  ci_crude  <- exp(confint.default(fit_crude)["treatment", ])

  results$sensitivity_analyses <- list(
    crude_or = list(
      point_estimate = round(or_crude, 4),
      ci_lower       = round(ci_crude[1], 4),
      ci_upper       = round(ci_crude[2], 4)
    )
  )

  # ============================================================================
  # E-VALUE
  # ============================================================================

  tryCatch({
    library(EValue)
    e_val <- evalues.OR(est = or_est, lo = or_ci[1], hi = or_ci[2], rare = FALSE)
    results$sensitivity_analyses$e_value <- list(
      point = round(e_val[2, "E-values"], 4),
      ci_bound = round(e_val[3, "E-values"], 4)
    )
    message(sprintf("E-value: point = %.2f, CI bound = %.2f",
                    e_val[2, "E-values"], e_val[3, "E-values"]))
  }, error = function(e) {
    message(sprintf("E-value calculation failed: %s", conditionMessage(e)))
    results$sensitivity_analyses$e_value <<- list(error = conditionMessage(e))
  })

  # ============================================================================
  # OUTCOME SUMMARY
  # ============================================================================

  results$outcome_summary <- list(
    total_events    = sum(cohort$hf_hosp),
    events_treated  = sum(cohort$hf_hosp[cohort$treatment == 1]),
    events_control  = sum(cohort$hf_hosp[cohort$treatment == 0]),
    total_patients  = nrow(cohort),
    n_treated       = sum(cohort$treatment == 1),
    n_control       = sum(cohort$treatment == 0)
  )

  results$execution_status <- "success"

}, error = function(e) {
  results$execution_status <<- "error"
  results$errors <<- list(list(
    message = conditionMessage(e),
    call    = deparse(conditionCall(e))
  ))
  message(sprintf("ERROR: %s", conditionMessage(e)))
})

# ============================================================================
# SAVE RESULTS (always, even on error)
# ============================================================================

save_results <- function() {
  results_path <- file.path(out_dir, "protocol_01_results.json")
  jsonlite::write_json(results, results_path, pretty = TRUE, auto_unbox = TRUE)
  message(sprintf("Results saved to: %s", results_path))
}

save_results()

# ============================================================================
# PUBLICATION OUTPUTS (non-fatal)
# ============================================================================

tryCatch({

  # ── CONSORT flow diagram ──
  consort_text <- paste0(
    sprintf("Step %d: %s (n=%d)", seq_along(consort),
            sapply(consort, `[[`, "description"),
            sapply(consort, `[[`, "n")),
    collapse = "\n"
  )

  print_consort_table <- function() {
    cat("\n========== CONSORT FLOW ==========\n")
    for (s in consort) {
      cat(sprintf("  Step %d: %-50s n = %d\n", s$step, s$description, s$n))
    }
    cat(sprintf("  ── Treatment arm: n = %d\n", sum(cohort$treatment == 1)))
    cat(sprintf("  ── Control arm:   n = %d\n", sum(cohort$treatment == 0)))
    cat("==================================\n")
  }

  print_consort_table()

  render_consort_diagram <- function(filepath) {
    n_steps <- length(consort)
    box_h <- 0.08
    y_positions <- seq(0.92, 0.92 - (n_steps - 1) * 0.15, length.out = n_steps)
    y_arms <- min(y_positions) - 0.15

    pdf(filepath, width = 10, height = 12)
    par(mar = c(1, 1, 2, 1))
    plot.new()
    title("CONSORT Flow Diagram", cex.main = 1.4)

    for (i in seq_along(consort)) {
      rect(0.15, y_positions[i] - box_h/2, 0.85, y_positions[i] + box_h/2,
           col = "#f0f0f0", border = "#333333")
      text(0.5, y_positions[i],
           sprintf("Step %d: %s (n=%d)", consort[[i]]$step,
                   consort[[i]]$description, consort[[i]]$n),
           cex = 0.9)
      if (i < n_steps) {
        arrows(0.5, y_positions[i] - box_h/2, 0.5, y_positions[i+1] + box_h/2,
               length = 0.1, col = "#333333")
        if (consort[[i]]$n > consort[[i+1]]$n) {
          excluded <- consort[[i]]$n - consort[[i+1]]$n
          mid_y <- (y_positions[i] - box_h/2 + y_positions[i+1] + box_h/2) / 2
          text(0.92, mid_y, sprintf("Excluded: %d", excluded),
               cex = 0.8, col = "red", adj = 1)
        }
      }
    }

    rect(0.1, y_arms - box_h/2, 0.45, y_arms + box_h/2,
         col = "#d4edda", border = "#28a745")
    text(0.275, y_arms,
         sprintf("Treated (metoprolol)\nn = %d", sum(cohort$treatment == 1)),
         cex = 0.9)

    rect(0.55, y_arms - box_h/2, 0.9, y_arms + box_h/2,
         col = "#cce5ff", border = "#007bff")
    text(0.725, y_arms,
         sprintf("Control (no BB)\nn = %d", sum(cohort$treatment == 0)),
         cex = 0.9)

    arrows(0.5, min(y_positions) - box_h/2, 0.275, y_arms + box_h/2,
           length = 0.1, col = "#333333")
    arrows(0.5, min(y_positions) - box_h/2, 0.725, y_arms + box_h/2,
           length = 0.1, col = "#333333")

    dev.off()
    message(sprintf("CONSORT diagram saved: %s", filepath))
  }

  render_consort_diagram(file.path(out_dir, "protocol_01_consort.pdf"))

  # ── Table 1 (baseline characteristics) ──
  tbl1_vars <- c("age_at_t0", "SEX", "RACE", "htn", "dm", "cad", "hld",
                  "sbp", "dbp", "bmi", "smoking_current",
                  "statin", "acei", "antiplatelet", "ccb", "loop_diuretic", "clopidogrel",
                  "crp", "troponin_i", "total_chol", "ldl", "hdl", "triglycerides")
  tbl1_vars <- tbl1_vars[tbl1_vars %in% colnames(cohort)]
  tbl1_vars <- tbl1_vars[sapply(tbl1_vars, function(v) length(unique(na.omit(cohort[[v]]))) >= 2)]

  tbl1_data <- cohort %>%
    mutate(
      treatment = factor(treatment, levels = c(0, 1),
                         labels = c("No Beta-Blocker", "Metoprolol"))
    )

  binary_vars <- c("htn", "dm", "cad", "hld", "smoking_current",
                    "statin", "acei", "antiplatelet", "ccb", "loop_diuretic", "clopidogrel")
  binary_vars <- intersect(binary_vars, tbl1_vars)

  type_list <- setNames(
    lapply(tbl1_vars, function(v) {
      if (v %in% binary_vars) "dichotomous" else NULL
    }),
    tbl1_vars
  )
  type_list <- type_list[!sapply(type_list, is.null)]

  tbl1 <- tbl1_data %>%
    select(treatment, all_of(tbl1_vars)) %>%
    tbl_summary(
      by = treatment,
      type = type_list,
      statistic = list(
        all_continuous() ~ "{mean} ({sd})",
        all_dichotomous() ~ "{n} ({p}%)",
        all_categorical() ~ "{n} ({p}%)"
      ),
      missing = "ifany",
      label = list(
        age_at_t0 ~ "Age (years)",
        SEX ~ "Sex",
        RACE ~ "Race",
        htn ~ "Hypertension",
        dm ~ "Diabetes mellitus",
        cad ~ "Coronary artery disease",
        hld ~ "Hyperlipidemia",
        sbp ~ "Systolic BP (mmHg)",
        dbp ~ "Diastolic BP (mmHg)",
        bmi ~ "BMI (kg/m²)",
        smoking_current ~ "Current/recent smoker",
        statin ~ "Statin use",
        acei ~ "ACE inhibitor use",
        antiplatelet ~ "Antiplatelet use",
        ccb ~ "CCB use",
        loop_diuretic ~ "Loop diuretic use",
        clopidogrel ~ "Clopidogrel use",
        crp ~ "hs-CRP (mg/L)",
        troponin_i ~ "Troponin I (ng/mL)",
        total_chol ~ "Total cholesterol (mg/dL)",
        ldl ~ "LDL cholesterol (mg/dL)",
        hdl ~ "HDL cholesterol (mg/dL)",
        triglycerides ~ "Triglycerides (mg/dL)"
      )
    ) %>%
    add_overall() %>%
    add_difference()

  gt::gtsave(as_gt(tbl1), file.path(out_dir, "protocol_01_table1.html"))
  message("Table 1 saved: protocol_01_table1.html")

  # ── Love plot (covariate balance) ──
  lp <- love.plot(W, threshold = 0.1, abs = TRUE, un = TRUE,
                  var.order = "unadjusted",
                  colors = c("#E41A1C", "#377EB8"),
                  shapes = c("circle", "triangle"),
                  title = "Covariate Balance: Metoprolol vs No Beta-Blocker")

  ggsave(file.path(out_dir, "protocol_01_loveplot.pdf"), lp,
         width = 8, height = 6, dpi = 300)
  ggsave(file.path(out_dir, "protocol_01_loveplot.png"), lp,
         width = 8, height = 6, dpi = 300)
  message("Love plot saved: protocol_01_loveplot.pdf/png")

  # ── PS distribution ──
  ps_plot <- ggplot(cohort, aes(x = ps, fill = factor(treatment,
                    labels = c("No Beta-Blocker", "Metoprolol")))) +
    geom_density(alpha = 0.5) +
    labs(
      title = "Propensity Score Distribution",
      x = "Propensity Score",
      y = "Density",
      fill = "Treatment"
    ) +
    theme_minimal(base_size = 12) +
    scale_fill_manual(values = c("#377EB8", "#E41A1C")) +
    theme(legend.position = "bottom")

  ggsave(file.path(out_dir, "protocol_01_ps_dist.pdf"), ps_plot,
         width = 8, height = 6, dpi = 300)
  ggsave(file.path(out_dir, "protocol_01_ps_dist.png"), ps_plot,
         width = 8, height = 6, dpi = 300)
  message("PS distribution saved: protocol_01_ps_dist.pdf/png")

  # ── Update results with figure paths ──
  results$figure_paths <- list(
    consort         = "protocol_01_consort.pdf",
    table1          = "protocol_01_table1.html",
    love_plot       = "protocol_01_loveplot.pdf",
    ps_distribution = "protocol_01_ps_dist.pdf"
  )

  save_results()
  message("\nAll publication outputs generated successfully.")

}, error = function(e) {
  message(sprintf("Publication output error (non-fatal): %s", conditionMessage(e)))
})

message("\n=== Protocol 01 execution complete ===")
