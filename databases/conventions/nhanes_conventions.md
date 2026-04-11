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

## Multi-Cycle Pooling (DEFAULT)

**CRITICAL: Pool 3 cycles (2013-2014 + 2015-2016 + 2017-2018) by default.**
A single NHANES cycle (~8,700 examined participants) is too small for most
target trial emulation analyses, especially those with mortality outcomes.
Pooling triples the sample size (~28,000) and, for mortality analyses, provides
longer follow-up from earlier cycles (up to 6 years for 2013-2014 vs 2 years
for 2017-2018).

**Only use a single cycle when:**
- The research question is specifically about a single time period
- A variable of interest is only available in one cycle
- Blood pressure is the primary exposure or outcome (protocol changed in 2017-2018)

### How to Pool

1. **Load all three cycles and bind:**

```r
# Load each cycle
demo_h <- nhanes("DEMO_H") |> mutate(cycle = "2013-2014")
demo_i <- nhanes("DEMO_I") |> mutate(cycle = "2015-2016")
demo_j <- nhanes("DEMO_J") |> mutate(cycle = "2017-2018")
combined <- bind_rows(demo_h, demo_i, demo_j)

# Repeat for each component table (GHB_H/I/J, BMX_H/I/J, etc.)
```

2. **Adjust weights:** Divide 2-year weights by the number of cycles pooled.

```r
# 3-cycle pooling (REQUIRED)
combined$WTMEC6YR <- combined$WTMEC2YR / 3
combined$WTSAF6YR <- combined$WTSAF2YR / 3  # for fasting subsample

# Use the adjusted weight in svydesign()
des <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTMEC6YR, nest = TRUE, data = combined
)
```

3. **Table name pattern:** Replace the suffix to load other cycles:
   - `_H` = 2013-2014, `_I` = 2015-2016, `_J` = 2017-2018
   - Example: `GHB_H`, `GHB_I`, `GHB_J` all have the same columns

4. **SEQN is unique within a cycle but NOT across cycles.** When pooling,
   create a composite key or add a cycle column to disambiguate.

### Known Cross-Cycle Differences

- **Blood pressure:** 2013-2016 uses BPX_H/BPX_I (auscultatory protocol with
  variables BPXSY1-4, BPXDI1-4). 2017-2018 uses BPXO_J (oscillometric with
  BPXOSY1-3, BPXODI1-3). Cannot directly pool BP readings across this boundary.
  For hypertension studies, either use 2013-2016 only (auscultatory) or
  2017-2018 only (oscillometric), or use self-reported hypertension (BPQ_H/I/J)
  which is consistent across cycles.
- **Race variable:** RIDRETH3 (with NH Asian category) available in all three
  cycles (2013-2018). Earlier cycles (pre-2011) only have RIDRETH1.
- **Some questionnaire items** are added or removed between cycles. Use
  `nhanesCodebook()` to verify variable availability per cycle.

### Do NOT Pool with _P

The pre-pandemic cycle (_P, 2017-March 2020) overlaps with _J (2017-2018).
Never pool _P with _J — this would double-count participants.

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

## Research Quality Safeguards

NHANES's public accessibility and API-based extraction tools have led to an
explosion of formulaic, low-quality research (Suchak et al. 2025, PLOS Biology,
doi:10.1371/journal.pbio.3003152). Agents MUST avoid these documented pitfalls:

### No Single-Factor Analyses of Multifactorial Conditions

Conditions like depression, cardiovascular disease, diabetes, and cognitive
decline are inherently multifactorial. Analyzing a single predictor (e.g.,
"dietary selenium and depression") in isolation — adjusting for basic
demographics but ignoring other known risk factors — produces misleading
results. It cannot distinguish predictors specific to a condition from
general markers of poor health.

**Rule:** Every NHANES protocol MUST include a multifactorial confounder
model that accounts for established risk factors for the outcome. A protocol
studying X → Y must adjust for known predictors of Y, not just age, sex,
and race. The confounder set must be justified with a DAG or domain-knowledge
rationale, not selected purely by statistical significance.

### Full Cycle Usage Required

When multiple NHANES cycles are available for the study variables, agents
MUST use all available cycles (default: 3-cycle pooling 2013-2018) unless
subsetting is explicitly justified. Valid justifications include:

- Measurement protocol changes across cycles (e.g., blood pressure
  auscultatory vs. oscillometric across 2016-2017 boundary)
- Variable only available in specific cycles
- Sensitivity analysis comparing cycle subsets

**Invalid justifications:** "We used 2017-2018 because it was most recent"
without addressing why earlier cycles were excluded. Selective cycle usage
without justification is a marker of data dredging (Suchak et al. 2025).

### No Data Dredging or Post-Hoc Hypothesis Formation

The automated nature of this system creates an elevated risk of generating
questions that fit the data rather than testing meaningful hypotheses. Agents
MUST:

- Derive research questions from the literature review (Phase 1), not from
  scanning NHANES variables for statistically significant associations
- State the hypothesis BEFORE examining the data
- Not reverse predictor and outcome to generate additional protocols without
  independent physiological justification
- Not generate multiple protocols that are minor variations of the same
  question (e.g., "vitamin D and depression" and "vitamin D and anxiety"
  and "vitamin D and cognitive decline") without acknowledging these as
  multiple comparisons requiring correction

### False Discovery Rate Correction Across Protocols

When the system generates multiple protocols within a single therapeutic
area, these collectively represent multiple hypothesis tests. The executive
summary (Phase 5) MUST:

- Report the total number of protocols tested
- Apply Benjamini-Yekutieli FDR correction across all primary effect
  estimates (accounts for potential dependence in NHANES survey data)
- Distinguish findings that survive FDR correction from those that do not
- Note that individual protocol reports present uncorrected p-values

### STROBE Compliance Required

All NHANES study reports MUST comply with the STROBE (Strengthening the
Reporting of Observational Studies in Epidemiology) checklist for
cross-sectional or cohort studies. Journal editors increasingly require
STROBE compliance for publications using public health datasets.

Key STROBE elements that agents must address:

| STROBE Item | Requirement |
|-------------|-------------|
| 1. Title/abstract | Indicate study design in title |
| 2. Background/rationale | Explain scientific rationale with references |
| 3. Objectives | State specific objectives and pre-specified hypotheses |
| 6. Participants | Describe eligibility criteria with NHANES cycle years |
| 7. Variables | Define all variables: exposures, outcomes, confounders, effect modifiers |
| 8. Data sources | Describe NHANES, survey design, weighting |
| 12. Statistical methods | Describe confounder adjustment, survey weighting, missing data handling, subgroup analyses, sensitivity analyses |
| 13. Participants | Report numbers at each stage (CONSORT flow) |
| 14. Descriptive data | Table 1 with characteristics by exposure group |
| 15. Outcome data | Report number of events, follow-up time |
| 16. Main results | Report unadjusted and adjusted estimates with CIs |
| 17. Other analyses | Report subgroup, sensitivity, and interaction analyses |
| 19. Limitations | Discuss potential biases, confounding, generalizability |
| 22. Funding | Acknowledge data source (NCHS/CDC) |

The report writer MUST include a STROBE compliance section or checklist in
every NHANES report.

## Target Trial Emulation Design Constraints

NHANES is a cross-sectional survey. Exposure and outcome are typically measured
at the same time point. This fundamentally limits which target trial designs
can be emulated and how well they satisfy the TARGET reporting guidelines.

### New-User Designs Are NOT Possible with NHANES

NHANES medication data (RXQ_RX) captures **current use** — what a participant
is taking in the past 30 days. It does NOT capture:
- When the medication was started (no initiation date)
- Prior medication history (no washout verification)
- Treatment changes over time (single cross-sectional snapshot)

This means **new-user (incident user) designs cannot be implemented** with
NHANES medication data. Any medication-based TTE using NHANES is inherently
a **prevalent-user design** and must be labeled as such.

### Why This Matters (TARGET Guideline Implications)

The TARGET reporting guidelines for target trial emulation require:

| TARGET Element | Requirement | NHANES Limitation |
|----------------|-------------|-------------------|
| Treatment strategies | Define initiation, switching, or continuation | Only "current use vs. non-use" is observable |
| Time zero | Align eligibility, treatment assignment, and follow-up start | Cannot align with treatment initiation — time zero is the exam visit, not when treatment started |
| Assignment procedure | Emulate randomization at time zero | Assignment is based on prevalent use, not a new treatment decision |
| Follow-up | Begins at time zero | Follow-up begins at exam, potentially years after treatment initiation |

**Consequence:** The "target trial" being emulated is NOT "initiate drug X
vs. do not initiate" but rather "be a current user of drug X at a random
health exam vs. not be a current user." These are fundamentally different
questions with different causal interpretations.

### Prevalent-User Bias

Medication-based NHANES TTEs are subject to three forms of prevalent-user bias:

1. **Depletion of susceptibles.** Patients who experienced early adverse
   events (or died) already stopped the drug and are not captured as
   "current users." This biases toward finding the drug is safe/beneficial.

2. **Survivor selection.** Current users have survived long enough to be
   surveyed. Non-users include people who never started AND people who
   started and stopped (possibly due to the outcome of interest).

3. **Confounding by treatment duration.** A patient on a statin for 10
   years differs from one who started last month, but NHANES treats both
   as "current statin users." Time-varying confounders accumulated during
   treatment are unmeasured.

### Well-Defined Interventions Requirement

Target trial emulation requires a **well-defined intervention** — a
specific, manipulable action that could in principle be assigned in a
randomized trial (Hernán & Robins, *Causal Inference*). This is not a
technicality; it determines whether the consistency assumption holds.

**Why biomarker levels are NOT well-defined interventions:**

"Assign HbA1c < 7%" is not a well-defined intervention because it does
not specify *how* the target is achieved. Metformin, insulin, SGLT2
inhibitors, and lifestyle modification all lower HbA1c but have different
causal effects on mortality and cardiovascular outcomes. The same is true
for "assign SBP < 130 mmHg" (which drug class? at what dose?) or "assign
LDL < 100 mg/dL" (statin vs. ezetimibe vs. PCSK9 inhibitor).

When the exposure is a biomarker level, the consistency assumption fails:
the potential outcome under "HbA1c < 7%" depends on which version of that
intervention is applied. Different patients achieved the same biomarker
level through different mechanisms, making the causal contrast ill-defined.

**Consequence for NHANES:** Biomarker-based studies using NHANES are
valuable **prospective observational studies**, but they should NOT be
framed as target trial emulations. Reserve TTE framing for exposures
where the intervention is specific and manipulable.

### Study Design Categories for NHANES

**Category A — Legitimate TTE (with caveats):**

These exposures are specific, manipulable interventions that could be
assigned in a trial:

- **Current medication use → mortality** (e.g., "take statin vs. not")
  - The intervention is specific: use of a named drug or drug class
  - Caveats: prevalent-user bias (see above), no new-user design possible
  - **Must be labeled as a prevalent-user design**
  - **Must discuss** all three forms of prevalent-user bias
- **Vaccination → mortality** (e.g., "receive flu vaccine vs. not")
  - The intervention is specific: get vaccinated or not
  - Caveat: healthy vaccinee bias (healthier people are more likely to
    get vaccinated, biasing toward apparent benefit)
- **Smoking cessation** (current vs. former smoker → mortality)
  - The intervention is specific: quit smoking
  - Caveat: residual confounding, "former" includes recent and distant quitters

**Category B — Prospective associational studies (NOT TTE):**

These exposures have strong prospective designs (baseline measurement →
mortality follow-up) but the "intervention" is not well-defined:

- **Biomarker levels → mortality** (HbA1c, BP, LDL, eGFR, hs-CRP)
- **Dietary exposure → mortality** (sodium intake, dietary pattern scores)
- **Physical activity level → mortality**
- **Anthropometric measures → mortality** (BMI, waist circumference)

These are valuable epidemiologic studies. They benefit from NHANES's
prospective mortality linkage and rich confounder data. But they should
be framed as **"prospective cohort studies with confounding adjustment"**
— not as target trial emulations.

**Do NOT use target trial specification tables** for Category B studies.
Instead, use standard epidemiologic methods framing (exposure, outcome,
confounders, follow-up period, statistical approach).

**Category C — Cross-sectional associations (neither TTE nor prospective):**

- Same-visit exposure → same-visit outcome (no temporal ordering)
- Self-reported condition → self-reported condition
- Any design claiming incident outcomes from cross-sectional data
- **Not recommended.** If unavoidable, frame as a cross-sectional
  associational analysis, not a causal study.

### Legitimate TTE Designs with NHANES

Only Category A exposures qualify for TTE framing:

1. **Prevalent medication use → mortality**
   - Example: Current statin use → all-cause mortality
   - Treatment: self-reported current use at NHANES exam (RXQ_RX)
   - Outcome: mortality follow-up via linked mortality file
   - Time zero: NHANES exam visit (not treatment initiation)
   - **Must be labeled as a prevalent-user design** in the protocol title
     and methods section
   - **Must discuss** depletion of susceptibles, survivor selection, and
     confounding by treatment duration in the limitations section
   - Consider sensitivity analysis restricting to participants with recent
     diagnosis (e.g., diabetes diagnosed within past 5 years per DIQ) as
     a proxy for more recent treatment initiation
   - The target trial being emulated: "Among people currently taking drug
     X, compare mortality outcomes to similar people not taking drug X" —
     NOT "initiate drug X vs. do not initiate"

2. **Vaccination → mortality**
   - Example: Flu vaccination in past 12 months → all-cause mortality
   - Treatment: self-reported vaccination status (IMQ questionnaire)
   - Outcome: mortality follow-up via linked mortality file
   - **Must discuss healthy vaccinee bias** — vaccinated individuals tend
     to be healthier and more health-seeking at baseline
   - Consider negative control outcomes to assess residual confounding

### Prospective Associational Studies with NHANES (NOT TTE)

When the best available NHANES exposure is a biomarker or lifestyle
measure, agents should frame the study as a prospective cohort study:

- Example: "Prospective association of HbA1c level with all-cause
  mortality in US adults: NHANES 2013-2018"
- Use standard epidemiologic framing: exposure, outcome, confounders
- Do NOT use a target trial specification table
- Do NOT claim to emulate a trial
- Use Cox proportional hazards or survey-weighted Cox models
- Propensity score methods are appropriate for confounding adjustment
  (the methods are the same; the *framing* differs)
- This is still a valuable study design — it leverages NHANES's
  nationally representative sample and prospective mortality follow-up

### Designs to AVOID

- Biomarker → same-visit biomarker (no temporal ordering possible)
- Self-reported condition → self-reported condition (both cross-sectional)
- Any design claiming incident (new-onset) outcomes from cross-sectional data
- Any design labeled as a "new-user" or "treatment initiation" study
  (NHANES cannot support this — see above)
- Any biomarker study framed as a TTE (biomarker levels are not
  well-defined interventions — see above)

### Agent Guidance: Choosing Between TTE and Associational Framing

When generating protocols for NHANES, agents must decide the framing
based on the exposure type:

- **If the exposure is a specific medication or vaccination:**
  → Use TTE framing (Category A) with prevalent-user caveats
- **If the exposure is a biomarker, dietary pattern, or lifestyle measure:**
  → Use prospective associational framing (Category B), NOT TTE
- **If the best question found in the literature requires a biomarker
  exposure and the user specified NHANES:**
  → Proceed with associational framing and note in the feasibility
  assessment that NHANES cannot support TTE for this question. Suggest
  MIMIC-IV or an EHR database as an alternative for TTE framing.

### Required Documentation

Every NHANES protocol MUST include:

1. **Explicit identification of study design category:** State whether
   the protocol is Category A (TTE with prevalent-user caveats),
   Category B (prospective associational), or Category C (cross-sectional)
2. **For Category A (TTE):** Target trial specification table with honest
   description of what trial is being emulated — including that time zero
   is the exam visit, not treatment initiation
3. **For Category A (TTE):** Label as "prevalent-user design" and discuss
   all three forms of prevalent-user bias
4. **For Category B (associational):** Do NOT include a target trial
   specification table. Use standard epidemiologic methods framing.
5. **Statement of cross-sectional design limitations** and how they
   constrain causal inference
6. **Sensitivity analyses:** At minimum, E-value for unmeasured confounding.
   For medication exposures, also consider restricting to recent diagnoses.
   For biomarker exposures, consider dose-response analysis.
7. **TARGET guideline compliance note (Category A only):** Explicitly
   state which TARGET elements are satisfied and which are limited

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

### Standard Analysis Setup (3-Cycle Pooled)

```r
library(nhanesA)
library(survey)
library(tidyverse)

# 1. Load and pool 3 cycles for each component
load_3cycles <- function(base_name) {
  suffixes <- c("_H", "_I", "_J")
  cycles   <- c("2013-2014", "2015-2016", "2017-2018")
  map2_dfr(suffixes, cycles, function(s, c) {
    nhanes(paste0(base_name, s)) |> mutate(cycle = c)
  })
}

demo <- load_3cycles("DEMO") |> filter(RIDSTATR == 2, RIDAGEYR >= 18)
ghb  <- load_3cycles("GHB")
bmx  <- load_3cycles("BMX")
bpq  <- load_3cycles("BPQ")
diq  <- load_3cycles("DIQ")

# 2. Merge on SEQN + cycle (SEQN is NOT unique across cycles)
analytic <- demo |>
  left_join(ghb, by = c("SEQN", "cycle")) |>
  left_join(bmx, by = c("SEQN", "cycle")) |>
  left_join(bpq, by = c("SEQN", "cycle")) |>
  left_join(diq, by = c("SEQN", "cycle"))

# 3. Adjust weights for 3-cycle pooling
analytic <- analytic |>
  mutate(WTMEC6YR = WTMEC2YR / 3)

# 4. Recode missing data (per codebook)
analytic <- analytic |>
  mutate(
    DMDEDUC2 = na_if(DMDEDUC2, 7) |> na_if(9),
    BPQ020   = na_if(BPQ020, 7) |> na_if(9),
    BPQ040A  = na_if(BPQ040A, 7) |> na_if(9),
    DIQ010   = na_if(DIQ010, 7) |> na_if(9)
  )

# 5. Create survey design with pooled weight
des <- svydesign(
  ids = ~SDMVPSU, strata = ~SDMVSTRA,
  weights = ~WTMEC6YR, nest = TRUE, data = analytic
)

# 6. Survey-weighted analysis
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

With 3-cycle pooling (default), NHANES provides ~28,000 examined participants.
Key implications:

- Most common exposures and outcomes have adequate sample sizes with 3 cycles
- Subgroup analyses (e.g., NH Asian females age 60+ with diabetes) can still
  drop below meaningful sample sizes — check cell counts before proceeding
- Survey variance estimation requires ≥2 PSUs per stratum. Dropping strata via
  aggressive subsetting can break `svydesign()`
- Treatment/control arms in TTE protocols may be imbalanced — check positivity
  before proceeding with propensity score methods
- Rule of thumb: minimum ~100 participants per treatment arm for weighted analyses
- For mortality outcomes, 3-cycle pooling is especially important: earlier cycles
  contribute longer follow-up (up to 6 years) and more events
