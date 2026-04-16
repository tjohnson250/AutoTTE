# Review: Protocol 01 — SGLT2i Class vs DPP-4i for 3P-MACE in Type 2 Diabetes

**Reviewer:** Auto-Protocol Designer Reviewer Agent
**Review date:** 2026-04-15
**Files reviewed:**
- `protocol_01.md` (protocol specification)
- `protocol_01_analysis.R` (R analysis script, 1,372 lines)
- `03_feasibility.md` (cross-reference)
- `secure_pcornet_cdw_conventions.md` (CDW conventions)
- `secure_pcornet_cdw_schema.txt` (database schema)

---

## Summary Verdict: REVISE

The protocol is well-designed, methodologically sound, and the R script is impressively thorough — all 7 target trial elements are present and well-specified, the confounder set is comprehensive (far beyond demographics), the estimand is justified, and all 13 CDW conventions are applied correctly. However, **two SQL bugs** in the outcome ascertainment queries would cause some post-index MI and stroke events to be missed, biasing results toward the null. These are straightforward to fix without any redesign.

---

## 1. Protocol Checklist Assessment

### Target Trial Elements

| # | Element | Status | Assessment |
|---|---------|--------|------------|
| 1 | Eligibility | PASS | Adults ≥18 with T2D (E11.x), new-user design with 180-day washout and continuous enrollment. Exclusions (T1D, GDM, ESRD, active cancer, same-day dual-class ties) are operationalizable and clinically appropriate. No look-ahead bias. |
| 2 | Treatment Strategies | PASS | Three arms (SGLT2i class, DPP-4i, SU) precisely defined via RXNORM_CUI lists. Class-level expansion from canagliflozin-only is well-justified by feasibility (N=142 canagliflozin). New-user design allows concomitant antidiabetics, consistent with CANVAS. |
| 3 | Treatment Assignment | PASS | Active comparator new-user design with PS overlap weighting. Separate PS models for each pairwise comparison. Assignment determined by drug class initiated at time zero. |
| 4 | Time Zero | PASS | Time zero = date of first qualifying prescription (RX_ORDER_DATE). Eligibility, assignment, and time zero coincide — **no immortal time bias**. Follow-up begins the day after time zero, consistent with CANVAS. |
| 5 | Outcome | PASS (with code bugs — see Section 2) | 3P-MACE composite (nonfatal MI, nonfatal ischemic stroke, CV death) with appropriate ICD-10 codes, encounter restrictions (IP/EI/ED), and legacy encounter filtering. Type 2 MI (I21.A1) excluded from primary, included in sensitivity — correct per CANVAS methodology. Secondary and safety outcomes well-specified. |
| 6 | Estimand | PASS | ATO (Average Treatment Effect in the Overlap population) via overlap weights. Well-justified for this study: overlap weights naturally downweight patients at PS extremes, providing robustness against the expected arm size imbalance (~9,833 SGLT2i vs estimated 8,000–20,000 DPP-4i). |
| 7 | Causal Contrast | PASS | Effect of initiating SGLT2i vs DPP-4i on hazard of 3P-MACE. ITT primary (treatment initiation policy), as-treated sensitivity. Clearly stated. |

**Immortal time bias:** None detected. Time zero = prescription date; eligibility assessed at or before that date; follow-up starts the day after. No gap between eligibility and treatment assignment.

### Confounder Set Assessment

The confounder set is comprehensive and well-justified:
- **Demographics:** age, sex, race, ethnicity (4 variables)
- **Vitals:** BMI, systolic BP, diastolic BP (3 variables)
- **Labs:** HbA1c, creatinine, eGFR, total cholesterol, LDL, HDL, triglycerides, hemoglobin, potassium, ALT (10 variables)
- **Comorbidities:** 13 diagnoses (HTN, HF, AF, CKD, prior MI, prior stroke, COPD, obesity, dyslipidemia, PAD, VTE, tobacco use, ASCVD composite)
- **Concomitant medications:** 6 drug classes (metformin, insulin, statin, ACEi/ARB, beta-blocker, antiplatelet)

Each confounder has a DAG justification. Variables excluded (smoking 99.8% missing, LVEF not structured, insurance 0% populated, NT-proBNP too sparse) are documented with rationale. Tobacco use disorder ICD-10 codes (F17.x, Z72.0, Z87.891) used as a proxy for smoking — a pragmatic and transparent choice.

### Variable Mapping and Schema Verification

All protocol concepts map to actual CDW tables and columns. Verified against `secure_pcornet_cdw_schema.txt`:

| Table.Column | Exists in Schema | Used Correctly |
|---|---|---|
| DEMOGRAPHIC.PATID, BIRTH_DATE, SEX, RACE, HISPANIC | Yes | Yes |
| DIAGNOSIS.DX, DX_TYPE, ADMIT_DATE, ENCOUNTERID | Yes | Yes |
| PRESCRIBING.RXNORM_CUI, RX_ORDER_DATE, RAW_RX_MED_NAME, RX_END_DATE, RX_DAYS_SUPPLY | Yes | Yes |
| ENROLLMENT.ENR_START_DATE, ENR_END_DATE | Yes | Yes |
| ENCOUNTER.ENCOUNTERID, ENC_TYPE, RAW_ENC_TYPE, ADMIT_DATE | Yes | Yes |
| VITAL.ORIGINAL_BMI, SYSTOLIC, DIASTOLIC, MEASURE_DATE | Yes | Yes |
| LAB_RESULT_CM.LAB_LOINC, RESULT_NUM, RESULT_DATE | Yes | Yes |
| DEATH.PATID, DEATH_DATE | Yes | Yes |
| DEATH_CAUSE.DEATH_CAUSE, DEATH_CAUSE_CODE, PATID | Yes | Yes |
| PROCEDURES.PX, PX_TYPE, PX_DATE | Yes | Yes |

All tables correctly qualified as `CDW.dbo.TABLE_NAME`. No references to nonexistent tables or columns.

### Internal Consistency

Exposures, outcomes, and confounders are consistent across protocol sections, variable mapping table, and R script. The feasibility modification (SGLT2i class as primary, canagliflozin as sensitivity) is consistently reflected throughout.

---

## 2. R Code Review Findings

### CDW Convention Compliance: 13/13

| Convention | Status | Location |
|---|---|---|
| Legacy encounter filtering | PASS | Lines 473, 485 (MI/stroke outcome queries). Comorbidity queries (lines 568–702) use EXISTS without ENCOUNTER join — acceptable per convention exception for binary indicators. |
| Date quality guards (≥2005-01-01) | PASS | Applied to all date-filtered queries: diagnosis (line 391), outcomes (lines 474, 486, 494), vitals (line 526), labs (line 545), prescribing washout (line 253), patient flags (throughout). |
| DEATH table deduplication | PASS | Lines 491–495: `ROW_NUMBER() OVER (PARTITION BY d.PATID ORDER BY d.DEATH_DATE) AS rn` with `rn = 1`. |
| ROW_NUMBER on LEFT JOINs | PASS | Vitals (line 522), labs (line 537), enrollment (line 510), death (line 491), tagged RxCUI (line 259). All LEFT JOINs use ROW_NUMBER. |
| Column name normalization | PASS | Line 803: `names(cohort) <- tolower(names(cohort))` immediately after `dbGetQuery()`. |
| COUNT(DISTINCT PATID) | PASS | Line 151: `count_temp()` uses `COUNT(DISTINCT PATID)`. |
| ODBC batch bug mitigation | PASS | Separate `dbExecute()` calls for DDL (lines 757–798) and `dbGetQuery()` for final SELECT (line 802). |
| ICD-10 only | PASS | Study period starts 2016-01-01 (line 35); `DX_TYPE = '10'` used throughout. |
| Table qualification | PASS | All tables use `CDW.dbo.TABLE_NAME` throughout. |
| Dynamic PS formula | PASS | `build_ps_formula()` (lines 156–170) drops single-level factors and zero-variance columns. |
| E-value `rare` argument | PASS | Line 1259: `evalues.HR(hr, lo = lo, hi = hi, rare = TRUE)`. |
| Empty cohort guard | PASS | Lines 1138–1145. |
| Treatment arms guard | PASS | Lines 916–920 (in `run_iptw_analysis()`), lines 1155–1158 (primary analysis). |

### Bug 1 (REVISE): MI and stroke outcome subqueries miss recurrent events after index date

**Severity:** Moderate — biases primary outcome toward the null
**Location:** Lines 468–476 (MI), Lines 478–488 (stroke)

**Problem:** The MI and stroke subqueries use `MIN(enc.ADMIT_DATE)` across ALL time to find each patient's earliest MI/stroke, then filter to `> index_date` in the LEFT JOIN condition. If a patient had a prior MI/stroke before their index date AND a new MI/stroke after their index date, the `MIN()` returns the pre-index date, the JOIN condition fails, and the post-index event is missed entirely.

**Example:** Patient has MI on 2014-06-01 (I21.4) and new MI on 2021-03-15. Index date is 2020-01-01.
- Subquery: `MIN(ADMIT_DATE)` = 2014-06-01
- JOIN: `2014-06-01 > 2020-01-01` → FALSE
- Result: Patient is coded as having no MI event, even though they had one in 2021

**Impact:** Patients with both pre-index and post-index MI/stroke events would be incorrectly censored as event-free. This underestimates the event rate and biases hazard ratios toward the null. The magnitude depends on the prevalence of recurrent MI/stroke (likely 5–15% of MI events in a T2D population).

**Fix:** Restructure the subqueries to filter to post-index dates before aggregating. Replace the MI subquery (lines 468–476) with:

```sql
LEFT JOIN (
  SELECT sub.PATID, MIN(sub.mi_date) AS mi_date
  FROM (
    SELECT dx.PATID, enc.ADMIT_DATE AS mi_date
    FROM CDW.dbo.DIAGNOSIS dx
    INNER JOIN CDW.dbo.ENCOUNTER enc ON dx.ENCOUNTERID = enc.ENCOUNTERID
    INNER JOIN #eligible e2 ON dx.PATID = e2.PATID
    WHERE dx.DX LIKE 'I21%'
      AND dx.DX NOT IN ('I21.A1','I21.A9','I21.B')
      AND dx.DX_TYPE = '10'
      AND enc.ENC_TYPE IN ('IP','EI','ED')
      AND enc.RAW_ENC_TYPE <> 'Legacy Encounter'
      AND enc.ADMIT_DATE > e2.index_date
      AND enc.ADMIT_DATE >= '2005-01-01'
  ) sub
  GROUP BY sub.PATID
) mi ON e.PATID = mi.PATID
```

Apply the same pattern to the stroke subquery (lines 478–488).

### Bug 2 (REVISE): I22.x (subsequent MI) codes missing from MI outcome query

**Severity:** Minor — small number of events missed
**Location:** Line 469

**Problem:** The protocol (Section 2.4) specifies MI as `I21.x (excl I21.A1, I21.A9, I21.B); I22.x (subsequent MI)`. The SQL only filters on `dx.DX LIKE 'I21%'` — I22.x codes are not included.

**Impact:** I22.x codes represent subsequent MI within 28 days of a prior MI. These are uncommon but would be missed. In rare cases, a patient's only MI code in this CDW could be I22.x (e.g., initial MI treated at another institution, re-infarction treated here).

**Fix:** Change line 469 from:
```sql
WHERE dx.DX LIKE 'I21%'
```
to:
```sql
WHERE (dx.DX LIKE 'I21%' OR dx.DX LIKE 'I22%')
```

And update the exclusion list on line 470 accordingly (I22.x codes don't have A1/A9/B subtypes, so the `NOT IN` clause can remain as-is).

### Other Code Checks

| Check | Status | Notes |
|---|---|---|
| `bal.tab()` uses `un = TRUE` | PASS | Line 935: `cobalt::bal.tab(w, stats = c("m", "v"), thresholds = c(m = 0.1), un = TRUE)` |
| `love.plot()` uses `un = TRUE` | PASS | Line 1044: `cobalt::love.plot(weights, threshold = 0.1, abs = TRUE, un = TRUE, ...)` |
| Publication outputs wrapped in `tryCatch()` | PASS | Lines 1322–1370: entire publication section in `tryCatch()` |
| Results saved to JSON | PASS | Lines 1316–1318 (always saved, even on error), line 1363 (updated after publication outputs) |
| No TODO/FIXME/placeholder code | PASS | Grep search returned no matches |
| Table 1 `pivot_longer()` type consistency | N/A | Script uses `gtsummary::tbl_summary()` which handles type consistency internally — no manual `summarise()` + `pivot_longer()` pattern |
| Weighted Cox uses robust SEs | PASS | Line 948: `robust = TRUE` |
| PS distribution plotted | PASS | `save_ps_distribution()` function (lines 1053–1067) |
| Schoenfeld residuals | NOT IMPLEMENTED | Protocol Section 5.5 mentions checking Schoenfeld residuals for PH assumption — the R script does not implement this check. Minor omission; suggest adding for completeness. |

### RxCUI Code Verification (R script vs. feasibility Appendix A)

| Drug | R Script Codes | Feasibility Codes | Match |
|---|---|---|---|
| Canagliflozin single | 1373463, 1373471, 1373469, 1373473 | A.1: Same | MATCH |
| Canagliflozin combo (Invokamet) | 1545150, 1545157, 1545161, 1545164 (SCD); 1545156, 1545159, 1545163, 1545166 (SBD) | A.2: Same | MATCH |
| Canagliflozin combo (Invokamet XR) | 1810997, 1810999, 1811003, 1811007, 1811011 | A.2: Same | MATCH |
| Empagliflozin single | 1545653, 1545658, 1545655, 1545660 | A.3: Same | MATCH |
| Empagliflozin combo (Synjardy) | 1602108–1602124 | Not in feasibility Appendix | UNVALIDATED* |
| Dapagliflozin single | 1488564, 1488569, 1488566, 1488571 | A.4: Same | MATCH |
| Dapagliflozin combo (Xigduo XR) | 1598392–1598398 | Not in feasibility Appendix | UNVALIDATED* |
| Sitagliptin | All 12 codes | A.5: Same | MATCH |
| Linagliptin | 1100702, 1100706 | A.5: Same | MATCH |
| Saxagliptin | 858036, 858042, 858040, 858044 | A.5: Same | MATCH |
| Alogliptin | All 6 codes | A.5: Same | MATCH |
| Glipizide | All 11 codes | A.6: Same | MATCH |
| Glimepiride | All 9 codes | A.6: Same | MATCH |
| Glyburide | All 12 codes | A.6: Same | MATCH |

*Synjardy and Xigduo XR combo RxCUIs were included by the worker but not validated via MCP tools during feasibility. The protocol acknowledges this limitation (Section 5.2). The codes appear plausible based on RxNorm naming patterns. Recommend validation when online access is available.

### ICD-10 Code Verification

All ICD-10 codes in the R script match the protocol and feasibility document. Verified:
- MI: I21.x (excl I21.A1, I21.A9, I21.B) — matches (though I22.x missing, flagged above)
- Stroke: I63.x — matches
- CV death causes: I20–I25, I46, I50, I60–I69, I71 — matches
- T2D: E11.x, DX_TYPE = '10' — matches
- T1D exclusion: E10.x — matches
- GDM exclusion: O24.x — matches
- ESRD: N18.6, Z99.2 — matches
- Cancer: C00–C97 — matches (code uses `DX >= 'C00' AND DX < 'C98'`)
- All 13 comorbidity code sets — match feasibility Appendix B.7

### Minor Observations (non-blocking)

1. **Dialysis CPT codes broader than protocol:** The R script (line 424) includes CPT 90945 and 90947 (peritoneal dialysis) in addition to the 90935–90940 range specified in the protocol's exclusion table. The code is MORE comprehensive — this is an improvement, not a bug. Suggest updating the protocol table to match.

2. **Schoenfeld residuals not implemented:** The protocol's limitations section (5.5) mentions checking the proportional hazards assumption via Schoenfeld residuals, but the R script does not implement this check. Suggest adding `cox.zph()` output to the results JSON for completeness.

3. **Glyxambi/Qtern gap:** The protocol correctly notes (Section 5.2) that Glyxambi (empagliflozin/linagliptin) and Qtern (dapagliflozin/saxagliptin) combination products are not captured, as they contain both SGLT2i and DPP-4i components. This is a known limitation, not a bug.

4. **CDM version discrepancy:** The database YAML configuration lists CDM version 7, while the protocol and feasibility reference PCORnet CDW v6.1. Minor documentation inconsistency; does not affect code correctness.

---

## 3. Overall Verdict: REVISE

### Issues Requiring Revision (2 items)

| # | Issue | Severity | Fix Complexity |
|---|---|---|---|
| 1 | MI/stroke outcome subqueries use `MIN(date)` across all time, missing recurrent events after index date | Moderate | Low — restructure subqueries to join #eligible and filter to post-index dates before aggregating |
| 2 | I22.x (subsequent MI) codes missing from MI outcome SQL, despite being specified in the protocol | Minor | Low — add `OR dx.DX LIKE 'I22%'` to MI WHERE clause |

### Non-blocking suggestions (address if convenient)

- Add `cox.zph()` for Schoenfeld residuals (protocol promises PH assumption check but code doesn't implement)
- Update protocol exclusion table to include CPT 90945, 90947 (already in code)
- Validate Synjardy and Xigduo XR combo RxCUIs when online access is available

---

## 4. What Was Done Well

This is high-quality work. Specific strengths:

1. **Thorough CDW convention compliance.** Every convention from `secure_pcornet_cdw_conventions.md` is applied — legacy encounter filtering, date guards, DEATH deduplication, ROW_NUMBER on LEFT JOINs, column normalization, COUNT(DISTINCT), ODBC batch separation, dynamic PS formula. This is rare; most first-pass code misses at least one.

2. **Comprehensive confounder set with DAG justification.** 30+ confounders spanning demographics, vitals, labs, comorbidities, and concomitant medications — with explicit DAG role and justification for each. Variables excluded are documented with reasons (smoking 99.8% missing, LVEF not structured, etc.). This goes well beyond the typical "age, sex, race" adjustment.

3. **Transparent feasibility adaptation.** The expansion from canagliflozin-only to SGLT2i class is clearly documented, consistently reflected across all sections, and canagliflozin is preserved as a pre-specified sensitivity analysis. The protocol doesn't pretend the original question was answered — it explains the modification and why.

4. **Robust error handling.** Empty cohort guards, treatment arm guards, dynamic PS formula that drops zero-variance columns, tryCatch wrapping for publication outputs, results saved to JSON even on pipeline error. The code is production-grade.

5. **Publication-ready output pipeline.** CONSORT diagrams, Table 1, love plots, PS distributions, KM curves, forest plots — all with both PDF and PNG outputs. This is unusual for a first-pass protocol.

6. **Well-specified sensitivity analyses.** Canagliflozin subgroup, as-treated, all-cause mortality in MACE, type 2 MI inclusion, saxagliptin exclusion, E-value, PS matching — each addresses a specific threat to validity.

7. **Honest limitations section.** Unmeasured confounders, channeling bias, time-varying confounding, class-level heterogeneity, treatment duration uncertainty, combination product gaps, single-institution generalizability — all acknowledged with their implications.

---

## 5. Reviewer Confidence

**High confidence** in this review. I verified:
- All 7 target trial elements against the REVIEW.md checklist
- All 13 CDW conventions against `secure_pcornet_cdw_conventions.md`
- All SQL table/column references against `secure_pcornet_cdw_schema.txt`
- All RxCUI code lists against `03_feasibility.md` Appendix A
- All ICD-10 code sets against `03_feasibility.md` Appendix B
- SQL logic for each major query block (new users, arm assignment, eligibility, outcomes, confounders, analytic cohort)
- R code logic for data preparation, IPTW analysis, subgroup analyses, sensitivity analyses, and publication outputs

The two bugs I identified are genuine logic errors, not subjective judgment calls. The fixes are straightforward.
