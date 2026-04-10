# Secure PCORnet CDW — Database Conventions

These conventions are specific to this CDW instance. Agents MUST read and apply
every convention when writing SQL or R code targeting this database. Reviewers
MUST check every convention as a review item.

## Required Filters

### Legacy Encounter Filtering (CRITICAL — duplicate records)

The CDW contains data from two EHR eras (AllScripts and Epic). When the
institution transitioned from AllScripts to Epic, some AllScripts records were
re-imported into Epic and re-fed into the CDW, creating **duplicates**.
These duplicates are flagged as `RAW_ENC_TYPE = 'Legacy Encounter'`.

**Rule:** Every query that joins ENCOUNTER must include:
```sql
AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
```

**Exception:** You may keep legacy encounters when building a binary "any prior
diagnosis" indicator where double-counting is harmless (e.g.,
`EXISTS (SELECT 1 FROM DIAGNOSIS WHERE DX LIKE 'I48%')`). Even then, prefer
filtering them out for consistency. Always document your choice.

The `CDW_Source` column on many tables indicates which feed produced the record
(e.g., 'GECBI' for Epic). Use this for additional verification when needed,
but `RAW_ENC_TYPE` on ENCOUNTER is the primary filter.

### Date Bounds (CRITICAL — junk dates)

The CDW contains junk dates ranging from 1820 to 3019 due to EHR default
values, data entry errors, and placeholder dates.

**Rule:** Every query that uses a date column (ADMIT_DATE, PX_DATE,
RX_ORDER_DATE, RESULT_DATE, etc.) MUST include an explicit date range filter:
```sql
WHERE e.ADMIT_DATE BETWEEN '2005-01-01' AND GETDATE()
```

Key data eras:
- Year 1900 has ~40K patients — this is a default/unknown date, not real data
- Pre-2000 data is sparse and unreliable
- Realistic clinical data begins around **2000** and reaches full volume ~**2005**
- **AllScripts era:** through ~2019-2020 (all data before Epic go-live)
- **Epic go-live:** ~2019-2020 (legacy encounter volume drops sharply after 2021)
- **Post-ICD-10 only:** 2016+ (ICD-10 transition was Oct 2015, separate from Epic)
- **Post-Epic + post-ICD-10:** ~2020+
- Future dates (2027+) include some scheduled appointments but mostly errors

Choose the study start date based on data volume and document the choice.

## Coding System Requirements

### ICD-9/10 Transition

The ICD-10 transition date is October 1, 2015. If the study period extends
before this date, queries must include both `DX_TYPE = '09'` and
`DX_TYPE = '10'` with appropriate code mappings. If the study starts after
Oct 2015, `DX_TYPE = '10'` alone is sufficient.

Check the data profile Section 4 to see which years have ICD-9 vs ICD-10 data.

### Clinical Code Validation (MANDATORY)

Every medication, diagnosis, lab, and procedure code list MUST be validated
using the MCP tools before the protocol is finalized.

**RxNorm (medications):**
- For EVERY drug, call `get_rxcuis_for_drug()` to get the COMPLETE set of
  SCD + SBD RXCUIs. Never manually curate a partial list.
- Include both SCD (generic) and SBD (branded) forms. EHRs record branded
  entries (e.g., "Ecotrin" for aspirin, "Hemady" for dexamethasone 20mg).
- Before finalizing, call `validate_rxcui_list()` on every RXCUI list.
- Common pitfall: using ingredient-level CUIs (e.g., '11289' for warfarin).
  PCORnet PRESCRIBING stores SCD/SBD-level CUIs — ingredient CUIs match NOTHING.

**ICD-10-CM (diagnoses):**
- For EVERY diagnosis, call `get_icd10_hierarchy()` to see all subcodes.
- Call `search_icd10()` to catch codes you might not know about.

**LOINC (labs):**
- For EVERY lab test, call `search_loinc()` and `find_related_loincs()` to
  find all related codes for the same analyte.

**HCPCS (procedures):**
- For parenteral drugs (IV/SC), look up corresponding J-codes using
  `search_hcpcs()`. Multi-source detection (PRESCRIBING + PROCEDURES +
  MED_ADMIN) is required for any parenteral agent.

## SQL Patterns

### Table Qualification

All tables must be fully qualified as `CDW.dbo.TABLE_NAME`, not bare
`dbo.TABLE_NAME`.

### DEATH Table Deduplication

Always use `ROW_NUMBER() OVER (PARTITION BY PATID ORDER BY DEATH_DATE) AS rn`
and filter to `rn = 1` when joining DEATH. Some patients have duplicate death
records:
```sql
LEFT JOIN (
  SELECT d.PATID, d.DEATH_DATE,
         ROW_NUMBER() OVER (PARTITION BY d.PATID ORDER BY d.DEATH_DATE) AS rn
  FROM CDW.dbo.DEATH d
) death ON t.PATID = death.PATID AND death.rn = 1
```

### ROW_NUMBER on ALL LEFT JOINs

Every LEFT JOIN to vitals, labs, enrollment, or DEATH must use
`ROW_NUMBER() OVER (PARTITION BY PATID ...) ... WHERE rn = 1` to guarantee
exactly 1 row per patient. Do NOT use `MAX(date)` + self-join — that pattern
returns duplicates when multiple records share the same max date.

If the CONSORT shows MORE patients after any step than before, row duplication
from JOINs is the cause.

### ODBC Batch Bug

Do not combine `SELECT INTO #temp` and `SELECT * FROM #temp` in the same
`dbExecute()` / `dbGetQuery()` call. The ODBC driver fails silently. Use
separate calls:
```r
dbExecute(con, sql_that_creates_temp_table)
cohort <- dbGetQuery(con, "SELECT * FROM #analytic_cohort")
```

### count_temp() Helper

Must use `COUNT(DISTINCT PATID)`, not `COUNT(*)`. Using `COUNT(*)` hides
row duplication from JOINs.

## Column Handling

### Case Normalization

SQL Server returns column names in unpredictable case. After `dbGetQuery()`,
always call:
```r
names(df) <- tolower(names(df))
```
Then use lowercase column names everywhere in R code.

### Factor Naming

Create derived factor columns with distinct names (`sex_cat`, `race_cat`,
`hispanic_cat`), not by overwriting the raw column in `mutate()`.

## R Code Patterns

### E-value Sensitivity Analysis

When using `evalues.HR()`, you MUST specify the `rare` argument:
```r
evalues.HR(hr, lo = ci_lo, hi = ci_hi, rare = TRUE)
```
Set `rare = TRUE` when outcome incidence < ~15%. Omitting `rare` causes a
runtime error.

### Empty Cohort Guard

After pulling the analytic cohort, check for 0 rows before proceeding:
```r
if (nrow(cohort) == 0) {
  message("*** STOPPING: Analytic cohort has 0 patients. ***")
  knitr::knit_exit()
}
```

### Treatment Arms Guard

Before calling `weightit()`, verify the treatment variable has >= 2 values:
```r
n_arms <- length(unique(cohort$treatment))
if (n_arms < 2) {
  stop(sprintf("Cannot run IPW: treatment has only %d unique value(s).", n_arms))
}
```

### Dynamic PS Formula

Build the propensity score formula dynamically, dropping single-level factors
and zero-variance columns. Small or specific cohorts often have single-level
factors that crash `weightit()`.

### Quarto Layout

The `.qmd` file must use a two-part layout:
- **Part 1 (function definitions):** No visible output.
- **Part 2 (execution sections):** Each section calls its function and displays
  results inline.

No monolithic `main()`. No `eval: false` chunks. No `png()`/`dev.off()` — all
plots render inline via Quarto figure chunks.
