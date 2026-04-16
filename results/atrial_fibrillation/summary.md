# Executive Summary: Atrial Fibrillation Target Trial Emulation

**Multi-DB Run** | Databases: synthetic_pcornet (PCORnet Synthetic CDW), nhanes (NHANES)
**Date:** 2026-04-14 | **Coordinator pipeline version:** multi-DB phase-major

---

## Overview

This run applied the target trial emulation (TTE) pipeline to **atrial fibrillation**
across two databases: the PCORnet Synthetic CDW (a 500-patient test dataset) and
NHANES (a nationally representative cross-sectional survey). The pipeline completed
all phases through execution and reporting, producing one protocol with results
from NHANES.

**Key finding:** Neither database was feasible for the original high-priority TTE
questions (DOAC comparisons, ablation, anticoagulation in CKD/liver disease). A
pivot to an alternative prevalent-user design in NHANES yielded a null result
(HR = 1.07, p = 0.84) for DOAC vs warfarin and all-cause mortality in CKD, which
is expected given the design's severe limitations. The primary value of this run
is demonstrating the pipeline's ability to navigate infeasibility and produce
methodologically honest analyses with appropriate caveats.

---

## Phase 1: Literature Discovery

### Search Strategy
- Three-pass search: 8 broad landscape queries, 5 targeted PICO-specific queries,
  citation chaining + WebSearch verification
- **49 unique PMIDs** cited (17 RCTs, 21 observational/cohort, 11 TTE studies,
  4 meta-analyses, 6 RCT subanalyses)

### Top Candidate Questions (Approved)

| Rank | Question | Gap Score |
|------|----------|:---------:|
| 1 | Apixaban vs rivaroxaban in AF + advanced CKD (stages 4-5) | 8 |
| 2 | Catheter ablation vs AADs in AF + HFpEF | 8 |
| 3 | DOACs vs warfarin in AF + liver cirrhosis | 8 |
| 4 | Early rhythm control vs usual care in AF + HF | 7 |
| 5 | LAAC vs continued anticoag in AF + dialysis | 6 |
| 6 | Appropriate vs inappropriate DOAC dose reduction in elderly | 6 |

**Review findings:** Reviewer identified 3 errors (Liu 2025 direction reversed,
missed TTE PMID 36252244, CLOSURE-AF mischaracterized). All corrected by coordinator.
Top 3 recommendations unchanged.

---

## Phase 2: Feasibility

### synthetic_pcornet (PCORnet Synthetic CDW) — INFEASIBLE

| Metric | Value |
|--------|-------|
| Total patients | 500 |
| AF patients | 50 |
| DOACs/warfarin | 0 |
| Advanced CKD | 0 |
| HFpEF/HFrEF | 0 |
| Cirrhosis | 0 |
| Stroke/bleeding events | 0 |

**Verdict:** All 6 questions infeasible. The 500-patient synthetic dataset lacks
all key exposures, subpopulations, and outcomes. Suitable only for pipeline testing.
**Dropped from later phases.**

### nhanes (NHANES) — INFEASIBLE for original questions; PIVOT to alternative

| Metric | Value |
|--------|-------|
| Adults examined (3 cycles) | 17,192 |
| Anticoagulant users (total) | 421 |
| — Warfarin | 258 |
| — Apixaban | 69 |
| — Rivaroxaban | 66 |
| AC users with eGFR < 60 | ~130 |
| AC users with eGFR < 30 | ~12 |

**Verdict:** All 6 original TTE questions infeasible (cross-sectional survey, no
longitudinal follow-up for time-to-event outcomes). NHANES lacks AF diagnosis,
procedure codes, and medication doses.

**Pivot:** Prevalent anticoagulant use (DOAC vs warfarin) → all-cause mortality
in CKD subgroups using NHANES mortality linkage (NDI, through 12/31/2019). This
is a Category A TTE with severe prevalent-user caveats.

### Cross-DB Replication

No questions were feasible on ≥2 databases. No cross-DB replication analysis
was possible.

---

## Phase 3: Protocol Generation

### NHANES Protocol 01: DOAC vs Warfarin → All-Cause Mortality in CKD

**Design:** Prevalent-user cohort, NHANES 2013-2018 pooled (3 cycles)

| Element | Specification |
|---------|--------------|
| Population | US adults on OAC with eGFR < 60 (CKD-EPI 2021 race-free) |
| Exposure | Current DOAC (apixaban/rivaroxaban/dabigatran) vs current warfarin |
| Outcome | All-cause mortality (NDI linkage through 12/31/2019) |
| Time zero | NHANES MEC examination date (NOT treatment initiation) |
| Estimand | ATE via survey-weighted IPW Cox PH |
| Confounders | Age, sex, race/ethnicity, eGFR, BMI, income, HbA1c, cholesterol, HDL, CHF, CHD, MI, stroke, diabetes, hypertension, smoking |

**Review:** 3 MUST FIX corrections applied (eGFR 1.012 female multiplier, income
in PS model, MI history in confounder table). 2 SHOULD FIX applied (unused survey
design object removed, E-value rare flag made conditional).

---

## Phase 4: Execution Results

### CONSORT Flow

| Step | Description | N |
|------|-------------|--:|
| 1 | US adults examined (MEC), 3 cycles 2013-2018 | 17,192 |
| 2 | On oral anticoagulant (DOAC or warfarin, excl. dual) | 391 |
| 3 | Serum creatinine available for eGFR | 361 |
| 4 | eGFR < 60 mL/min/1.73m² (CKD stage 3-5) | 130 |
| 5 | Linked mortality follow-up available (ELIGSTAT=1) | 129 |
| 6 | Complete data for analysis | **125** |
| | — DOAC arm | 46 |
| | — Warfarin arm | 79 |

### Primary Analysis

| Metric | Value |
|--------|-------|
| Effect measure | Hazard ratio (Cox PH) |
| HR (DOAC vs warfarin) | **1.07** |
| 95% CI | 0.57 – 2.02 |
| p-value | 0.84 |
| Total deaths | 53 |
| Deaths (DOAC arm) | 14 |
| Deaths (warfarin arm) | 39 |
| Median follow-up | 30 months |

### Balance Diagnostics

| Metric | Value |
|--------|-------|
| Max SMD (pre-weighting) | 1.056 |
| Max SMD (post-weighting) | 0.125 |
| All covariates < 0.1 | No (1 covariate slightly above) |

### Sensitivity Analyses

| Analysis | HR | 95% CI |
|----------|:--:|--------|
| IPW-adjusted (primary) | 1.07 | 0.57 – 2.02 |
| Unadjusted (survey-only) | 1.19 | 0.60 – 2.37 |
| E-value (point estimate) | 1.27 | — |
| E-value (CI bound) | 1.00 | — |

### Multiple Comparison Correction

Only one primary hypothesis was tested in this run. Benjamini-Yekutieli FDR
correction is not applicable. The single p-value (0.84) is well above any
reasonable significance threshold.

### Interpretation

The null result (HR ≈ 1.0 with wide confidence intervals spanning 0.57-2.02)
is **expected and should not be interpreted as evidence of no difference**
between DOACs and warfarin for mortality in CKD. The study is fundamentally
limited by:

1. **Prevalent-user bias:** Comparing survivors of each treatment, not new
   initiators. Early adverse events are invisible.
2. **No AF ascertainment:** NHANES has no AF diagnosis variable. The cohort
   includes all anticoagulant users with CKD, regardless of indication.
3. **Cross-sectional exposure:** Medication captured at a single time point
   with no duration, switching, or adherence data.
4. **Small sample size:** 125 patients (46 DOAC, 79 warfarin) is well below
   the minimum for robust propensity score analyses.
5. **Low E-value (1.27):** Even modest unmeasured confounding could explain
   the observed association.

---

## Publication Outputs

### NHANES Protocol 01

| Output | File |
|--------|------|
| Protocol | `nhanes/protocols/protocol_01.md` |
| R analysis script | `nhanes/protocols/protocol_01_analysis.R` |
| Results JSON | `nhanes/protocols/protocol_01_results.json` |
| Report | `nhanes/protocols/protocol_01_report.md` |
| Baseline characteristics | `nhanes/protocols/protocol_01_table1.html` |
| Covariate balance (love plot) | `nhanes/protocols/protocol_01_loveplot.pdf` |
| PS distribution | `nhanes/protocols/protocol_01_ps_dist.pdf` |
| KM survival curves | `nhanes/protocols/protocol_01_km.pdf` |
| CONSORT diagram | `nhanes/protocols/protocol_01_consort.pdf` |

---

## Database Summary

| Database | Disposition | Status | Protocols | Notes |
|----------|:----------:|--------|:---------:|-------|
| synthetic_pcornet | RUN | **Failed (infeasible)** | 0 | 500-patient test dataset |
| nhanes | RUN | **Completed** | 1 | Prevalent-user alternative; null result |

---

## Pipeline Statistics

| Metric | Value |
|--------|-------|
| Total sub-agents launched | 10 |
| Discovery workers | 2 (1 ran out of turns) |
| Discovery reviewers | 1 |
| Feasibility workers | 2 (1 per DB) |
| Protocol workers | 1 |
| Protocol reviewers | 1 |
| Execution workers | 2 (1 failed, 1 succeeded) |
| Report writers | 1 |
| Backtracks | 0 |
| Total revision cycles | 0 |

---

## Recommendations

1. **For the atrial fibrillation TTE questions identified in this run:**
   The 6 approved questions (especially Q1-Q3) are best addressed using
   longitudinal claims or EHR databases with:
   - ≥100,000 AF patients for adequate subgroup sizes
   - Complete DOAC/warfarin prescribing with fill dates and doses
   - Procedure codes (ablation, LAAC)
   - Lab data (eGFR, liver function) for severity staging
   - Incident outcome events (stroke, bleeding, hospitalization, mortality)
   
   Recommended data sources: Medicare claims (CMS), Optum/MarketScan,
   VA CDW, or a full-scale PCORnet CDW.

2. **For this NHANES analysis:**
   The prevalent-user result (HR = 1.07) should not be cited as evidence
   about DOAC vs warfarin effectiveness. It demonstrates that the TTE
   pipeline can process survey data with honest design caveats. The NHANES
   cohort characterization (nationally representative anticoagulant use
   patterns by CKD stage) may complement future claims-based TTE studies
   as a descriptive reference.

3. **For the synthetic PCORnet CDW:**
   Continue using this dataset for pipeline testing and R script validation.
   It is not suitable for any clinical research protocol.
