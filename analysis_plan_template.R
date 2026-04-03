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

  # ── Balance Diagnostics ──
  bal <- bal.tab(weights, stats = c("m", "v"), thresholds = c(m = 0.1))
  print(bal)

  # Save Love plot
  love.plot(weights,
            threshold = 0.1,
            abs = TRUE,
            title = "Covariate Balance (IPW)")

  # ── Weighted Outcome Model ──
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


# ─── 8. Run Pipeline ────────────────────────────────────────────────────────

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
  return(results)
}

# Uncomment to run:
# results <- main()
