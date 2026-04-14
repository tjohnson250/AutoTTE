# Protocol 01: Beta-Blocker (Metoprolol) Initiation in AF + HF → HF Hospitalization

**Database:** PCORnet Synthetic CDW (`synthetic_pcornet`)
**CDM:** PCORnet v6.0 | **Engine:** DuckDB
**Date:** 2026-04-13

---

## 1. Clinical Context

Heart failure (HF) and atrial fibrillation (AF) frequently coexist, sharing
risk factors including hypertension, diabetes, and coronary artery disease.
Beta-blockers are guideline-recommended for HF with reduced ejection fraction
(HFrEF) to reduce mortality and hospitalization (ACC/AHA Class I
recommendation). However, the role of beta-blockers in AF with concurrent HF
is more nuanced. The AF-CHF trial (Roy et al., NEJM 2008) showed no mortality
benefit from rhythm control over rate control in AF+HF. More recently, Liu
et al. (BMC Med 2025, PMID 41121356) applied target trial emulation to compare
digoxin vs. beta-blockers for rate control in AF+HF, finding digoxin
associated with higher all-cause mortality.

Metoprolol succinate is the most commonly prescribed beta-blocker for HF
(based on MERIT-HF evidence) and is frequently used for rate control in AF.
Despite this, no target trial emulation has specifically examined the causal
effect of metoprolol initiation on HF hospitalization in patients with
co-occurring AF and HF using real-world data.

**This protocol is a methodological demonstration using synthetic data
(n=50). Results have no clinical validity.**

---

## 2. Target Trial Specification

### 2.1 Eligibility Criteria

| Criterion | Definition | Codes |
|-----------|-----------|-------|
| Age | ≥18 years at time zero | `DEMOGRAPHIC.BIRTH_DATE` |
| AF diagnosis | ≥1 ICD-10-CM diagnosis of atrial fibrillation | I48.0, I48.11, I48.19, I48.20, I48.21, I48.91 |
| HF diagnosis | ≥1 ICD-10-CM diagnosis of heart failure (any type) | I50.1, I50.20–I50.23, I50.30–I50.33, I50.40–I50.43, I50.810–I50.814, I50.82–I50.84, I50.89, I50.9 |
| Exclusion | Patients prescribed a non-metoprolol beta-blocker (contaminates comparator) | RxNorm: 8787 (propranolol), 1202 (atenolol), 20352 (carvedilol), 19484 (bisoprolol), 31555 (nebivolol), 7442 (nadolol), 6185 (labetalol), 9947 (sotalol) — unless also prescribed metoprolol |

**ICD-10-CM AF codes (validated via MCP `search_icd10`):**
- I48.0 — Paroxysmal atrial fibrillation
- I48.11 — Longstanding persistent atrial fibrillation
- I48.19 — Other persistent atrial fibrillation
- I48.20 — Chronic atrial fibrillation, unspecified
- I48.21 — Permanent atrial fibrillation
- I48.91 — Unspecified atrial fibrillation

**ICD-10-CM HF codes (validated via MCP `search_icd10`):**
- I50.1 — Left ventricular failure
- I50.20–I50.23 — Systolic (congestive) HF
- I50.30–I50.33 — Diastolic (congestive) HF
- I50.40–I50.43 — Combined systolic and diastolic HF
- I50.810–I50.814 — Right heart failure
- I50.82 — Biventricular HF
- I50.83 — High output HF
- I50.84 — End stage HF
- I50.89 — Other HF
- I50.9 — Heart failure, unspecified

### 2.2 Treatment Strategies

| Arm | Definition |
|-----|-----------|
| **Intervention** | Initiation of metoprolol (any salt/formulation) within 180 days of time zero. RxNorm ingredient CUI: 6918. Full product set (SCD+SBD): 36 codes including metoprolol succinate ER tablets (866412, 866419, 866427, 866436), capsules (1999031, 1999033, 1999035, 1999037), and metoprolol tartrate IR tablets (866511, 866514, 866924), branded forms (Toprol-XL, Kapspargo, Lopressor). In this synthetic database, prescriptions are stored at the ingredient level (RXNORM_CUI = '6918'). |
| **Comparator** | No beta-blocker therapy at any time. Patients must have no prescription for any beta-blocker (metoprolol, propranolol, atenolol, carvedilol, bisoprolol, nebivolol, nadolol, labetalol, sotalol). |

**Grace period:** 180 days from time zero. This accommodates clinical reality
where beta-blocker initiation may be deferred until HF is stabilized.

### 2.3 Assignment Procedure

Patients are assigned to treatment strategies based on observed prescribing
patterns (emulated randomization). Confounding is addressed via inverse
probability weighting (IPW) to emulate the randomization that would occur
in the target trial.

### 2.4 Outcome Definition

**Primary outcome:** Heart failure hospitalization, defined as an inpatient
encounter (`ENCOUNTER.ENC_TYPE = 'IP'`) with a concurrent HF diagnosis
(any I50.x code in `DIAGNOSIS` linked to the same `ENCOUNTERID`), occurring
after time zero.

This is operationalized as a **binary outcome** (any HF hospitalization
yes/no during follow-up) rather than time-to-event, given the extremely
small sample size (n≈43) which precludes reliable hazard estimation.

### 2.5 Time Zero

**First AF diagnosis date** for each patient: the earliest `DX_DATE` in
`DIAGNOSIS` where `DX LIKE 'I48%' AND DX_TYPE = '10'`. This anchors the
study at the clinical event that triggers consideration of rate-control
therapy.

### 2.6 Causal Contrast and Estimand

**Estimand:** Average Treatment Effect (ATE) — the causal risk difference
for HF hospitalization comparing a world where all eligible patients
initiate metoprolol vs. a world where none do.

**Justification:** ATE is appropriate because we seek the population-level
effect of a treatment policy (metoprolol initiation for all AF+HF patients),
not just the effect among those who actually received it (ATT). This aligns
with the policy-relevant question: "Should metoprolol be initiated in all
AF+HF patients?"

**Effect measure:** Risk difference (RD) from IPW-weighted logistic
regression, with odds ratio (OR) as a secondary measure.

---

## 3. Emulation Using Observational Data

### 3.1 Target Dataset

**PCORnet Synthetic CDW** (`synthetic_pcornet`), a DuckDB database containing
500 synthetic patients in PCORnet v6.0 CDM format. This database was
generated for methodological testing and does not represent real patient
data.

### 3.2 Variable Mapping

| Protocol Concept | Table.Column | Notes |
|-----------------|-------------|-------|
| Patient ID | `DEMOGRAPHIC.PATID` | Universal key |
| Age at time zero | Derived: `first_af_date - DEMOGRAPHIC.BIRTH_DATE` | In years |
| Sex | `DEMOGRAPHIC.SEX` | F, M |
| Race | `DEMOGRAPHIC.RACE` | PCORnet codes (01–07) |
| Hispanic ethnicity | `DEMOGRAPHIC.HISPANIC` | Y, N, NI |
| AF diagnosis | `DIAGNOSIS.DX LIKE 'I48%'` | `DX_TYPE = '10'` |
| HF diagnosis | `DIAGNOSIS.DX LIKE 'I50%'` | `DX_TYPE = '10'` |
| Metoprolol Rx | `PRESCRIBING.RXNORM_CUI = '6918'` | Ingredient-level CUI |
| Any beta-blocker Rx | `PRESCRIBING.RXNORM_CUI IN (...)` | 9 BB ingredient CUIs |
| HTN comorbidity | `DIAGNOSIS.DX = 'I10'` | Essential hypertension |
| DM comorbidity | `DIAGNOSIS.DX LIKE 'E11%'` | Type 2 diabetes |
| CAD comorbidity | `DIAGNOSIS.DX LIKE 'I25%'` | Chronic ischemic heart disease |
| HLD comorbidity | `DIAGNOSIS.DX LIKE 'E78%'` | Disorders of lipoprotein metabolism |
| Systolic BP | `VITAL.SYSTOLIC` | Closest to time zero |
| Diastolic BP | `VITAL.DIASTOLIC` | Closest to time zero |
| BMI | `VITAL.ORIGINAL_BMI` | Closest to time zero |
| Smoking status | `VITAL.SMOKING` | PCORnet codes |
| Statin use | `PRESCRIBING.RXNORM_CUI = '83367'` | Atorvastatin (only statin in DB) |
| ACE inhibitor use | `PRESCRIBING.RXNORM_CUI = '29046'` | Lisinopril |
| Antiplatelet use | `PRESCRIBING.RXNORM_CUI = '1191'` | Aspirin |
| CCB use | `PRESCRIBING.RXNORM_CUI = '435'` | Amlodipine |
| Loop diuretic use | `PRESCRIBING.RXNORM_CUI = '7646'` | Furosemide |
| CRP (baseline) | `LAB_RESULT_CM.LAB_LOINC = '30522-7'` | hs-CRP, Mass/vol in Serum/Plasma |
| Troponin I (baseline) | `LAB_RESULT_CM.LAB_LOINC = '10839-9'` | Cardiac troponin I, Mass/vol |
| Total cholesterol | `LAB_RESULT_CM.LAB_LOINC = '2093-3'` | Mass/vol in Serum/Plasma |
| LDL cholesterol | `LAB_RESULT_CM.LAB_LOINC = '13457-7'` | Calculated, Serum/Plasma |
| HDL cholesterol | `LAB_RESULT_CM.LAB_LOINC = '2085-9'` | Mass/vol in Serum/Plasma |
| Triglycerides | `LAB_RESULT_CM.LAB_LOINC = '2571-8'` | Mass/vol in Serum/Plasma |
| HF hospitalization (outcome) | `ENCOUNTER.ENC_TYPE = 'IP'` + `DIAGNOSIS.DX LIKE 'I50%'` | Post-time-zero, same encounter |

### 3.3 Emulation of Protocol Elements

**Eligibility:** Identify patients with both AF (I48.x) and HF (I50.x)
diagnoses in `DIAGNOSIS`, aged ≥18 at first AF date.

**Treatment assignment:** Metoprolol initiation determined from
`PRESCRIBING.RXNORM_CUI = '6918'`. Patients with only non-metoprolol
beta-blockers are excluded to maintain a clean comparator.

**Follow-up:** Begins at time zero (first AF diagnosis). Follow-up end
is the earliest of: HF hospitalization, death (`DEATH.DEATH_DATE`), or
administrative end (last encounter date).

**Outcome ascertainment:** Inpatient encounters with a linked HF diagnosis
code, occurring after time zero.

---

## 4. Statistical Analysis Plan

### 4.1 Primary Analysis

**Method:** Inverse probability weighting (IPW) with logistic regression
for the binary outcome (HF hospitalization yes/no).

**Justification:** IPW is the standard approach for TTE with a binary
treatment. Given n≈43, we use logistic regression rather than Cox
proportional hazards because:
1. The sample is too small for reliable hazard estimation
2. Binary outcome simplifies interpretation
3. Avoids proportional hazards assumption with too few events

### 4.2 Confounder Identification

Confounders are selected based on domain knowledge (common causes of both
beta-blocker prescribing and HF hospitalization):

**DAG reasoning:**
- **Age, sex, race:** Demographics that influence prescribing patterns and
  HF severity
- **HTN, DM, CAD, HLD:** Comorbidities that are indications for or against
  beta-blocker use AND independent risk factors for HF hospitalization
- **Baseline BP:** Higher BP may prompt more aggressive pharmacotherapy;
  also predicts HF decompensation
- **BMI:** Obesity affects drug selection and HF prognosis
- **Smoking:** CV risk factor affecting both prescribing decisions and outcomes
- **Concurrent medications:** Statin, ACE-I, antiplatelet, CCB, furosemide
  indicate overall treatment intensity (common cause of both exposure and
  outcome through physician behavior and disease severity)
- **Baseline CRP, troponin I:** Inflammatory and myocardial injury markers
  reflecting disease severity

**Not included (unavailable or not confounders):**
- LVEF: Not available in PCORnet CDM (would be a key confounder in real data)
- NT-proBNP: Not available in this database
- eGFR/creatinine: Not available for this cohort
- Medications that are neither causes nor consequences of BB prescribing

### 4.3 Propensity Score Model

Logistic regression predicting P(metoprolol | confounders). Formula
constructed dynamically — single-level factors and zero-variance columns
are dropped before fitting (critical for small samples).

IPW weights estimated using `WeightIt::weightit()` with ATE estimand.

### 4.4 Balance Diagnostics

- Standardized mean differences (SMD) before and after weighting
- Love plot with threshold at |SMD| = 0.1 (`cobalt::love.plot()` with `un = TRUE`)
- PS distribution by treatment group (overlap assessment)

### 4.5 Primary Model

IPW-weighted logistic regression:

```
glm(hf_hosp ~ treatment, family = binomial, weights = ipw_weights)
```

Report: OR, 95% CI, risk difference, risk ratio.

### 4.6 Sensitivity Analyses

1. **E-value** (VanderWeele & Ding, 2017): Minimum strength of unmeasured
   confounding needed to explain the observed association. Calculated for
   the OR using `EValue::evalues.OR()`.

2. **Unweighted logistic regression:** Compare crude vs. IPW-adjusted
   estimates to assess confounding magnitude.

---

## 5. R Analysis Script

See `protocol_01_analysis.R` in this directory. The script:
- Connects to the DuckDB database directly
- Builds the cohort with CONSORT flow tracking
- Pulls baseline covariates (demographics, comorbidities, vitals, labs, meds)
- Dynamically constructs the PS formula
- Fits IPW via `WeightIt`
- Assesses balance via `cobalt`
- Runs IPW-weighted logistic regression
- Calculates E-value
- Produces publication outputs (Table 1, Love plot, PS distribution, CONSORT)
- Saves structured results to `protocol_01_results.json`

---

## 6. Limitations and Threats to Validity

### Critical Limitations

1. **Severely underpowered (n≈43).** With ~29 treated and ~14 controls,
   this study cannot detect clinically meaningful effect sizes. The minimum
   detectable OR at 80% power with these group sizes would be approximately
   5–8, far exceeding what is clinically plausible. **This protocol is a
   methodological demonstration only.**

2. **Synthetic data.** All patient records are artificially generated.
   Associations between variables do not reflect real biological or clinical
   relationships. Results have no clinical validity whatsoever.

3. **Uniform comorbidity profile.** The feasibility assessment found that
   nearly all AF+HF patients have HTN, DM, CAD, and HLD, severely limiting
   confounder variability and potentially causing positivity violations.

4. **Data-driven question selection.** This question was identified based
   on data availability in the synthetic database, not from the
   literature-driven gap analysis. It does not represent a true evidence gap.

### Methodological Threats

5. **Missing LVEF data.** Left ventricular ejection fraction is the single
   most important confounder in any beta-blocker/HF study (determines HFrEF
   vs. HFpEF, and beta-blocker benefit differs dramatically by HF type).
   Its absence is a critical unmeasured confounder.

6. **No enrollment table.** Cannot verify continuous enrollment, leading to
   potential selection bias if patients leave the health system
   differentially by treatment arm.

7. **Metoprolol formulation not distinguishable.** RxNorm ingredient CUI 6918
   captures both metoprolol succinate (ER, guideline-recommended for HF) and
   metoprolol tartrate (IR, not recommended for HF). This conflates
   potentially different clinical effects.

8. **Binary outcome simplification.** Collapsing time-to-HF-hospitalization
   into any/none loses timing information. Necessary given sample size but
   reduces statistical power further.

9. **No dose information used.** Metoprolol dose-response is well-established
   but not modeled here due to sample size constraints.

10. **Immortal time bias risk.** The 180-day grace period for treatment
    initiation creates potential for immortal time bias. Patients in the
    treated group must survive long enough to receive the prescription.
    Partially mitigated by the binary outcome design (not time-to-event).
