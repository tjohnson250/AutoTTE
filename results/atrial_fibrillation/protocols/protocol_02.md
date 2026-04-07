# Protocol 02: Early Rhythm Control vs Rate Control in Elderly AF Patients (Age >= 80)

**Target Trial Emulation Protocol**
**Date:** 2026-04-06
**Data Source:** PCORnet CDW (institutional Clinical Data Warehouse, MS SQL Server)
**Gap Score:** 8/10

---

## 1. Clinical Context and Evidence Gap

### Background

Atrial fibrillation (AF) is the most common sustained cardiac arrhythmia, with prevalence rising sharply with age. Among patients aged 80 and older, AF prevalence exceeds 10-15%, and these patients carry disproportionate burdens of stroke, heart failure, and cardiovascular death. The fundamental management decision in AF -- whether to pursue rhythm control (restoring and maintaining sinus rhythm) or rate control (allowing AF to persist while controlling ventricular rate) -- has been debated for decades.

### Landmark RCT Evidence

Several landmark trials compared rhythm control vs rate control strategies:

- **AFFIRM** (PMID: 12466506, 2002): The largest rate-vs-rhythm trial (N=4,060). No survival benefit with rhythm control; trend toward increased mortality (possibly from antiarrhythmic drug toxicity). Mean age 69.7 years. Led to a decade of rate-control-first practice.
- **RACE** (PMID: 12466507, 2002): Noninferior outcomes with rate control vs rhythm control (N=522). Dutch multicenter trial.
- **AF-CHF** (PMID: 18083932, 2008): In AF patients with HF (LVEF <=35%), rhythm control did not reduce cardiovascular death vs rate control (N=1,376).
- **EAST-AFNET 4** (PMID: 32865375, 2020): The paradigm-shifting trial. In patients with EARLY AF (diagnosed within 12 months), early rhythm control reduced the composite of CV death, stroke, and HF hospitalization vs rate control (HR 0.79, 96% CI 0.66-0.94, N=2,789). Median age 70. This trial changed guidelines to favor early rhythm control.

### The Evidence Gap in Octogenarians

EAST-AFNET 4 enrolled patients aged 65-85, but the proportion aged >= 80 was small (~8%). Post-hoc age analyses suggest the benefit of early rhythm control **attenuates with increasing age** (PMID: 35589174). Specifically:

- Patients < 65: Strong benefit (HR ~0.55)
- Patients 65-74: Moderate benefit (HR ~0.75)
- Patients >= 75: Attenuated/uncertain benefit (HR ~0.90, CI crosses 1.0)

Whether the EAST-AFNET 4 benefit extends to octogenarians (>= 80) is unknown because:

1. **RCTs systematically underrepresent the very elderly.** AFFIRM had an upper age limit of ~80 in practice; EAST-AFNET 4 capped at 85.
2. **Octogenarians have competing risks.** Non-cardiovascular mortality may dominate, reducing the relative benefit of rhythm control.
3. **Antiarrhythmic drug toxicity is higher in the elderly.** Amiodarone (the most commonly used AAD in the elderly) has pulmonary, thyroid, and hepatic toxicity. Flecainide and sotalol carry proarrhythmic risk, particularly in patients with structural heart disease (common in this age group).
4. **Ablation is rarely performed in octogenarians.** The procedural risk-benefit ratio shifts unfavorably.
5. **Polypharmacy and frailty** create additional confounding and risk.

A recent observational analysis using Korean National Health Insurance data (PMID: 35589174) found that early rhythm control was associated with reduced CV outcomes in younger AF patients but the benefit was attenuated in older age groups, with no significant benefit above age 75. However, this study was conducted in an Asian population with different comorbidity profiles and treatment patterns than US populations.

### Clinical Relevance

Octogenarians represent the fastest-growing segment of AF patients. Current guidelines (2023 ACC/AHA/ACCP/HRS, PMID: 38033089) recommend consideration of rhythm control in symptomatic AF but provide no age-specific guidance for the very elderly. Clinicians face genuine uncertainty: should an 83-year-old with newly diagnosed AF be started on amiodarone or simply have their heart rate controlled with a beta-blocker? This protocol addresses that question using real-world data from a population systematically excluded from RCTs.

### Guideline Context

- **2023 ACC/AHA/ACCP/HRS AF Guideline** (PMID: 38033089): Recommends rhythm control for symptomatic AF and early rhythm control for AF diagnosed within 12 months (Class I). No age-specific exemption, but acknowledges limited evidence in the very elderly.
- **2020 ESC AF Guidelines** (PMID: 32860505): Similar recommendation for early rhythm control based on EAST-AFNET 4. Notes that evidence in patients >75 is limited.

---

## 2. Target Trial Specification

### 2.1 Eligibility Criteria

**Inclusion:**
1. Adults aged >= 80 years at the time of first AF diagnosis
2. Newly diagnosed AF: first ICD-10 I48.x code with no prior I48.x code in the preceding 365 days
3. Received at least one rhythm-control or rate-control medication/procedure within 12 months of AF diagnosis
4. At least one non-legacy encounter in the CDW within 365 days before AF diagnosis (evidence of active care)

**Exclusion:**
1. Prior AF diagnosis (I48.x) within 365 days before the qualifying AF encounter (ensures incident AF)
2. Patients receiving NEITHER rhythm control NOR rate control within 12 months of AF diagnosis (untreatable or no documented treatment)
3. Death within 12 months of AF diagnosis (landmark survival requirement)

### 2.2 Treatment Strategies

**Intervention -- Early Rhythm Control:**
Any of the following within 12 months of AF diagnosis:
- **Antiarrhythmic drug (AAD) prescription:**
  - Amiodarone (oral): RXCUI 835956, 833528, 835960, 834348, 833530, 835958, 834346, 834350
  - Flecainide: RXCUI 886662, 886666, 886671
  - Sotalol (all formulations including AF-labeled): RXCUI 904634, 1923426, 1923422, 1923424, 904632, 904589, 1922765, 1922720, 1922763, 904605, 904571, 904583, 904593, 1923427, 1923423, 1923425, 904591, 1922766, 1922721, 1922764
  - Dronedarone: RXCUI 854856, 854859
  - Dofetilide: RXCUI 310003, 310004, 310005, 284404, 284405, 285016
  - Propafenone (IR + ER): RXCUI 861424, 861427, 861430, 861156, 861164, 861171, 861159, 861167, 861173
- **Cardioversion:** CPT 92960 (external), 92961 (internal)
- **Catheter ablation:** CPT 93656 (pulmonary vein isolation), 93657 (additional ablation)

**Comparator -- Rate Control:**
ONLY rate-control agents within 12 months of AF diagnosis, with NO AAD, cardioversion, or ablation:
- Metoprolol (tartrate + succinate): RXCUI 866924, 866514, 866511, 2723025, 1606347, 1606349, 866427, 866436, 866412, 866419, 866429, 866438, 866414, 866421
- Diltiazem (IR + ER): RXCUI 833217, 831103, 831102, 831054, 830861, 830845, 830837, 830801, 830795, 831359, 830874, 830877, 830879, 830882, 830897, 830900
- Verapamil (IR + ER): RXCUI 897722, 897683, 897666, 901438, 901446, 897584, 897612, 897618, 897590, 897624, 897596, 897630, 897659, 897640, 897649
- Digoxin: RXCUI 245273, 197604, 197606, 393245, 309888, 309889, 260350, 260351, 1245443, 1245373

**Classification logic (ITT from first strategy):**
- If a patient receives ANY rhythm-control intervention at any point within 12 months, they are classified as **rhythm control**, even if they also received rate-control agents (which is expected and common).
- If a patient receives ONLY rate-control agents (no AAD, no cardioversion, no ablation) within 12 months, they are classified as **rate control**.
- Treatment crossover after the 12-month classification window does not change the assigned group (intention-to-treat principle).

### 2.3 Assignment Procedure

Treatment assignment is non-randomized. Assignment is determined by the clinical strategy received within 12 months of AF diagnosis. Confounding by indication is addressed through inverse probability of treatment weighting (IPW) using a propensity score model. Key confounders driving treatment selection include age, sex, comorbidities (especially HF, which drives rhythm control preference), CHA2DS2-VASc score, renal function, and baseline vital signs.

### 2.4 Time Zero and Landmark Design

**Time zero (enrollment):** Date of first AF diagnosis (first I48.x code at age >= 80 with no prior I48.x in >= 365 days).

**Landmark design:** This protocol uses a 12-month landmark approach to handle the treatment classification window:
1. Patients are enrolled at time zero (AF diagnosis)
2. Treatment strategy is classified based on what occurs in the 12 months after time zero
3. Patients who die or are lost to follow-up before the 12-month landmark are **excluded** (landmark survival requirement)
4. Outcome assessment begins at the 12-month landmark (day 366)
5. Follow-up continues for up to 1,095 additional days (3 years) from the landmark, or until death, end of study period, or loss to follow-up

**Rationale for landmark design:** Without the landmark requirement, patients in the rate-control group would accumulate "immortal time" during the classification window -- they cannot be classified as rhythm control (by dying before receiving an AAD), creating a systematic bias. The landmark approach ensures both groups have survived the classification period and follow-up begins on equal footing.

### 2.5 Outcome Definition and Measurement Window

**Primary outcome -- Composite of:**
1. **Cardiovascular death:** Death (CDW.dbo.DEATH) with a cardiovascular cause code (I-codes) in CDW.dbo.DEATH_CAUSE. If DEATH_CAUSE is poorly populated (<30% of deaths have a cause code), **all-cause death** is substituted as the death component.
2. **Stroke:** First occurrence of ischemic stroke (I63.x) or hemorrhagic stroke (I61.x) on an inpatient encounter (ENC_TYPE IN ('IP','EI')) after the landmark.
3. **HF hospitalization:** First occurrence of heart failure (I50.x) as a diagnosis on an inpatient encounter (ENC_TYPE IN ('IP','EI')) after the landmark.

The composite is defined as the **first occurrence of any component**.

**Secondary outcomes:**
1. All-cause mortality
2. Cardiovascular death (if DEATH_CAUSE is sufficiently populated)
3. Ischemic stroke (I63.x) alone
4. HF hospitalization (I50.x on IP/EI) alone
5. AF-related hospitalization: I48.x as primary or any diagnosis on an IP/EI encounter

**Follow-up window:** 1,095 days (3 years) from the 12-month landmark. Patients are censored at death (for non-mortality outcomes), end of study period (2024-12-31), or end of follow-up window, whichever comes first.

### 2.6 Causal Contrast and Estimand

**Causal contrast:** Average Treatment Effect (ATE) of early rhythm control vs rate control on the composite CV outcome in elderly AF patients aged >= 80.

**Estimand:** The marginal hazard ratio comparing rhythm control to rate control, estimated via IPW-weighted Cox proportional hazards regression. This answers: "What would the hazard of the composite outcome have been if the entire eligible population had received early rhythm control, compared to if they had all received rate control?"

---

## 3. Emulation Using Observational Data

### 3.1 Target Dataset and Justification

**Dataset:** PCORnet CDW (institutional Clinical Data Warehouse) on MS SQL Server.
**Connection:** `DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")`

**Justification:**
- **86,308 AF patients** (I48.x, ICD-10) provide a large base population
- **Estimated 12,000-16,000 newly diagnosed AF patients >= 80** with adequate treatment arm sizes
- Rhythm control arm (~3,000-5,000) and rate control arm (~6,000-10,000) are well-populated
- Rich confounder data: demographics, comorbidities, labs (eGFR, HbA1c, hemoglobin), vitals, concomitant medications
- Medication data via PRESCRIBING (RXNORM_CUI) with 98.6% completeness
- Procedure data via PROCEDURES for cardioversion and ablation codes

### 3.2 Study Period

**2016-01-01 to 2024-12-31**

Justification:
- ICD-10 fully in effect from 2016 (Oct 2015 transition; by 2016, ICD-10 is dominant per CDW data profile Section 4)
- Ending 2024 to ensure patients diagnosed up to 2023-12-31 have a full 12-month classification window, with some follow-up beyond the landmark
- Study period spans both AllScripts (pre-2020) and Epic (post-2020) eras; legacy encounter filtering (`RAW_ENC_TYPE <> 'Legacy Encounter'`) is REQUIRED on all encounter joins
- Sensitivity analysis restricted to 2021+ (post-Epic only) is included

### 3.3 Variable Mapping

| Protocol Element | CDW Table | Column(s) | Codes / Logic |
|-----------------|-----------|-----------|---------------|
| **Population: AF, age >= 80** | DIAGNOSIS + DEMOGRAPHIC | DX, BIRTH_DATE | DX LIKE 'I48%' AND DX_TYPE = '10' AND age >= 80 |
| **Newly diagnosed AF** | DIAGNOSIS | DX, ADMIT_DATE | First I48.x with no prior I48.x in >= 365 days |
| **Rhythm control: AADs** | PRESCRIBING | RXNORM_CUI | See Section 2.2 for complete RXCUI list |
| **Rhythm control: Cardioversion** | PROCEDURES | PX, PX_TYPE | PX IN ('92960','92961') AND PX_TYPE = 'CH' |
| **Rhythm control: Ablation** | PROCEDURES | PX, PX_TYPE | PX IN ('93656','93657') AND PX_TYPE = 'CH' |
| **Rate control: Beta-blockers** | PRESCRIBING | RXNORM_CUI | Metoprolol RXCUIs (see Section 2.2) |
| **Rate control: CCBs** | PRESCRIBING | RXNORM_CUI | Diltiazem, verapamil RXCUIs (see Section 2.2) |
| **Rate control: Digoxin** | PRESCRIBING | RXNORM_CUI | Digoxin RXCUIs (see Section 2.2) |
| **CV death** | DEATH + DEATH_CAUSE | DEATH_DATE, DEATH_CAUSE | Death with DEATH_CAUSE LIKE 'I%' AND DEATH_CAUSE_CODE = '10' |
| **Stroke** | DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I63.x OR I61.x on IP/EI encounter |
| **HF hospitalization** | DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I50.x on IP/EI encounter |
| **All-cause mortality** | DEATH | DEATH_DATE | Any death record (ROW_NUMBER deduplicated) |
| **AF hospitalization** | DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I48.x on IP/EI encounter |
| **Age** | DEMOGRAPHIC | BIRTH_DATE | DATEDIFF(year, BIRTH_DATE, index_date) |
| **Sex, race, ethnicity** | DEMOGRAPHIC | SEX, RACE, HISPANIC | Standard PCORnet codes |
| **BMI, BP** | VITAL | ORIGINAL_BMI, SYSTOLIC, DIASTOLIC | Most recent within 365 days before index |
| **eGFR** | LAB_RESULT_CM | LOINC 48642-3, 62238-1 | Most recent within 180 days |
| **HbA1c** | LAB_RESULT_CM | LOINC 4548-4 | Most recent within 180 days |
| **Hemoglobin** | LAB_RESULT_CM | LOINC 718-7 | Most recent within 180 days |
| **Comorbidities** | DIAGNOSIS | DX, DX_TYPE | 365-day lookback (HF, HTN, DM, CKD, stroke/TIA, vascular disease) |
| **CHA2DS2-VASc** | Derived | Multiple | Computed from age, sex, comorbidities |
| **OAC use** | PRESCRIBING | RXNORM_CUI | Any DOAC or warfarin within 90 days of index |

### 3.4 Legacy Encounter Handling

**Decision: Exclude legacy encounters.** All ENCOUNTER joins include `e.RAW_ENC_TYPE <> 'Legacy Encounter'` to prevent double-counting of AllScripts records that were re-imported into Epic. This applies to:
- The index AF diagnosis encounter
- Outcome encounters (stroke, HF hospitalization, AF hospitalization)
- Procedure identification (cardioversion, ablation)

**Exception:** Comorbidity lookback uses `EXISTS` subqueries against DIAGNOSIS (not encounter-joined), which is acceptable per WORKER.md guidelines since the purpose is binary "any prior diagnosis" and double-counting is harmless.

---

## 4. Statistical Analysis Plan

### 4.1 Primary Analysis: IPW-Weighted Cox Proportional Hazards

**Method:** Inverse Probability of Treatment Weighting (IPW) with logistic regression propensity score model, followed by weighted Cox proportional hazards regression.

**Estimand:** ATE (Average Treatment Effect).

**Propensity score model:** Logistic regression predicting P(rhythm control | covariates):

Confounders:
- Demographics: age_at_index, sex, race, ethnicity
- Vitals: BMI, systolic BP, diastolic BP
- Labs: eGFR, HbA1c, hemoglobin
- Comorbidities: HF, hypertension, diabetes, CKD, prior stroke/TIA, vascular disease, prior bleeding, COPD, dementia
- CHA2DS2-VASc score
- Concomitant medications: OAC use, statin, ACEi/ARB
- Calendar year of AF diagnosis (secular trends in rhythm control adoption)

The PS formula is built dynamically, dropping single-level factors and zero-variance numeric columns.

**Balance diagnostics:**
- Love plot with |SMD| < 0.1 threshold
- Effective sample size calculation
- PS distribution overlap assessment

**Outcome models:** Weighted Cox PH for each outcome:
- Primary: `Surv(time_to_composite, composite_event) ~ treatment`
- Secondary: Separate models for each secondary outcome

### 4.2 Subgroup Analyses

Pre-specified subgroups (composite outcome):
1. Age 80-84 vs >= 85
2. Sex (female vs male)
3. CHA2DS2-VASc score (< 5 vs >= 5)
4. Heart failure (yes vs no)
5. CKD (yes vs no)

Each subgroup re-fits the propensity score model within the subgroup to account for different confounder distributions. Minimum 10 patients per arm within each subgroup.

### 4.3 Sensitivity Analyses

1. **E-value analysis:** Quantifies the strength of unmeasured confounding required to explain away the observed association. Uses `evalues.HR()` with `rare = TRUE` (outcome incidence < 15%).

2. **PS trimming (5th-95th percentile):** Restricts to patients within the PS overlap region to reduce influence of extreme weights.

3. **Post-Epic era only (2021+):** Restricts to the Epic EHR era to eliminate potential data quality differences between AllScripts and Epic periods.

4. **90-day grace period sensitivity:** Re-classifies patients based on treatment received within 90 days (instead of 12 months) of AF diagnosis, with a 90-day landmark. This tests whether results are sensitive to the length of the classification window.

5. **All-cause mortality substitution:** If the primary composite uses CV death (from DEATH_CAUSE), a sensitivity analysis substitutes all-cause death to assess robustness to cause-of-death misclassification.

---

## 5. Limitations and Threats to Validity

### 5.1 Unmeasured Confounding

- **LVEF (ejection fraction):** Not captured as structured data. Patients with HFrEF may be more likely to receive amiodarone (the only AAD safe in HFrEF). This is a strong driver of treatment selection that cannot be adjusted for.
- **Symptom severity (EHRA score):** Not available. Symptomatic patients are more likely to receive rhythm control. This creates confounding by indication.
- **Left atrial size:** Larger left atria predict AF recurrence and may discourage rhythm control attempts. Not available.
- **Frailty:** Not directly captured. Frailer patients may be less likely to receive rhythm control (or more likely to receive amiodarone over ablation). Partially captured through comorbidity burden.
- **Smoking:** 99.8% unknown/NI in the CDW VITAL table -- effectively unusable.

### 5.2 Methodological Limitations

- **Landmark bias:** The 12-month landmark excludes patients who die within 12 months of AF diagnosis. If rhythm control reduces early mortality, this would be missed. If rhythm control increases early mortality (e.g., proarrhythmia), this would also be missed. The landmark analysis captures only the long-term effect conditional on surviving the initial treatment period.
- **Treatment crossover:** After the 12-month classification, patients may cross over. The ITT analysis does not account for this, which will dilute the treatment effect estimate toward the null.
- **CV death ascertainment:** DEATH_CAUSE table completeness is uncertain. If poorly populated, falling back to all-cause mortality introduces misclassification of the composite outcome.
- **Competing risks:** All-cause mortality competes with non-fatal outcomes. In this elderly population, competing mortality is high and may differential between treatment groups.

### 5.3 Data Limitations

- Study spans AllScripts and Epic eras, with potential data quality shifts at the Epic transition (~2019-2020). Sensitivity analysis restricted to post-Epic era addresses this.
- PRESCRIBING captures orders, not necessarily dispensing or adherence. Patients may not fill prescriptions.
- Cardioversion and ablation identification relies on CPT codes in PROCEDURES; some may be missed if coded differently.
- The CDW is a single-center dataset, limiting generalizability.

---

## 6. Expected Results and Interpretation

Based on the existing literature:
- We expect the rhythm control arm to have **more comorbidities** at baseline (especially HF and prior stroke), as sicker patients are more likely to be referred for rhythm control.
- After IPW adjustment, we hypothesize that early rhythm control will show either a **null or modest benefit** (HR 0.85-1.05) for the composite outcome in octogenarians, consistent with the age-attenuation pattern observed in EAST-AFNET 4 post-hoc analyses.
- The all-cause mortality analysis will be important because competing non-cardiovascular mortality may dominate in this age group.
- Subgroup analysis by age 80-84 vs >= 85 may reveal that any rhythm control benefit is limited to the "younger old" (80-84) and absent in the "oldest old" (>= 85).
