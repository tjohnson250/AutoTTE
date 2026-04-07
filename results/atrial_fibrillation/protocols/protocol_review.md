# Protocol Review -- Atrial Fibrillation TTE Protocols

**Reviewer:** Independent Review Agent
**Date:** 2026-04-07
**Scope:** Three target trial emulation protocols for atrial fibrillation, targeting the PCORnet CDW

---

## Protocol 1: Apixaban vs Rivaroxaban in AF+CKD

### Summary Verdict: ACCEPT

Protocol 1 is a well-designed active-comparator, new-user target trial emulation comparing apixaban vs rivaroxaban in AF patients with CKD 3b-5. The methodology is sound, the code implements what the protocol describes, and the time-zero definition correctly avoids immortal time bias. Minor issues noted below do not threaten validity.

### TTE Checklist

| Element | Status | Notes |
|---------|--------|-------|
| Eligibility | PASS | AF (I48.x excluding flutter) + CKD 3b-5 (dual ascertainment: Dx or eGFR < 45) + new DOAC user (365-day washout). All criteria are operationalizable. No look-ahead bias. |
| Treatment | PASS | Apixaban vs rivaroxaban identified by RXNORM_CUI with both SCD and SBD forms. Comprehensive coverage of both drugs at all approved doses. |
| Assignment | PASS | Based on first DOAC prescription at index date. Ambiguous assignments (both drugs on same day) are removed. |
| Time zero | PASS | Date of first DOAC prescription. Aligns eligibility, treatment, and follow-up start. |
| Outcome | PASS | Composite stroke/SE + major bleeding. Ascertained from IP/ED/EI encounters with legacy filter. Individual components well-defined. |
| Estimand | PASS | ATE, justified for population-level prescribing question. |
| Causal contrast | PASS | ITT approach primary; as-treated sensitivity analysis planned. |

### Code Review

**Structural requirements -- all pass:**
- All tables fully qualified as `CDW.dbo.TABLE_NAME`
- T-SQL syntax throughout (DATEADD, DATEDIFF, GETDATE, ISNULL)
- Legacy encounter filter (`RAW_ENC_TYPE <> 'Legacy Encounter'`) applied to all ENCOUNTER joins
- Date bounds on all date columns (no unbounded date queries)
- RXNORM_CUI for all medications (no drug name strings)
- LOINC codes for all labs
- `ROW_NUMBER() OVER (PARTITION BY PATID ...)` for all patient-level JOINs: vitals, each lab, DEATH, ENROLLMENT
- `dbExecute()` for temp table creation; `dbGetQuery()` for final data pull (separate calls)
- `names(cohort) <- tolower(names(cohort))` immediately after `dbGetQuery()` (line 887)
- No `png()`/`dev.off()` -- all plots rendered inline via Quarto figure chunks with `#| fig-cap`, `#| fig-width`, etc.
- Two-part layout: Part 1 (Sections 0-8) defines functions with no output; Part 2 (Sections 9+) executes and displays
- No monolithic `main()` function
- Empty cohort guard with `knitr::knit_exit()` (line 1567)
- Dynamic PS formula construction via `build_ps_formula()` (drops single-level factors and zero-variance columns)
- E-value with `rare = TRUE` (lines 1434, 1447)
- CONSORT flow diagram: text table + graphical diagram tracking counts at every step
- `count_temp()` uses `COUNT(DISTINCT PATID)` (line 843)
- `build_cohort_sql()` in a single code chunk (lines 101-833)
- Derived factor columns use distinct names (`sex_cat`, `race_cat`, `ckd_stage_cat`, etc.)
- Treatment arms guard before IPW (line 1173)
- Comorbidities use GROUP BY (safe, 1 row per patient)
- Concomitant medications use SELECT DISTINCT (safe, 1 row per patient)

**Minor issues identified:**

1. **Anemia ICD-10 range incomplete (minor).** The protocol document specifies `D50.x-D64.x` for anemia, but the SQL (line 589-591) only includes `D50%`, `D51%`, `D52%`, `D53%`, `D63%`, `D64%` -- missing `D54%` through `D62%` (nutritional, hemolytic, aplastic, and posthemorrhagic anemias). Since anemia is a binary confounder flag (not an outcome), the impact is slight undercounting of anemia prevalence, which would modestly attenuate confounding adjustment. Not a fatal flaw.

2. **Concomitant medication RXCUI lists are representative subsets.** The statin, ACEi/ARB, beta-blocker, PPI, and NSAID RXCUI lists include SCD forms for common doses but not necessarily all branded (SBD) forms. For binary confounder flags (prescribed yes/no), PCORnet PRESCRIBING may store either the SCD or SBD code depending on the EHR. Missing some SBD codes could slightly undercount concurrent medication use. This is a minor issue for confounder adjustment and does not threaten the primary analysis.

3. **ICD-9 codes not included for comorbidity lookback.** All queries use `DX_TYPE = '10'` only. With the study starting 2016-01-01 and a 365-day lookback, the earliest lookback reaches January 2015, which is before the ICD-10 transition (October 2015). Diagnoses from Jan-Sep 2015 in ICD-9 would be missed. This affects only patients with early 2016 index dates and is a minor limitation.

### Immortal Time Bias Assessment

**No immortal time bias.** Time zero is the date of the first DOAC prescription, which is simultaneously:
- The treatment-defining event (prescription of apixaban or rivaroxaban)
- The start of eligibility (patient meets all inclusion criteria on this date)
- The start of follow-up (outcomes assessed from this date forward)

The new-user design ensures no prior DOAC exposure within 365 days. There is no gap between eligibility and treatment assignment. This is the gold standard for avoiding immortal time bias in active-comparator drug studies.

### What Was Done Well

- Dual CKD ascertainment (diagnosis codes + lab-based eGFR) captures patients who may lack coded CKD diagnoses
- Comprehensive exclusion of ESRD/dialysis (both ICD-10 and CPT procedure codes)
- CKD stage subgroup analysis with separate PS models per subgroup
- Dose subgroup analysis (standard vs reduced dose) addresses pharmacokinetic concerns
- As-treated sensitivity analysis addresses ITT limitations
- Post-Epic era sensitivity analysis addresses EHR transition concerns
- Thorough limitations section with specific unmeasured confounders identified

### Verdict: ACCEPT

No changes required. The protocol is ready for execution.

---

## Protocol 2: Early Rhythm vs Rate Control in Elderly AF

### Summary Verdict: ACCEPT

Protocol 2 uses a 12-month landmark design to compare early rhythm control vs rate control in AF patients aged >= 80. The landmark approach correctly handles the immortal time bias inherent in treatment classification windows. The code is well-structured and implements the protocol faithfully. Minor issues noted but none warrant revision.

### TTE Checklist

| Element | Status | Notes |
|---------|--------|-------|
| Eligibility | PASS | Age >= 80, newly diagnosed AF (365-day washout), received rhythm or rate control within 12 months. Active care requirement (non-legacy encounter in prior 365 days). |
| Treatment | PASS | Rhythm control: AADs (amiodarone, flecainide, sotalol, dronedarone, dofetilide, propafenone) + cardioversion (CPT 92960/92961) + ablation (CPT 93656/93657). Rate control: metoprolol, diltiazem, verapamil, digoxin. All identified by RXNORM_CUI with SCD+SBD forms. |
| Assignment | PASS | Any rhythm control intervention within 12 months = rhythm control arm. Rate control only = rate control arm. ITT classification. |
| Time zero | PASS | First AF diagnosis date (first I48.x at age >= 80 with no prior I48.x in >= 365 days). |
| Outcome | PASS | Composite CV death + stroke + HF hospitalization. Intelligent DEATH_CAUSE completeness check with fallback to all-cause death. |
| Estimand | PASS | ATE, appropriate for population-level treatment strategy question. |
| Causal contrast | PASS | ITT approach. Treatment crossover after classification window does not change assignment. |

### Code Review

**Structural requirements -- all pass:**
- All tables `CDW.dbo.TABLE_NAME`
- T-SQL syntax throughout
- Legacy encounter filter on all ENCOUNTER joins (eligibility, outcome ascertainment, procedure identification)
- Date bounds on all date columns
- RXNORM_CUI for all medications
- LOINC for all labs
- `ROW_NUMBER()` for vitals, labs, DEATH, ENROLLMENT
- `dbExecute()`/`dbGetQuery()` pattern correct (5 sequential `dbExecute` calls, then `dbGetQuery` for final pull)
- `names(cohort) <- tolower(names(cohort))` (line 851)
- No `png()`/`dev.off()`
- Two-part layout (Part 1: functions, Part 2: execution)
- No monolithic `main()`
- Empty cohort guard with `knitr::knit_exit()` (line 1573)
- Treatment arms guard (line 1596)
- Dynamic PS formula construction
- E-value with `rare = TRUE` (lines 1419, 1432)
- CONSORT flow diagram with text + graphical rendering
- `count_temp()` uses `COUNT(DISTINCT PATID)` (line 797)
- `build_cohort_sql()` in a single code chunk
- Derived factor columns use distinct names
- Comorbidities via GROUP BY (safe)
- Concomitant medications via SELECT DISTINCT (safe)

**Notable code quality features:**
- **DEATH_CAUSE completeness check** (lines 337-354): Queries the proportion of deaths with a cause code, then uses CV death in the composite if >= 30% of deaths have cause codes, otherwise substitutes all-cause death. This is a smart, data-driven approach.
- **CHA2DS2-VASc computation** in SQL is correct (all patients >= 80 get age score = 2; components correctly summed).
- **Landmark filter** (lines 298-326): Correctly excludes patients who die before the 12-month landmark using deduplicated DEATH table with ROW_NUMBER().

**Minor issues identified:**

1. **AF flutter codes included (intentional, not an error).** The eligibility SQL uses `DX LIKE 'I48%'` without excluding flutter (I48.3, I48.4, I48.92). This differs from Protocols 1 and 3, which exclude flutter. For Protocol 2, this is clinically appropriate: the rhythm vs rate control question applies to both AF and atrial flutter. AFFIRM and EAST-AFNET 4 included flutter patients.

2. **ICD-9 transition coverage.** Same as Protocol 1: `DX_TYPE = '10'` only, 365-day lookback from 2016 start. Minor impact.

3. **Study period end consideration.** Study period ends 2024-12-31. Patients diagnosed in late 2023 or 2024 may not have a full 12-month classification window within the data. However, these patients would be excluded by the landmark survival requirement (which requires surviving to the landmark date), and outcomes beyond the data would be administratively censored. This is standard practice.

4. **Metoprolol RXCUI list includes some uncommon formulations** (e.g., RXCUI 2723025, 1606347, 1606349). These appear to be newer generic entries. Including them is conservative and correct.

### Immortal Time Bias Assessment

**Correctly handled via landmark design.** The 12-month landmark addresses the fundamental immortal time problem in treatment classification windows:

1. **Without landmark:** Patients classified as "rate control" cannot die during the classification window (because if they died, they'd never receive a rhythm control drug, guaranteeing their classification as rate control). This creates a survival bias favoring rate control.

2. **With landmark:** Both groups must survive 12 months. Follow-up begins at the landmark (day 366). This eliminates the differential immortal time.

The implementation is correct:
- Step 3 (`landmark_sql`): Excludes patients with `DEATH_DATE <= DATEADD(day, 365, index_date)` using deduplicated DEATH records
- Step 4 (`outcome_sql`): All outcomes ascertained from `landmark_date` forward (not from `index_date`)
- Time-to-event variables computed from `landmark_date`

**Known limitation of landmark design (acknowledged in protocol):** Early treatment effects (both beneficial and harmful) within the first 12 months are invisible. If rhythm control causes early proarrhythmic deaths, these are excluded. If rhythm control prevents early strokes, these are also excluded. The analysis captures only the long-term conditional effect. This is a design trade-off, not a bias.

### What Was Done Well

- Landmark design is the correct methodological choice for this question
- DEATH_CAUSE completeness check with automatic fallback is a practical and defensible approach
- CHA2DS2-VASc score computed in SQL for confounder adjustment (accounts for high baseline stroke risk in this elderly population)
- Dementia and COPD included as confounders (important in octogenarians)
- Age 80-84 vs >= 85 subgroup analysis directly addresses the clinical question
- 90-day grace period sensitivity analysis tests robustness to classification window length
- All-cause mortality substitution sensitivity analysis (for CV death misclassification)

### Verdict: ACCEPT

No changes required. The landmark design is the appropriate methodology and is correctly implemented.

---

## Protocol 3: OAC vs No OAC at Low CHA2DS2-VASc

### Summary Verdict: REVISE

Protocol 3 addresses the highest-priority clinical question (OAC at the guideline threshold) with an appropriate treated-vs-untreated design. The code quality is high and follows CDW conventions throughout. However, there is a meaningful discrepancy between the protocol document's time-zero definition and the SQL implementation that needs correction.

### TTE Checklist

| Element | Status | Notes |
|---------|--------|-------|
| Eligibility | PASS | NVAF + CHA2DS2-VASc = 1 (men) / 2 (women), no prior OAC, age 18-74, no stroke/TIA, no cancer. Score computation in SQL is correct. |
| Treatment | PASS | OAC (all DOACs + warfarin, 53 RXCUIs) vs no OAC, within +/-7 day grace period. Comprehensive OAC coverage. |
| Assignment | PASS | Based on OAC prescription within +/-7 days of time zero. ROW_NUMBER() used to select the closest OAC prescription if multiple exist. |
| Time zero | **FLAG** | Protocol document says "first qualifying encounter" but SQL uses "first AF encounter." See detailed assessment below. |
| Outcome | PASS | Primary: ischemic stroke/SE. Secondary: major bleeding, ICH, all-cause mortality. Net clinical benefit calculation. All well-defined. |
| Estimand | PASS | ATE, appropriate for population-level guideline question. |
| Causal contrast | PASS | OAC initiation vs no OAC initiation. ITT approach. |

### Code Review

**Structural requirements -- all pass:**
- All tables `CDW.dbo.TABLE_NAME`
- T-SQL syntax throughout
- Legacy encounter filter on ENCOUNTER joins
- Date bounds on all date columns
- RXNORM_CUI for all medications (comprehensive OAC list with 53 SCD+SBD codes)
- LOINC for all labs
- `ROW_NUMBER()` for vitals, labs, DEATH, ENROLLMENT, OAC assignment
- `dbExecute()`/`dbGetQuery()` pattern correct
- `names(cohort) <- tolower(names(cohort))` (line 857)
- No `png()`/`dev.off()`
- Two-part layout
- No monolithic `main()`
- Empty cohort guard with `knitr::knit_exit()` (line 1619)
- Dynamic PS formula construction
- E-value with `rare = TRUE` (lines 1460, 1473)
- CONSORT flow diagram
- `count_temp()` uses `COUNT(DISTINCT PATID)` (line 813)
- `build_cohort_sql()` in single code chunk
- Derived factor columns use distinct names
- Comorbidities via GROUP BY
- Concomitant medications via SELECT DISTINCT

**Notable code quality features:**
- CHA2DS2-VASc computation in SQL is correctly implemented with all component flags
- `driving_component` column identifies which single factor drives the score (excellent for subgroup analyses)
- Net clinical benefit calculation with ICH weight of 1.5 (Singer et al. methodology)
- DOAC-only sensitivity analysis tests whether results are driven by warfarin-specific effects
- Comprehensive exclusion logic: stroke/TIA explicitly excluded (would add 2 points), age >= 75 excluded (would add 2 points), providing safety checks redundant with score filter
- 730-day comorbidity lookback (longer than other protocols) -- appropriate for CHA2DS2-VASc lifetime diagnoses

### Issues Requiring Revision

**1. Time-zero discrepancy between protocol document and SQL implementation (REVISE)**

The protocol document (Section 2.5) states:
> "Time zero = the date of the **first qualifying encounter** where a patient has: (1) An AF diagnosis on or before that date, (2) CHA2DS2-VASc = 1 (men) or 2 (women) based on all diagnoses on or before that date..."

But the SQL implementation (lines 152-168) computes the CHA2DS2-VASc score only at the **first AF encounter** (`MIN(dx.ADMIT_DATE)`):

```sql
-- First AF encounter per patient (the earliest encounter with an AF Dx)
SELECT dx.PATID, MIN(dx.ADMIT_DATE) AS first_af_date
INTO #first_af_enc
...
```

Then the score is computed at `first_af_date` (line 176):
```sql
SELECT fa.PATID, fa.first_af_date AS index_date, ...
```

**Consequence:** Patients who have AF diagnosed first with CHA2DS2-VASc = 0, and then later develop a risk factor (e.g., HTN diagnosis 2 years later, bringing their score to 1), are excluded. The clinical decision point for OAC in these patients is when they reach the target score, not when they were first diagnosed with AF. These patients are clinically relevant to the research question.

**Fix options:**
- **(Recommended) Option A:** Update the protocol document Section 2.5 to explicitly state that time zero is the first AF encounter date, with the score evaluated at that date only. Add a limitation noting that patients who reach the target score after their initial AF diagnosis are excluded. This is the simpler fix and is defensible -- the first AF encounter is a natural clinical decision point.
- **Option B:** Modify the SQL to evaluate the score at each encounter (or at least at each subsequent visit with new diagnosis codes) until the target score is met. This captures more patients but adds significant SQL complexity.

**Impact assessment:** This is a moderate issue. It does not introduce bias (the patients who are captured are correctly handled), but it reduces the eligible population and may exclude a clinically relevant subgroup. It also creates an inconsistency between the protocol document and the code.

### Immortal Time Bias Assessment

**No immortal time bias in the captured population.** Time zero is the first AF encounter date. Treatment assignment (OAC vs no OAC) is determined within +/-7 days of this date. Follow-up begins at time zero. There is no gap between eligibility and treatment assignment.

However, the +/-7 day grace period deserves scrutiny:
- A patient who receives OAC 7 days **before** the first AF encounter is classified as treated. This could occur if OAC was prescribed at a pre-diagnostic visit (e.g., based on clinical suspicion before formal AF coding). This is reasonable and emulates the clinical decision timeline.
- A patient who receives OAC 7 days **after** the first AF encounter is also classified as treated. During those 7 days, the patient is in the "no OAC" state but is classified as "OAC." Under ITT, this is a minor misclassification that slightly dilutes the treatment effect. The 7-day window is narrow enough that this is acceptable.

**Confounding by indication** is the primary threat to validity, not immortal time bias. The protocol correctly identifies this and addresses it with IPW + E-value analysis. The E-value will be critical for interpreting results.

### What Was Done Well

- Treated-vs-untreated design is the correct approach when randomization is unethical
- Driving component identification enables subgroup analyses by the specific risk factor
- Net clinical benefit calculation (stroke reduction minus 1.5x ICH excess) provides a clinically meaningful summary measure
- Comprehensive confounder set includes non-score comorbidities (CKD, prior bleeding, liver disease, anemia, obesity, COPD, OSA, alcohol use) that go beyond the CHA2DS2-VASc components
- DOAC-only sensitivity analysis addresses potential warfarin-specific effects
- OAC type distribution table shows the mix of DOACs and warfarin in the treated arm
- E-value analysis for both stroke/SE and major bleeding outcomes
- Thorough limitations section with honest acknowledgment of confounding by indication
- The protocol document provides clear justification for why a TTE is needed (randomization considered unethical; BRAIN-AF stopped for futility on wrong endpoint)

### Verdict: REVISE

**Specific changes required:**

1. **Resolve the time-zero discrepancy.** Either:
   - (a) Update protocol_03.md Section 2.5 to state that time zero is the first AF encounter date, with CHA2DS2-VASc computed at that date only. Add a limitation statement noting that patients who reach the target score after initial AF diagnosis are excluded. Add a rough estimate of the proportion of eligible patients this might miss.
   - (b) Modify the SQL to evaluate the score at subsequent encounters until the target score is first met.

   Option (a) is recommended as the simpler fix.

---

## Summary

| Protocol | Design | Question | Verdict | Key Issue |
|----------|--------|----------|---------|-----------|
| 01 | Active comparator, new user | Apixaban vs rivaroxaban in AF+CKD 3b-5 | **ACCEPT** | None (minor RXCUI/ICD-10 coverage notes) |
| 02 | Landmark (12-month classification window) | Rhythm vs rate control in AF age >= 80 | **ACCEPT** | None (landmark correctly handles immortal time) |
| 03 | Treated vs untreated, new user | OAC vs no OAC at CHA2DS2-VASc threshold | **REVISE** | Time-zero definition discrepancy between protocol document and SQL |

### Cross-Protocol Observations

**Strengths shared across all three protocols:**
- Consistent CDW coding standards (all tables fully qualified, legacy encounter filtering, RXNORM_CUI, LOINC, ROW_NUMBER deduplication, date bounds)
- Two-part Quarto layout with function definitions separated from execution
- CONSORT flow diagrams tracking patient counts at every step
- Dynamic PS formula construction that gracefully handles single-level factors
- Treatment arms guard before IPW analysis
- E-value analysis for unmeasured confounding sensitivity
- Post-Epic era sensitivity analyses
- Separate `dbExecute()` and `dbGetQuery()` calls (correct ODBC pattern)
- Empty cohort guard with `knitr::knit_exit()`

**Minor issues shared across all three protocols:**
- ICD-9 codes not included for comorbidity lookback. Since all protocols start in 2016 with 365-day (or 730-day) lookback, pre-October 2015 ICD-9 diagnoses are missed. The impact is small and diminishes as the study period progresses.
- Concomitant medication RXCUI lists use representative SCD subsets for confounders. This is acceptable for binary confounder flags but could slightly undercount concurrent medication use if patients' prescriptions were recorded with SBD codes not in the list.

**Methodological strengths:**
- Protocol 1 uses the active-comparator new-user design (gold standard for drug comparison)
- Protocol 2 uses a landmark design (correct approach for treatment classification windows)
- Protocol 3 includes a net clinical benefit calculation (essential for the risk-benefit question)
- All three protocols include pre-specified subgroup analyses with re-fitted PS models within each subgroup
- All three protocols include multiple sensitivity analyses addressing different sources of bias
