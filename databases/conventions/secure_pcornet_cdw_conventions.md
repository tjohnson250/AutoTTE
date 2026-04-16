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
- **AllScripts era:** through May 20, 2021 (all data before Epic go-live)
- **Epic go-live:** May 21, 2021 (legacy encounter volume drops sharply after this date)
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

### DX code storage format — DOTTED

This CDW stores the `DX` column **with periods** (`'N18.30'`, `'G30.0'`,
`'S72.0'`). Verified 2026-04-15: 99.76% of ICD-10 rows contain a period
(106,245,470 dotted vs 257,510 dotless; the 0.24% dotless are three-
character roots like `E11` that never carry a period in either convention).

**Rule:** When writing `IN (...)` lists or exact-match comparisons against
`DX`, always emit dotted codes (e.g. `IN ('N18.30', 'N18.31', ...)`). When
writing `LIKE` prefixes, include the period where it naturally appears
(e.g. `LIKE 'S72.0%'` for hip fracture). Do not strip periods.

The `expand_icd_codes()` helper some protocols use to emit both dotted
and dotless forms is a harmless no-op here but can be dropped in
site-specific protocols for readability.

### ICD-10-CM code-set updates (CKD example)

ICD-10-CM updates annually. Notable: in the October 2022 release, CKD
stage 3 was split from the single code `N18.3` into three codes: `N18.30`
(stage 3 unspecified), `N18.31` (stage 3a), and `N18.32` (stage 3b). This
CDW accumulates data across the update, so patients coded before Oct 2022
carry `N18.3` and patients coded after carry `N18.30`/`.31`/`.32`.

**Rule:** When defining a stage-3-to-5 CKD population, the IN list MUST
include BOTH the legacy and the new codes:
```sql
DX IN ('N18.3', 'N18.30', 'N18.31', 'N18.32', 'N18.4', 'N18.5')
```

The same principle applies to any other condition whose ICD-10-CM coding
changed during the study period. Before locking in an exact-code IN list,
check the [ICD-10-CM change logs](https://www.cdc.gov/nchs/icd/icd-10-cm.htm)
for the code family.

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
