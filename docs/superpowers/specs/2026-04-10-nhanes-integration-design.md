# NHANES Integration Design

**Date:** 2026-04-10
**Approach:** Enrich PUBLIC_DATASETS entry + YAML database config (Approach A)

## Overview

Integrate NHANES as a first-class data source in AutoTTE so that agents can
design and execute target trial emulation protocols against NHANES data. This
requires creating the four standard database support files (YAML config, schema,
profile, conventions) and wiring the existing PUBLIC_DATASETS entry to point at
the schema/profile/conventions files.

## Scope

- Default cycle: **2017-2018** (suffix `_J`)
- Broad coverage: ~25 NHANES components spanning demographics, examination,
  laboratory, questionnaire, dietary, and mortality domains
- Online mode via `nhanesA` R package with DuckDB in-memory backend
- Offline mode via static schema dump and data profile

## Files to Create

### 1. `databases/nhanes.yaml`

YAML config consumed by `run.sh` and `r_executor_server.py`.

```yaml
id: "nhanes"
name: "NHANES"
cdm: "nhanes"
engine: "duckdb"
online: true

connection:
  r_code: |
    library(nhanesA)
    library(duckdb)
    con <- dbConnect(duckdb::duckdb(), ":memory:")
    load_nhanes <- function(tbl) {
      if (!dbExistsTable(con, tbl)) {
        df <- nhanes(tbl)
        dbWriteTable(con, tbl, df)
        message(sprintf("Loaded %s: %d rows, %d cols", tbl, nrow(df), ncol(df)))
      }
      invisible(NULL)
    }

schema_prefix: ""
schema_dump: "databases/schemas/nhanes_schema.txt"
data_profile: "databases/profiles/nhanes_profile.md"
conventions: "databases/conventions/nhanes_conventions.md"
```

Key design decisions:
- **DuckDB in-memory**: Tables are lazy-loaded from CDC via `nhanesA` and
  registered in DuckDB. Agents call `load_nhanes("TABLE_NAME")` before querying.
  This avoids a multi-minute startup while giving agents SQL access via
  `query_db()`.
- **No schema_prefix**: DuckDB in-memory tables are bare names.
- **cdm: "nhanes"**: NHANES does not map to PCORnet or OMOP. Agents use
  NHANES variable names directly.

### 2. `databases/schemas/nhanes_schema.txt`

Plain-text listing of ~25 key NHANES components organized by domain. Each entry
lists the table name, cycle suffix, description, and key columns with types.

Domains covered:
- **Demographics**: DEMO — age, sex, race/ethnicity, income, education, survey weights
- **Examination**: BPX (blood pressure), BMX (body measures), AUX (audiometry)
- **Laboratory**: GHB (HbA1c), TCHOL (total cholesterol), HDL, TRIGLY, GLU
  (fasting glucose), BIOPRO (biochemistry — creatinine, albumin, etc.), CBC
  (complete blood count), ALB_CR (urine albumin/creatinine), HSCRP (CRP),
  COT (cotinine), INS (insulin), FETIB (iron)
- **Questionnaire**: SMQ (smoking), ALQ (alcohol), BPQ (BP/cholesterol Qs),
  DIQ (diabetes), MCQ (medical conditions), PAQ (physical activity),
  RXQ_RX (prescription meds), DPQ (PHQ-9 depression), KIQ_U (kidney),
  CDQ (cardiovascular), SLQ (sleep), HIQ (insurance), HUQ (utilization)
- **Dietary**: DR1TOT/DR2TOT (total nutrient intake day 1/2), DBQ (diet behavior)
- **Mortality**: Linked mortality follow-up file (downloaded separately from
  NCHS as CSV; not available via nhanesA)

### 3. `databases/profiles/nhanes_profile.md`

Data profile covering:
- **Sample sizes**: ~9,254 participants in 2017-2018; ~15,560 in pre-pandemic
  2017-March 2020
- **Fasting subsample**: ~50% of participants (morning session). Affects
  glucose, insulin, triglycerides. Uses separate weight variable WTSAF2YR.
- **Age range**: 0-80 (top-coded at 80)
- **Demographics**: Race/ethnicity (Mexican American, Other Hispanic, Non-Hispanic
  White, Non-Hispanic Black, Non-Hispanic Asian, Other/Multi), sex, income-to-
  poverty ratio, education levels
- **Lab coverage**: Which labs are full-sample vs fasting-subsample. Approximate
  N for each.
- **Mortality linkage**: Available through 2019 for the 2017-2018 cycle.
  Approximately 2-3% mortality rate over follow-up period.
- **Prescription medication**: RXQ_RX has 30-day medication use with RxCUI
  codes. Covers ~7,000-8,000 participants with ≥1 prescription per cycle.

### 4. `databases/conventions/nhanes_conventions.md`

The critical file. Sections:

#### Survey Design (MANDATORY)
- ALL analyses producing population-level estimates MUST use `survey` package
- Weight variables: WTMEC2YR (MEC exam + lab), WTINT2YR (interview-only
  components), WTSAF2YR (fasting subsample)
- Design variables: SDMVSTRA (strata), SDMVPSU (PSU)
- Pattern: `svydesign(ids = ~SDMVPSU, strata = ~SDMVSTRA, weights = ~WTMEC2YR,
  nest = TRUE, data = df)`
- Agents MUST use `svyglm()`, `svycoxph()`, `svymean()` etc. — never unweighted
  `glm()` or `coxph()` for population inference
- Exception: internal validity analyses (e.g., within-sample prediction) may
  omit weights with explicit justification

#### Cycle Combining
- When pooling N cycles, divide weights by N (e.g., 2-cycle: WTMEC4YR = WTMEC2YR / 2)
- Variable name suffixes change per cycle: _H (2013-2014), _I (2015-2016),
  _J (2017-2018), _P (2017-March 2020 pre-pandemic)
- Must rename/harmonize columns after loading (strip suffix, standardize names)
- Some variables are added, removed, or recoded between cycles — check codebooks

#### Missing Data Codes
- 7 / 77 / 777 / 7777 = Refused
- 9 / 99 / 999 / 9999 = Don't know
- These are NOT NA in the raw data. Must recode per-variable using codebook
  values (e.g., `na_if(., 77) |> na_if(99)` — adapt digit count to each field)
- Period (.) in SAS transport = NA in R (handled by nhanesA)

#### Fasting Subsample
- Glucose (GLU), triglycerides (TRIGLY), insulin (INS) require fasting
- Use WTSAF2YR, not WTMEC2YR, for fasting-only labs
- Only morning-session participants (~50%) have fasting labs
- Using full-sample weights for fasting labs = biased estimates

#### Age Top-Coding
- Ages ≥80 are coded as 80. Cannot distinguish 80 from 95.
- For elderly-focused studies, document this ceiling effect
- RIDAGEYR is age in years at screening. RIDAGEMN (months) available for <24mo

#### Target Trial Emulation Caveats
- NHANES is cross-sectional: exposure and outcome measured simultaneously
  for most variables
- Legitimate TTE designs:
  1. **Mortality outcomes**: Baseline exposure → mortality follow-up (true
     prospective). This is the strongest design.
  2. **Self-reported history**: "Have you ever been diagnosed with X?" as
     time-zero, current biomarker as outcome. Requires careful temporal
     reasoning.
  3. **Medication use → biomarker**: Current 30-day medication → current lab
     value. Cross-sectional, but interpretable under strong assumptions
     (treatment already initiated, measuring ongoing effect).
- Agents MUST justify temporal ordering in every protocol
- Agents MUST document the cross-sectional limitation and its implications

#### R Code Patterns
- Load data: `nhanes('DEMO_J')` returns a data frame
- Translate codes: `nhanesTranslate('DEMO_J', colnames = c('RIAGENDR', 'RIDRETH3'))`
- Join key: `SEQN` (respondent sequence number) — unique within a cycle
- Lazy DuckDB loading: `load_nhanes("DEMO_J")` then `query_db("SELECT * FROM DEMO_J")`
- Survey-weighted regression:
  ```r
  library(survey)
  des <- svydesign(ids = ~SDMVPSU, strata = ~SDMVSTRA,
                   weights = ~WTMEC2YR, nest = TRUE, data = df)
  fit <- svyglm(outcome ~ treatment + age + sex, design = des, family = quasibinomial())
  ```

#### Variable Naming
- No CDM mapping. Use NHANES variable names directly.
- The schema file is the authoritative reference for available variables.
- `nhanesCodebook('DEMO_J')` for full codebook of any table.
- Common gotcha: some variable names differ across cycles (e.g., race variable
  changed from RIDRETH1 to RIDRETH3 starting in 2011-2012).

## Files to Modify

### `tools/datasource_server.py`

Add three keys to the existing NHANES entry in `PUBLIC_DATASETS` (lines 63-78):

```python
"schema_dump": "databases/schemas/nhanes_schema.txt",
"data_profile": "databases/profiles/nhanes_profile.md",
"conventions": "databases/conventions/nhanes_conventions.md",
```

This enables `get_schema('nhanes')`, `get_profile('nhanes')`, and
`get_conventions('nhanes')` to work even without `--db-config`.

No other code changes needed — the existing `get_schema()`, `get_profile()`,
and `get_conventions()` functions already resolve relative paths against
PROJECT_ROOT and read file content.

## Launch Commands

```bash
# Online mode — agents can query NHANES data live via nhanesA
./run.sh "type 2 diabetes" --db-config databases/nhanes.yaml

# Offline mode — agents work from schema dump and data profile only
./run.sh "type 2 diabetes" --db-config databases/nhanes.yaml --db-mode offline

# Public datasets only (no --db-config) — agents see NHANES metadata
# and can read schema/profile/conventions, but cannot query live data
./run.sh "type 2 diabetes"
```

## Prerequisites

- R with packages: `nhanesA`, `duckdb`, `survey`, `tidyverse`
- Internet access (for nhanesA to download from CDC) when running online mode
- No pre-download or setup script required — nhanesA caches data automatically
