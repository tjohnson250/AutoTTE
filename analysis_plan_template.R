# =============================================================================
# Auto-Protocol Designer — R Analysis Plan Template
# =============================================================================
# This template is used by the agent as a starting scaffold when generating
# target trial emulation analysis plans. The LLM fills in the specifics.
#
# Framework: Target Trial Emulation (Hernán & Robins)
# =============================================================================

library(tidyverse)
library(WeightIt)     # propensity score weighting
library(cobalt)       # balance diagnostics
library(survival)     # time-to-event outcomes
library(sandwich)     # robust SEs
library(lmtest)       # coeftest with robust SEs
library(EValue)       # sensitivity analysis
library(jsonlite)     # JSON export for structured results
library(gtsummary)    # publication Table 1 (tbl_summary / tbl_svysummary)
library(gt)           # table formatting + export (gtsave)
library(survminer)    # KM curves with risk tables (ggsurvplot)

# Optional, depending on analysis approach chosen by agent:
# library(MatchIt)    # matching
# library(tmle)       # TMLE
# library(lmtp)       # longitudinal modified treatment policies
# library(SuperLearner)


# ─── 0. Configuration (filled by agent) ─────────────────────────────────────

config <- list(
  dataset_name     = "{{DATASET_NAME}}",
  dataset_path     = "{{DATASET_PATH}}",
  question         = "{{CAUSAL_QUESTION}}",
  exposure_var     = "{{EXPOSURE_VAR}}",
  outcome_var      = "{{OUTCOME_VAR}}",
  time_var         = "{{TIME_VAR}}",        # NULL if not time-to-event
  estimand         = "{{ESTIMAND}}",        # ATE, ATT
  analysis_method  = "{{METHOD}}"           # ipw, gcomp, tmle, matching
)


# ─── 1. Data Loading ────────────────────────────────────────────────────────

# Placeholder: the agent fills in the actual loading code based on the dataset.
# Examples:
#   MIMIC-IV:  read from CSVs or BigQuery
#   NHANES:    use nhanesA package or downloaded XPT files
#   MEPS:      use MEPS R package or AHRQ data files

load_data <- function(config) {
  # TODO: Agent fills in dataset-specific loading code
  stop("Data loading not yet implemented — agent will fill this in.")
}


# ─── 2. Cohort Definition (Eligibility Criteria) ────────────────────────────

define_cohort <- function(df, config) {
  # Apply eligibility criteria from the target trial protocol.
  # The agent maps each criterion to specific variable filters.

  cohort <- df |>
    # {{ELIGIBILITY_FILTERS}}
    # Example:
    # filter(age >= 65) |>
    # filter(diagnosis_code %in% c("I48.0", "I48.1", "I48.2")) |>
    # filter(!is.na(exposure_var)) |>
    identity()

  message(sprintf("Cohort: %d patients (from %d total)", nrow(cohort), nrow(df)))
  return(cohort)
}


# ─── 3. Treatment Definition ────────────────────────────────────────────────

define_treatment <- function(cohort, config) {
  # Create binary treatment indicator based on protocol definition.
  # The agent specifies exactly how treatment is defined from the data.

  cohort <- cohort |>
    mutate(
      treatment = case_when(
        # {{TREATMENT_DEFINITION}}
        # Example:
        # medication %in% c("apixaban", "rivaroxaban", "dabigatran") ~ 1L,
        # medication == "warfarin" ~ 0L,
        TRUE ~ NA_integer_
      )
    ) |>
    filter(!is.na(treatment))

  message(sprintf("Treatment: %d treated, %d control",
                  sum(cohort$treatment == 1), sum(cohort$treatment == 0)))
  return(cohort)
}


# ─── 4. Outcome Definition ──────────────────────────────────────────────────

define_outcome <- function(cohort, config) {
  # Define the outcome variable per the protocol.
  # Handles both binary and time-to-event outcomes.

  cohort <- cohort |>
    mutate(
      outcome = {{OUTCOME_DEFINITION}}
      # Example (binary):
      #   as.integer(stroke_within_90d == 1)
      # Example (time-to-event):
      #   Surv(time_to_event, event_indicator)
    )

  return(cohort)
}


# ─── 5. Confounder Set ──────────────────────────────────────────────────────

# The agent identifies confounders from the protocol's variable mapping.
confounders <- c(
  # {{CONFOUNDER_LIST}}
  # Example:
  # "age", "sex", "race_ethnicity", "bmi", "creatinine",
  # "cha2ds2_vasc_score", "has_bleed_score", "prior_stroke"
)

# Build propensity score formula
ps_formula <- as.formula(
  paste("treatment ~", paste(confounders, collapse = " + "))
)


# ─── 6. Analysis ────────────────────────────────────────────────────────────

run_ipw_analysis <- function(cohort, ps_formula, config) {
  # ── Propensity Score Estimation ──
  weights <- weightit(
    ps_formula,
    data    = cohort,
    method  = "glm",       # or "gbm", "bart", "super" for SuperLearner
    estimand = config$estimand
  )

  # ── Balance Diagnostics (un = TRUE ensures pre-weighting SMDs are computed) ──
  bal <- bal.tab(weights, stats = c("m", "v"), thresholds = c(m = 0.1), un = TRUE)
  print(bal)

  # Love plot with pre- and post-weighting SMDs
  love.plot(weights,
            threshold = 0.1,
            abs = TRUE, un = TRUE,
            var.order = "unadjusted",
            title = "Covariate Balance (IPW)")

  # ── Weighted Outcome Model ──
  cohort$ps  <- weights$ps
  cohort$ipw <- weights$weights

  if (is.null(config$time_var)) {
    # Binary outcome
    fit <- glm(outcome ~ treatment,
               data    = cohort,
               weights = ipw,
               family  = binomial(link = "logit"))

    # Robust standard errors
    robust_results <- coeftest(fit, vcov = vcovHC(fit, type = "HC3"))
    print(robust_results)

    # Risk difference (marginal)
    rd <- weighted.mean(cohort$outcome[cohort$treatment == 1], cohort$ipw[cohort$treatment == 1]) -
          weighted.mean(cohort$outcome[cohort$treatment == 0], cohort$ipw[cohort$treatment == 0])
    message(sprintf("Estimated risk difference: %.4f", rd))

  } else {
    # Time-to-event outcome
    fit <- coxph(Surv(get(config$time_var), outcome) ~ treatment,
                 data    = cohort,
                 weights = ipw,
                 robust  = TRUE)
    print(summary(fit))
  }

  return(list(weights = weights, fit = fit, balance = bal))
}


run_gcomp_analysis <- function(cohort, ps_formula, config) {
  # G-computation / standardization approach
  # Fit outcome model with treatment and confounders
  outcome_formula <- as.formula(
    paste("outcome ~ treatment *", paste(confounders, collapse = " + "))
  )

  fit <- glm(outcome_formula, data = cohort, family = binomial(link = "logit"))

  # Predict under intervention (treatment = 1 for all)
  cohort_treated <- cohort |> mutate(treatment = 1L)
  cohort_control <- cohort |> mutate(treatment = 0L)

  p1 <- mean(predict(fit, newdata = cohort_treated, type = "response"))
  p0 <- mean(predict(fit, newdata = cohort_control, type = "response"))

  rd <- p1 - p0
  rr <- p1 / p0

  message(sprintf("G-computation results:"))
  message(sprintf("  Risk under treatment:  %.4f", p1))
  message(sprintf("  Risk under control:    %.4f", p0))
  message(sprintf("  Risk difference:       %.4f", rd))
  message(sprintf("  Risk ratio:            %.4f", rr))

  # Bootstrap CIs
  boot_rd <- replicate(1000, {
    idx <- sample(nrow(cohort), replace = TRUE)
    boot_data <- cohort[idx, ]
    boot_fit <- glm(outcome_formula, data = boot_data, family = binomial)
    p1_b <- mean(predict(boot_fit, newdata = boot_data |> mutate(treatment = 1L), type = "response"))
    p0_b <- mean(predict(boot_fit, newdata = boot_data |> mutate(treatment = 0L), type = "response"))
    p1_b - p0_b
  })

  ci <- quantile(boot_rd, c(0.025, 0.975))
  message(sprintf("  95%% CI: [%.4f, %.4f]", ci[1], ci[2]))

  return(list(fit = fit, rd = rd, rr = rr, ci = ci))
}


# ─── 7. Sensitivity Analysis ────────────────────────────────────────────────

run_sensitivity <- function(results, config) {
  # E-value for unmeasured confounding
  # Requires point estimate and CI bound

  if (!is.null(results$rr)) {
    ev <- evalues.RR(results$rr, lo = results$ci[1], hi = results$ci[2])
    print(ev)
    message("E-value computed. Interpretation: an unmeasured confounder would")
    message("need an association of this strength with both treatment and outcome")
    message("to explain away the observed effect.")
  }

  # Additional sensitivity analyses the agent might add:
  # - Quantitative bias analysis
  # - Alternate confounder sets
  # - Different model specifications
  # - Subgroup analyses
}


# ─── 8. Publication Output Functions ─────────────────────────────────────────
# These functions save publication-quality figures and tables alongside the
# JSON results. Each is called from main() after the analysis completes,
# wrapped in tryCatch() so failures do not prevent JSON results from saving.

save_results <- function(results_list, protocol_id, output_dir = ".") {
  results_list$execution_timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
  if (is.null(results_list$execution_status)) {
    results_list$execution_status <- "success"
  }
  output_path <- file.path(output_dir, paste0(protocol_id, "_results.json"))
  jsonlite::write_json(results_list, output_path, pretty = TRUE, auto_unbox = TRUE)
  message(sprintf("Results saved to: %s", output_path))
  invisible(output_path)
}

# For NHANES survey-weighted data, use tbl_svysummary().
# For non-survey public datasets, use tbl_summary().
save_table1 <- function(data_or_design, treatment_var, confounders,
                        protocol_id, output_dir, survey = FALSE) {
  if (survey) {
    tbl <- tbl_svysummary(data_or_design, by = all_of(treatment_var),
             include = all_of(confounders),
             statistic = list(all_continuous() ~ "{mean} ({sd})",
                              all_categorical() ~ "{n_unweighted} ({p}%)"),
             missing = "ifany") |>
      add_overall() |>
      add_difference() |>
      bold_labels()
  } else {
    tbl <- data_or_design |>
      select(all_of(c(treatment_var, confounders))) |>
      tbl_summary(by = all_of(treatment_var),
                  statistic = list(all_continuous() ~ "{mean} ({sd})",
                                   all_categorical() ~ "{n} ({p}%)"),
                  missing = "ifany") |>
      add_overall() |>
      add_difference() |>
      bold_labels()
  }
  tbl <- tbl |>
    as_gt() |>
    tab_header(title = "Table 1: Baseline Characteristics")
  gtsave(tbl, file.path(output_dir, paste0(protocol_id, "_table1.html")))
  message(sprintf("  Saved: %s_table1.html", protocol_id))
}

save_outcome_table <- function(results_list, protocol_id, output_dir) {
  pa <- results_list$primary_analysis
  outcome_df <- tibble::tibble(
    Outcome = pa$comparison %||% "Primary",
    Method = pa$method %||% "IPW",
    `Effect Estimate (95% CI)` = sprintf("%.2f (%.2f\u2013%.2f)",
      pa$point_estimate, pa$ci_lower, pa$ci_upper),
    `P-value` = sprintf("%.4f", pa$p_value)
  )
  tbl <- gt::gt(outcome_df) |>
    gt::tab_header(title = "Table 2: Outcome Results")
  gt::gtsave(tbl, file.path(output_dir, paste0(protocol_id, "_table2.html")))
  message(sprintf("  Saved: %s_table2.html", protocol_id))
}

save_love_plot <- function(weights, protocol_id, output_dir) {
  p <- love.plot(weights, threshold = 0.1, abs = TRUE, un = TRUE,
                 var.order = "unadjusted",
                 title = "Covariate Balance: Before & After Weighting")
  ggsave(file.path(output_dir, paste0(protocol_id, "_loveplot.pdf")),
         p, width = 8, height = 6)
  ggsave(file.path(output_dir, paste0(protocol_id, "_loveplot.png")),
         p, width = 8, height = 6, dpi = 300)
  message(sprintf("  Saved: %s_loveplot.pdf/png", protocol_id))
}

save_km_curves <- function(cohort, time_var, event_var, treatment_label_var,
                           protocol_id, output_dir, weights_col = "ipw") {
  km_formula <- as.formula(paste0(
    "Surv(", time_var, ", ", event_var, ") ~ ", treatment_label_var))
  km_fit <- survfit(km_formula, data = cohort, weights = cohort[[weights_col]])
  p <- ggsurvplot(km_fit, data = cohort, risk.table = TRUE, pval = TRUE,
                  xlab = "Days from Time Zero",
                  ylab = "Event-Free Probability",
                  palette = c("#2E9FDF", "#E7B800"),
                  title = paste("Kaplan-Meier:", protocol_id))
  pdf(file.path(output_dir, paste0(protocol_id, "_km.pdf")),
      width = 8, height = 7)
  print(p)
  dev.off()
  png(file.path(output_dir, paste0(protocol_id, "_km.png")),
      width = 2400, height = 2100, res = 300)
  print(p)
  dev.off()
  message(sprintf("  Saved: %s_km.pdf/png", protocol_id))
}

save_ps_distribution <- function(cohort, ps_col, treatment_label_col,
                                 protocol_id, output_dir) {
  p <- ggplot(cohort, aes(x = .data[[ps_col]],
                          fill = .data[[treatment_label_col]])) +
    geom_density(alpha = 0.5) +
    labs(x = "Propensity Score", y = "Density",
         title = "Propensity Score Distribution",
         fill = "Treatment") +
    theme_minimal() +
    theme(legend.position = "bottom")
  ggsave(file.path(output_dir, paste0(protocol_id, "_ps_dist.pdf")),
         p, width = 7, height = 5)
  ggsave(file.path(output_dir, paste0(protocol_id, "_ps_dist.png")),
         p, width = 7, height = 5, dpi = 300)
  message(sprintf("  Saved: %s_ps_dist.pdf/png", protocol_id))
}

save_forest_plot <- function(subgroup_results, protocol_id, output_dir) {
  df <- subgroup_results |> filter(!is.na(hr))
  if (nrow(df) < 2) {
    message("  Skipped forest plot: fewer than 2 estimable subgroups")
    return(invisible(NULL))
  }
  p <- ggplot(df, aes(x = hr, y = forcats::fct_rev(subgroup))) +
    geom_point(size = 3) +
    geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper), height = 0.2) +
    geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
    scale_x_log10() +
    labs(x = "Hazard Ratio (95% CI)", y = NULL,
         title = paste("Subgroup Analysis:", protocol_id)) +
    theme_minimal()
  ggsave(file.path(output_dir, paste0(protocol_id, "_forest.pdf")),
         p, width = 8, height = 5)
  ggsave(file.path(output_dir, paste0(protocol_id, "_forest.png")),
         p, width = 8, height = 5, dpi = 300)
  message(sprintf("  Saved: %s_forest.pdf/png", protocol_id))
}

save_consort_figure <- function(consort, protocol_id, output_dir) {
  pdf(file.path(output_dir, paste0(protocol_id, "_consort.pdf")),
      width = 10, height = 12)
  render_consort_diagram(consort)
  dev.off()
  png(file.path(output_dir, paste0(protocol_id, "_consort.png")),
      width = 3000, height = 3600, res = 300)
  render_consort_diagram(consort)
  dev.off()
  message(sprintf("  Saved: %s_consort.pdf/png", protocol_id))
}


# ─── 9. Run Pipeline ────────────────────────────────────────────────────────

main <- function() {
  df     <- load_data(config)
  cohort <- define_cohort(df, config)
  cohort <- define_treatment(cohort, config)
  cohort <- define_outcome(cohort, config)

  results <- switch(config$analysis_method,
    ipw      = run_ipw_analysis(cohort, ps_formula, config),
    gcomp    = run_gcomp_analysis(cohort, ps_formula, config),
    # tmle   = run_tmle_analysis(cohort, confounders, config),
    # matching = run_matching_analysis(cohort, ps_formula, config),
    stop(paste("Unknown method:", config$analysis_method))
  )

  run_sensitivity(results, config)

  message("Analysis complete.")

  # ── Save Structured Results ──────────────────────────────────────────
  pid <- config$protocol_id %||% "protocol_01"
  results_json <- list(
    protocol_id = pid,
    protocol_title = config$question,
    database = list(id = config$dataset_name %||% "unknown",
                    name = config$dataset_name %||% "unknown"),
    warnings = list(),
    errors = list()
  )
  save_results(results_json, pid)

  # ── Publication Outputs (non-fatal) ──────────────────────────────────
  output_dir <- "."
  tryCatch({
    message("\n=== Generating Publication Outputs ===")
    save_table1(cohort, "treatment_label", confounders, pid, output_dir)
    save_love_plot(results$weights, pid, output_dir)
    if (!is.null(config$time_var)) {
      save_km_curves(cohort, config$time_var, config$outcome_var,
                     "treatment_label", pid, output_dir)
    }
    save_ps_distribution(cohort, "ps", "treatment_label", pid, output_dir)
    save_outcome_table(results_json, pid, output_dir)
    # save_forest_plot(subgroup_results, pid, output_dir)  # uncomment when subgroups are computed

    # Add figure paths to JSON and re-save
    results_json$figure_paths <- list(
      table1          = paste0(pid, "_table1.html"),
      table2          = paste0(pid, "_table2.html"),
      love_plot       = paste0(pid, "_loveplot.pdf"),
      km_curve        = paste0(pid, "_km.pdf"),
      ps_distribution = paste0(pid, "_ps_dist.pdf")
    )
    save_results(results_json, pid)
    message("=== Publication outputs complete ===")
  }, error = function(e) {
    message(sprintf("WARNING: Publication output generation failed: %s",
                    conditionMessage(e)))
    message("JSON results were already saved successfully.")
  })

  return(results)
}

# Uncomment to run:
# results <- main()
