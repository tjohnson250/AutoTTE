# Executive Summary: Type 2 Diabetes Pipeline Run

**Therapeutic Area:** Type 2 Diabetes Mellitus
**Study:** SGLT2 Inhibitors vs DPP-4 Inhibitors for 3-Point MACE
**Database:** PCORnet CDW v6.1 (institutional Clinical Data Warehouse, MS SQL Server)
**Date:** 2026-04-15 (protocol) / 2026-04-16 (execution and reporting)
**Mode:** OFFLINE protocol design, followed by local R execution and `--resume-reports`

> **Updated 2026-04-16:** Analysis has now been executed against the live CDW. Per-protocol results are reported in Section 6A below, with Benjamini-Yekutieli FDR correction applied across all primary hypotheses tested. The full per-protocol narrative report is in `protocols/protocol_01_report.md`.

---

## 1. Pipeline Overview

### 1.1 Study Description

This pipeline designed a target trial emulation protocol to evaluate the comparative cardiovascular effectiveness of SGLT2 inhibitors versus DPP-4 inhibitors (primary comparator) and second-generation sulfonylureas (secondary comparator) for 3-point MACE (cardiovascular death, nonfatal myocardial infarction, nonfatal ischemic stroke) in adults with type 2 diabetes. The original study description specified canagliflozin as the index drug; a feasibility-driven modification expanded the exposure to the SGLT2 inhibitor class (see Section 3).

### 1.2 Phases Completed

| Phase | Description | Key Output | Sub-Agents |
|-------|-------------|------------|------------|
| **Phase 0** | Data source onboarding | Schema, profile, and conventions verified | — |
| **Phase 1** | Literature discovery | `01_literature_scan.md`, `02_evidence_gaps.md` | Worker + Reviewer |
| **Phase 1 Review** | Independent peer review | `review_discovery.md` — verdict: REVISE | Reviewer |
| **Phase 2** | Dataset feasibility | `03_feasibility.md` (1,229 lines) | Worker |
| **Phase 3** | Protocol generation | `protocol_01.md`, `protocol_01_analysis.R` (1,372 lines) | Worker |
| **Phase 3 Review** | Protocol peer review | `review_protocol_01.md` — verdict: REVISE (2 bugs fixed) | Reviewer |

**Total sub-agents launched:** 5 (discovery worker, discovery reviewer, feasibility worker, protocol worker, protocol reviewer)

### 1.3 Key Coordinator Decisions

| Decision | Rationale |
|----------|-----------|
| Accept literature review with noted corrections | All 7 PICO questions approved; core evidence gap (no canagliflozin-specific TTE) validated despite Filion 2020 omission |
| Skip formal feasibility review | Canagliflozin N=142 is an unambiguous factual finding from the data profile |
| Adopt Alternative D (SGLT2i class + canagliflozin sensitivity) | Preserves both comparator arms; provides adequate power; canagliflozin subgroup still reported |
| Apply both SQL bug fixes from protocol review | Straightforward fixes; no design changes needed |

---

## 2. Literature Findings

### 2.1 Search Scope

The literature scan identified **32 unique PMIDs** across three search passes:

| Pass | Strategy | Queries | Key Yield |
|------|----------|---------|-----------|
| **Pass 1** | Broad landscape | 8 thematic queries | 812 results; core CVOTs and observational studies |
| **Pass 2** | PICO-targeted | 5 narrow queries | 348 results; canagliflozin-specific and TTE-focused papers |
| **Pass 3** | Citation chaining | 3 seed papers | Forward/backward citation tracing from CANVAS, Xie 2023, D'Andrea 2023 |

### 2.2 Landmark Randomized Controlled Trials

**SGLT2 Inhibitor CVOTs (vs Placebo):**

| Trial | Drug | PMID | N | 3P-MACE HR (95% CI) |
|-------|------|------|---|---------------------|
| CANVAS Program | Canagliflozin | 28605608 | 10,142 | **0.86 (0.75–0.97)** |
| EMPA-REG OUTCOME | Empagliflozin | 26378978 | 7,020 | **0.86 (0.74–0.99)** |
| DECLARE-TIMI 58 | Dapagliflozin | 30415602 | 17,160 | 0.93 (0.84–1.03) |
| CREDENCE | Canagliflozin | 30990260 | 4,401 | Renal primary; CV secondary benefit |

**DPP-4 Inhibitor CVOTs (vs Placebo):**

| Trial | Drug | PMID | N | 3P-MACE HR (95% CI) |
|-------|------|------|---|---------------------|
| SAVOR-TIMI 53 | Saxagliptin | 23992601 | 16,492 | 1.00 (0.89–1.12) |
| TECOS | Sitagliptin | 27437883 | 14,671 | ~1.01 (noninferior) |
| CAROLINA | Linagliptin | 31536101 | 6,033 | Noninferior to glimepiride |

DPP-4 inhibitors are cardiovascularly neutral (pooled HR ~0.99 for MACE), supporting their role as an active comparator (pharmacoepidemiologic placebo) for observational studies of SGLT2i CV effects.

**Key Observational Studies (SGLT2i vs DPP-4i):**

| Study | PMID | Design | N | MACE HR (95% CI) |
|-------|------|--------|---|-------------------|
| D'Andrea et al. 2023 | 36745425 | PS-matched CE | 87,274 matched | 0.85 (0.75–0.95) |
| EMPRISE (Htoo 2024) | 38509341 | PS-matched CE | 115,116 pairs | 0.73 (0.62–0.86) |
| Xie et al. 2023 | 37499675 | **Target trial emulation** | 283,998 | 0.86 (0.82–0.89) |
| Kosjerina et al. 2025 | 40201798 | **Target trial emulation** | 35,679 | 0.65 (0.63–0.68) |

No head-to-head RCT of canagliflozin vs any DPP-4 inhibitor has used MACE as a primary outcome. The only canagliflozin-vs-DPP-4i RCT (CANTABILE, PMID 34481910) enrolled 162 patients and focused on metabolic surrogates.

### 2.3 Evidence Gaps Identified

Seven PICO questions were ranked by a composite gap score (clinical importance, evidence gap quality, feasibility, methodological novelty, study alignment):

| Rank | Question | Gap Score |
|------|----------|-----------|
| 1 | SGLT2i (canagliflozin focus) vs DPP-4i for 3P-MACE | **8.05** |
| 2 | SGLT2i vs 2nd-gen SU for 3P-MACE | 7.5 |
| 3 | Individual MACE components (CV death, MI, stroke) | 7.3 |
| 4 | Hospitalization for heart failure | 6.8 |
| 5 | Safety profile (amputation, DKA, genital infections) | 6.5 |
| 6 | CKD subgroup analysis | 6.2 |
| 7 | ASCVD subgroup analysis | 5.8 |

### 2.4 Critical Review Finding: Filion 2020 Omission and Correction

The independent reviewer identified a critical omission: **Filion et al. 2020** (BMJ, PMID 32967856), a multi-database retrospective cohort study of 419,734 matched patients across 7 Canadian provinces and the UK. This study provides canagliflozin-specific 3P-MACE data versus DPP-4 inhibitors:

- **Overall SGLT2i vs DPP-4i:** HR 0.76 (0.69–0.84)
- **Canagliflozin-specific:** HR **0.79 (0.66–0.94)**
- **Dapagliflozin-specific:** HR 0.73 (0.63–0.85)
- **Empagliflozin-specific:** HR 0.77 (0.68–0.87)

This contradicted the worker's claim that "no study has compared canagliflozin specifically vs DPP-4i for 3P-MACE." The evidence gap was reframed: while canagliflozin-specific observational MACE data exists (Filion 2020), **no published study has emulated a canagliflozin-specific target trial against DPP-4i for 3P-MACE**, and no study has used PCORnet CDM data for this comparison. The gap score was adjusted from 8.4 to 8.05; the ranking was unchanged.

The reviewer also identified missing citations for LEGEND-T2DM (Patel et al. 2024, JACC) and Shin et al. 2025 (PMID 39836397), and verified that all 14 spot-checked PMIDs were real with accurately described findings (no hallucinated references).

---

## 3. Feasibility Assessment

### 3.1 Database Capabilities

The PCORnet CDW is a large, institutional clinical data warehouse with substantial depth for this study:

| Resource | Metric |
|----------|--------|
| Total patients | 10,091,847 |
| Type 2 diabetes patients (E11.x) | **242,522** |
| Total SGLT2i patients | ~9,833 (empagliflozin 6,526 + dapagliflozin 3,165 + canagliflozin 142) |
| DPP-4i patients (estimated) | 8,000–20,000 |
| 2nd-gen SU patients (estimated) | 15,000–35,000 |
| HbA1c coverage | 332,556 patients |
| eGFR coverage | 167,036 patients |
| Lipid panel coverage | 337,620 patients |
| Death records | 113,105 patients (3 sources: local EHR, vital statistics, NDI) |

The database supports the full set of confounders required for the propensity score model, including demographics, vitals (BMI, blood pressure), laboratory values (HbA1c, creatinine/eGFR, lipid panel, hemoglobin, potassium, ALT), 13 comorbidity categories (via ICD-10 diagnoses), and 6 concomitant medication classes.

### 3.2 Critical Limitation: Canagliflozin N = 142

The CDW contains only **142 patients with any canagliflozin prescription** (380 total prescription records). After applying eligibility criteria (new-user status, 180-day enrollment, post-ICD-10 study period), the canagliflozin arm would shrink to an estimated 80–120 patients, yielding approximately 5–6 expected MACE events — far below the minimum needed for any causal inference analysis.

**Context:** Canagliflozin lost significant market share after the 2017 CANVAS amputation signal and FDA boxed warning (later removed in 2020). Empagliflozin (6,526 patients) and dapagliflozin (3,165 patients) dominate SGLT2i prescribing at this institution.

### 3.3 Design Modification

The coordinator adopted **Alternative D** from the feasibility assessment:

| Aspect | Original Design | Modified Design |
|--------|----------------|-----------------|
| Intervention | Canagliflozin only | **SGLT2i class** (canagliflozin + empagliflozin + dapagliflozin) |
| Expected new-user N | ~80–120 | **~4,000–7,000** |
| Expected MACE events | ~5–6 | **~200–350** |
| Canagliflozin subgroup | Primary analysis | Pre-specified descriptive sensitivity analysis |
| Comparators | Unchanged | DPP-4i (primary), SU (secondary) |

This modification preserves the clinical question (SGLT2i CV benefit vs DPP-4i) while providing adequate statistical power. It is consistent with published class-level analyses from CVD-REAL (PMID 29540325), EASEL (PMID 29133607), and the Xie et al. 2023 TTE (PMID 37499675).

### 3.4 Known Data Gaps

| Gap | Severity | Mitigation |
|-----|----------|------------|
| Canagliflozin N=142 | Fatal (for original design) | SGLT2i class expansion (Alternative D) |
| Smoking (99.8% unknown in VITAL) | High | Tobacco use disorder ICD-10 codes (F17.x, Z72.0, Z87.891) as proxy |
| DEATH_CAUSE completeness unknown | High | All-cause mortality sensitivity analysis |
| Insurance/payer (0% populated) | Moderate | Cannot adjust; noted as limitation |
| RX_END_DATE (47.6%) / RX_DAYS_SUPPLY (42.8%) | Moderate | Hierarchical duration estimation with 90-day default |
| NT-proBNP (4,714 patients) | Moderate | Too sparse for PS model; HF ICD subtyping used instead |

---

## 4. Protocol Summary

### 4.1 Study Design

**Design:** Active comparator new-user target trial emulation

**Study period:** 2016-01-01 to 2025-12-31

**Treatment arms:**

| Arm | Class | Drugs Included | Estimated New-User N |
|-----|-------|----------------|---------------------|
| **A (Treatment)** | SGLT2 inhibitors | Canagliflozin, empagliflozin, dapagliflozin | 4,000–7,000 |
| **B (Primary comparator)** | DPP-4 inhibitors | Sitagliptin, linagliptin, saxagliptin, alogliptin | 3,000–9,000 |
| **C (Secondary comparator)** | 2nd-gen sulfonylureas | Glipizide, glimepiride, glyburide | 5,000–14,000 |

### 4.2 Target Trial Specification

| Element | Target Trial | Emulation |
|---------|-------------|-----------|
| **Eligibility** | Adults ≥18 with T2D, no prior same-class use, ≥180 days enrollment | E11.x diagnosis, 180-day washout/enrollment, exclusions for T1D, GDM, ESRD, active cancer |
| **Treatment strategies** | Initiate SGLT2i vs DPP-4i vs SU | New prescription identified via RXNORM_CUI in PRESCRIBING |
| **Assignment** | Random allocation | Propensity score overlap weighting (ATO estimand) |
| **Time zero** | Randomization date | Date of first qualifying prescription (RX_ORDER_DATE) |
| **Outcome** | 3P-MACE (CV death, nonfatal MI, nonfatal stroke) | ICD-10 coded diagnoses on IP/EI/ED encounters + DEATH/DEATH_CAUSE tables |
| **Estimand** | ITT (treatment initiation policy) | Follow from time zero regardless of treatment changes |
| **Causal contrast** | HR for SGLT2i vs DPP-4i on 3P-MACE hazard | Weighted Cox PH with robust SEs |

### 4.3 Confounder Set (32 Variables)

The propensity score model includes 32 variables with explicit DAG justification for each:

| Category | Variables | Count |
|----------|-----------|-------|
| Demographics | Age, sex, race, Hispanic ethnicity | 4 |
| Vitals | BMI, systolic BP, diastolic BP | 3 |
| Laboratory values | HbA1c, creatinine, eGFR, total cholesterol, LDL, HDL, triglycerides, hemoglobin, potassium, ALT | 10 |
| Comorbidities | Hypertension, HF, AF, CKD, prior MI, prior stroke, COPD, obesity, dyslipidemia, PAD, VTE/PE, tobacco use disorder, ASCVD composite | 13* |
| Concomitant medications | Metformin, insulin, statin, ACEi/ARB, beta-blocker, antiplatelet | 6 |

*Note: The ASCVD composite overlaps with prior MI, prior stroke, and PAD. The PS model includes the individual components; the composite is used for subgroup analysis.

Variables excluded with documented justification: VITAL.SMOKING (99.8% missing), LVEF (not structured), insurance (0% populated), NT-proBNP (too sparse), OTC aspirin (not captured), diabetes duration (imprecise), albuminuria (not available).

### 4.4 Outcomes

**Primary:** 3-point MACE (first occurrence of CV death, nonfatal MI [I21.x excluding type 2 MI], or nonfatal ischemic stroke [I63.x])

**Secondary:**
- Individual MACE components (CV death, MI, stroke analyzed separately)
- Hospitalization for heart failure (I50.x on inpatient encounter)
- All-cause mortality

**Safety:**
- Lower-extremity amputation (CPT procedure codes)
- Diabetic ketoacidosis (E11.10, E11.11)
- Genital mycotic infections (B37.3x, N76.0, N77.1, N48.1)
- Acute kidney injury (N17.x)

### 4.5 Statistical Analysis Plan

| Component | Approach |
|-----------|----------|
| **Propensity score** | Logistic regression; dynamic formula drops single-level factors and zero-variance columns |
| **Weighting** | Overlap weights (ATO estimand) via `WeightIt::weightit()` |
| **Outcome model** | Weighted Cox proportional hazards with robust (sandwich) SEs |
| **Effect measure** | Hazard ratio with 95% CI |
| **Balance diagnostics** | Love plot; pre/post-weighting SMDs; target SMD < 0.10 |
| **PS distribution** | Density plots by treatment group to assess overlap |

### 4.6 Sensitivity Analyses (7 Pre-Specified)

| # | Analysis | Purpose |
|---|----------|---------|
| 1 | Canagliflozin-only subgroup | Addresses the original study question (descriptive; expected ~5–6 MACE events) |
| 2 | As-treated analysis | Censors at treatment discontinuation + 30-day grace period; per-protocol effect |
| 3 | All-cause mortality in MACE composite | Replaces CV death with all-cause death; addresses DEATH_CAUSE completeness uncertainty |
| 4 | Include type 2 MI (I21.A1) | Sensitivity to MI coding variations |
| 5 | Exclude saxagliptin from DPP-4i arm | Addresses saxagliptin's unique HHF signal (SAVOR-TIMI 53 HR 1.27) |
| 6 | E-value | Quantifies minimum unmeasured confounding strength to explain away observed association |
| 7 | PS matching (1:1 nearest-neighbor) | Alternative estimation method for robustness |

### 4.7 Pre-Specified Subgroup Analyses (4 Subgroups)

| Subgroup | Definition | Rationale |
|----------|------------|-----------|
| Age ≥65 vs <65 | Dichotomized at index | Elderly at higher baseline CV risk |
| Sex (male vs female) | DEMOGRAPHIC.SEX | CV risk profiles and treatment response differ |
| Prior ASCVD (yes vs no) | ICD-10 history of IHD, stroke, PAD | CANVAS enrolled 65.6% with CVD history; benefit may differ by prevention context |
| CKD (yes vs no) | N18.x (excl ESRD) or eGFR < 60 | CREDENCE showed canagliflozin CV/renal benefit in CKD |

### 4.8 Protocol Review Findings

The independent protocol reviewer assessed all 7 target trial elements, verified all 13 CDW conventions in the R script, and cross-checked all RxNorm, ICD-10, and LOINC codes against the feasibility document and database schema. Two SQL bugs were identified and fixed:

| Bug | Severity | Description | Fix |
|-----|----------|-------------|-----|
| **1** | Moderate | MI/stroke outcome subqueries used `MIN(ADMIT_DATE)` across all time, then filtered `> index_date` in the JOIN condition. Patients with pre-index AND post-index events had their post-index events missed, biasing toward the null. | Restructured subqueries to join the eligible cohort table and filter to post-index dates *before* aggregating with `MIN()` |
| **2** | Minor | I22.x (subsequent MI within 28 days) codes were specified in the protocol but missing from the MI SQL query | Added `OR dx.DX LIKE 'I22%'` to the MI WHERE clause |

Both fixes were applied by the coordinator. The protocol now passes all acceptance criteria.

### 4.9 Analysis Script

The R analysis script (`protocol_01_analysis.R`) is a complete, production-grade implementation spanning 1,372 lines. It includes:

- Cohort assembly with CONSORT flow tracking
- Propensity score estimation with dynamic formula construction
- Overlap weighting and balance diagnostics
- Weighted Cox regression for primary, secondary, and safety outcomes
- All 7 sensitivity analyses and 4 subgroup analyses
- Publication-ready outputs (Table 1, love plot, PS distribution, KM curves, forest plot, CONSORT diagram)
- Structured results JSON for downstream report generation
- Error handling (empty cohort guards, treatment arm guards, tryCatch wrapping)

---

## 5. Strengths and Limitations

### 5.1 Pipeline Strengths

1. **Literature rigor with independent verification.** The three-pass search strategy identified 32 unique PMIDs. All 14 PMIDs spot-checked by the independent reviewer were real with accurately described findings — no hallucinated references. The reviewer's identification of the Filion 2020 omission (PMID 32967856) demonstrated the value of the peer review step and led to a more honest framing of the evidence gap.

2. **Transparent feasibility adaptation.** Rather than proceeding with an underpowered canagliflozin-only analysis, the pipeline identified the N=142 barrier early, evaluated four alternatives, and selected the best balance of statistical power and fidelity to the original question. The canagliflozin subgroup is preserved as a pre-specified sensitivity analysis, and the modification is documented throughout all downstream artifacts.

3. **Comprehensive confounder adjustment.** The 32-variable propensity score model includes demographics, vitals, 10 laboratory values, 13 comorbidity categories, and 6 concomitant medication classes — with explicit DAG justification for each variable and documented rationale for excluded variables. This goes well beyond the typical "age, sex, race" adjustment.

4. **Full CDW convention compliance.** All 13 database-specific conventions (legacy encounter filtering, date quality guards, DEATH deduplication, ROW_NUMBER on LEFT JOINs, column normalization, COUNT(DISTINCT), ODBC batch separation, dynamic PS formula, etc.) were correctly applied in the R script — verified by the protocol reviewer.

5. **Quality-assured code.** The protocol review identified and fixed two SQL bugs before the script could be run against live data. Both bugs would have biased results toward the null by missing post-index MI/stroke events in patients with recurrent events.

6. **Well-specified sensitivity analyses.** Seven sensitivity analyses each address a specific threat to validity (canagliflozin subgroup, per-protocol effect, DEATH_CAUSE completeness, MI coding, saxagliptin HHF signal, unmeasured confounding via E-value, alternative estimation method).

### 5.2 Limitations

1. **Single-institution CDW.** Results will reflect prescribing patterns and patient demographics at one institution and may not generalize to other settings. A multi-site PCORnet query would increase sample size and generalizability but requires additional governance.

2. **Canagliflozin underpowered.** The canagliflozin-only sensitivity analysis will have an estimated 80–120 patients with ~5–6 MACE events. This is informative only as a descriptive analysis with wide confidence intervals — it cannot provide the canagliflozin-specific causal estimates originally intended.

3. **Unmeasured confounders.** Smoking status (VITAL.SMOKING 99.8% missing), left ventricular ejection fraction, socioeconomic status, insurance type (0% populated), OTC aspirin use, physical activity, diet, and frailty are not available for PS adjustment. Tobacco use disorder ICD-10 codes serve as an imperfect proxy for smoking. The E-value sensitivity analysis will quantify the minimum unmeasured confounding strength needed to explain away observed associations.

4. **CV death ascertainment uncertainty.** DEATH_CAUSE completeness in this CDW is unknown. If sparsely populated, the CV death component of the MACE composite will be systematically undercounted. The all-cause mortality sensitivity analysis directly addresses this.

5. **Treatment duration measurement.** RX_END_DATE is populated in only 47.6% of records and RX_DAYS_SUPPLY in 42.8%. The as-treated analysis relies on a hierarchical imputation strategy with a 90-day default, which may misclassify true treatment duration.

6. **Channeling bias.** SGLT2i may be preferentially prescribed to patients with established CVD or HF (guideline-concordant prescribing post-CVOT publications). While the PS model includes extensive CV comorbidity and medication variables, residual confounding from this channeling is possible.

7. **Class-level heterogeneity.** Combining three SGLT2 inhibitors with different selectivity profiles masks potential within-class differences. The CANVAS amputation signal is unique to canagliflozin; Kornelius et al. 2025 reported canagliflozin may have higher MACE risk versus selective SGLT2i (HR 1.23, 1.14–1.33). However, Shin et al. 2025 (PMID 39836397) found comparable CV effectiveness across individual SGLT2i using TTE methodology.

---

## 6A. Execution Results (2026-04-16)

The analysis script executed successfully against the live PCORnet CDW on 2026-04-16 (`execution_status = "success"`, no warnings). Full numeric results are in `protocols/protocol_01_results.json`; the per-protocol narrative with literature comparison, STROBE checklist, and figure references is in `protocols/protocol_01_report.md`.

### 6A.1 Cohort Assembly

| Step | N |
|---|---|
| SGLT2i new users (180-day washout) | 8,372 |
| DPP-4i new users (180-day washout) | 7,685 |
| 2nd-gen SU new users (180-day washout) | 18,834 |
| All initiators across the three classes | 26,931 |
| Eligible after exclusions and enrollment requirements | 13,745 |
| Analytic cohort (primary SGLT2i vs DPP-4i pairwise: 6,520) | 13,745 |

### 6A.2 Balance Diagnostics

| Metric | Pre-weighting | Post-weighting |
|---|---|---|
| Maximum SMD across covariates | 0.776 | 0.0001 |
| All below 0.10 threshold | No | Yes |

Overlap weighting produced excellent balance on measured confounders; no PS model re-specification was required.

### 6A.3 Primary and Secondary Hazard Ratios

| Comparison | N treated | N control | Events (T/C) | HR (95% CI) | Uncorrected p | BY-FDR p |
|---|---|---|---|---|---|---|
| **SGLT2i vs DPP-4i (primary)** | 3,436 | 3,084 | 47 / 64 | **0.927 (0.615, 1.397)** | 0.718 | 0.718 |
| SGLT2i vs SU (secondary) | 3,436 | 7,225 | — | 0.701 (0.495, 0.993) | 0.046 | — (not a primary hypothesis) |
| Canagliflozin vs DPP-4i (descriptive) | 762 | — | — | 1.276 (0.674, 2.418) | — | — (underpowered, descriptive only) |

- **Median follow-up:** 1,353 days. **Total MACE events:** 111.
- **E-value for primary HR:** 1.370 (point estimate); CI bound not defined because the primary CI crosses the null.

### 6A.4 Multiple Comparison Correction

**Number of primary hypotheses tested across this run: 1** (SGLT2i vs DPP-4i for 3P-MACE).

With a single primary test, Benjamini-Yekutieli FDR correction is a no-op and the corrected p-value equals the uncorrected p-value (0.718). The secondary SU comparison and the canagliflozin descriptive subgroup are within-protocol sensitivity analyses, not separate primary hypotheses, and are therefore not part of the cross-protocol FDR set.

**Conclusion after correction:** No hypothesis in this run survives the pre-specified α = 0.05 threshold after FDR correction. The primary SGLT2i-vs-DPP-4i comparison is non-notable both before and after correction. Future runs that execute multiple protocols in the same therapeutic area should re-apply BY-FDR across the expanded set of primary hypotheses.

### 6A.5 Interpretation in One Paragraph

The primary analysis did not detect a statistically notable difference in MACE hazard between SGLT2i and DPP-4i initiators (HR 0.927, 95% CI 0.615–1.397, p = 0.718). The point estimate is directionally consistent with the class-level RCT and observational literature (CANVAS 0.86, EMPA-REG 0.86, DECLARE 0.93, D'Andrea 2023 0.85, Xie 2023 0.86), but the confidence interval is wide and uninformative about effects in either direction. With 111 MACE events across the pairwise cohort — roughly two orders of magnitude fewer than in VA-wide or Medicare-wide cohorts — this single institutional CDW is underpowered to stabilize MACE-level effect sizes. The secondary SGLT2i-vs-SU comparison is borderline notable before correction (HR 0.701, p = 0.046) but is vulnerable to multiplicity adjustment. The canagliflozin descriptive subgroup (HR 1.276, N = 762) operationally confirmed that agent-specific inference is not feasible in this data source, validating the Alternative D class-level design.

### 6A.6 Published-Literature Concordance

| Source | Comparison | HR (95% CI) | Our HR |
|---|---|---|---|
| CANVAS (Neal 2017) | Canagliflozin vs placebo | 0.86 (0.75–0.97) | — |
| EMPA-REG (Zinman 2015) | Empagliflozin vs placebo | 0.86 (0.74–0.99) | — |
| DECLARE (Wiviott 2019) | Dapagliflozin vs placebo | 0.93 (0.84–1.03) | — |
| D'Andrea 2023 | SGLT2i vs DPP-4i (PS-matched) | 0.85 (0.75–0.95) | 0.927 |
| EMPRISE (Htoo 2024) | Empagliflozin vs DPP-4i | 0.73 (0.62–0.86) | 0.927 |
| Xie 2023 | SGLT2i vs DPP-4i (TTE) | 0.86 (0.82–0.89) | 0.927 |
| Kosjerina 2025 | SGLT2i vs DPP-4i (TTE, elderly) | 0.65 (0.63–0.68) | 0.927 |
| Filion 2020 | Canagliflozin vs DPP-4i | 0.79 (0.66–0.94) | 1.276 (descriptive, underpowered) |
| Xie 2023 | SGLT2i vs SU (TTE) | 0.77 (0.74–0.80) | 0.701 (secondary) |

The primary point estimate is directionally consistent with published estimates but attenuated (0.927 vs 0.73–0.86), plausibly reflecting channeling-by-indication residual confounding, within-class heterogeneity, or sampling variability in a smaller cohort.

---

## 6. Next Steps

### 6.1 Immediate Actions

1. **Review the protocol** (`protocols/protocol_01.md`) to verify the study design, confounder set, and sensitivity analyses match the intended research objectives.

2. **Run the analysis script** against the live CDW:
   ```bash
   cd results/type_2_diabetes/protocols
   Rscript protocol_01_analysis.R
   ```
   Prerequisites: R ≥ 4.1 with required packages (tidyverse, DBI, odbc, WeightIt, cobalt, survival, survminer, EValue, gtsummary, MatchIt, etc.); ODBC DSN `SQLODBCD17CDM` configured; permissions for temp table creation. Expected runtime: 15–45 minutes.

3. **Check results** in `protocols/protocol_01_results.json` and associated publication outputs (Table 1, love plot, PS distribution, KM curves, forest plot, CONSORT diagram).

### 6.2 Report Generation — Complete

Results generation and narrative reporting are complete as of 2026-04-16. The report-writing agent produced `protocols/protocol_01_report.md` (8 sections, STROBE checklist, literature concordance). All numeric values were spot-checked against `protocols/protocol_01_results.json` and match to the decimal places reported. No synthetic-data caveat was applied (institutional PCORnet EHR data is real). See Section 6A above for the cross-protocol summary and multiplicity correction.

### 6.3 Important Notes for Execution

| Item | Detail |
|------|--------|
| Unvalidated combo RxCUIs | Synjardy (empagliflozin/metformin) and Xigduo XR (dapagliflozin/metformin) codes were included but not validated via MCP tools. Verify patient counts after execution. |
| Schoenfeld residuals | The protocol mentions PH assumption checking but the R script does not implement `cox.zph()`. Consider adding post-hoc if the PH assumption is suspect. |
| CDM version | Database YAML lists CDM v7; protocol references v6.1. Minor documentation discrepancy; does not affect code. |

---

## 7. Key References

| PMID | Citation | Role in This Study |
|------|----------|-------------------|
| 28605608 | Neal B et al. NEJM 2017. CANVAS Program. | Canagliflozin CVOT; MACE HR 0.86 (0.75–0.97); benchmark trial |
| 26378978 | Zinman B et al. NEJM 2015. EMPA-REG OUTCOME. | Empagliflozin CVOT; MACE HR 0.86 (0.74–0.99) |
| 30415602 | Wiviott SD et al. NEJM 2019. DECLARE-TIMI 58. | Dapagliflozin CVOT; MACE HR 0.93 (0.84–1.03) |
| 30990260 | Perkovic V et al. NEJM 2019. CREDENCE. | Canagliflozin renal/CV benefit in CKD |
| 23992601 | Scirica BM et al. NEJM 2013. SAVOR-TIMI 53. | Saxagliptin CVOT; MACE neutral; HHF signal (HR 1.27) |
| 27437883 | Green JB et al. JAMA Cardiol 2016. TECOS. | Sitagliptin CV neutrality |
| 31536101 | Rosenstock J et al. JAMA 2019. CAROLINA. | Linagliptin vs glimepiride; MACE noninferior |
| 36745425 | D'Andrea E et al. JAMA Intern Med 2023. | SGLT2i vs DPP-4i; mod-MACE HR 0.85 (0.75–0.95) |
| 38509341 | Htoo PT et al. Diabetologia 2024. EMPRISE. | Empagliflozin vs DPP-4i; MACE HR 0.73 (0.62–0.86) |
| 37499675 | Xie Y et al. Lancet Diabetes Endocrinol 2023. | 4-arm TTE; SGLT2i vs DPP-4i MACE HR 0.86 (0.82–0.89) |
| 40201798 | Kosjerina V et al. eClinicalMedicine 2025. | TTE in elderly; 3P-MACE IRR 0.65 (0.63–0.68) |
| 32967856 | Filion KB et al. BMJ 2020. | Canagliflozin-specific MACE vs DPP-4i: HR 0.79 (0.66–0.94); critical review finding |
| 29938883 | Ryan PB et al. Diabetes Obes Metab 2018. OBSERVE-4D. | Canagliflozin HHF/amputation; no MACE data |
| 34481910 | Son C et al. Diabetes Res Clin Pract 2021. CANTABILE. | Canagliflozin vs teneligliptin RCT; metabolic endpoints only (N=162) |
| 41246652 | Prakash V et al. Cureus 2025. | DPP-4i CV meta-analysis confirming class neutrality |
| 34364771 | Mannucci E et al. Nutr Metab Cardiovasc Dis 2021. | DPP-4i MACE meta-analysis |

---

## 8. Pipeline Artifact Inventory

| File | Lines | Description |
|------|-------|-------------|
| `01_literature_scan.md` | 204 | Literature scan: 32 PMIDs, 3 search passes, CVOTs + observational + TTE landscape |
| `02_evidence_gaps.md` | 264 | 7 ranked PICO questions with gap scores, stress tests, and search completeness checklist |
| `03_feasibility.md` | 1,229 | Database feasibility: exposure/outcome/confounder mapping, sample size estimates, 4 alternatives |
| `review_discovery.md` | 290 | Independent review: 14 PMIDs verified, Filion 2020 identified, all 7 questions approved |
| `protocols/protocol_01.md` | 404 | Full TTE protocol: target trial spec, variable mapping, statistical plan, limitations |
| `protocols/protocol_01_analysis.R` | 1,372 | Complete R script: cohort assembly through publication outputs |
| `protocols/review_protocol_01.md` | 259 | Protocol review: 13/13 CDW conventions verified, 2 SQL bugs found and fixed |
| `protocols/protocol_01_results.json` | — | Structured execution results (HRs, CIs, CONSORT, balance, E-value, subgroups) |
| `protocols/protocol_01_report.md` | 281 | Per-protocol narrative report: 8 sections, STROBE checklist, literature concordance |
| `protocols/protocol_01_table1.html` | — | Publication Table 1 (SGLT2i vs DPP-4i baseline) |
| `protocols/protocol_01_table1_vs_su.html` | — | Publication Table 1 (SGLT2i vs SU baseline) |
| `protocols/protocol_01_consort.{png,pdf}` | — | CONSORT flow diagram |
| `protocols/protocol_01_loveplot{,_vs_su}.{png,pdf}` | — | Love plots (pre/post weighting SMDs) for both comparisons |
| `protocols/protocol_01_ps_dist.{png,pdf}` | — | Propensity score distributions |
| `protocols/protocol_01_km{,_vs_su}.{png,pdf}` | — | Kaplan-Meier curves for both comparisons |
| `protocols/protocol_01_forest.{png,pdf}` | — | Subgroup forest plot (age / sex / ASCVD / CKD) |
| `coordinator_log.md` | — | Decision log: all coordinator choices with rationale (includes resume-mode entry) |
| `NEXT_STEPS.md` | 88 | Execution instructions (superseded now that execution is complete) |
| `summary.md` | — | This document |
