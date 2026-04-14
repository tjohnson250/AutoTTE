# Executive Summary: Atrial Fibrillation Target Trial Emulation Run

**Therapeutic area:** Atrial fibrillation
**Database:** PCORnet Synthetic CDW (`synthetic_pcornet`) — 500 synthetic patients, PCORnet v6.0, DuckDB
**Run date:** 2026-04-13
**Protocols executed:** 1 (methodological demonstration)
**Primary hypotheses tested:** 1 (no multiple comparison correction required)

> **Synthetic Data Caveat:** This run used a small synthetic database generated
> for methodological testing. All 500 patient records are artificially
> generated. Associations between variables do not reflect real biological or
> clinical relationships. **Effect estimates have no clinical validity.** This
> summary documents the system's ability to execute the full TTE pipeline
> end-to-end against a PCORnet-formatted database, not the clinical findings.

---

## 1. Run Overview

The Auto-Protocol Designer system was deployed against the atrial fibrillation
therapeutic area using the PCORnet Synthetic CDW, a 500-patient DuckDB database
in PCORnet v6.0 format. The system executed all pipeline phases: data source
onboarding, literature discovery, evidence gap ranking, feasibility assessment,
protocol generation, R script execution, and per-protocol reporting.

**Key decision point:** All five literature-derived causal questions were
infeasible against this database. The coordinator pivoted to an alternative
question identified from available data — metoprolol initiation in AF with
heart failure — to complete a methodological demonstration of the pipeline.

---

## 2. Literature Discovery

A three-pass literature search identified **82 unique PMIDs** across 8 broad
landscape searches and 10 targeted PICO-specific searches, with citation
chaining for the top 3 questions.

**Key findings:**
- 18 RCTs, 32 observational comparative effectiveness studies, 18 meta-analyses/systematic reviews, and 7 existing TTE studies in AF were identified
- The existing 7 AF TTE studies cover: digoxin vs. beta-blockers (Liu 2025), DOACs vs. warfarin in cancer (Truong 2024, 2025), antithrombotic management (Prunel 2025), suicide risk with OACs (Li 2024), OAC resumption after subdural hematoma (Anno 2024), and anticoagulation after sepsis-onset AF (Walkey 2023)
- No existing TTE addresses any of the top 4 ranked evidence gaps

**Discovery review verdict: ACCEPT.** An independent reviewer verified 15 PMIDs
(13 accurate, 2 minor description errors not affecting conclusions), confirmed
all "no TTE exists" claims via independent PubMed and WebSearch searches, and
validated the self-consistency check.

---

## 3. Evidence Gaps

Five causal questions were ranked by evidence gap score:

| Rank | Question | Gap Score | Existing TTE? |
|------|----------|-----------|---------------|
| 1 | Early rhythm control vs. rate control in newly diagnosed AF (EAST-AFNET 4 emulation) | 8/10 | No |
| 2 | Catheter ablation vs. antiarrhythmic drugs in AF + HFpEF | 8/10 | No |
| 3 | Apixaban vs. rivaroxaban in AF + advanced CKD (eGFR < 30) | 7/10 | No |
| 4 | DOACs vs. warfarin in AF + liver cirrhosis | 7/10 | No |
| 5 | DOACs (apixaban vs. rivaroxaban) in AF + active cancer | 5/10 | Yes (DOACs-as-class vs. warfarin only) |

**Q1 (Early rhythm vs. rate control)** has the strongest TTE rationale: EAST-AFNET 4 provides a clear target trial protocol, multiple real-world validations exist (Dickow 2023, Chao 2022, Gu 2024 meta-analysis), but no study has applied the formal TTE framework with explicit handling of immortal time bias, per-protocol effects via clone-censor-weight, or US claims/EHR replication of this European RCT.

**Q2 (Ablation vs. AADs in HFpEF)** addresses a question with no completed RCT (CABA-HFPEF-DZHK27 results expected 2027-2028) and strong observational signals (DeLuca 2025: mortality HR 0.43) that have not been analyzed via TTE.

---

## 4. Feasibility Findings

All five literature-derived questions were **NOT FEASIBLE** against synthetic_pcornet.

**Root cause:** The synthetic database was generated with siloed clinical profiles
(cardiac, diabetic, respiratory, mental health, multimorbid, healthy). The cardiac
profile (50 AF patients) includes only common chronic disease medications and
diagnoses:

| Missing Data Category | Impact |
|-----------------------|--------|
| **No anticoagulants** (DOACs, warfarin) — 0 prescriptions | Blocks Q1, Q3, Q4, Q5 |
| **No antiarrhythmic drugs** (amiodarone, flecainide, sotalol) — 0 prescriptions | Blocks Q1, Q2 |
| **No ablation procedures** (CPT 93653-93657) — 0 procedures | Blocks Q2 |
| **No comorbidity crossover** — 0 AF patients with CKD, cirrhosis, or cancer | Blocks Q3, Q4, Q5 |
| **No stroke or bleeding outcomes** — 0 events | Blocks all 5 questions |

**Coordinator pivot:** An alternative question was identified from available data:

> **Q-Alt: Effect of metoprolol initiation (vs. no beta-blocker) on HF hospitalization in AF + HF patients**

This leveraged the 50 AF+HF patients (29 with metoprolol, 21 without beta-blocker), the only constructable exposure contrast and outcome in the database. It was advanced as a **methodological demonstration only**.

---

## 5. Protocol Execution Results

### Protocol 01: Metoprolol Initiation in AF+HF → HF Hospitalization

**Design:** Target trial emulation with IPW-weighted logistic regression for binary outcome (HF hospitalization yes/no). Time zero at first AF diagnosis. ATE estimand.

**Cohort:** 43 patients after excluding 7 with non-metoprolol beta-blockers (29 treated, 14 control).

**Propensity score model:** `treatment ~ dm + hld + hdl` (only 3 covariates retained sufficient variability; most planned confounders were near-uniform in this synthetic sample).

**Balance:** Post-weighting maximum SMD improved from 1.113 to 0.219 (below 0.1 threshold not achieved; HDL remained imbalanced).

| Measure | Result |
|---------|--------|
| IPW-weighted OR | **0.493** (95% CI: 0.200–1.219) |
| P-value | 0.126 |
| Risk — metoprolol | 29.0% (8/29) |
| Risk — no beta-blocker | 45.2% (6/14) |
| Risk difference | **-16.3 percentage points** |
| Crude OR | 0.508 (95% CI: 0.134–1.931) |
| E-value | CI crosses 1.0; E-value for lower limit = 1.0 |

**Interpretation:** The point estimate suggests a direction toward lower HF hospitalization with metoprolol, but the result is not statistically significant. The wide confidence interval (spanning 80% reduction to 22% increase in odds) reflects severe imprecision from the sample size of 43. The crude and adjusted ORs are nearly identical, suggesting limited measured confounding. **No clinical inference should be drawn.** Critical unmeasured confounders (LVEF) and synthetic data invalidate any clinical interpretation.

**Pipeline outputs produced:**
- CONSORT flow diagram (PDF)
- Table 1 — baseline characteristics (HTML)
- Love plot — covariate balance (PDF)
- Propensity score distribution plot (PDF)
- Structured results (JSON)
- Per-protocol report with STROBE compliance checklist

---

## 6. Methodological Assessment

### What Worked

1. **End-to-end pipeline execution.** The system completed all phases from literature search through R script execution and report generation against a real CDM structure, demonstrating that the automated TTE pipeline is functional on PCORnet v6.0 data.

2. **Literature discovery depth.** The three-pass search (broad, targeted PICO, citation chaining) with 82 PMIDs and independent WebSearch verification of methodology claims produced a thorough, reviewer-validated evidence landscape.

3. **Feasibility honesty.** Rather than forcing an infeasible analysis, the system correctly identified all 5 original questions as infeasible with specific blocking reasons and transparent root cause analysis.

4. **Adaptive decision-making.** The coordinator's pivot to an alternative question preserved pipeline demonstration value while prominently documenting the synthetic data limitation at every stage.

5. **Code validation.** Clinical codes (ICD-10-CM for AF/HF, RxNorm for metoprolol and other beta-blockers) were validated via MCP tools against authoritative code sets before use in the protocol.

### What Didn't Work

1. **Database-question mismatch.** The synthetic database's 27-drug formulary lacks every medication class relevant to AF research (anticoagulants, antiarrhythmics, digoxin). This made the entire literature-derived question set unusable.

2. **Residual covariate imbalance.** Post-weighting SMD of 0.219 exceeded the 0.1 threshold. With only 3 covariates in the PS model (out of 15+ planned), the IPW could not fully adjust for confounding.

3. **E-value computation.** The sensitivity analysis for unmeasured confounding failed due to a subscript-out-of-bounds error in the `EValue` package when the CI crosses 1.0. This is a known edge case that should be handled gracefully.

4. **Near-uniform covariate distributions.** Synthetic data with identical comorbidity profiles (100% HTN, 98% CAD, 88% HLD among AF patients) caused most planned confounders to be dropped from the PS model, undermining the causal inference framework.

### Lessons Learned

- **Database selection is the most critical decision.** A database must contain the treatments, outcomes, and comorbidity overlap relevant to the research question. Feasibility assessment should ideally occur before literature discovery to avoid wasted effort, or the system should support early "data inventory" checks.
- **Synthetic databases are useful for pipeline testing but fundamentally cannot validate the causal inference methodology** — they lack the real-world correlation structure between treatments, confounders, and outcomes that IPW is designed to address.
- **Small-sample TTE requires aggressive formula simplification.** The dynamic PS formula construction (dropping zero-variance and single-level factors) was essential and should be standard practice.

---

## 7. Recommendations for Real-World Application

The five literature-derived evidence gaps identified in this run represent genuine, reviewer-verified research opportunities. To execute these protocols with clinically meaningful results, the following database characteristics are needed:

### Recommended Databases by Question

| Question | Required Data | Recommended Database Types |
|----------|--------------|---------------------------|
| **Q1: Early rhythm vs. rate control** | AAD prescriptions, ablation CPTs, stroke/CV death outcomes, ≥12 months follow-up from AF diagnosis | Large US claims (Optum, MarketScan, Medicare) or EHR (PCORnet clinical sites, VA CDW) |
| **Q2: Ablation vs. AADs in AF+HFpEF** | Ablation CPTs, AAD Rx, LVEF/echo data for HFpEF definition, HF hospitalization outcomes | EHR with structured echo data (VA CDW, PCORnet sites with cardiology data, TriNetX) |
| **Q3: Apixaban vs. rivaroxaban in CKD** | DOAC Rx, eGFR labs, bleeding/stroke outcomes | EHR-linked claims with lab results (PCORnet clinical sites, OneFlorida+, VA CDW) |
| **Q4: DOACs vs. warfarin in cirrhosis** | OAC Rx, cirrhosis ICD codes + liver function labs (bilirubin, albumin, INR), bleeding/stroke outcomes | EHR with hepatology data (VA CDW, PCORnet sites, TriNetX) |
| **Q5: Apixaban vs. rivaroxaban in cancer** | DOAC Rx, cancer staging, bleeding outcomes | Cancer registry-linked claims (SEER-Medicare) or EHR (PCORnet oncology sites) |

### Minimum Database Requirements

For any of these questions:
- **Sample size:** ≥5,000 AF patients with the relevant comorbidity to achieve adequate statistical power
- **Medication data:** Prescription or dispensing records with RxNorm coding for DOACs/AADs
- **Outcome data:** ICD-coded stroke (I63.x), bleeding (D62, K25-K28, K92.x, I61.x), and death with cause
- **Temporal resolution:** Dated diagnoses, prescriptions, and encounters to define time zero and follow-up
- **Lab data (Q2-Q4):** eGFR, LVEF, liver function tests for population definition and confounder adjustment

---

## Synthetic Data Caveat

This entire run was conducted on the **PCORnet Synthetic CDW**, a 500-patient
database generated for methodological testing purposes. Key implications:

- **No clinical validity.** All effect estimates, confidence intervals, and
  p-values are artifacts of synthetic data generation, not reflections of real
  treatment effects.
- **No biological plausibility.** The synthetic cohort has a mean age of 22
  years for AF+HF patients (real-world median > 70 years), 100% comorbidity
  overlap, and no clinically relevant medications (anticoagulants,
  antiarrhythmics).
- **Pipeline validation only.** This run demonstrates that the Auto-Protocol
  Designer can: (a) conduct systematic literature discovery, (b) identify and
  rank evidence gaps, (c) assess database feasibility, (d) generate executable
  TTE protocols with validated clinical codes, (e) run R analysis scripts
  against PCORnet CDM data, and (f) produce publication-quality outputs
  (CONSORT diagrams, Table 1, balance diagnostics, effect estimates).
- **The five evidence gaps identified are real.** The literature discovery and
  gap ranking are independent of the database and represent genuine TTE
  opportunities in atrial fibrillation research. These questions should be
  pursued against appropriately sized real-world databases.
