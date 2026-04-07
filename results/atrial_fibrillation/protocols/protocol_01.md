# Protocol 01: Apixaban vs Rivaroxaban for Stroke Prevention in AF Patients with CKD Stage 3b-5

**Target Trial Emulation Protocol**
**Date:** 2026-04-06
**Data Source:** PCORnet CDW (institutional Clinical Data Warehouse, MS SQL Server)
**Gap Score:** 7/10

---

## 1. Clinical Context and Evidence Gap

### Background

Atrial fibrillation (AF) and chronic kidney disease (CKD) frequently coexist, with 15-30% of AF patients having concurrent CKD (PMID: 31648714). This overlap creates a clinical challenge: CKD patients with AF are simultaneously at elevated risk for ischemic stroke (due to AF-related thromboembolism) and major bleeding (due to uremic platelet dysfunction and impaired drug clearance). Direct oral anticoagulants (DOACs) have largely replaced warfarin for stroke prevention in AF, but the comparative effectiveness of individual DOACs in moderate-to-severe CKD (eGFR < 45 mL/min/1.73m2) remains uncertain.

### Landmark RCT Evidence

The four pivotal DOAC trials each compared a single DOAC to warfarin — not to each other:

- **ARISTOTLE** (PMID: 21870978): Apixaban was superior to warfarin for stroke/SE prevention, with lower major bleeding and lower mortality (N=18,201). The trial excluded patients with eGFR < 25 mL/min.
- **ROCKET AF** (PMID: 21830957): Rivaroxaban was noninferior to warfarin for stroke/SE, with similar major bleeding (N=14,264). The trial excluded patients with CrCl < 30 mL/min.
- **RE-LY** (PMID: 19717844): Dabigatran 150mg showed lower stroke/SE than warfarin; excluded CrCl < 30 mL/min.
- **ENGAGE AF-TIMI 48** (PMID: 24251359): Edoxaban was noninferior with lower bleeding; excluded CrCl < 30 mL/min.

No head-to-head RCT has compared any two DOACs directly. All trials systematically excluded patients with severe CKD (eGFR < 25-30), which represents the very population where comparative safety data is most needed.

### Observational Evidence for DOAC-vs-DOAC Comparisons

Large observational studies consistently suggest an apixaban safety advantage over rivaroxaban in general AF populations:

- **Lip et al.** (PMID: 36315950, 2022): Multinational population-based cohort across 6 countries. Apixaban had the lowest major bleeding rate among DOACs.
- **Ray et al.** (PMID: 34932078, 2021): US claims-based cohort. Rivaroxaban was associated with higher ischemic and hemorrhagic event rates compared to apixaban.
- **Dawwas et al.** (PMID: 36252244, 2022): Population-based study in AF with valvular heart disease (N=19,894 matched). Apixaban showed lower stroke/SE (HR 0.57) and bleeding (HR 0.51) versus rivaroxaban.
- **Douros et al.** (PMID: 39154873, 2024): Population-based cohort demonstrating apixaban had lower major bleeding than rivaroxaban regardless of baseline bleeding risk level.
- **Noseworthy et al.** (PMID: 32283966, 2020): Instrumental variable analysis confirming higher stroke risk with rivaroxaban versus apixaban.

### The CKD Evidence Gap

Despite growing general-population data, head-to-head DOAC comparisons in CKD remain sparse:

- **US Nationwide Cohort** (PMID: 37839687, 2024): The key study — a claims-based cohort in CKD stages 4/5 showing rivaroxaban and warfarin both associated with higher major bleeding compared to apixaban. This is the only large direct DOAC-vs-DOAC comparison in advanced CKD.
- **Mavrakanas et al.** (PMID: 38035566, 2023): Review concluding DOACs are preferred over warfarin in moderate CKD but evidence is limited in severe CKD/dialysis. No DOAC-vs-DOAC data synthesized.
- **Shin et al.** (PMID: 38744617, 2024): JAMA systematic review of DOACs in CKD, finding limited dose-comparison data.
- **Scoping review** (PMID: 41733864, 2026): Explicitly identifies "limited dose-comparison studies, heterogeneous outcomes, and sparse data in non-dialysis patients" as the critical gap.
- **CODE-AF Registry** (PMID: 36579375, 2022): DOACs vs warfarin in advanced CKD/dialysis. Lower bleeding with DOACs, but no DOAC-to-DOAC comparison.
- **Apixaban PK review** (PMC: 11344734, 2024): Apixaban pharmacokinetics remain consistent across CKD stages, supporting its use in renal impairment. Apixaban has the lowest renal clearance (~27%) among DOACs versus rivaroxaban (~36%).

### Pharmacokinetic Rationale

Apixaban has the lowest renal clearance of all DOACs (~27%, compared to ~36% for rivaroxaban, ~80% for dabigatran, and ~50% for edoxaban). This pharmacokinetic property makes apixaban theoretically preferable in CKD, as drug accumulation and bleeding risk are less dependent on residual renal function. The FDA-approved labeling permits apixaban use down to CrCl 15 mL/min and even in dialysis patients, while rivaroxaban is recommended only down to CrCl 15 mL/min with more limited data below CrCl 30.

### Clinical Relevance

Nephrologists and cardiologists face the choice between apixaban and rivaroxaban in AF patients with CKD 3b-5 daily. Non-dialysis CKD stage 3b-4 is the largest underserved population — too sick for RCT inclusion criteria but not yet on dialysis. A well-designed target trial emulation comparing these two DOACs in this population would be among the first formal causal analyses addressing this clinical question and could directly influence prescribing decisions for thousands of patients.

### Guideline Context

The 2023 ACC/AHA/ACCP/HRS AF guideline (PMID: 38033089) recommends DOACs over warfarin for AF patients with CKD not on dialysis (Class I, Level A), but does not recommend one DOAC over another in this population due to insufficient comparative data.

---

## 2. Target Trial Specification

### 2.1 Eligibility Criteria

**Inclusion:**
1. Adults aged >= 18 years
2. Documented non-valvular AF (ICD-10: I48.0, I48.11, I48.19, I48.20, I48.21, I48.91 — all AF codes excluding flutter)
3. CKD stage 3b-5 (eGFR < 45 mL/min/1.73m2), ascertained by either:
   - **Diagnosis-based:** ICD-10 N18.32 (stage 3b), N18.4 (stage 4), or N18.5 (stage 5) on or before time zero, OR
   - **Lab-based:** eGFR < 45 mL/min/1.73m2 (LOINC 48642-3, 62238-1, 33914-3, 98979-8) within 180 days before time zero
4. New initiation of apixaban or rivaroxaban (first prescription with no prior DOAC use in 365 days)
5. At least one non-legacy encounter in the CDW within 365 days before time zero

**Exclusion:**
1. Valvular AF: rheumatic mitral valve disease (I05.0-I05.9), rheumatic aortic/tricuspid/multiple valve disease (I06.x, I07.x, I08.x), or prosthetic heart valve (Z95.2, Z95.3, Z95.4)
2. ESRD or dialysis at baseline: ICD-10 N18.6, Z99.2, or dialysis procedure codes (CPT 90935-90940, 90945, 90947)
3. Prior use of any DOAC (apixaban, rivaroxaban, dabigatran, edoxaban) within 365 days before time zero (new-user washout)
4. Concurrent use of BOTH apixaban and rivaroxaban within the grace period (ambiguous assignment)
5. Active cancer with expected survival < 6 months (to reduce competing mortality)

### 2.2 Treatment Strategies

- **Intervention (Apixaban arm):** Initiation of apixaban at any dose:
  - 5mg tablets: RXCUI 1364445 (SCD), 1364447 (SBD/Eliquis)
  - 2.5mg tablets: RXCUI 1364435 (SCD), 1364441 (SBD/Eliquis)

- **Comparator (Rivaroxaban arm):** Initiation of rivaroxaban at any dose approved for AF:
  - 20mg tablets: RXCUI 1232086 (SCD), 1232088 (SBD/Xarelto)
  - 15mg tablets: RXCUI 1232082 (SCD), 1232084 (SBD/Xarelto)
  - 10mg tablets: RXCUI 1114198 (SCD), 1114202 (SBD/Xarelto)
  - 2.5mg tablets: RXCUI 2059015 (SCD), 2059017 (SBD/Xarelto)

This is an **active-comparator, new-user** design. Both arms receive anticoagulation — the causal question is whether apixaban produces different rates of stroke/SE and major bleeding compared to rivaroxaban specifically in the CKD 3b-5 population.

### 2.3 Assignment Procedure

Treatment is assigned based on the first DOAC prescription in a patient meeting all eligibility criteria. Assignment is non-randomized and subject to confounding (e.g., physicians may prefer apixaban in patients with worse renal function). Confounding is addressed through inverse probability of treatment weighting (IPW) using a propensity score model with rich covariate adjustment.

### 2.4 Outcome Definition and Measurement Window

**Primary Outcome — Composite of stroke/systemic embolism and major bleeding:**
The primary composite captures the net clinical trade-off inherent to anticoagulation: stroke prevention benefit versus bleeding risk.

**Secondary Outcomes:**

1. **Stroke / systemic embolism (efficacy):**
   - Ischemic stroke: ICD-10 I63.x (all subcodes)
   - Systemic embolism: ICD-10 I74.x (arterial embolism/thrombosis)
   - Ascertained from inpatient/ED encounters (ENC_TYPE IN ('IP', 'EI', 'ED'))
   - First occurrence after time zero within follow-up window

2. **Major bleeding (safety):**
   - Intracranial hemorrhage: ICD-10 I60.x (SAH), I61.x (intracerebral), I62.x (other intracranial)
   - GI bleeding: K92.0 (hematemesis), K92.1 (melena), K92.2 (GI hemorrhage NOS), K62.5 (rectal hemorrhage), K25.0/K25.4 (gastric ulcer with hemorrhage), K26.0/K26.4 (duodenal ulcer with hemorrhage), K27.0/K27.4 (peptic ulcer with hemorrhage), K29.01 (acute gastritis with bleeding)
   - Ascertained from inpatient/ED encounters
   - First occurrence after time zero within follow-up window

3. **GI bleeding (subset of major bleeding):**
   - K92.0, K92.1, K92.2, K62.5, K25.0, K25.4, K26.0, K26.4, K27.0, K27.4, K29.01

4. **All-cause mortality:**
   - Source: CDW.dbo.DEATH table (113,105 patients with death records)
   - Deduplicated using ROW_NUMBER() OVER (PARTITION BY PATID)
   - First death record within follow-up window

**Follow-up and Censoring:**
- Maximum follow-up: 365 days from time zero
- Censored at: end of follow-up (365 days), death (for non-mortality outcomes), end of study period (2025-12-31), or initiation of dialysis (N18.6 / Z99.2 diagnosis or dialysis CPT code after time zero)

### 2.5 Time Zero

**Time zero = date of first DOAC prescription** (apixaban or rivaroxaban) in a patient who has:
1. Prior or concurrent AF diagnosis (I48.x, excluding flutter)
2. Evidence of CKD 3b-5 (diagnosis code OR eGFR < 45 within 180 days before the prescription)
3. No prior DOAC use in the preceding 365 days (new-user design)
4. No ESRD/dialysis

This time-zero definition aligns eligibility, treatment assignment, and follow-up start to avoid immortal time bias. There is no gap between becoming eligible and being assigned to treatment — they occur on the same date.

### 2.6 Causal Contrast and Estimand

**Estimand:** Average Treatment Effect (ATE)

**Causal contrast:** The difference in 365-day risk of the composite outcome (stroke/SE + major bleeding) comparing a world in which all eligible patients received apixaban versus a world in which all received rivaroxaban.

**Justification for ATE:** The ATE is appropriate because the clinical question is population-level: "For a typical AF patient with CKD 3b-5, which DOAC should be prescribed?" Both drugs are genuinely used in this population, making the ATE identifiable.

### 2.7 Follow-up Period

365 days from time zero, reflecting the standard 1-year evaluation window used in anticoagulation outcomes research.

---

## 3. Emulation Using Observational Data

### 3.1 Target Dataset

**PCORnet CDW** — institutional Clinical Data Warehouse on MS SQL Server containing data from ~10 million patients across two EHR eras (AllScripts through ~2019-2020; Epic from ~2019-2020 onward). Connection: `DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")`.

**Study period:** 2016-01-01 to 2025-12-31

Justification:
- ICD-10 transition completed October 2015; 2016 ensures clean ICD-10 coding for CKD substaging (N18.31 vs N18.32)
- Apixaban (FDA approved for AF December 2012) and rivaroxaban (November 2011) both well-established by 2016
- Spans both AllScripts (pre-2020) and Epic (post-2020) EHR eras
- Legacy encounter filtering (`RAW_ENC_TYPE <> 'Legacy Encounter'`) applied throughout to prevent double-counting from AllScripts-to-Epic migration

### 3.2 Variable Mapping

| Protocol Element | CDW Table | Column(s) | Codes / Logic |
|-----------------|-----------|-----------|---------------|
| **AF diagnosis** | CDW.dbo.DIAGNOSIS | DX, DX_TYPE | DX LIKE 'I48%' AND DX_TYPE = '10' (excludes I48.3, I48.4, I48.92 for flutter) |
| **CKD 3b-5 (Dx)** | CDW.dbo.DIAGNOSIS | DX | N18.32 (3b), N18.4, N18.5 |
| **CKD 3b-5 (lab)** | CDW.dbo.LAB_RESULT_CM | LAB_LOINC, RESULT_NUM | LOINC 48642-3/62238-1/33914-3/98979-8, RESULT_NUM < 45 |
| **ESRD/dialysis exclusion** | CDW.dbo.DIAGNOSIS + PROCEDURES | DX, PX | N18.6, Z99.2; CPT 90935, 90937, 90940, 90945, 90947 |
| **Valvular exclusion** | CDW.dbo.DIAGNOSIS | DX | I05.x, I06.x, I07.x, I08.x, Z95.2, Z95.3, Z95.4 |
| **Apixaban exposure** | CDW.dbo.PRESCRIBING | RXNORM_CUI | 1364435, 1364445, 1364441, 1364447 |
| **Rivaroxaban exposure** | CDW.dbo.PRESCRIBING | RXNORM_CUI | 1114198, 1232082, 1232086, 2059015, 1114202, 1232084, 1232088, 2059017 |
| **Prior DOAC washout** | CDW.dbo.PRESCRIBING | RXNORM_CUI, RX_ORDER_DATE | No DOAC RxCUI in 365 days before index |
| **Stroke/SE outcome** | CDW.dbo.DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I63.x, I74.x; IP/ED/EI encounters |
| **Major bleeding outcome** | CDW.dbo.DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I60.x, I61.x, I62.x (ICH); K92.0, K92.1, K92.2, K62.5 (GI bleed); IP/ED/EI encounters |
| **GI bleeding** | CDW.dbo.DIAGNOSIS + ENCOUNTER | DX | K92.0, K92.1, K92.2, K62.5, K25.0, K25.4, K26.0, K26.4, K27.0, K27.4, K29.01 |
| **All-cause mortality** | CDW.dbo.DEATH | DEATH_DATE | ROW_NUMBER() to deduplicate |
| **Demographics** | CDW.dbo.DEMOGRAPHIC | PATID, BIRTH_DATE, SEX, RACE, HISPANIC | Age, sex, race, ethnicity |
| **eGFR (continuous)** | CDW.dbo.LAB_RESULT_CM | LOINC 48642-3, 62238-1 | Most recent within 180 days before index |
| **Serum creatinine** | CDW.dbo.LAB_RESULT_CM | LOINC 2160-0 | Most recent within 180 days before index |
| **HbA1c** | CDW.dbo.LAB_RESULT_CM | LOINC 4548-4 | Most recent within 180 days before index |
| **Hemoglobin** | CDW.dbo.LAB_RESULT_CM | LOINC 718-7 | Most recent within 180 days before index |
| **Platelets** | CDW.dbo.LAB_RESULT_CM | LOINC 777-3 | Most recent within 180 days before index |
| **BMI** | CDW.dbo.VITAL | ORIGINAL_BMI | Most recent within 365 days before index |
| **Blood pressure** | CDW.dbo.VITAL | SYSTOLIC, DIASTOLIC | Most recent within 365 days before index |
| **Comorbidities** | CDW.dbo.DIAGNOSIS | DX, DX_TYPE = '10' | Lookback 365 days (see Section 3.3) |
| **Concomitant meds** | CDW.dbo.PRESCRIBING | RXNORM_CUI | Within 90 days before index |
| **Enrollment** | CDW.dbo.ENROLLMENT | ENR_BASIS | Active at time zero |

### 3.3 Confounder Definitions

**Comorbidities** (binary, any occurrence within 365 days before time zero):

| Comorbidity | ICD-10 Pattern | Rationale |
|-------------|---------------|-----------|
| Heart failure | I50.x | Increases stroke and bleeding risk |
| Hypertension | I10, I11.x, I12.x, I13.x, I15.x, I16.x | CHA2DS2-VASc component |
| Diabetes | E10.x, E11.x, E13.x | CHA2DS2-VASc component, affects CKD progression |
| Prior ischemic stroke/TIA | I63.x, G45.x | CHA2DS2-VASc component, strongest stroke predictor |
| Prior systemic embolism | I74.x | CHA2DS2-VASc component |
| Prior MI / vascular disease | I21.x, I25.x, I70.x | CHA2DS2-VASc component |
| Prior major bleeding | I60.x, I61.x, I62.x, K92.x | Bleeding risk factor, may drive DOAC choice |
| Liver disease | K70.x-K74.x | Affects drug metabolism and bleeding risk |
| Anemia | D50.x-D64.x | Bleeding risk factor |
| Obesity | E66.x | Affects drug pharmacokinetics |
| Cancer (active) | C00-C97 | Competing mortality risk |

**Concomitant medications** (binary, any prescription within 90 days before time zero):

| Medication | RXNORM_CUI Strategy | Rationale |
|------------|---------------------|-----------|
| Antiplatelet (aspirin, clopidogrel, prasugrel, ticagrelor) | PRESCRIBING RXNORM_CUI | Increases bleeding risk with anticoagulation |
| Statin | PRESCRIBING RXNORM_CUI | Surrogate for cardiovascular care quality |
| ACE inhibitor / ARB | PRESCRIBING RXNORM_CUI | CKD management, cardiovascular protection |
| Beta-blocker | PRESCRIBING RXNORM_CUI | AF rate control |
| Proton pump inhibitor | PRESCRIBING RXNORM_CUI | GI bleeding prophylaxis |
| NSAID | PRESCRIBING RXNORM_CUI | Increases GI bleeding risk |

### 3.4 Legacy Encounter Handling

All ENCOUNTER joins include `AND e.RAW_ENC_TYPE <> 'Legacy Encounter'` to exclude duplicate records from the AllScripts-to-Epic migration. This is applied to:
- Encounter-based eligibility checks
- Outcome ascertainment (diagnosis-encounter links)
- Vital and lab date filtering (where encounter-linked)

For comorbidity lookback (binary "any prior diagnosis" indicators), legacy encounters are also excluded for consistency, although double-counting would be harmless for EXISTS-based checks.

### 3.5 CKD Ascertainment Strategy

We use a **dual strategy** combining diagnosis codes and laboratory data:

1. **Diagnosis codes:** N18.32 (CKD 3b), N18.4 (CKD stage 4), N18.5 (CKD stage 5). We exclude N18.30 (unspecified stage 3) and N18.31 (stage 3a) because eGFR 45-59 is stage 3a and above our threshold.

2. **Lab values:** eGFR < 45 mL/min/1.73m2 from LAB_RESULT_CM using LOINCs:
   - 48642-3 (GFR/BSA predicted by creatinine, serum/plasma)
   - 62238-1 (GFR/BSA predicted by creatinine and cystatin C)
   - 33914-3 (GFR/BSA predicted by creatinine, MDRD)
   - 98979-8 (GFR/BSA predicted by creatinine, CKD-EPI 2021)

The dual strategy captures patients who have CKD but may lack a coded diagnosis (e.g., nephrology consult not yet completed) and vice versa. The CDW has 167,036 patients with eGFR data (LOINC 48642-3) and 38,009 with CKD stage 3 diagnoses.

---

## 4. Statistical Analysis Plan

### 4.1 Primary Analysis: Inverse Probability Weighting (IPW)

**Method:** Propensity score estimation via logistic regression, followed by inverse probability weighting to create a pseudo-population in which treatment assignment is independent of measured confounders. Weighted Cox proportional hazards models estimate the hazard ratio (HR) for each outcome.

**Steps:**
1. Estimate the propensity score: P(apixaban | confounders) using logistic regression
2. Compute stabilized IPW weights
3. Assess covariate balance using absolute standardized mean differences (SMD); target SMD < 0.10
4. Fit weighted Cox PH models for each outcome with robust (sandwich) variance estimation
5. Generate weighted Kaplan-Meier curves for visual comparison

**Confounder set for the PS model:**
- Demographics: age_at_index, sex, race, ethnicity
- Renal function: eGFR (continuous), serum creatinine
- Vitals: BMI, systolic BP, diastolic BP
- Labs: HbA1c, hemoglobin, platelets
- Comorbidities: heart failure, hypertension, diabetes, prior stroke/TIA, prior MI/vascular disease, prior bleeding, liver disease, anemia, obesity, cancer
- Medications: antiplatelet, statin, ACEi/ARB, beta-blocker, PPI, NSAID
- CKD stage category (3b vs 4 vs 5)
- Calendar year of index date
- Enrollment basis

**Dynamic formula construction:** The PS formula is built dynamically by dropping single-level factors and zero-variance numeric covariates. This prevents model fitting errors in small subgroups.

### 4.2 Balance Diagnostics

- **Love plot:** Absolute SMD before and after weighting, with threshold at 0.10
- **Propensity score distribution:** Overlapping density plots by treatment group to assess positivity
- **Effective sample size (ESS):** Reported for both arms to quantify weight-induced precision loss

### 4.3 Subgroup Analyses

Pre-specified subgroups:
1. **CKD stage:** 3b (eGFR 30-44) vs 4-5 (eGFR < 30)
2. **Age:** < 75 vs >= 75 years
3. **Sex:** Male vs Female
4. **DOAC dose:** Standard dose vs reduced dose (apixaban 5mg vs 2.5mg; rivaroxaban 20mg vs 15mg/10mg)
5. **Prior bleeding:** Yes vs No
6. **Diabetes:** Yes vs No

Each subgroup analysis re-fits the PS model within the subgroup (since treatment assignment mechanisms may differ) and reports the weighted HR with 95% CI. Interaction p-values are reported but interpreted cautiously given multiple comparisons.

### 4.4 Sensitivity Analyses

1. **E-value analysis:** Quantifies the minimum strength of unmeasured confounding (on the risk ratio scale) needed to explain away the observed association. Uses `evalues.HR()` with `rare = TRUE` (outcome incidence expected < 15%).

2. **PS trimming:** Exclude patients with extreme propensity scores (< 5th or > 95th percentile) to assess whether results are driven by patients with very high or very low probability of receiving apixaban. Re-estimates HR in the trimmed population.

3. **As-treated analysis:** Censor patients at treatment discontinuation or switching (identified by a gap of > 60 days in PRESCRIBING records for the index drug, or a new prescription for the comparator drug). This addresses the ITT assumption of the primary analysis.

4. **Post-Epic era only (2021+):** Restricts to encounters from the Epic era (post-2020) to assess whether results are robust to the EHR transition.

5. **Calendar time adjustment:** Include index year as a covariate to account for temporal trends in DOAC prescribing patterns.

---

## 5. Estimated Sample Size

Based on the CDW data profile and feasibility assessment:
- AF patients (I48.x): 86,308
- Apixaban users in CDW: 6,664 total
- Rivaroxaban users in CDW: 3,410 total
- AF + CKD 3b-5 overlap (dual ascertainment): estimated 8,000-15,000 patients
- **Apixaban arm (AF + CKD + new user):** ~1,500-2,500
- **Rivaroxaban arm (AF + CKD + new user):** ~700-1,200
- **Total estimated analytic cohort:** 2,200-3,700

This sample size is adequate for the composite primary outcome (expected event rate ~10-15% at 1 year) but may limit power for individual secondary outcomes, particularly intracranial hemorrhage. Subgroup analyses by CKD stage 4-5 (eGFR < 30) will have the smallest sample sizes and should be interpreted as exploratory.

---

## 6. Limitations and Threats to Validity

### 6.1 Unmeasured Confounding

The primary threat to validity. Key unmeasured confounders include:
- **Prescriber specialty:** Nephrologists may preferentially prescribe apixaban over rivaroxaban in CKD, creating selection bias. The CDW has PROVIDER.PROVIDER_SPECIALTY_PRIMARY but it may be incompletely populated.
- **Patient frailty:** Not directly captured. Frailer patients may receive reduced doses and have worse outcomes regardless of drug choice.
- **Smoking status:** Unusable in this CDW (99.8% unknown/NI in VITAL.SMOKING).
- **LVEF / echocardiographic data:** Not available as structured data.
- **Proteinuria/UACR:** Not well-represented in the CDW; limits CKD prognostic characterization.
- **Patient preference and insurance formulary:** May drive drug choice independently of clinical factors.

The **E-value analysis** will quantify the sensitivity of results to unmeasured confounding.

### 6.2 Exposure Misclassification

- PRESCRIBING captures prescribed, not dispensed, medications. Some patients may fill a prescription for one DOAC but not take it.
- DISPENSING (NDC-based) could supplement PRESCRIBING but uses different identifiers.
- Treatment switching and discontinuation are common; the ITT approach may dilute true drug effects (addressed by the as-treated sensitivity analysis).

### 6.3 Outcome Misclassification

- ICD-10-based stroke and bleeding ascertainment has well-documented sensitivity and specificity limitations.
- Stroke codes (I63.x) may include incidental or mild strokes; restricting to IP/ED encounters improves specificity.
- GI bleeding codes may capture minor bleeding events; our major bleeding definition uses inpatient/ED requirement as a severity filter.

### 6.4 CKD Staging Precision

- ICD-10 CKD staging depends on provider coding practices. Some patients may be coded as N18.3 (unspecified stage 3) rather than N18.31 (3a) vs N18.32 (3b).
- eGFR-based ascertainment captures patients without coded CKD but depends on having a lab result in the lookback window.
- Patients' CKD stage may change during follow-up (progression to ESRD → censoring event).

### 6.5 Positivity Concerns

Both DOACs are genuinely prescribed in this population, but the 2:1 apixaban-to-rivaroxaban ratio (reflecting national prescribing trends post-2018) means the rivaroxaban arm will be smaller. In severe CKD (stage 4-5), rivaroxaban use may be very uncommon, creating positivity violations in subgroup analyses. Propensity score overlap will be assessed visually, and extreme weights will be addressed through PS trimming.

### 6.6 Immortal Time Bias

Minimized by design: time zero is the date of first DOAC prescription (the treatment-defining event), so there is no gap between eligibility and exposure assignment. The new-user design ensures patients contribute follow-up only from the date they initiate therapy.

### 6.7 Informative Censoring

Patients who discontinue their DOAC or switch to the comparator are followed under the ITT approach (primary analysis). Informative censoring may occur if sicker patients are more likely to stop therapy. The as-treated sensitivity analysis addresses this by censoring at discontinuation/switching.

---

## 7. Code Reference (Summary)

### 7.1 ICD-10-CM Codes

**Atrial fibrillation:** I48.0, I48.11, I48.19, I48.20, I48.21, I48.91 (SQL: `DX LIKE 'I48%'` with exclusion of I48.3, I48.4, I48.92 for flutter)

**CKD stages:** N18.32 (3b), N18.4, N18.5 | Excluded: N18.6 (ESRD), Z99.2 (dialysis dependence)

**Stroke/SE:** I63.x (ischemic stroke), I74.x (arterial embolism/thrombosis)

**Major bleeding:** I60.x (SAH), I61.x (intracerebral hemorrhage), I62.x (other intracranial), K92.0 (hematemesis), K92.1 (melena), K92.2 (GI hemorrhage NOS), K62.5 (rectal hemorrhage), K25.0/K25.4, K26.0/K26.4, K27.0/K27.4, K29.01

**Valvular exclusion:** I05.x, I06.x, I07.x, I08.x, Z95.2, Z95.3, Z95.4

### 7.2 RxNorm CUIs

**Apixaban:** 1364435 (2.5mg SCD), 1364445 (5mg SCD), 1364441 (2.5mg SBD), 1364447 (5mg SBD)

**Rivaroxaban:** 1114198 (10mg SCD), 1232082 (15mg SCD), 1232086 (20mg SCD), 2059015 (2.5mg SCD), 1114202 (10mg SBD), 1232084 (15mg SBD), 1232088 (20mg SBD), 2059017 (2.5mg SBD)

### 7.3 LOINC Codes

**eGFR:** 48642-3, 62238-1, 33914-3, 98979-8
**Serum creatinine:** 2160-0
**HbA1c:** 4548-4
**Hemoglobin:** 718-7
**Platelets:** 777-3

---

## 8. Supporting Literature

| Citation | PMID | Relevance |
|----------|------|-----------|
| ARISTOTLE (Granger et al., 2011) | 21870978 | Apixaban vs warfarin landmark RCT |
| ROCKET AF (Patel et al., 2011) | 21830957 | Rivaroxaban vs warfarin landmark RCT |
| RE-LY (Connolly et al., 2009) | 19717844 | Dabigatran vs warfarin landmark RCT |
| ENGAGE AF-TIMI 48 (Giugliano et al., 2013) | 24251359 | Edoxaban vs warfarin landmark RCT |
| Ray et al. (JAMA, 2021) | 34932078 | Rivaroxaban vs apixaban; higher events with rivaroxaban |
| Lip et al. (multinational, 2022) | 36315950 | DOAC comparisons across 6 countries |
| Dawwas et al. (2022) | 36252244 | Apixaban vs rivaroxaban in AF+VHD |
| Douros et al. (2024) | 39154873 | Apixaban lower bleeding regardless of risk |
| US CKD cohort (2024) | 37839687 | Key study: DOAC comparison in CKD 4/5 |
| Scoping review (2026) | 41733864 | Identifies sparse non-dialysis data |
| Mavrakanas et al. (2023) | 38035566 | DOACs in CKD review |
| Shin et al. (JAMA, 2024) | 38744617 | DOACs in CKD systematic review |
| CODE-AF Registry (2022) | 36579375 | DOACs in advanced CKD/dialysis |
| Apixaban PK in CKD (2024) | PMC:11344734 | PK consistent across CKD stages |
| 2023 ACC/AHA AF Guideline | 38033089 | Current clinical guideline |
| JACC CKD/AF review (2019) | 31648714 | Comprehensive AC in CKD/AF review |
| Apixaban dose in severe CKD (2023) | 37681341 | 5mg vs 2.5mg apixaban in CKD 4/5 |
| Noseworthy et al. (IV, 2020) | 32283966 | IV analysis confirming rivaroxaban risk |
