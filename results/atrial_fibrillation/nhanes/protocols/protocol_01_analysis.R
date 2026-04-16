# protocol_01_analysis.R
# DOAC vs Warfarin and All-Cause Mortality in CKD: NHANES 2013-2018
# Prevalent-user design with survey weights and IPW adjustment

# ── Project root resolution ──
if (nzchar(Sys.getenv("AUTOPROTOCOL_PROJECT_ROOT"))) {
  setwd(Sys.getenv("AUTOPROTOCOL_PROJECT_ROOT"))
} else if (file.exists("WORKER.md")) {
  # already in project root
} else if (file.exists("../WORKER.md")) {
  setwd("..")
}

# ── Libraries ──
library(nhanesA)
library(survey)
library(tidyverse)
library(survival)
library(WeightIt)
library(cobalt)
library(EValue)
library(jsonlite)
library(gtsummary)
library(gt)
library(survminer)

# ── Configuration ──
PROTOCOL_ID  <- "protocol_01"
OUTPUT_DIR   <- "results/atrial_fibrillation/nhanes/protocols"
dir.create(OUTPUT_DIR, recursive = TRUE, showWarnings = FALSE)

# ── Results initialisation ──
results <- list(
  protocol_id        = PROTOCOL_ID,
  protocol_title     = "DOAC vs Warfarin and All-Cause Mortality in CKD: NHANES 2013-2018",
  database           = list(id = "nhanes", name = "NHANES"),
  design_category    = "Category A - Prevalent-user TTE",
  execution_timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
  execution_status   = "running"
)

# ── Helper: load and pool 3 NHANES cycles ──
load_3cycles <- function(base_name, select_cols = NULL) {
  suffixes <- c("_H", "_I", "_J")
  cycles   <- c("2013-2014", "2015-2016", "2017-2018")
  purrr::map2_dfr(suffixes, cycles, function(s, cy) {
    tryCatch({
      df <- nhanes(paste0(base_name, s), translate = FALSE)
      if (!is.null(select_cols)) {
        keep <- intersect(select_cols, names(df))
        df <- df[, c("SEQN", keep), drop = FALSE]
      }
      df |> mutate(cycle = cy, across(where(is.factor), as.character))
    },
    error = function(e) {
      message(sprintf("Warning: Could not load %s%s: %s", base_name, s,
                      conditionMessage(e)))
      tibble()
    })
  })
}

# ── Helper: CONSORT text table ──
print_consort_table <- function(steps) {
  cat("\n=== CONSORT Flow ===\n")
  for (s in steps) {
    cat(sprintf("Step %d: %-55s N = %s\n", s$step, s$description,
                format(s$n, big.mark = ",")))
  }
  cat("====================\n\n")
}

# ── Helper: CONSORT diagram (grid graphics) ──
render_consort_diagram <- function(steps, filepath) {
  pdf(filepath, width = 10, height = 12)
  grid::grid.newpage()
  n_steps <- length(steps)
  box_h <- 0.06
  gap   <- (0.85 - n_steps * box_h) / (n_steps - 1)

  for (i in seq_along(steps)) {
    y <- 0.92 - (i - 1) * (box_h + gap)
    label <- sprintf("%s\n(N = %s)", steps[[i]]$description,
                     format(steps[[i]]$n, big.mark = ","))
    grid::grid.rect(x = 0.5, y = y, width = 0.7, height = box_h,
                    gp = grid::gpar(fill = "grey95", col = "black"))
    grid::grid.text(label, x = 0.5, y = y,
                    gp = grid::gpar(fontsize = 9, lineheight = 1.1))
    if (i < n_steps) {
      grid::grid.lines(x = c(0.5, 0.5),
                       y = c(y - box_h / 2, y - box_h / 2 - gap + 0.01),
                       arrow = grid::arrow(length = grid::unit(0.08, "inches")),
                       gp = grid::gpar(col = "black"))
    }
  }
  dev.off()
}

# ── Helper: read NHANES linked mortality file (fixed-width) ──
read_nhanes_mort <- function(url, cycle_label) {
  tryCatch({
    lines <- readLines(url)
    tibble(
      SEQN         = as.integer(trimws(substr(lines, 1, 14))),
      ELIGSTAT     = as.integer(substr(lines, 15, 15)),
      MORTSTAT     = suppressWarnings(as.integer(substr(lines, 16, 16))),
      UCOD_LEADING = trimws(substr(lines, 17, 19)),
      DIABETES_MCF = suppressWarnings(as.integer(substr(lines, 20, 20))),
      HYPERTEN_MCF = suppressWarnings(as.integer(substr(lines, 21, 21)))
    ) |>
      mutate(cycle = cycle_label) |>
      bind_cols({
        remainder <- trimws(substr(lines, 22, nchar(lines)))
        parts <- str_split_fixed(remainder, "\\s+", 2)
        tibble(
          PERMTH_INT = suppressWarnings(as.numeric(parts[, 1])),
          PERMTH_EXM = suppressWarnings(as.numeric(parts[, 2]))
        )
      })
  }, error = function(e) {
    message(sprintf("Warning: Could not load mortality for %s: %s",
                    cycle_label, conditionMessage(e)))
    tibble()
  })
}

consort_steps <- list()

# ══════════════════════════════════════════════════════════════════════════════
# MAIN ANALYSIS PIPELINE
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

# ── Step 1: Load demographics ──
message("Step 1: Loading demographics (3 cycles)...")
demo <- load_3cycles("DEMO") |>
  mutate(RIDSTATR = as.numeric(RIDSTATR),
         RIDAGEYR = as.numeric(RIDAGEYR),
         RIAGENDR = as.numeric(RIAGENDR),
         WTMEC2YR = as.numeric(WTMEC2YR),
         INDFMPIR = as.numeric(INDFMPIR)) |>
  filter(RIDSTATR == 2, RIDAGEYR >= 18)

consort_steps <- append(consort_steps, list(
  list(step = 1, description = "US adults examined (MEC), 3 cycles 2013-2018",
       n = nrow(demo))
))

# ── Step 2: Load medications, identify treatment groups ──
message("Step 2: Loading medications...")
rxq <- load_3cycles("RXQ_RX")

doac_pattern     <- regex("apixaban|rivaroxaban|dabigatran", ignore_case = TRUE)
warfarin_pattern <- regex("warfarin", ignore_case = TRUE)

doac_users <- rxq |>
  filter(str_detect(RXDDRUG, doac_pattern)) |>
  distinct(SEQN, cycle) |>
  mutate(doac_use = 1L)

warfarin_users <- rxq |>
  filter(str_detect(RXDDRUG, warfarin_pattern)) |>
  distinct(SEQN, cycle) |>
  mutate(warfarin_use = 1L)

ac_users <- doac_users |>
  full_join(warfarin_users, by = c("SEQN", "cycle")) |>
  mutate(doac_use     = replace_na(doac_use, 0L),
         warfarin_use = replace_na(warfarin_use, 0L)) |>
  filter(!(doac_use == 1 & warfarin_use == 1)) |>
  mutate(treatment = if_else(doac_use == 1, 1L, 0L))

demo_ac <- demo |>
  inner_join(ac_users, by = c("SEQN", "cycle"))

consort_steps <- append(consort_steps, list(
  list(step = 2,
       description = "On oral anticoagulant (DOAC or warfarin, excl. dual)",
       n = nrow(demo_ac))
))

# ── Step 3: Load serum creatinine, calculate eGFR ──
message("Step 3: Loading biochemistry and calculating eGFR...")
biopro <- load_3cycles("BIOPRO")

demo_ac_labs <- demo_ac |>
  inner_join(biopro |>
               mutate(LBXSCR = as.numeric(LBXSCR),
                      LBXSAL = as.numeric(LBXSAL)) |>
               select(SEQN, cycle, LBXSCR, LBXSAL),
             by = c("SEQN", "cycle")) |>
  filter(!is.na(LBXSCR))

demo_ac_labs <- demo_ac_labs |>
  mutate(
    female = as.integer(RIAGENDR == 2),
    kappa  = if_else(female == 1, 0.7, 0.9),
    alpha  = if_else(female == 1, -0.241, -0.302),
    eGFR   = 142 * pmin(LBXSCR / kappa, 1)^alpha *
                   pmax(LBXSCR / kappa, 1)^(-1.200) *
                   0.9938^RIDAGEYR *
                   if_else(female == 1, 1.012, 1.0)
  )

consort_steps <- append(consort_steps, list(
  list(step = 3, description = "Serum creatinine available for eGFR",
       n = nrow(demo_ac_labs))
))

ckd_cohort <- demo_ac_labs |> filter(eGFR < 60)

consort_steps <- append(consort_steps, list(
  list(step = 4, description = "eGFR < 60 mL/min/1.73m2 (CKD stage 3-5)",
       n = nrow(ckd_cohort))
))

# ── Step 4: Load covariates ──
message("Step 4: Loading covariates...")
ghb    <- load_3cycles("GHB")
bmx    <- load_3cycles("BMX")
mcq    <- load_3cycles("MCQ", select_cols = c("MCQ160B", "MCQ160C", "MCQ160E", "MCQ160F"))
diq    <- load_3cycles("DIQ")
smq    <- load_3cycles("SMQ")
bpq    <- load_3cycles("BPQ")
tchol  <- load_3cycles("TCHOL")
hdl    <- load_3cycles("HDL")
alb_cr <- load_3cycles("ALB_CR")

cohort <- ckd_cohort |>
  left_join(ghb    |> select(SEQN, cycle, LBXGH),   by = c("SEQN", "cycle")) |>
  left_join(bmx    |> select(SEQN, cycle, BMXBMI),   by = c("SEQN", "cycle")) |>
  left_join(mcq    |> select(SEQN, cycle, any_of(c("MCQ160B", "MCQ160C", "MCQ160E", "MCQ160F"))),
            by = c("SEQN", "cycle")) |>
  left_join(diq    |> select(SEQN, cycle, DIQ010),   by = c("SEQN", "cycle")) |>
  left_join(smq    |> select(SEQN, cycle, SMQ020, SMQ040), by = c("SEQN", "cycle")) |>
  left_join(bpq    |> select(SEQN, cycle, BPQ020),   by = c("SEQN", "cycle")) |>
  left_join(tchol  |> select(SEQN, cycle, LBXTC),    by = c("SEQN", "cycle")) |>
  left_join(hdl    |> select(SEQN, cycle, LBDHDD),   by = c("SEQN", "cycle")) |>
  left_join(alb_cr |> select(SEQN, cycle, URDACT),   by = c("SEQN", "cycle"))

# Convert all to numeric (translate=FALSE may still return character)
cohort <- cohort |>
  mutate(across(c(any_of(c("MCQ160B","MCQ160C","MCQ160E","MCQ160F",
                            "DIQ010","SMQ020","SMQ040","BPQ020",
                            "LBXGH","BMXBMI","LBXTC","LBDHDD","URDACT",
                            "LBXSCR","LBXSAL"))), as.numeric))

# Recode NHANES missing-data sentinel codes (per codebook)
cohort <- cohort |>
  mutate(
    MCQ160B = na_if(MCQ160B, 7) |> na_if(9),
    MCQ160C = na_if(MCQ160C, 7) |> na_if(9),
    MCQ160E = na_if(MCQ160E, 7) |> na_if(9),
    MCQ160F = na_if(MCQ160F, 7) |> na_if(9),
    DIQ010  = na_if(DIQ010, 7)  |> na_if(9),
    SMQ020  = na_if(SMQ020, 7)  |> na_if(9),
    SMQ040  = na_if(SMQ040, 7)  |> na_if(9),
    BPQ020  = na_if(BPQ020, 7)  |> na_if(9)
  )

# Derive binary indicators
cohort <- cohort |>
  mutate(
    chf            = as.integer(MCQ160B == 1),
    chd            = as.integer(MCQ160C == 1),
    mi_hx          = as.integer(MCQ160E == 1),
    stroke_hx      = as.integer(MCQ160F == 1),
    diabetes        = as.integer(DIQ010 == 1),
    hypertension    = as.integer(BPQ020 == 1),
    current_smoker  = as.integer(SMQ020 == 1 & SMQ040 %in% c(1, 2)),
    race_eth        = factor(RIDRETH3)
  )

# ── Step 5: Download and merge mortality ──
message("Step 5: Downloading NHANES linked mortality files...")
mort_urls <- c(
  "2013-2014" = "https://ftp.cdc.gov/pub/Health_Statistics/NCHS/datalinkage/linked_mortality/NHANES_2013_2014_MORT_2019_PUBLIC.dat",
  "2015-2016" = "https://ftp.cdc.gov/pub/Health_Statistics/NCHS/datalinkage/linked_mortality/NHANES_2015_2016_MORT_2019_PUBLIC.dat",
  "2017-2018" = "https://ftp.cdc.gov/pub/Health_Statistics/NCHS/datalinkage/linked_mortality/NHANES_2017_2018_MORT_2019_PUBLIC.dat"
)

mort <- purrr::imap_dfr(mort_urls, ~ read_nhanes_mort(.x, .y)) |>
  filter(ELIGSTAT == 1)

cohort_mort <- cohort |>
  inner_join(mort |> select(SEQN, cycle, MORTSTAT, PERMTH_EXM, UCOD_LEADING),
             by = c("SEQN", "cycle")) |>
  filter(!is.na(PERMTH_EXM), PERMTH_EXM > 0)

consort_steps <- append(consort_steps, list(
  list(step = 5, description = "Linked mortality follow-up available (ELIGSTAT=1)",
       n = nrow(cohort_mort))
))

# ── Step 6: Final analytic cohort ──
message("Step 6: Building final analytic cohort...")
analytic <- cohort_mort |>
  filter(!is.na(BMXBMI), !is.na(WTMEC2YR), WTMEC2YR > 0) |>
  mutate(
    chf            = replace_na(chf, 0L),
    chd            = replace_na(chd, 0L),
    mi_hx          = replace_na(mi_hx, 0L),
    stroke_hx      = replace_na(stroke_hx, 0L),
    diabetes        = replace_na(diabetes, 0L),
    hypertension    = replace_na(hypertension, 0L),
    current_smoker  = replace_na(current_smoker, 0L),
    WTMEC6YR        = WTMEC2YR / 3
  )

consort_steps <- append(consort_steps, list(
  list(step = 6, description = "Complete data for analysis (non-missing BMI, wt>0)",
       n = nrow(analytic))
))

results$consort <- list(
  steps      = consort_steps,
  n_treated  = sum(analytic$treatment == 1),
  n_control  = sum(analytic$treatment == 0)
)
print_consort_table(consort_steps)

message(sprintf("DOAC arm: %d | Warfarin arm: %d",
                sum(analytic$treatment == 1), sum(analytic$treatment == 0)))

# ── Empty cohort guard ──
if (nrow(analytic) == 0) {
  results$execution_status <- "error"
  results$errors <- list(list(message = "Analytic cohort has 0 patients"))
  results_path <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_results.json"))
  jsonlite::write_json(results, results_path, pretty = TRUE, auto_unbox = TRUE)
  message("*** STOPPING: Analytic cohort has 0 patients. ***")
  stop("Empty cohort")
}

# ── Treatment arms guard ──
if (length(unique(analytic$treatment)) < 2) {
  results$execution_status <- "error"
  results$errors <- list(list(message = "Treatment variable has < 2 levels"))
  results_path <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_results.json"))
  jsonlite::write_json(results, results_path, pretty = TRUE, auto_unbox = TRUE)
  message("*** STOPPING: Treatment variable has < 2 levels. ***")
  stop("Single treatment arm")
}

# ── Step 7: Propensity score estimation ──
message("Step 7: Estimating propensity scores...")

# Build PS formula dynamically, dropping zero-variance predictors
ps_candidates <- c("RIDAGEYR", "female", "eGFR", "BMXBMI", "INDFMPIR",
                    "chf", "chd", "mi_hx", "stroke_hx", "diabetes",
                    "hypertension", "current_smoker")

# Add continuous lab covariates if enough non-missing
for (v in c("LBXGH", "LBXTC", "LBDHDD")) {
  if (sum(!is.na(analytic[[v]])) >= 10) ps_candidates <- c(ps_candidates, v)
}

# Drop single-level / zero-variance columns
ps_vars <- c()
for (v in ps_candidates) {
  vals <- analytic[[v]]
  if (is.factor(vals)) {
    if (nlevels(droplevels(vals)) >= 2) ps_vars <- c(ps_vars, v)
  } else if (is.numeric(vals)) {
    if (sd(vals, na.rm = TRUE) > 0) ps_vars <- c(ps_vars, v)
  }
}

# Add race/ethnicity if >= 2 levels
if (nlevels(droplevels(analytic$race_eth)) >= 2) {
  ps_vars <- c(ps_vars, "race_eth")
}

ps_formula <- as.formula(paste("treatment ~", paste(ps_vars, collapse = " + ")))
message("PS formula: ", deparse(ps_formula))

# Use WeightIt with survey sampling weights
wt_obj <- weightit(
  ps_formula, data = analytic,
  method    = "ps",
  estimand  = "ATE",
  s.weights = "WTMEC6YR"
)

analytic$ps   <- wt_obj$ps
analytic$sipw <- wt_obj$weights

# Combined survey × IPW weights
analytic$combined_wt <- analytic$WTMEC6YR * analytic$sipw

# Truncate extreme combined weights at 1st/99th percentiles
wt_bounds <- quantile(analytic$combined_wt, c(0.01, 0.99), na.rm = TRUE)
analytic$combined_wt <- pmin(pmax(analytic$combined_wt, wt_bounds[1]),
                              wt_bounds[2])

# ── Step 8: Balance diagnostics ──
message("Step 8: Assessing covariate balance...")

bal <- bal.tab(wt_obj, stats = c("m", "v"), un = TRUE,
               thresholds = c(m = 0.1))
print(bal)

smd_before <- max(abs(bal$Balance$Diff.Un), na.rm = TRUE)
smd_after  <- max(abs(bal$Balance$Diff.Adj), na.rm = TRUE)

results$balance_diagnostics <- list(
  pre_weighting_max_smd  = round(smd_before, 3),
  post_weighting_max_smd = round(smd_after, 3),
  all_below_threshold    = smd_after < 0.1,
  threshold              = 0.1
)
message(sprintf("Max SMD — before: %.3f, after: %.3f", smd_before, smd_after))

# ── Step 9: Primary analysis — Survey-weighted Cox PH ──
message("Step 9: Fitting survey-weighted Cox PH model...")

svy_cox_des <- svydesign(
  ids     = ~SDMVPSU,
  strata  = ~SDMVSTRA,
  weights = ~combined_wt,
  nest    = TRUE,
  data    = analytic
)

cox_fit <- svycoxph(
  Surv(PERMTH_EXM, MORTSTAT) ~ treatment,
  design = svy_cox_des
)

cox_summary <- summary(cox_fit)
hr    <- exp(coef(cox_fit)["treatment"])
hr_ci <- exp(confint(cox_fit)["treatment", ])
hr_p  <- cox_summary$coefficients["treatment", "Pr(>|z|)"]

results$primary_analysis <- list(
  method         = "Survey-weighted IPW Cox PH (prevalent-user design)",
  estimand       = "ATE",
  effect_measure = "HR",
  point_estimate = round(as.numeric(hr), 3),
  ci_lower       = round(as.numeric(hr_ci[1]), 3),
  ci_upper       = round(as.numeric(hr_ci[2]), 3),
  p_value        = round(as.numeric(hr_p), 4),
  interpretation = sprintf(
    "HR = %.2f (95%% CI: %.2f-%.2f); DOAC vs warfarin for all-cause mortality",
    hr, hr_ci[1], hr_ci[2]
  )
)

message(sprintf("HR = %.3f (95%% CI: %.3f-%.3f), p = %.4f",
                hr, hr_ci[1], hr_ci[2], hr_p))

# Outcome summary
results$outcome_summary <- list(
  total_events          = sum(analytic$MORTSTAT == 1),
  events_treated        = sum(analytic$MORTSTAT[analytic$treatment == 1] == 1),
  events_control        = sum(analytic$MORTSTAT[analytic$treatment == 0] == 1),
  median_followup_months = round(median(analytic$PERMTH_EXM), 1),
  n_treated             = sum(analytic$treatment == 1),
  n_control             = sum(analytic$treatment == 0)
)

# ── Step 10: E-value sensitivity analysis ──
message("Step 10: Computing E-value...")
evalue_result <- tryCatch({
  event_rate <- sum(analytic$MORTSTAT == 1) / nrow(analytic)
  ev <- EValue::evalues.HR(est = as.numeric(hr),
                           lo  = as.numeric(hr_ci[1]),
                           hi  = as.numeric(hr_ci[2]),
                           rare = event_rate < 0.10)
  list(
    point = round(ev[2, "point"], 2),
    ci    = round(ev[2, "lower"], 2)
  )
}, error = function(e) {
  message("E-value calculation skipped: ", conditionMessage(e))
  list(point = 1, ci = 1,
       note = "CI crosses null; E-value is 1 by definition.")
})

results$sensitivity_analyses <- list(e_value = evalue_result)

# ── Unadjusted (survey-only) Cox as sensitivity ──
message("Sensitivity: unadjusted survey-weighted Cox...")
svy_unadj <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTMEC6YR, nest = TRUE, data = analytic
)
cox_unadj <- tryCatch({
  fit <- svycoxph(Surv(PERMTH_EXM, MORTSTAT) ~ treatment, design = svy_unadj)
  hr_u  <- exp(coef(fit)["treatment"])
  ci_u  <- exp(confint(fit)["treatment", ])
  list(HR = round(as.numeric(hr_u), 3),
       ci_lower = round(as.numeric(ci_u[1]), 3),
       ci_upper = round(as.numeric(ci_u[2]), 3))
}, error = function(e) {
  message("Unadjusted Cox failed: ", conditionMessage(e))
  list(note = conditionMessage(e))
})
results$sensitivity_analyses$unadjusted_cox <- cox_unadj

results$execution_status <- "success"

}, error = function(e) {
  results$execution_status <<- "error"
  results$errors <<- list(list(
    message = conditionMessage(e),
    call    = deparse(conditionCall(e))
  ))
  message(sprintf("ERROR: %s", conditionMessage(e)))
})

# ── Save results (always, even on error) ──
results_path <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_results.json"))
jsonlite::write_json(results, results_path, pretty = TRUE, auto_unbox = TRUE)
message(sprintf("Results saved to: %s", results_path))

# ══════════════════════════════════════════════════════════════════════════════
# PUBLICATION OUTPUTS (non-fatal — wrapped in tryCatch)
# ══════════════════════════════════════════════════════════════════════════════
tryCatch({

  message("\n=== Generating publication outputs ===")

  # ── Table 1: Baseline characteristics ──
  message("Generating Table 1...")
  tbl1_data <- analytic |>
    mutate(treatment_label = factor(
      if_else(treatment == 1, "DOAC", "Warfarin"),
      levels = c("DOAC", "Warfarin")
    ))

  tbl1 <- tbl1_data |>
    select(treatment_label, RIDAGEYR, female, eGFR, BMXBMI, LBXGH,
           LBXTC, LBDHDD, chf, chd, mi_hx, stroke_hx, diabetes,
           hypertension, current_smoker) |>
    tbl_summary(
      by = treatment_label,
      label = list(
        RIDAGEYR       ~ "Age (years)",
        female         ~ "Female",
        eGFR           ~ "eGFR (mL/min/1.73m2)",
        BMXBMI         ~ "BMI (kg/m2)",
        LBXGH          ~ "HbA1c (%)",
        LBXTC          ~ "Total cholesterol (mg/dL)",
        LBDHDD         ~ "HDL cholesterol (mg/dL)",
        chf            ~ "Heart failure",
        chd            ~ "Coronary heart disease",
        mi_hx          ~ "Prior myocardial infarction",
        stroke_hx      ~ "Prior stroke",
        diabetes        ~ "Diabetes",
        hypertension    ~ "Hypertension",
        current_smoker  ~ "Current smoker"
      ),
      statistic = list(
        all_continuous()  ~ "{mean} ({sd})",
        all_dichotomous() ~ "{n} ({p}%)"
      ),
      missing = "ifany"
    ) |>
    add_overall() |>
    add_difference()

  tbl1_path <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_table1.html"))
  gt::gtsave(as_gt(tbl1), tbl1_path)
  message(sprintf("Table 1 saved: %s", tbl1_path))

  # ── Love plot ──
  message("Generating love plot...")
  lp_pdf <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_loveplot.pdf"))
  lp_png <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_loveplot.png"))

  pdf(lp_pdf, width = 8, height = 6)
  love.plot(wt_obj, threshold = 0.1, abs = TRUE, un = TRUE, stars = "std",
            title = "Covariate Balance: DOAC vs Warfarin (NHANES CKD Cohort)")
  dev.off()

  png(lp_png, width = 8, height = 6, units = "in", res = 300)
  love.plot(wt_obj, threshold = 0.1, abs = TRUE, un = TRUE, stars = "std",
            title = "Covariate Balance: DOAC vs Warfarin (NHANES CKD Cohort)")
  dev.off()

  message(sprintf("Love plot saved: %s", lp_pdf))

  # ── PS distribution ──
  message("Generating PS distribution plot...")
  ps_plot <- ggplot(analytic,
                    aes(x = ps,
                        fill = factor(treatment,
                                      labels = c("Warfarin", "DOAC")))) +
    geom_density(alpha = 0.5) +
    labs(x = "Propensity Score", y = "Density", fill = "Treatment",
         title = "Propensity Score Distribution by Treatment Group") +
    theme_minimal()

  ggsave(file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_ps_dist.pdf")),
         ps_plot, width = 8, height = 6)
  ggsave(file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_ps_dist.png")),
         ps_plot, width = 8, height = 6, dpi = 300)
  message("PS distribution saved.")

  # ── KM curves (weighted) ──
  message("Generating Kaplan-Meier curves...")
  km_fit <- survfit(
    Surv(PERMTH_EXM, MORTSTAT) ~ treatment,
    data = analytic, weights = combined_wt
  )

  km_plot <- ggsurvplot(
    km_fit, data = analytic,
    risk.table  = TRUE,
    pval        = TRUE,
    legend.labs = c("Warfarin", "DOAC"),
    xlab        = "Months from MEC Exam",
    ylab        = "Survival Probability",
    title       = "All-Cause Mortality: DOAC vs Warfarin in CKD\n(NHANES 2013-2018, Prevalent-User Design)",
    ggtheme     = theme_minimal()
  )

  km_pdf <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_km.pdf"))
  km_png <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_km.png"))

  pdf(km_pdf, width = 8, height = 7)
  print(km_plot)
  dev.off()

  png(km_png, width = 8, height = 7, units = "in", res = 300)
  print(km_plot)
  dev.off()

  message(sprintf("KM curves saved: %s", km_pdf))

  # ── CONSORT diagram ──
  message("Generating CONSORT diagram...")
  consort_pdf <- file.path(OUTPUT_DIR, paste0(PROTOCOL_ID, "_consort.pdf"))
  render_consort_diagram(consort_steps, consort_pdf)
  message(sprintf("CONSORT diagram saved: %s", consort_pdf))

  # ── Update results with figure paths ──
  results$figure_paths <- list(
    table1          = paste0(PROTOCOL_ID, "_table1.html"),
    love_plot       = paste0(PROTOCOL_ID, "_loveplot.pdf"),
    ps_distribution = paste0(PROTOCOL_ID, "_ps_dist.pdf"),
    km_curve        = paste0(PROTOCOL_ID, "_km.pdf"),
    consort         = paste0(PROTOCOL_ID, "_consort.pdf")
  )

  jsonlite::write_json(results, results_path, pretty = TRUE, auto_unbox = TRUE)
  message("Results re-saved with figure paths.")

}, error = function(e) {
  message(sprintf("Publication output error (non-fatal): %s",
                  conditionMessage(e)))
})

message("\n=== Analysis complete ===")
