# Protocol 01: DOAC vs Warfarin and All-Cause Mortality in CKD — Prevalent-User Design

**Database:** NHANES (National Health and Nutrition Examination Survey), 2013-2018 pooled
**Design Category:** Category A — Legitimate TTE with prevalent-user caveats
**Date:** 2026-04-14

---

## 1. Clinical Context

Atrial fibrillation (AF) patients with chronic kidney disease (CKD) face elevated
risks of both thromboembolic events and bleeding. Oral anticoagulation is the
cornerstone of stroke prevention, but the optimal agent in CKD remains uncertain.
The pivotal DOAC trials (RE-LY, ROCKET-AF, ARISTOTLE, ENGAGE AF-TIMI 48) excluded
patients with advanced CKD (eGFR <25–30), and the only dedicated RCTs in CKD/ESKD
(RENAL-AF, N=154; De Vriese et al., N=132) were underpowered. Observational studies
(Fu et al. 2024, PMID 37839687; Yao et al. 2020, PMID 33012172) suggest apixaban
may have lower bleeding risk than rivaroxaban in CKD, but no target trial emulation
has been applied to this question in the CKD population.

NHANES uniquely offers nationally representative, lab-based eGFR staging and
prospective mortality linkage (NDI follow-up through December 31, 2019). However,
NHANES captures only prevalent (current) medication use at a single cross-sectional
visit. This protocol therefore emulates a "prevalent-user" trial comparing current
DOAC use (apixaban, rivaroxaban, or dabigatran) vs current warfarin use among US
adults with eGFR <60, with all-cause mortality as the outcome.

**This is NOT a new-user design.** NHANES cannot identify treatment initiation
dates, prior medication history, or treatment switching. The target trial being
emulated is: "Among people currently taking an oral anticoagulant at a random
health examination, compare mortality outcomes between DOAC and warfarin users
with moderate-to-severe CKD." This is a fundamentally different question from
"initiate DOAC vs warfarin," and causal interpretation is severely limited by
prevalent-user bias (see Section 6).

---

## 2. Target Trial Specification

| Element | Target Trial | Emulation in NHANES |
|---------|-------------|---------------------|
| **Eligibility** | US adults currently taking an oral anticoagulant (DOAC or warfarin) with eGFR <60 mL/min/1.73m² | Adults ≥18 examined in NHANES MEC (RIDSTATR=2), self-reporting current use of apixaban, rivaroxaban, dabigatran, or warfarin (RXQ_RX, RXDDRUG), with lab-calculated eGFR <60 (CKD-EPI 2021, serum creatinine from BIOPRO). Pooled across 3 cycles (2013-2014, 2015-2016, 2017-2018). |
| **Treatment strategies** | Strategy A: Currently taking a DOAC (apixaban, rivaroxaban, or dabigatran). Strategy B: Currently taking warfarin. | Classified from RXDDRUG in RXQ_RX. Participants taking both a DOAC and warfarin simultaneously are excluded. |
| **Assignment procedure** | Random assignment at time zero | Not randomized. Propensity score inverse probability weighting (IPW) adjusts for measured confounders. Assignment reflects prevalent use, not a treatment decision. |
| **Outcome** | All-cause mortality | All-cause mortality from NHANES Public-Use Linked Mortality File (NDI linkage through 12/31/2019). MORTSTAT=1 indicates death; PERMTH_EXM provides person-months from MEC exam. |
| **Time zero** | Date of NHANES MEC examination | NHANES examination date. This is NOT treatment initiation — participants may have been on their anticoagulant for days to years before the exam. |
| **Causal contrast** | Average treatment effect (ATE) of being a current DOAC user vs current warfarin user on all-cause mortality | Survey-weighted IPW-adjusted hazard ratio from Cox PH regression. |
| **Follow-up** | From MEC exam to death or administrative censoring (12/31/2019) | PERMTH_EXM provides follow-up in person-months. Maximum ~72 months (2013-2014 cycle) to ~24 months (2017-2018 cycle). |

### Eligibility Criteria (Detailed)

**Inclusion:**
1. Age ≥18 years at NHANES examination
2. Completed MEC examination (RIDSTATR = 2)
3. Currently taking warfarin OR a DOAC (apixaban, rivaroxaban, or dabigatran) per RXQ_RX
4. Serum creatinine available (LBXSCR in BIOPRO table)
5. Calculated eGFR <60 mL/min/1.73m² (CKD-EPI 2021 race-free equation)
6. Eligible for mortality follow-up (ELIGSTAT = 1 in linked mortality file)
7. Non-zero MEC exam weight (WTMEC2YR > 0)

**Exclusion:**
1. Concurrent use of both a DOAC and warfarin (dual anticoagulant users)
2. Missing BMI (required for PS model)

### Note on AF Ascertainment

NHANES has no direct AF diagnosis variable. The MCQ questionnaire asks about CHF,
CHD, heart attack, and stroke, but not AF. Anticoagulant use is used as a proxy
for AF indication, but anticoagulants are also prescribed for DVT/PE, mechanical
valves, and other conditions. This introduces exposure misclassification: some
participants in the cohort may not have AF. The ICD-10 reason-for-use codes
(RXDRSC1-3) in RXQ_RX may help identify AF-specific use but have variable
completeness.

---

## 3. Emulation Using Observational Data

### Target Dataset

NHANES 2013-2014 (_H), 2015-2016 (_I), 2017-2018 (_J), pooled. Expected analytic
sample: approximately 100-130 anticoagulant users with eGFR <60 across all 3 cycles
(based on feasibility assessment: 118 anticoagulant users with eGFR 30-59 plus ~12
with eGFR <30).

### Variable Mapping

| Protocol Concept | NHANES Table | Variable(s) | Notes |
|-----------------|-------------|-------------|-------|
| **Treatment** | RXQ_RX_H/I/J | RXDDRUG | String match: "Apixaban", "Rivaroxaban", "Dabigatran" → DOAC; "Warfarin" → control |
| **Age** | DEMO_H/I/J | RIDAGEYR | Years; top-coded at 80 |
| **Sex** | DEMO_H/I/J | RIAGENDR | 1=Male, 2=Female |
| **Race/ethnicity** | DEMO_H/I/J | RIDRETH3 | 6-level including NH Asian |
| **Education** | DEMO_H/I/J | DMDEDUC2 | 5-level; recode 7/9 → NA |
| **Income-poverty ratio** | DEMO_H/I/J | INDFMPIR | Continuous, capped at 5.0 |
| **Serum creatinine** | BIOPRO_H/I/J | LBXSCR | mg/dL; used for eGFR calculation |
| **eGFR** | Derived | — | CKD-EPI 2021 from LBXSCR + age + sex |
| **BMI** | BMX_H/I/J | BMXBMI | kg/m² |
| **HbA1c** | GHB_H/I/J | LBXGH | % |
| **Total cholesterol** | TCHOL_H/I/J | LBXTC | mg/dL |
| **HDL cholesterol** | HDL_H/I/J | LBDHDD | mg/dL |
| **Urine albumin-creatinine ratio** | ALB_CR_H/I/J | URDACT | mg/g; albuminuria staging |
| **CHF history** | MCQ_H/I/J | MCQ160B | 1=Yes; recode 7/9 → NA |
| **CHD history** | MCQ_H/I/J | MCQ160C | 1=Yes; recode 7/9 → NA |
| **Stroke history** | MCQ_H/I/J | MCQ160F | 1=Yes; recode 7/9 → NA |
| **Diabetes** | DIQ_H/I/J | DIQ010 | 1=Yes; recode 7/9 → NA |
| **Hypertension** | BPQ_H/I/J | BPQ020 | 1=Yes; recode 7/9 → NA |
| **Smoking** | SMQ_H/I/J | SMQ020, SMQ040 | Current smoker = SMQ020==1 & SMQ040 ∈ {1,2} |
| **Mortality status** | Linked Mortality File | MORTSTAT | 0=Alive, 1=Deceased |
| **Follow-up time** | Linked Mortality File | PERMTH_EXM | Person-months from MEC exam |
| **Cause of death** | Linked Mortality File | UCOD_LEADING | Recode category (secondary analysis) |
| **Survey weight** | DEMO_H/I/J | WTMEC2YR | Adjusted: WTMEC6YR = WTMEC2YR / 3 for 3-cycle pooling |
| **Stratum** | DEMO_H/I/J | SDMVSTRA | Masked variance pseudo-stratum |
| **PSU** | DEMO_H/I/J | SDMVPSU | Masked variance pseudo-PSU |

### eGFR Calculation (CKD-EPI 2021 Race-Free Equation)

```
eGFR = 142 × min(Scr/κ, 1)^α × max(Scr/κ, 1)^(-1.200) × 0.9938^Age × [1.012 if female]
```

Where:
- Female: κ = 0.7, α = -0.241, sex multiplier = 1.012
- Male: κ = 0.9, α = -0.302, sex multiplier = 1.0

This is the 2021 CKD-EPI race-free equation (Inker et al., NEJM 2021), consistent
with NKF-ASN recommendations. No race coefficient is included.

---

## 4. Statistical Analysis Plan

### 4.1 Primary Analysis

**Method:** Inverse probability weighted (IPW) Cox proportional hazards regression
with survey weights.

**Estimand:** Average treatment effect (ATE) — the average causal effect of being
a DOAC user vs warfarin user on all-cause mortality, under the prevalent-user
interpretation.

**Approach:**
1. **Propensity score estimation:** Survey-weighted logistic regression (svyglm
   with quasibinomial family) modeling P(DOAC | covariates). The PS formula is
   built dynamically, dropping single-level factors and zero-variance columns.
2. **IPW weights:** Stabilized inverse probability weights for ATE estimation.
   Extreme weights truncated at the 1st and 99th percentiles.
3. **Combined weights:** Survey weights (WTMEC6YR) × stabilized IPW weights.
4. **Outcome model:** Survey-weighted Cox PH (svycoxph) with treatment as the
   sole predictor, using combined weights. The survey design accounts for
   stratification and clustering.

### 4.2 Confounder Set (DAG-Justified)

The following confounders are included as common causes of anticoagulant choice
and mortality:

| Confounder | Rationale |
|-----------|-----------|
| Age | Older patients more likely to receive warfarin (familiarity); strong mortality predictor |
| Sex | Sex differences in anticoagulant prescribing and mortality |
| Race/ethnicity | Racial disparities in DOAC access and mortality |
| eGFR | CKD severity drives both drug choice (dose adjustment) and mortality |
| BMI | Obesity affects drug metabolism and mortality |
| Diabetes | Comorbidity burden → drug choice and mortality |
| CHF | Heart failure → drug choice and mortality |
| CHD | Cardiovascular disease burden |
| Prior stroke | Influences anticoagulation intensity decisions |
| Hypertension | Cardiovascular risk factor |
| Smoking | Cardiovascular risk factor |
| HbA1c | Glycemic control → mortality; correlated with comorbidity |
| Total cholesterol | Cardiovascular risk marker |
| HDL cholesterol | Cardiovascular risk marker |
| Prior MI | MI influences anticoagulation intensity; strong mortality predictor |
| Income-poverty ratio | DOAC cost $400+/month vs pennies for warfarin (2013-2018); income drives drug choice |

**Omitted variables (acceptable):**
- Education: Weak confounder of drug class choice after conditioning on income.
- UACR: Informative for CKD severity but may be collinear with eGFR. Excluded
  from PS model but reported descriptively.

### 4.3 Balance Diagnostics

- Absolute standardized mean differences (SMD) before and after IPW weighting
- Threshold: all covariates <0.1 SMD post-weighting
- Love plot showing pre- and post-weighting SMDs (cobalt package, `un = TRUE`,
  `stars = "std"`)
- Propensity score distribution by treatment group

### 4.4 Sensitivity Analyses

1. **E-value** for unmeasured confounding (EValue package, `rare = TRUE` given
   low mortality rate in the sample)
2. **Unweighted Cox model** (survey weights only, no IPW) as a reference
3. **Subgroup analysis** by CKD severity (eGFR 30-59 vs eGFR <30) if sample
   size permits (exploratory — likely too small)

---

## 5. CONSORT Flow Diagram

```
US adults examined (MEC), 3 NHANES cycles 2013-2018
  │  N ≈ 17,192
  ▼
Currently taking oral anticoagulant (DOAC or warfarin)
  │  N ≈ 393 (excluding dual users and edoxaban)
  ▼
Serum creatinine available
  │  N ≈ 380
  ▼
eGFR < 60 mL/min/1.73m²
  │  N ≈ 130
  ▼
Linked mortality follow-up available (ELIGSTAT = 1)
  │  N ≈ 125
  ▼
Complete data for analysis (non-missing BMI, non-zero weight)
  │  N ≈ 115-125
  ├── DOAC arm (treatment = 1): N ≈ 35-45
  └── Warfarin arm (treatment = 0): N ≈ 75-85
```

*Note: Exact counts from executed analysis. The warfarin arm is expected to be
larger because warfarin has been available longer and CKD patients (who tend to
be older) may be more likely to be on an established medication.*

---

## 6. Limitations and Threats to Validity

### 6.1 Prevalent-User Bias (Critical)

This design is subject to three forms of prevalent-user bias:

1. **Depletion of susceptibles.** Patients who experienced early adverse events
   (death, major bleeding, stroke) on their anticoagulant already stopped the
   drug or died before the NHANES exam. Current users are "survivors" of the
   initial treatment period. This biases results toward finding the drug is
   beneficial — we are comparing survivors on DOAC vs survivors on warfarin,
   not new initiators.

2. **Survivor selection.** The cohort only includes people who survived long
   enough to be surveyed while on their medication. Patients who died shortly
   after starting an anticoagulant are excluded. If one drug has higher early
   mortality, that drug's survivors will appear healthier.

3. **Confounding by treatment duration.** A patient on warfarin for 15 years
   differs profoundly from one who started 3 months ago, but NHANES treats
   both as "current warfarin users." Time-varying confounders accumulated
   during treatment (worsening CKD, new comorbidities, dose changes) are
   unmeasured. Because DOACs were introduced more recently (dabigatran 2010,
   rivaroxaban 2011, apixaban 2012), DOAC users in 2013-2018 are, on average,
   newer initiators than warfarin users, creating systematic confounding by
   duration.

### 6.2 No AF Ascertainment

NHANES has no AF-specific diagnosis variable. The cohort includes all
anticoagulant users with CKD, regardless of indication. Some participants
may be anticoagulated for DVT/PE, mechanical heart valves, or other
conditions. This introduces exposure misclassification and limits the
clinical specificity of the findings.

### 6.3 Cross-Sectional Exposure Assessment

Medication use is captured at a single time point (30-day recall). We cannot
verify:
- Duration of anticoagulant use
- Prior switching between agents
- Adherence patterns
- Whether the medication was actually being taken vs. just reported

### 6.4 Small Sample Size

The expected analytic sample of ~115-130 participants (with ~35-45 DOAC users)
is below the recommended minimum for robust propensity score analyses. The
study is likely underpowered for the mortality outcome, and effect estimates
will have wide confidence intervals. Results should be interpreted as
hypothesis-generating, not confirmatory.

### 6.5 Age Top-Coding

Ages ≥80 are coded as 80 in NHANES. In a CKD anticoagulation population
(expected mean age ~70-75), this ceiling effect compresses age-related
heterogeneity in the oldest patients.

### 6.6 Unmeasured Confounders

Key unmeasured confounders include:
- **AF type** (paroxysmal, persistent, permanent) — not available
- **CHA₂DS₂-VASc score** — partially constructible but AF diagnosis component missing
- **HAS-BLED score** — not fully constructible (no prior bleeding data)
- **INR control for warfarin** — not measured
- **Healthcare utilization** — limited to self-report
- **Socioeconomic access** — partially captured by income/education
- **Provider specialty** — not available
- **Frailty** — not directly measured (partially proxied by BMI, comorbidities)

### 6.7 TARGET Guideline Compliance

| TARGET Element | Status | Note |
|---------------|--------|------|
| Eligibility criteria | Satisfied | Lab-based eGFR + medication report |
| Treatment strategies | Limited | Prevalent use, not initiation or treatment strategy |
| Assignment procedure | Partially satisfied | IPW for measured confounders; prevalent-user bias unaddressed |
| Time zero | Limited | Exam date, not treatment decision date |
| Outcome definition | Satisfied | NDI-linked all-cause mortality |
| Causal contrast | Satisfied with caveats | ATE under prevalent-user interpretation |
| Follow-up | Satisfied | Prospective from exam to death/censoring |

---

## 7. R Analysis Script

See `protocol_01_analysis.R` for the complete, runnable analysis code.
