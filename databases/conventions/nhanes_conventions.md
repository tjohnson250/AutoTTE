# NHANES — Database Conventions

These conventions are specific to NHANES data accessed via the nhanesA R package
and loaded into DuckDB in-memory. Agents MUST read and apply every convention
when writing R or SQL code targeting NHANES. Reviewers MUST check every
convention as a review item.

## Data Access: nhanesA + DuckDB

NHANES data is accessed via the `nhanesA` R package, which downloads SAS
transport (XPT) files from the CDC website and returns R data frames. In online
mode, these are loaded into a DuckDB in-memory database for SQL querying.

### Loading Tables

```r
# Load a table into DuckDB (lazy — fetches from CDC on first call)
load_nhanes("DEMO_J")

# Then query via SQL
query_db("SELECT * FROM DEMO_J WHERE RIDAGEYR >= 18")

# Or load directly in R without DuckDB
df <- nhanes("DEMO_J")
```

### Join Key

All tables join on `SEQN` (Respondent Sequence Number). SEQN is unique within
a cycle but NOT across cycles.

```sql
SELECT d.*, g.LBXGH
FROM DEMO_J d
INNER JOIN GHB_J g ON d.SEQN = g.SEQN
WHERE d.RIDSTATR = 2
```

## Survey Design (MANDATORY)

**CRITICAL: Every analysis producing population-level estimates MUST use the
`survey` package with the complex survey design.** Failing to do so produces
biased point estimates and incorrect standard errors/confidence intervals.

### Design Variables

| Variable | Purpose | When to Use |
|----------|---------|-------------|
| WTMEC2YR | MEC exam weight (2-year) | Exam or lab components |
| WTINT2YR | Interview weight (2-year) | Interview-only components |
| WTSAF2YR | Fasting subsample weight | Fasting labs (glucose, triglycerides, insulin) |
| SDMVSTRA | Masked variance pseudo-stratum | Always (design structure) |
| SDMVPSU | Masked variance pseudo-PSU | Always (design structure) |

### Required Pattern

```r
library(survey)

# Standard MEC design (exam + lab data)
des <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  nest = TRUE,
  data = analytic_df
)

# Fasting subsample design (glucose, triglycerides, insulin)
des_fasting <- svydesign(
  ids = ~SDMVPSU,
  strata = ~SDMVSTRA,
  weights = ~WTSAF2YR,
  nest = TRUE,
  data = fasting_df
)
```

### Weighted Analysis Functions

Use survey-weighted versions of ALL statistical functions:

| Instead of | Use | Package |
|-----------|-----|---------|
| `mean()` | `svymean()` | survey |
| `glm()` | `svyglm()` | survey |
| `coxph()` | `svycoxph()` | survey |
| `chisq.test()` | `svychisq()` | survey |
| `t.test()` | `svyttest()` | survey |
| `quantile()` | `svyquantile()` | survey |
| `table()` | `svytable()` | survey |
| `lm()` | `svyglm(..., family = gaussian())` | survey |
| `logistic via glm()` | `svyglm(..., family = quasibinomial())` | survey |

**Note:** Use `quasibinomial()` not `binomial()` for logistic regression with
survey designs to avoid "non-integer successes" warnings.

### Exception

Internal validity analyses (e.g., within-sample prediction models, machine
learning) may omit survey weights with explicit justification documented in the
protocol. External generalizability claims still require weighting.

## Missing Data Codes (MANDATORY)

NHANES uses special numeric codes for non-response. These are NOT coded as NA
in the raw data and MUST be recoded before analysis.

| Code | Meaning |
|------|---------|
| 7, 77, 777, 7777 | Refused |
| 9, 99, 999, 9999 | Don't know |

The number of digits matches the field width. For example, a 2-digit field uses
77/99; a 4-digit field uses 7777/9999.

**Rule:** For every variable used in analysis, check the codebook for special
codes and recode to NA:

```r
# Per-variable approach (preferred — use exact codes from codebook)
df <- df |>
  mutate(
    INDHHIN2 = na_if(INDHHIN2, 77) |> na_if(99),
    DMDMARTZ = na_if(DMDMARTZ, 77) |> na_if(99),
    ALQ121   = na_if(ALQ121, 777) |> na_if(999)
  )
```

Do NOT blindly recode all 77s and 99s — some variables legitimately have these
values (e.g., lab results, continuous measures). Always check the codebook.

## Cycle Combining

When pooling multiple 2-year cycles:

1. **Adjust weights:** Divide 2-year weights by the number of cycles pooled.

```r
# Two cycles (e.g., 2015-2016 + 2017-2018)
combined$WTMEC4YR <- combined$WTMEC2YR / 2

# Three cycles
combined$WTMEC6YR <- combined$WTMEC2YR / 3
```

2. **Harmonize variable names:** Suffixes change per cycle. Strip or standardize.

```r
# Load and rename
demo_i <- nhanes("DEMO_I") |> mutate(cycle = "2015-2016")
demo_j <- nhanes("DEMO_J") |> mutate(cycle = "2017-2018")
combined <- bind_rows(demo_i, demo_j)
```

3. **Check for variable changes:** Some variables are added, removed, or recoded
   between cycles. Use `nhanesCodebook()` to compare. Common changes:
   - Blood pressure protocol changed from auscultatory to oscillometric in
     2017-2018 (BPX → BPXO). Cannot directly combine BP readings across this
     boundary.
   - Race variable RIDRETH3 (with NH Asian category) available from 2011-2012+.
     Earlier cycles only have RIDRETH1.

4. **Use single-cycle data by default.** Only combine cycles when sample size
   is insufficient for the research question.

## Fasting Subsample

Glucose, triglycerides, and insulin are measured only in participants examined
in the morning session after an overnight fast (~50% of MEC participants).

**Rules:**
- Use `WTSAF2YR` (not `WTMEC2YR`) as the weight variable for any analysis
  involving fasting labs
- Merge fasting weights from the fasting lab table (e.g., GLU_J has WTSAF2YR)
- Participants with WTSAF2YR == 0 or NA were not in the fasting subsample —
  exclude them
- BIOPRO_J glucose (LBXSGL) is NOT fasting — it is measured in all participants.
  Use GLU_J (LBXGLU) for fasting glucose.

```r
# Correct: fasting glucose with fasting weight
fasting_df <- demo |>
  inner_join(glu, by = "SEQN") |>
  filter(WTSAF2YR > 0 & !is.na(WTSAF2YR))

des_fasting <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTSAF2YR, nest = TRUE, data = fasting_df
)
```

## Age Top-Coding

Ages ≥80 are coded as 80 in `RIDAGEYR`. This is a disclosure protection
measure.

- Cannot distinguish 80-year-olds from 95-year-olds
- For elderly-focused protocols, document this ceiling effect as a limitation
- `RIDAGEMN` (age in months) is only available for children under 24 months

## Target Trial Emulation Design Constraints

NHANES is a cross-sectional survey. Exposure and outcome are typically measured
at the same time point. This fundamentally limits causal inference designs.

### Legitimate TTE Designs with NHANES

1. **Mortality outcomes (strongest design)**
   - Baseline: NHANES exam visit (exposure, confounders measured)
   - Follow-up: Linked mortality file (prospective outcome)
   - Time-to-event: PERMTH_EXM from mortality file
   - This is a true prospective design and the preferred approach

2. **Prevalent exposure → mortality**
   - Example: Current statin use → all-cause mortality
   - Treatment: self-reported or biomarker-confirmed at exam
   - Outcome: mortality follow-up
   - Limitation: prevalent user bias (survivors already selected)

3. **Cross-sectional with temporal reasoning (weaker)**
   - Example: "Ever diagnosed with diabetes" (past) → current HbA1c
   - Requires careful justification of temporal ordering
   - Cannot establish when exposure began relative to outcome

### Designs to AVOID

- Biomarker → same-visit biomarker (no temporal ordering)
- Self-reported condition → self-reported condition (both cross-sectional)
- Any design claiming incident (new-onset) outcomes from cross-sectional data

### Required Documentation

Every NHANES TTE protocol MUST include:
1. Explicit justification of temporal ordering between exposure and outcome
2. Statement of cross-sectional design limitations
3. Discussion of prevalent user bias if using current medication exposure
4. Sensitivity analysis for unmeasured time-varying confounding

## Prescription Medication Conventions

RXQ_RX_J contains 30-day prescription medication use.

- **Multiple rows per participant** — one row per medication. Always aggregate
  to participant level when building analytic cohorts.
- **Drug identification:** Use `RXDDRUG` (generic drug name string), not
  Lexicon Plus codes, for human-readable medication classification.
- **No RxNorm CUIs:** NHANES uses Lexicon Plus drug codes (RXDDRGID), not
  RxNorm. Match on generic drug name if mapping to RxNorm.
- **Self-reported:** Subject to recall bias and underreporting. Participants
  bring medication bottles to the interview, but compliance varies.
- **ICD-10-CM reason for use:** RXDRSC1-3 contain ICD-10 codes for why the
  medication was prescribed. Useful for indication-based cohort selection.

```r
# Example: Identify statin users
statin_names <- c("Atorvastatin", "Rosuvastatin", "Simvastatin",
                  "Pravastatin", "Lovastatin", "Fluvastatin", "Pitavastatin")

statin_users <- rxq |>
  filter(str_detect(toupper(RXDDRUG), paste(toupper(statin_names), collapse = "|"))) |>
  distinct(SEQN) |>
  mutate(statin_use = 1L)

analytic <- demo |>
  left_join(statin_users, by = "SEQN") |>
  mutate(statin_use = replace_na(statin_use, 0L))
```

## R Code Patterns

### Standard Analysis Setup

```r
library(nhanesA)
library(survey)
library(tidyverse)

# 1. Load and merge tables
load_nhanes("DEMO_J")
load_nhanes("GHB_J")
load_nhanes("BMX_J")
load_nhanes("BPQ_J")
load_nhanes("DIQ_J")

analytic <- query_db("
  SELECT d.SEQN, d.RIAGENDR, d.RIDAGEYR, d.RIDRETH3,
         d.DMDEDUC2, d.INDFMPIR,
         d.WTMEC2YR, d.SDMVSTRA, d.SDMVPSU,
         g.LBXGH,
         b.BMXBMI,
         bpq.BPQ020, bpq.BPQ040A,
         diq.DIQ010
  FROM DEMO_J d
  LEFT JOIN GHB_J g ON d.SEQN = g.SEQN
  LEFT JOIN BMX_J b ON d.SEQN = b.SEQN
  LEFT JOIN BPQ_J bpq ON d.SEQN = bpq.SEQN
  LEFT JOIN DIQ_J diq ON d.SEQN = diq.SEQN
  WHERE d.RIDSTATR = 2 AND d.RIDAGEYR >= 18
")

# 2. Recode missing data (per codebook)
analytic <- analytic |>
  mutate(
    DMDEDUC2 = na_if(DMDEDUC2, 7) |> na_if(9),
    BPQ020   = na_if(BPQ020, 7) |> na_if(9),
    BPQ040A  = na_if(BPQ040A, 7) |> na_if(9),
    DIQ010   = na_if(DIQ010, 7) |> na_if(9)
  )

# 3. Create survey design
des <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTMEC2YR, nest = TRUE, data = analytic
)

# 4. Survey-weighted analysis
fit <- svyglm(outcome ~ treatment + RIDAGEYR + factor(RIAGENDR) +
               factor(RIDRETH3) + DMDEDUC2 + INDFMPIR + BMXBMI,
               design = des, family = quasibinomial())
```

### Codebook Lookup

```r
# Get full codebook for a table (useful for verifying missing codes)
cb <- nhanesCodebook("DEMO_J")

# Translate coded values to labels
demo_labeled <- nhanesTranslate("DEMO_J",
  colnames = c("RIAGENDR", "RIDRETH3", "DMDEDUC2"))
```

### Mortality Analysis

```r
# Load mortality file (downloaded separately as CSV)
mort <- read_csv("NHANES_2017_2018_MORT_2019_PUBLIC.csv")

# Merge with NHANES
analytic_mort <- analytic |>
  inner_join(mort, by = "SEQN") |>
  filter(ELIGSTAT == 1)  # Eligible for follow-up

# Survey-weighted Cox model for mortality
des_mort <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTMEC2YR, nest = TRUE, data = analytic_mort
)

fit_cox <- svycoxph(
  Surv(PERMTH_EXM, MORTSTAT) ~ treatment + RIDAGEYR + factor(RIAGENDR),
  design = des_mort
)
```

## Column Handling

### Case Sensitivity

NHANES variables from nhanesA retain their original case (UPPERCASE). When
loaded into DuckDB, column names preserve case. Use UPPERCASE in SQL queries:

```sql
SELECT SEQN, RIDAGEYR, LBXGH FROM DEMO_J
```

In R code, also use UPPERCASE variable names to match:

```r
df |> filter(RIDAGEYR >= 18, RIAGENDR == 1)
```

### Derived Variables

Create derived variables with distinct lowercase names to avoid overwriting:

```r
analytic <- analytic |>
  mutate(
    age_cat = cut(RIDAGEYR, breaks = c(18, 40, 60, 80), right = FALSE,
                  labels = c("18-39", "40-59", "60-79")),
    obese = as.integer(BMXBMI >= 30),
    diabetes_status = case_when(
      DIQ010 == 1 ~ "diabetes",
      DIQ010 == 3 ~ "prediabetes",
      DIQ010 == 2 ~ "no_diabetes",
      TRUE ~ NA_character_
    )
  )
```

## Sample Size Considerations

NHANES has ~8,700 examined participants per 2-year cycle. Key implications:

- Subgroup analyses (e.g., NH Asian females age 60+ with diabetes) can quickly
  drop below meaningful sample sizes
- Survey variance estimation requires ≥2 PSUs per stratum. Dropping strata via
  aggressive subsetting can break `svydesign()`
- For rare exposures/outcomes, consider pooling 2-3 cycles (with weight adjustment)
- Treatment/control arms in TTE protocols may be imbalanced — check positivity
  before proceeding with propensity score methods
- Rule of thumb: minimum ~100 participants per treatment arm for weighted analyses
