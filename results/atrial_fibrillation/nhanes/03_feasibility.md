# Dataset Feasibility: NHANES — Atrial Fibrillation

**Database:** NHANES (National Health and Nutrition Examination Survey)
**CDM:** nhanes (nhanesA R package → DuckDB in-memory)
**Cycles assessed:** 2013-2014 (_H), 2015-2016 (_I), 2017-2018 (_J), pooled
**Date:** 2026-04-14

---

## Executive Summary

NHANES is a cross-sectional survey with no longitudinal follow-up, no procedure codes,
no prescription fill dates, and no hospital records. **Five of the six approved questions
are infeasible for target trial emulation (TTE) using NHANES** because they require
time-to-event outcomes (stroke, major bleeding, HF hospitalization, mortality) following
treatment *initiation*, which NHANES cannot observe. NHANES captures only prevalent
medication use — a single snapshot of what the participant is currently taking.

**One question (Q6: appropriate vs inappropriate DOAC dose reduction in elderly) has
partial feasibility** as a prevalent-user design with mortality follow-up, but faces
severe sample size limitations (n ≈ 76 elderly DOAC users across 3 cycles) and the
inability to determine dosing appropriateness from NHANES data.

NHANES's unique value for the AF therapeutic area lies not in TTE but in **nationally
representative prevalence estimates** of anticoagulant use patterns, comorbidity burden,
and biomarker-based severity staging among AF-related populations. These descriptive
analyses can complement TTE studies conducted in claims or EHR databases.

---

## Overall NHANES Inventory for AF Research

### Sample Sizes (3-cycle pooled, 2013-2018, adults ≥18, MEC examined)

| Population | Unweighted N |
|-----------|-------------|
| All adults examined | 17,192 |
| Anticoagulant users (any) | 421 |
| — Warfarin | 258 |
| — Apixaban | 69 |
| — Rivaroxaban | 66 |
| — Dabigatran | 28 |
| — Edoxaban | 0 |
| Antiarrhythmic users (any) | 120 |
| — Amiodarone | 47 |
| — Sotalol | 37 |
| — Flecainide | 16 |
| — Dronedarone | 11 |
| — Propafenone | 9 |
| — Dofetilide | 1 |
| Self-reported CHF | 597 |
| Self-reported CHD | 741 |
| Self-reported stroke | 684 |
| Self-reported liver condition | 787 |
| Self-reported weak/failing kidneys | 649 |
| Dialysis past 12 months | 59 |
| eGFR < 15 (lab-based) | 52 |
| eGFR 15-29 | 96 |
| eGFR 30-59 | 1,103 |
| Adults age ≥ 75 | 1,723 |
| Rate control medication users | 2,173 |

### Critical Cross-Tabulations

| Intersection | N |
|-------------|---|
| Anticoagulant + CHF | 132 |
| Anticoagulant + liver condition | 25 |
| Anticoagulant + weak/failing kidneys | 63 |
| Anticoagulant + dialysis | 6 |
| Anticoagulant + eGFR < 30 | 12 |
| Anticoagulant + eGFR 30-59 | 118 |
| DOAC + liver condition | 6 |
| Warfarin + liver condition | 19 |
| Elderly (75+) anticoagulant users | 198 |
| Elderly (75+) DOAC users | 76 |

### Laboratory Coverage (3-cycle pooled)

| Lab Component | Available N |
|--------------|------------|
| Serum creatinine (eGFR calculation) | ~16,163 adults |
| Urine albumin-creatinine ratio | ~23,964 |
| Albumin | ~18,714 |
| Bilirubin | ~18,706 |
| ALT | ~18,709 |
| AST | ~18,689 |
| GGT | ~18,710 |
| Platelets (for FIB-4) | ~24,189 |

### Key NHANES Limitation: No AF Diagnosis Variable

**NHANES has no direct question asking "Have you ever been told you have atrial
fibrillation?"** The MCQ questionnaire asks about CHF (MCQ160B), CHD (MCQ160C),
heart attack (MCQ160E), and stroke (MCQ160F), but not AF specifically. AF patients
can only be identified *indirectly* through:

1. **Anticoagulant use** — but anticoagulants are also used for DVT/PE, mechanical
   valves, and other indications
2. **Antiarrhythmic use** — more specific to AF but also used for other arrhythmias
3. **ICD-10 reason-for-use codes (RXDRSC1-3)** — available for some medications,
   but completeness varies

This means NHANES cannot define a clean AF cohort. Any AF-specific analysis must
proxy through medication use, introducing misclassification bias.

---

## Per-Question Feasibility Assessment

### Q1: Apixaban vs Rivaroxaban in AF + Advanced CKD (Gap Score 8)

**Verdict: INFEASIBLE for TTE. Marginally feasible for cross-sectional prevalence analysis.**

#### Why infeasible for TTE

1. **No new-user design possible.** NHANES captures prevalent medication use only.
   Cannot identify when apixaban or rivaroxaban was initiated, precluding time-zero
   alignment with treatment start.

2. **No time-to-event outcomes.** The primary outcomes (stroke/SE, major bleeding)
   require incident event detection over follow-up. NHANES has mortality linkage but
   not stroke or bleeding event data. Self-reported stroke (MCQ160F) is prevalent, not
   incident.

3. **Critically small sample size.** Among 3-cycle pooled adults:
   - Apixaban users: 69
   - Rivaroxaban users: 66
   - Anticoagulant users with eGFR < 30: **12 total** (across all AC types)
   - Apixaban or rivaroxaban with eGFR < 30: estimated **3-5** (too few to tabulate)

   Even for a cross-sectional comparison, the intersection of specific DOAC + advanced
   CKD is far below the minimum ~100 per arm needed for weighted analyses.

4. **Prevalent-user bias.** Patients who experienced early adverse events on these
   DOACs in CKD are not captured — they stopped the drug before the survey.

#### What NHANES *could* contribute

- **Nationally representative estimate** of anticoagulant prescribing patterns among
  US adults with CKD (lab-defined by eGFR), broken down by CKD stage
- **Characterization of comorbidity burden** among anticoagulant users with CKD
  (BMI, diabetes, hypertension, smoking, other medications)
- These would be Category B (prospective associational) or Category C (cross-sectional
  descriptive) analyses, NOT TTE

**Feasibility score: 1/10**

---

### Q2: Catheter Ablation vs AADs in AF + HFpEF (Gap Score 8)

**Verdict: INFEASIBLE. Cannot be studied in NHANES at all.**

#### Why infeasible

1. **No procedure data.** NHANES has no procedure code tables (no CPT, no ICD-10-PCS).
   Catheter ablation (CPT 93656) cannot be identified. There is no self-report question
   about cardiac procedures like ablation.

2. **HFpEF cannot be defined.** NHANES asks about CHF (MCQ160B = "Yes" for 597
   participants across 3 cycles), but there is no echocardiography data to determine
   ejection fraction. HFpEF (EF ≥ 50%) vs HFrEF (EF < 40%) cannot be distinguished.

3. **No AF diagnosis.** As noted above, NHANES has no AF-specific question.

4. **No incident outcomes.** HF hospitalization, AF recurrence, and all-cause death
   following a procedure cannot be tracked.

#### What NHANES *could* contribute

- Nothing directly relevant to this question. NHANES has no procedural or
  echocardiographic data. The CHF question (MCQ160B) is too nonspecific to
  characterize the HFpEF population.

**Feasibility score: 0/10**

---

### Q3: DOACs vs Warfarin in AF + Liver Cirrhosis (Gap Score 8)

**Verdict: INFEASIBLE for TTE. Very limited cross-sectional descriptive analysis possible.**

#### Why infeasible for TTE

1. **No new-user design.** Same prevalent-user limitation as Q1.

2. **No time-to-event outcomes.** Stroke/SE and major bleeding cannot be ascertained.
   Mortality linkage exists but with only 25 anticoagulant users reporting a liver
   condition (6 DOAC, 19 warfarin), mortality events would be in single digits.

3. **Extremely small sample.** The intersection of DOAC use + liver condition is
   **6 participants** across 3 cycles. Warfarin + liver is 19. These numbers are
   far too small for any comparative analysis.

4. **Cirrhosis vs. "liver condition" ambiguity.** NHANES asks "Ever told you had any
   liver condition" (MCQ160L) — this captures hepatitis, fatty liver, and other
   conditions alongside cirrhosis. No Child-Pugh staging is possible. While NHANES
   has the lab components for partial staging (albumin: 18,714; bilirubin: 18,706;
   platelets: 24,189 for FIB-4), these cannot distinguish compensated from
   decompensated cirrhosis, and there is no ascites or encephalopathy data.

#### What NHANES *could* contribute

- **Nationally representative prevalence** of liver disease among anticoagulant users
- **FIB-4 score distribution** among anticoagulant users (using AST, ALT, platelets, age)
  to characterize subclinical liver fibrosis burden — a Category B descriptive analysis
- This would be a descriptive/epidemiologic contribution, not TTE

**Feasibility score: 1/10**

---

### Q4: Early Rhythm Control vs Usual Care in AF + HF (Gap Score 7)

**Verdict: INFEASIBLE for TTE. Limited cross-sectional analysis possible.**

#### Why infeasible for TTE

1. **Cannot define "early" rhythm control.** NHANES captures current medication use,
   not when it was started relative to an AF diagnosis. The EAST-AFNET 4 design
   requires identifying patients within 1 year of AF diagnosis who initiated rhythm
   control — this temporal relationship is completely unobservable in NHANES.

2. **No AF diagnosis date.** There is no AF diagnosis variable at all, let alone a
   date of diagnosis.

3. **No incident HF hospitalization or CV death events.** The composite outcome
   (CV death, stroke, HF hospitalization) requires longitudinal event tracking.
   NHANES mortality linkage provides all-cause and some cause-specific mortality,
   but not HF hospitalization.

4. **Rhythm vs. rate control is observable but non-specific.** NHANES can identify
   antiarrhythmic drug users (120 across 3 cycles) and rate control drug users
   (2,173), but:
   - Many rate control users do not have AF (beta-blockers are prescribed for
     hypertension, CHF, etc.)
   - The 120 AAD users vs. 2,173 rate control users creates extreme imbalance
   - Without an AF cohort definition, it's impossible to restrict to AF patients

#### What NHANES *could* contribute

- **Prevalence of antiarrhythmic vs. rate control medication use** among adults with
  CHF (MCQ160B), as a descriptive characterization of current US practice patterns
- However, without AF identification, this analysis conflates AF-related and
  non-AF-related prescribing

**Feasibility score: 1/10**

---

### Q5: LAAC vs Continued Anticoagulation in AF + Dialysis (Gap Score 6)

**Verdict: INFEASIBLE. Cannot be studied in NHANES at all.**

#### Why infeasible

1. **No procedure data.** LAAC (Watchman/Amulet) device implantation cannot be
   identified. NHANES has no procedure codes, device registries, or surgical
   history questions specific enough to capture LAAC.

2. **Extremely small dialysis population.** Only 59 adults reported dialysis in the
   past 12 months across 3 cycles. Of these, only **6** were also taking an
   anticoagulant. This is far below any analytical threshold.

3. **No AF diagnosis.** Cannot confirm these dialysis patients have AF.

4. **No relevant outcomes.** Stroke/SE and bleeding outcomes require claims or EHR data.

#### What NHANES *could* contribute

- Nothing directly relevant. The dialysis population (n=59) could contribute to
  descriptive epidemiology of CKD/ESKD patients, but not to this specific question.

**Feasibility score: 0/10**

---

### Q6: Appropriate vs Inappropriate DOAC Dose Reduction in Elderly (Gap Score 6)

**Verdict: INFEASIBLE for the intended design. Marginal cross-sectional analysis only.**

#### Why infeasible for TTE

1. **Cannot determine DOAC dose from NHANES.** The RXQ_RX table captures the drug name
   (RXDDRUG) but **not the dose or formulation**. "Apixaban" is recorded without
   distinguishing 5 mg BID from 2.5 mg BID. Without dose information, the core
   question — whether dose reduction was guideline-concordant — cannot be assessed.

2. **Cannot assess dose appropriateness.** Even if dose were available, determining
   appropriateness requires knowing the patient's weight, renal function, and age at
   the time of prescribing — NHANES provides these at the exam visit, but the
   prescription may have been written months earlier when parameters differed.

3. **Sample size.** Elderly (≥75) DOAC users total 76 across 3 cycles (apixaban 29,
   rivaroxaban 36, dabigatran 11). Splitting this into "appropriate" vs "inappropriate"
   dosing groups would yield analytically useless cell sizes.

4. **No incident outcomes.** Stroke and bleeding events require longitudinal follow-up.

#### What NHANES *could* contribute

- **National prevalence of DOAC use among elderly US adults** by drug type, with
  characterization of renal function (eGFR), body weight, and CHA₂DS₂-VASc risk
  factor components
- This is a descriptive epidemiologic contribution (Category C: cross-sectional),
  not TTE

**Feasibility score: 1/10**

---

## Summary Table

| # | Question | TTE Feasible? | Alternative Design? | Key Blocker | NHANES N (intersection) | Score |
|---|----------|:------------:|:-------------------:|-------------|:-----------------------:|:-----:|
| 1 | Apixaban vs rivaroxaban in AF + CKD | **No** | Descriptive prevalence | No new-user design; n ≈ 3-5 in target population | ~12 (any AC + eGFR<30) | 1/10 |
| 2 | Catheter ablation vs AADs in AF + HFpEF | **No** | None | No procedure codes; no EF data | 0 | 0/10 |
| 3 | DOACs vs warfarin in AF + cirrhosis | **No** | Descriptive FIB-4 | No new-user design; n = 6 DOAC+liver | 25 (any AC + liver) | 1/10 |
| 4 | Early rhythm vs usual care in AF + HF | **No** | Practice pattern prevalence | No AF dx; no temporal data; no HF hospitalization | ~120 AAD users (no AF filter) | 1/10 |
| 5 | LAAC vs anticoag in AF + dialysis | **No** | None | No procedure codes; n = 6 AC+dialysis | 6 | 0/10 |
| 6 | DOAC dose reduction in elderly | **No** | Descriptive prevalence | No dose data in NHANES | 76 (elderly DOAC) | 1/10 |

---

## What NHANES Uniquely Offers for AF Research

While NHANES cannot support TTE for these questions, it provides capabilities that
claims and EHR databases lack:

1. **Nationally representative prevalence estimates** of anticoagulant prescribing
   patterns, using survey weights to project to the US adult population
2. **Lab-based CKD staging** (serum creatinine → eGFR via CKD-EPI equation; urine
   ACR for albuminuria) — more accurate than ICD-code-based CKD identification
3. **Liver fibrosis scoring** (FIB-4 from AST, ALT, platelets, age) to characterize
   subclinical liver disease burden among medication users
4. **Rich confounder data** including measured BMI, blood pressure, HbA1c, lipids,
   smoking biomarkers (cotinine), dietary intake, physical activity, and
   socioeconomic variables — all from standardized protocols, not billing codes
5. **Mortality linkage** with up to 6 years of follow-up (2013-2014 cycle through
   December 31, 2019)

### Recommended Alternative NHANES Analyses

If an NHANES protocol is desired for this therapeutic area, the most defensible
designs would be:

- **Prevalent anticoagulant use → all-cause mortality in CKD subgroups** (Category A
  TTE with prevalent-user caveats). Exposure: current warfarin vs current DOAC.
  Outcome: linked mortality. Population: adults with eGFR < 60. Expected sample:
  ~130 AC users with eGFR < 60. This is the only design that approaches minimum
  analytical thresholds, but prevalent-user bias would severely limit causal
  interpretation.

- **Cross-sectional descriptive analysis** of anticoagulant prescribing patterns by
  CKD stage, liver disease status, and age group (Category C). No causal claims,
  but nationally representative prevalence estimates that complement claims-based
  TTE studies.

---

## Conclusion

**NHANES is not a suitable database for any of the six approved TTE questions in
atrial fibrillation.** The fundamental barriers are:

1. No AF diagnosis variable
2. No procedure data (ruling out ablation and LAAC questions)
3. No medication dose data (ruling out dose-appropriateness questions)
4. Cross-sectional medication capture with no initiation dates (ruling out new-user designs)
5. No incident stroke, bleeding, or hospitalization outcomes
6. Small sample sizes at the intersection of specific drugs + specific comorbidities

These are structural limitations of NHANES's cross-sectional survey design, not
data quality issues that could be worked around with creative study design. The
approved questions are best addressed using longitudinal claims or EHR databases
(e.g., PCORnet CDM) that capture treatment initiation, procedure codes, and
incident clinical events over time.
