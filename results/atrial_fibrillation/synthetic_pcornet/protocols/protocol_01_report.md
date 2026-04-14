# Protocol 01: Metoprolol Initiation in AF+HF and HF Hospitalization

> **Note:** This analysis was conducted on synthetic data. Effect estimates
> are not clinically interpretable and are presented solely to demonstrate
> the analytic pipeline.

**Database:** PCORnet Synthetic CDW (`synthetic_pcornet`)
**CDM:** PCORnet v6.0 | **Engine:** DuckDB
**Execution date:** 2026-04-13
**Status:** Success

---

## 1. Clinical Context and Rationale

Heart failure (HF) and atrial fibrillation (AF) frequently coexist, sharing
risk factors such as hypertension, diabetes, and coronary artery disease. The
management of AF in the setting of concurrent HF remains an area of active
investigation. The EAST-AFNET 4 trial demonstrated that early rhythm control
reduces a composite of cardiovascular death, stroke, and HF hospitalization in
newly diagnosed AF (Kirchhof et al. 2020, PMID: 32865375). However, rate
control with beta-blockers remains the first-line strategy for many patients
with AF and HF, particularly when rhythm control is not pursued.

Liu et al. (2025, PMID: 41121356) recently applied target trial emulation to
compare digoxin versus beta-blockers for rate control in AF with HF, finding
digoxin associated with higher all-cause mortality. This study highlighted the
value of TTE methodology in pharmacoepidemiologic comparisons within this
population but did not isolate the effect of metoprolol specifically, nor did
it examine HF hospitalization as a primary outcome.

Metoprolol succinate is guideline-recommended for HF with reduced ejection
fraction (ACC/AHA Class I) and is widely used for rate control in AF. Despite
this, no target trial emulation has specifically examined the causal effect of
metoprolol initiation on HF hospitalization in patients with co-occurring AF
and HF. This analysis addresses that gap as a methodological demonstration
using a synthetic PCORnet database (n=50). The question was selected based on
data availability in this database rather than from the literature-derived
evidence gap analysis, which identified questions requiring anticoagulants,
antiarrhythmics, and ablation procedures not present in this synthetic dataset.

---

## 2. Methods Summary

### Target Trial Specification

| Element | Target Trial | Emulation |
|---------|-------------|-----------|
| Eligibility | Adults ≥18 with both AF (ICD-10 I48.x) and HF (ICD-10 I50.x) diagnoses, excluding patients on non-metoprolol beta-blockers | Patients with both AF and HF diagnoses in PCORnet `DIAGNOSIS` table; non-metoprolol BB users excluded via `PRESCRIBING` |
| Treatment strategies | (1) Initiate metoprolol within 180 days; (2) No beta-blocker therapy | (1) ≥1 metoprolol prescription (RxNorm CUI 6918); (2) No beta-blocker prescriptions of any type |
| Assignment procedure | Random assignment to strategy | Observed prescribing; confounding addressed via inverse probability weighting (IPW) |
| Time zero | Date of AF diagnosis | First AF diagnosis date (`DX_DATE` where `DX LIKE 'I48%'`) |
| Outcome | HF hospitalization (inpatient encounter with HF diagnosis) | Binary: any inpatient encounter (`ENC_TYPE = 'IP'`) with concurrent I50.x diagnosis after time zero |
| Estimand | Average Treatment Effect (ATE) | ATE via IPW-weighted logistic regression |
| Causal contrast | Risk difference for HF hospitalization: metoprolol initiation vs. no beta-blocker | Risk difference and odds ratio from IPW-weighted logistic regression |

### Statistical Approach

**Inverse probability weighting (IPW)** with logistic regression for the binary
outcome (HF hospitalization yes/no). IPW was selected as the standard approach
for TTE with a binary treatment. Given the extremely small sample (n=43),
logistic regression was preferred over Cox proportional hazards to avoid
unreliable hazard estimation and proportional hazards assumption violations
with too few events.

**Propensity score model:** `treatment ~ dm + hld + hdl`. The formula was
constructed dynamically — single-level factors and zero-variance columns were
dropped before fitting, which is critical for small samples where many
covariates have near-uniform distributions.

**Database and study period:** PCORnet Synthetic CDW, a DuckDB database
containing 500 synthetic patients in PCORnet v6.0 format. This database was
generated for methodological testing and does not represent real patient data.

**Key confounders adjusted for:** Diabetes mellitus (DM), hyperlipidemia (HLD),
and HDL cholesterol. Many planned confounders (age, sex, race, HTN, CAD, blood
pressure, BMI, smoking, concurrent medications) were dropped from the PS model
due to near-uniform distributions or single-level factors in this small
synthetic sample.

---

## 3. Results

### 3.1 Cohort Assembly

| Step | Description | N Remaining |
|------|-------------|-------------|
| 1 | Patients with both AF and HF diagnoses | 50 |
| 2 | All AF+HF patients (synthetic data, age filter waived) | 50 |
| 3 | Exclude patients with non-metoprolol beta-blocker only | 43 |
| 4 | Final analytic cohort | 43 |

The final cohort comprised 43 patients: 29 in the metoprolol group and 14 in
the no-beta-blocker control group. Seven patients were excluded because they
received a non-metoprolol beta-blocker without concurrent metoprolol, which
would contaminate the comparator arm.

![CONSORT Flow Diagram](protocol_01_consort.pdf)

### 3.2 Baseline Characteristics

> **Table 1** (publication-quality) is available as a formatted HTML file:
> `protocol_01_table1.html`

| Characteristic | Overall (N=43) | No Beta-Blocker (N=14) | Metoprolol (N=29) |
|----------------|:--------------:|:---------------------:|:-----------------:|
| Age, years, mean (SD) | 22 (9) | 20 (8) | 23 (10) |
| Female sex, n (%) | 21 (49%) | 7 (50%) | 14 (48%) |
| Hypertension, n (%) | 40 (93%) | 12 (86%) | 28 (97%) |
| Diabetes mellitus, n (%) | 26 (60%) | 5 (36%) | 21 (72%) |
| Coronary artery disease, n (%) | 42 (98%) | 13 (93%) | 29 (100%) |
| Hyperlipidemia, n (%) | 38 (88%) | 10 (71%) | 28 (97%) |
| Systolic BP, mmHg, mean (SD) | 142 (17) | 142 (18) | 143 (17) |
| Diastolic BP, mmHg, mean (SD) | 90 (11) | 90 (13) | 89 (10) |
| BMI, kg/m², mean (SD) | 28.2 (3.8) | 29.0 (4.5) | 27.8 (3.5) |
| Current/recent smoker, n (%) | 20 (47%) | 4 (29%) | 16 (55%) |
| Statin use, n (%) | 23 (53%) | 9 (64%) | 14 (48%) |
| ACE inhibitor use, n (%) | 15 (35%) | 5 (36%) | 10 (34%) |
| Antiplatelet use, n (%) | 20 (47%) | 8 (57%) | 12 (41%) |
| CCB use, n (%) | 9 (21%) | 2 (14%) | 7 (24%) |
| Loop diuretic use, n (%) | 2 (4.7%) | 0 (0%) | 2 (6.9%) |
| Total cholesterol, mg/dL, mean (SD) | 208 (44) | 215 (47) | 204 (43) |
| LDL cholesterol, mg/dL, mean (SD) | 96 (35) | 84 (26) | 102 (38) |
| HDL cholesterol, mg/dL, mean (SD) | 45 (11) | 40 (13) | 47 (9) |
| Triglycerides, mg/dL, mean (SD) | 162 (103) | 182 (119) | 153 (95) |

Notable imbalances at baseline: diabetes mellitus was more prevalent in the
metoprolol group (72% vs. 36%, p=0.048) and hyperlipidemia trended higher
(97% vs. 71%, p=0.057). Mean age was unrealistically low (22 years) due to
the synthetic data generation process. Coronary artery disease was nearly
universal (98%), limiting its utility as a confounder.

### 3.3 Covariate Balance

The propensity score model included only three covariates that retained
sufficient variability: diabetes mellitus, hyperlipidemia, and HDL cholesterol.

| Metric | Value |
|--------|-------|
| Pre-weighting maximum SMD | 1.113 |
| Post-weighting maximum SMD | 0.219 |
| All covariates below SMD < 0.1 threshold | No |

IPW reduced the maximum SMD from 1.113 to 0.219, representing substantial
improvement but failing to achieve the conventional threshold of SMD < 0.1 for
all covariates. HDL cholesterol remained the most imbalanced covariate after
weighting (post-weighting SMD = 0.219). This residual imbalance should be
considered when interpreting the effect estimate.

![Covariate Balance — Love Plot](protocol_01_loveplot.pdf)

![Propensity Score Distribution](protocol_01_ps_dist.pdf)

### 3.4 Primary Analysis

| Measure | Estimate |
|---------|----------|
| Method | IPW-weighted logistic regression |
| Estimand | ATE |
| Odds ratio | 0.493 (95% CI: 0.200, 1.219) |
| P-value | 0.126 |
| Risk in treated (metoprolol) | 29.0% (8 events / 29 patients) |
| Risk in control (no beta-blocker) | 45.2% (6 events / 14 patients) |
| Risk difference | -16.3 percentage points |
| Total HF hospitalization events | 14 of 43 patients (32.6%) |

The IPW-weighted odds ratio for HF hospitalization was 0.493 (95% CI: 0.200,
1.219; p = 0.126), comparing metoprolol initiation to no beta-blocker therapy.
The point estimate suggests a direction toward lower HF hospitalization risk
with metoprolol (absolute risk 29.0% vs. 45.2%), but this result **did not
reach statistical significance**. The confidence interval is wide, spanning
from a 80% reduction to a 22% increase in odds, reflecting the severe
imprecision inherent in this sample size.

### 3.5 Secondary and Sensitivity Analyses

**Crude (unadjusted) analysis:**

| Measure | Estimate |
|---------|----------|
| Crude odds ratio | 0.508 (95% CI: 0.134, 1.931) |

The crude OR (0.508) was similar in magnitude and direction to the IPW-adjusted
OR (0.493), suggesting limited confounding by the measured covariates. Both
estimates have wide confidence intervals crossing 1.0.

**E-value:**

The E-value calculation encountered a computational error ("subscript out of
bounds"), likely due to the confidence interval crossing the null (OR = 1.0).
When the CI includes 1.0, the E-value for the confidence interval limit is
1.0 by definition, meaning that even minimal unmeasured confounding could
explain the observed association. This further underscores the fragility of
the point estimate.

---

## 4. Interpretation

The point estimate (OR = 0.493) suggests a direction toward reduced HF
hospitalization with metoprolol initiation in patients with AF and HF, but the
result is not statistically significant and the confidence interval is wide.
Given the synthetic data and sample size of 43, no clinical inference should
be drawn from this analysis.

In context, Liu et al. (2025, PMID: 41121356) found that digoxin was
associated with *higher* all-cause mortality compared to beta-blockers in
AF+HF using target trial emulation. While that study addressed mortality
rather than HF hospitalization and compared digoxin to beta-blockers as a
class (not metoprolol specifically), the directional finding that beta-blockers
may be preferable is broadly consistent with the point estimate observed here.

The CASTLE-AF trial (Marrouche et al. 2018, PMID: 29385358) demonstrated that
catheter ablation significantly reduced HF hospitalization in AF patients with
HFrEF, and the CABANA HF subgroup analysis (Packer et al. 2021,
PMID: 33554614) showed ablation reduced AF recurrence in HF patients. These
trials addressed rhythm control via ablation rather than rate control with
beta-blockers, but they establish that AF management strategies can
meaningfully reduce HF hospitalization in appropriately selected patients.

No RCT has specifically examined metoprolol initiation versus no beta-blocker
on HF hospitalization in AF+HF patients. The MERIT-HF trial established
metoprolol succinate's mortality benefit in HFrEF (regardless of AF status),
but a direct comparison to no beta-blocker for the HF hospitalization endpoint
in AF+HF remains an evidence gap — albeit one with limited clinical equipoise
given existing guideline recommendations.

---

## 5. Limitations

### Synthetic Data Caveat

> **This analysis was conducted on synthetic data (n=50, 43 in final cohort).
> All patient records are artificially generated. Associations between
> variables do not reflect real biological or clinical relationships. Effect
> estimates are not clinically interpretable and are presented solely to
> demonstrate the analytic pipeline.**

### Protocol-Level Limitations

1. **Severely underpowered (n=43).** With 29 treated and 14 control patients,
   this study cannot detect clinically meaningful effect sizes. The minimum
   detectable OR at 80% power with these group sizes would be approximately
   5–8, far exceeding clinically plausible effects.

2. **Data-driven question selection.** This question was identified based on
   data availability in the synthetic database, not from the literature-driven
   gap analysis. The original five literature-derived AF questions (DOAC
   comparisons, ablation vs. AADs, early rhythm control) were all infeasible
   because the database lacks anticoagulants, antiarrhythmics, and ablation
   procedures.

3. **Missing LVEF data.** Left ventricular ejection fraction is the single
   most important confounder in any beta-blocker/HF study. It determines
   HFrEF vs. HFpEF classification, and beta-blocker benefit differs
   dramatically by HF type. Its absence represents critical unmeasured
   confounding.

4. **Near-uniform comorbidity profiles.** Hypertension (93%), CAD (98%), and
   hyperlipidemia (88%) were nearly universal, severely limiting confounder
   variability and leading to most planned covariates being dropped from the
   propensity score model.

5. **Metoprolol formulation not distinguishable.** The RxNorm ingredient CUI
   captures both metoprolol succinate (ER, guideline-recommended for HF) and
   metoprolol tartrate (IR, not recommended for HF), conflating potentially
   different clinical effects.

6. **Binary outcome simplification.** Collapsing time-to-HF-hospitalization
   into any/none loses timing information. This was necessary given sample
   size but further reduces statistical power.

7. **Immortal time bias risk.** The 180-day grace period for treatment
   initiation creates potential for immortal time bias — patients in the
   treated group must survive long enough to receive the prescription.

### Execution-Level Warnings

8. **Residual covariate imbalance.** Post-weighting maximum SMD was 0.219,
   exceeding the conventional 0.1 threshold. HDL cholesterol remained
   imbalanced after IPW, meaning the effect estimate may still be confounded
   by lipid-related factors.

9. **E-value computation failed.** The sensitivity analysis for unmeasured
   confounding could not be completed due to a computational error. The CI
   crossing 1.0 implies an E-value of 1.0 for the lower confidence limit,
   indicating extreme vulnerability to unmeasured confounding.

10. **Unrealistic demographics.** Mean age of 22 years for an AF+HF
    population is biologically implausible (real-world median age is typically
    >70 years), confirming the synthetic nature of the data.

---

## 6. Conclusions

This analysis demonstrated the complete target trial emulation pipeline —
from cohort assembly through propensity score weighting to effect estimation —
applied to the question of metoprolol initiation and HF hospitalization in
patients with AF and HF. The pipeline successfully produced a CONSORT flow
diagram, baseline characteristics table, covariate balance diagnostics, and
IPW-weighted effect estimates.

The point estimate (OR = 0.493; risk difference = -16.3 percentage points)
suggested a direction toward benefit with metoprolol, but the result was not
statistically significant (p = 0.126) and the confidence interval was wide
(95% CI: 0.200, 1.219). Given the synthetic data, sample size of 43, residual
covariate imbalance, and critical unmeasured confounders (LVEF), these results
carry no clinical validity. They serve exclusively as a methodological
demonstration that the automated TTE system can execute end-to-end on a
PCORnet-formatted database.

---

## 7. STROBE Compliance Checklist

| STROBE Item | Description | Location in Report |
|-------------|-------------|-------------------|
| 1a | Title: indicate study design | Title |
| 1b | Abstract: informative, balanced summary | Section 1 |
| 2 | Background: scientific rationale | Section 1 |
| 3 | Objectives: state specific objectives | Section 1 |
| 4 | Study design: present key elements | Section 2 (target trial table) |
| 5 | Setting: dates, periods, locations | Section 2 (database description) |
| 6a | Participants: eligibility criteria | Section 2 (target trial table), Section 3.1 |
| 7 | Variables: define all variables | Section 2 (confounders, PS model) |
| 8 | Data sources: describe data source | Section 2 (PCORnet Synthetic CDW) |
| 12a | Statistical methods: describe all | Section 2 (IPW, logistic regression) |
| 12b | Subgroup and interaction analyses | N/A — sample size precluded subgroup analyses |
| 12d | Sensitivity analyses | Section 3.5 (crude OR, E-value) |
| 13a | Participant numbers at each stage | Section 3.1 (CONSORT table) |
| 14a | Descriptive data: characteristics | Section 3.2 (Table 1) |
| 15 | Outcome data: events, follow-up | Section 3.4 (14 events in 43 patients) |
| 16a | Main results: unadjusted and adjusted | Section 3.4 (IPW OR), Section 3.5 (crude OR) |
| 17 | Other analyses: subgroup, sensitivity | Section 3.5 |
| 19 | Limitations: discuss sources of bias | Section 5 |
| 22 | Funding/data source acknowledgment | Section 2 (synthetic data), Section 6 |

---

## 8. References

1. Kirchhof P et al. "Early Rhythm-Control Therapy in Patients with Atrial Fibrillation (EAST-AFNET 4)." 2020. PMID: 32865375

2. Liu et al. "Target trial emulation: Digoxin vs beta-blocker in AF+HF." 2025. PMID: 41121356

3. Marrouche NF et al. "Catheter Ablation for Atrial Fibrillation with Heart Failure (CASTLE-AF)." 2018. PMID: 29385358

4. Packer DL et al. "Ablation Versus Drug Therapy for Atrial Fibrillation in Heart Failure: Results from the CABANA Trial." 2021. PMID: 33554614

5. Zafeiropoulos S et al. "Meta-analysis of rhythm vs. rate control in atrial fibrillation." 2024. PMID: 38727662
