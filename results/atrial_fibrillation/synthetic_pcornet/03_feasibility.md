# Dataset Feasibility Assessment: PCORnet Synthetic CDW

**Database:** PCORnet Synthetic CDW (`synthetic_pcornet`)
**CDM:** PCORnet v6.0 | **Engine:** DuckDB | **Mode:** Online
**Assessment Date:** 2026-04-14

---

## Executive Summary

**Overall Verdict: NOT FEASIBLE for any of the 6 candidate questions.**

The PCORnet Synthetic CDW is a small (N=500) synthetic dataset that lacks the
key exposures (DOACs, warfarin, antiarrhythmic drugs, catheter ablation, LAAC),
subpopulations (advanced CKD, HFpEF, cirrhosis, dialysis), and outcomes
(stroke/SE, major bleeding) required for all 6 proposed target trial emulations.
The 50 AF patients have a uniform comorbidity profile with only rate-control and
preventive cardiovascular medications. This database cannot support protocol
development for any question at any level of rigor.

---

## 1. Database Overview

### Available Tables

| Table | Rows | Key Date Column |
|-------|------|-----------------|
| DEMOGRAPHIC | 500 | BIRTH_DATE |
| ENCOUNTER | 3,949 | ADMIT_DATE |
| DIAGNOSIS | 13,055 | DX_DATE |
| PRESCRIBING | 3,504 | RX_ORDER_DATE |
| LAB_RESULT_CM | 7,946 | RESULT_DATE |
| PROCEDURES | 11,773 | PX_DATE |
| VITAL | 3,550 | MEASURE_DATE |
| DEATH | 32 | DEATH_DATE |
| PROVIDER | 500 | — |

**Missing PCORnet tables:** CONDITION, MED_ADMIN, DISPENSING, DEATH_CAUSE, ENROLLMENT

### Coding Systems

- **Diagnosis:** 100% ICD-10-CM (DX_TYPE = '10')
- **Procedures:** 100% CPT/HCPCS (PX_TYPE = 'CH')
- **Medications:** 27 distinct RxNorm CUIs (ingredient-level)
- **Labs:** 15 distinct LOINC codes

---

## 2. AF Cohort Characterization

### Patient Counts (Queried from Database)

| Population | N (distinct patients) |
|-----------|----------------------|
| Total patients | 500 |
| AF patients (I48.xx) | 50 |
| CKD any stage (N18.xx) | 104 |
| CKD stages 4–5 (N18.4, N18.5, N18.6) | **0** |
| Heart failure any (I50.xx) | 104 |
| HFpEF / diastolic HF (I50.3x) | **0** |
| HFrEF / systolic HF (I50.2x) | **0** |
| Liver cirrhosis (K70.3x, K74.xx, K71.7) | **0** |
| Dialysis (Z99.2, Z49.xx, N18.6) | **0** |
| Stroke/systemic embolism (I63.xx, I74.xx) | **0** |
| Major bleeding (K92.0–2, D62, I60–I62) | **0** |

### AF Diagnosis Codes

Only one AF code is present: **I48.91** (Unspecified atrial fibrillation) — 50
patients, 172 diagnosis records. No paroxysmal (I48.0), persistent (I48.11,
I48.19), permanent (I48.21), or chronic (I48.20) subtypes.

### Comorbidity Overlap with AF (N=50)

| Combination | N |
|------------|---|
| AF + CKD (any) | **0** |
| AF + HF (any) | 50 |
| AF + HTN | 50 |
| AF + Type 2 DM | 49 |
| AF + Obesity (E66) | 0 |
| AF + CKD + HF | **0** |

All 50 AF patients have co-occurring diagnoses for hypertension (I10),
heart failure (I50.9, unspecified), coronary artery disease (I25), and
hyperlipidemia (E78). This uniform profile is characteristic of a synthetic
dataset with a single cardiovascular clinical template.

### Specific HF and CKD Codes Present

| Code | Description | N patients |
|------|-------------|-----------|
| I50.9 | Heart failure, unspecified | 104 |
| N18.3 | CKD, stage 3 | 104 |

No CKD stage 4 (N18.4), stage 5 (N18.5), ESRD (N18.6), diastolic HF (I50.3x),
or systolic HF (I50.2x) codes exist in the entire database.

### AF Patient Demographics

| Sex | N | Mean Age | Min | Max |
|-----|---|----------|-----|-----|
| F | 26 | ~70 | 45 | 90 |
| M | 24 | ~65 | 9 | 91 |

Race distribution across 7 categories (PCORnet coding). Age range is appropriate
for AF but includes one outlier (age 9, likely synthetic artifact).

### Medications Prescribed to AF Patients

| Drug (RxNorm CUI) | N patients | N prescriptions |
|-------------------|-----------|----------------|
| Atorvastatin (83367) | 44 | 198 |
| Aspirin (1191) | 43 | 191 |
| Lisinopril (29046) | 34 | 159 |
| Metoprolol succinate (6918) | 29 | 120 |
| Amlodipine (17767) | 21 | 104 |
| Clopidogrel (32968) | 17 | 67 |
| Furosemide (8787) | 12 | 52 |

**Critically absent from the entire database (all 500 patients):**
- Apixaban (RxCUI 1364435, 1364445) — **not present**
- Rivaroxaban (RxCUI 1114198, 1232082, 1232086) — **not present**
- Dabigatran — **not present**
- Edoxaban — **not present**
- Warfarin (RxCUI 855288–855350) — **not present**
- Amiodarone (RxCUI 833528) — **not present**
- Flecainide — **not present**
- Sotalol — **not present**
- Dronedarone — **not present**
- Dofetilide — **not present**

The 27 RxNorm CUIs in the database represent only common preventive/chronic
disease medications: statins, aspirin, ACE inhibitors, beta-blockers, diuretics,
metformin, insulin, inhalers, antidepressants, analgesics, and anxiolytics.
**No anticoagulants or antiarrhythmic drugs exist in the database.**

### Lab Results for AF Patients

| LOINC | Analyte | N pts | N results | Mean | Range |
|-------|---------|-------|-----------|------|-------|
| 13457-7 | LDL cholesterol (direct) | 50 | 391 | 111.9 | 50–190 |
| 2093-3 | Total cholesterol | 50 | 379 | 209.3 | 125–300 |
| 2085-9 | HDL cholesterol | 50 | 413 | 43.2 | 20–60 |
| 2571-8 | Triglycerides | 50 | 406 | 171.3 | 50–398 |
| 30522-7 | hsCRP | 48 | 185 | 168.2 | 0.05–871 |
| 10839-9 | Troponin I | 46 | 107 | 0.05 | 0–1.9 |

**Critically absent for AF patients:** eGFR (33914-3), serum creatinine
(2160-0), HbA1c (4548-4), glucose (2345-7). These LOINCs exist in the database
but are assigned to non-AF patients only. CKD staging by lab values is impossible
for AF patients.

**Absent from entire database:** Albumin, bilirubin, INR/PT, AST, ALT, platelet
count — none of these have LOINC codes in the database. Liver function
assessment (Child-Pugh, MELD) and bleeding risk scoring (HAS-BLED) are
impossible.

### Procedures for AF Patients

| CPT | Description | N pts | N procedures |
|-----|-------------|-------|-------------|
| 93306 | Echocardiogram | 50 | 344 |
| 93000 | ECG, 12-lead | 50 | 530 |

**Critically absent from entire database:**
- 93656 (comprehensive EP study + ablation) — no catheter ablation
- 93653 (EP study + SVT ablation) — no ablation
- 33340 (percutaneous LAAC, e.g., Watchman) — no LAAC
- 33267 (thoracoscopic LAAC) — no surgical LAAC
- 90935/90937 (hemodialysis) — no dialysis procedures

### Outcomes

- **Death among AF patients:** 1 patient (of 50)
- **Stroke/SE (I63, I74):** 0 patients in entire database
- **Major bleeding (I60–I62, K92.0–2, D62):** 0 patients in entire database

---

## 3. Per-Question Feasibility Assessment

### Q1: Apixaban vs Rivaroxaban in AF + Advanced CKD (Gap Score 8)

**Verdict: NOT FEASIBLE**

| PICO Element | Required | Available | Gap |
|-------------|----------|-----------|-----|
| Population: AF + CKD 4–5 | AF + eGFR<30 or N18.4/N18.5/N18.6 | 0 patients (AF+CKD overlap = 0; no stages 4–5) | **Fatal** |
| Exposure: Apixaban | RxCUI 1364435/1364445 | 0 prescriptions | **Fatal** |
| Comparator: Rivaroxaban | RxCUI 1114198/1232082/1232086 | 0 prescriptions | **Fatal** |
| Outcome: Stroke/SE | I63, I74 | 0 patients | **Fatal** |
| Outcome: Major bleeding | I60–62, K92, D62 | 0 patients | **Fatal** |
| Confounder: eGFR labs | LOINC 33914-3, 2160-0 | Not available for AF patients | **Fatal** |
| Confounder: CHA₂DS₂-VASc | Age, sex, HF, HTN, DM, stroke, vascular | Stroke and vascular partly missing | Moderate |

**Estimated cohort size:** 0 patients. No intersection of AF, advanced CKD,
and DOAC exposure exists. Even relaxing CKD to any stage yields 0 AF+CKD overlap.

**Positivity:** Complete violation — no patients receive either treatment arm.

**Variable mapping:**

| Protocol Concept | PCORnet Table.Column | Status |
|-----------------|---------------------|--------|
| AF diagnosis | DIAGNOSIS.DX (I48.xx) | Available (50 pts) |
| CKD stage | DIAGNOSIS.DX (N18.4–6) | **Missing** (0 pts) |
| eGFR | LAB_RESULT_CM.LAB_LOINC (33914-3) | **Missing for AF pts** |
| Apixaban Rx | PRESCRIBING.RXNORM_CUI | **Missing** (0 in DB) |
| Rivaroxaban Rx | PRESCRIBING.RXNORM_CUI | **Missing** (0 in DB) |
| Stroke/SE outcome | DIAGNOSIS.DX (I63, I74) | **Missing** (0 in DB) |
| Bleeding outcome | DIAGNOSIS.DX (I60-62, K92, D62) | **Missing** (0 in DB) |
| Mortality | DEATH.DEATH_DATE | 1 AF death |

---

### Q2: Catheter Ablation vs AADs in AF + HFpEF (Gap Score 8)

**Verdict: NOT FEASIBLE**

| PICO Element | Required | Available | Gap |
|-------------|----------|-----------|-----|
| Population: AF + HFpEF | I48 + I50.3x (or EF≥50%) | 0 HFpEF patients (only I50.9 unspecified) | **Fatal** |
| Exposure: Catheter ablation | CPT 93656 | 0 procedures | **Fatal** |
| Comparator: AADs | Amiodarone, flecainide, sotalol | 0 prescriptions | **Fatal** |
| Outcome: Death + HF hospitalization | DEATH + I50 inpatient | 1 death; HF hospitalization not distinguishable | **Fatal** |
| Confounder: EF measurement | Echo-derived EF | No structured EF data | **Fatal** |

**Estimated cohort size:** 0 patients. No ablation procedures or AAD
prescriptions exist. HFpEF cannot be identified because only unspecified HF
(I50.9) is coded, and ejection fraction is not available as a structured data
element (echocardiogram CPT 93306 is present, but EF values are not in
LAB_RESULT_CM or any other table).

**Positivity:** Complete violation — neither treatment arm exists.

**Variable mapping:**

| Protocol Concept | PCORnet Table.Column | Status |
|-----------------|---------------------|--------|
| AF diagnosis | DIAGNOSIS.DX (I48.91) | Available (50 pts) |
| HFpEF | DIAGNOSIS.DX (I50.3x) | **Missing** (0 pts) |
| Ejection fraction | LAB_RESULT_CM or structured echo | **Missing** |
| Ablation procedure | PROCEDURES.PX (93656) | **Missing** (0 in DB) |
| AAD prescriptions | PRESCRIBING.RXNORM_CUI | **Missing** (0 in DB) |
| HF hospitalization | ENCOUNTER (IP) + DIAGNOSIS (I50) | Partially available but no ablation/AAD |
| AF recurrence | DIAGNOSIS.DX (I48) post-procedure | Unverifiable without intervention |

---

### Q3: DOACs vs Warfarin in AF + Liver Cirrhosis (Gap Score 8)

**Verdict: NOT FEASIBLE**

| PICO Element | Required | Available | Gap |
|-------------|----------|-----------|-----|
| Population: AF + cirrhosis | I48 + K70.3x/K74.xx/K71.7 | 0 cirrhosis patients in entire DB | **Fatal** |
| Exposure: Any DOAC | Apixaban/rivaroxaban/edoxaban | 0 prescriptions | **Fatal** |
| Comparator: Warfarin | RxCUI 855288–855350 | 0 prescriptions | **Fatal** |
| Outcome: Stroke/SE | I63, I74 | 0 patients | **Fatal** |
| Outcome: Major bleeding | I60–62, K92, D62 | 0 patients | **Fatal** |
| Confounder: Liver function | Albumin, bilirubin, INR, platelets | **No liver-related LOINCs in DB** | **Fatal** |
| Confounder: Child-Pugh score | Albumin + bilirubin + INR + ascites + encephalopathy | Not constructable | **Fatal** |

**Estimated cohort size:** 0 patients. Zero cirrhosis diagnoses and zero
anticoagulant prescriptions in the entire database.

**Variable mapping:**

| Protocol Concept | PCORnet Table.Column | Status |
|-----------------|---------------------|--------|
| AF diagnosis | DIAGNOSIS.DX (I48.91) | Available (50 pts) |
| Cirrhosis | DIAGNOSIS.DX (K70.3x, K74.xx) | **Missing** (0 in DB) |
| DOAC Rx | PRESCRIBING.RXNORM_CUI | **Missing** (0 in DB) |
| Warfarin Rx | PRESCRIBING.RXNORM_CUI | **Missing** (0 in DB) |
| Albumin lab | LAB_RESULT_CM.LAB_LOINC | **Missing** |
| Bilirubin lab | LAB_RESULT_CM.LAB_LOINC | **Missing** |
| INR lab | LAB_RESULT_CM.LAB_LOINC | **Missing** |
| MELD score | Derived from bilirubin + INR + creatinine | Not constructable |

---

### Q4: Early Rhythm Control vs Usual Care in AF + HF (Gap Score 7)

**Verdict: NOT FEASIBLE**

| PICO Element | Required | Available | Gap |
|-------------|----------|-----------|-----|
| Population: New AF + HF | I48 (first dx) + I50 | 50 AF+HF patients but no temporal data on "new" AF | Moderate |
| Exposure: Rhythm control | AAD or ablation within 1 year | 0 AADs, 0 ablations | **Fatal** |
| Comparator: Rate control | Beta-blocker, CCB, digoxin | Metoprolol (29 AF pts) | Partially available |
| Outcome: CV death/stroke/HF hosp | Death + I63 + I50 inpatient | 1 death; 0 stroke; HF hosp unclear | **Fatal** |
| Time zero: AF diagnosis date | First I48 date per patient | Available | OK |

**Estimated cohort size:** At most 29 patients in the rate-control arm
(metoprolol), 0 patients in the rhythm-control arm. The study requires two
treatment arms; having zero patients in the rhythm-control arm is an
absolute barrier.

**Positivity:** Complete violation for the rhythm-control arm.

**Variable mapping:**

| Protocol Concept | PCORnet Table.Column | Status |
|-----------------|---------------------|--------|
| New AF diagnosis | DIAGNOSIS.DX_DATE (first I48) | Available |
| HF diagnosis | DIAGNOSIS.DX (I50.9) | Available (50 pts) |
| AAD initiation | PRESCRIBING.RXNORM_CUI | **Missing** (0 AADs) |
| Ablation | PROCEDURES.PX (93656) | **Missing** (0 in DB) |
| Metoprolol (rate control) | PRESCRIBING.RXNORM_CUI (6918) | 29 AF pts |
| CV death | DEATH table | 1 AF patient |
| Stroke | DIAGNOSIS.DX (I63) | **Missing** (0 in DB) |

---

### Q5: LAAC vs Continued Anticoag in AF + Dialysis (Gap Score 6)

**Verdict: NOT FEASIBLE**

| PICO Element | Required | Available | Gap |
|-------------|----------|-----------|-----|
| Population: AF + dialysis | I48 + Z99.2/Z49/hemodialysis CPT | 0 dialysis patients | **Fatal** |
| Exposure: LAAC device | CPT 33340 | 0 procedures | **Fatal** |
| Comparator: Anticoagulation | DOAC or warfarin | 0 prescriptions | **Fatal** |
| Outcome: Stroke/SE | I63, I74 | 0 patients | **Fatal** |
| Outcome: Major bleeding | I60–62, K92, D62 | 0 patients | **Fatal** |

**Estimated cohort size:** 0 patients. No dialysis diagnoses, no LAAC
procedures, and no anticoagulants in the database.

---

### Q6: Appropriate vs Inappropriate DOAC Dose Reduction in Elderly AF (Gap Score 6)

**Verdict: NOT FEASIBLE**

| PICO Element | Required | Available | Gap |
|-------------|----------|-----------|-----|
| Population: AF, age ≥75 | I48 + birth date | ~15–20 AF pts ≥75 (estimated from demographics) | Small but present |
| Exposure: Guideline-concordant DOAC | DOAC Rx + dose + renal function | 0 DOAC prescriptions | **Fatal** |
| Comparator: Off-label dose reduction | DOAC Rx at reduced dose without criteria | 0 DOAC prescriptions | **Fatal** |
| Dosing assessment | RX_DOSE_ORDERED, weight, creatinine | Dose data structure exists but no DOACs | **Fatal** |
| Outcome: Stroke/SE | I63, I74 | 0 patients | **Fatal** |
| Outcome: Major bleeding | I60–62, K92, D62 | 0 patients | **Fatal** |

**Estimated cohort size:** 0 DOAC-treated patients. While elderly AF patients
exist, the complete absence of DOACs makes this question unanswerable. Even the
PRESCRIBING table's RX_DOSE_ORDERED field cannot be leveraged without DOAC
prescriptions.

---

## 4. Cross-Cutting Data Gaps

### Fatal Gaps (Affect All 6 Questions)

1. **No anticoagulants:** Zero prescriptions for apixaban, rivaroxaban,
   dabigatran, edoxaban, or warfarin. This single gap eliminates questions
   1, 3, 5, and 6 entirely.

2. **No antiarrhythmic drugs:** Zero prescriptions for amiodarone, flecainide,
   sotalol, dronedarone, or dofetilide. This eliminates questions 2 and 4.

3. **No stroke/SE outcome codes:** Zero patients with ischemic stroke (I63) or
   systemic embolism (I74) in the entire database. The primary efficacy
   outcome for anticoagulation studies cannot be assessed.

4. **No major bleeding codes:** Zero patients with intracranial hemorrhage
   (I60–I62), GI bleeding (K92), or acute posthemorrhagic anemia (D62).
   The primary safety outcome is unobservable.

5. **No interventional procedures:** No catheter ablation (93656), no LAAC
   (33340), no hemodialysis (90935/90937). Questions 2 and 5 have no
   intervention arm.

### Moderate Gaps

6. **No HF subtype specificity:** Only I50.9 (unspecified HF) is coded.
   Distinguishing HFpEF (I50.3x) from HFrEF (I50.2x) is impossible.
   No structured ejection fraction data.

7. **No advanced CKD:** CKD is coded only as N18.3 (stage 3). Stages 4–5
   and ESRD (N18.4–N18.6) are absent. eGFR and creatinine labs exist but
   are not linked to AF patients.

8. **No liver disease or liver labs:** Zero cirrhosis codes. No albumin,
   bilirubin, INR, or platelet LOINCs. Child-Pugh and MELD scores cannot
   be constructed.

9. **Limited medication formulary:** Only 27 drugs, all common chronic
   disease medications. No specialty drugs (anticoagulants, antiarrhythmics,
   immunosuppressants, etc.).

10. **Missing ENROLLMENT table:** Cannot verify continuous enrollment or
    calculate washout periods. New-user designs require enrollment data to
    confirm no prior use of the study drug.

---

## 5. What the Database CAN Support

Despite being infeasible for all 6 target questions, the synthetic PCORnet CDW
could support:

- **Cardiovascular risk factor profiling:** 50 AF patients with complete
  lipid panels, vitals, echocardiograms, and ECGs
- **Metoprolol utilization patterns:** 29 AF patients with metoprolol
  prescriptions and longitudinal follow-up
- **Basic cohort characterization:** Demographics, comorbidity burden,
  encounter patterns for a cardiovascular cohort
- **Data pipeline testing:** Validate PCORnet CDM queries, cohort-building
  logic, and analysis scripts before deploying to a real CDW

---

## 6. Recommendations

1. **Do not proceed to protocol development** for any of the 6 questions
   using this database.

2. **Seek a full-scale PCORnet CDW** with:
   - ≥100,000 AF patients for adequate subgroup sizes
   - Complete medication formulary including DOACs, warfarin, and AADs
   - Procedure data including ablation and device implantation codes
   - Outcome events (stroke, bleeding, mortality)
   - Lab results including renal function, liver function, and coagulation
   - ENROLLMENT table for new-user design validation

3. **Consider alternative data sources:**
   - Medicare claims (CMS) for elderly AF + CKD/dialysis populations
   - Optum/MarketScan for commercial + Medicare populations
   - VA CDW for comprehensive labs + medications + outcomes
   - IQVIA/Flatiron for oncology + AF overlap populations

4. **Use this synthetic database only for:** testing analysis scripts,
   validating SQL/R code logic, and rehearsing the analysis pipeline before
   deployment to real data.

---

## Appendix: Clinical Code Reference

### ICD-10-CM Codes Searched

| Condition | Codes | Found in DB |
|-----------|-------|------------|
| Atrial fibrillation | I48.0, I48.11, I48.19, I48.20, I48.21, I48.91 | I48.91 only |
| CKD stage 4 | N18.4 | No |
| CKD stage 5 | N18.5 | No |
| ESRD | N18.6 | No |
| HFpEF (diastolic) | I50.30, I50.31, I50.32, I50.33 | No |
| HFrEF (systolic) | I50.20, I50.21, I50.22, I50.23 | No |
| Alcoholic cirrhosis | K70.30, K70.31 | No |
| Other cirrhosis | K74.60, K74.69 | No |
| Toxic cirrhosis | K71.7 | No |
| Dialysis dependence | Z99.2 | No |
| Ischemic stroke | I63.xx | No |
| Systemic embolism | I74.xx | No |
| Intracranial hemorrhage | I60–I62 | No |
| GI bleeding | K92.0, K92.1, K92.2 | No |

### RxNorm CUIs Searched (Not Found in DB)

| Drug | SCD RxCUIs | Present |
|------|-----------|---------|
| Apixaban 2.5 mg | 1364435 | No |
| Apixaban 5 mg | 1364445 | No |
| Rivaroxaban 10 mg | 1114198 | No |
| Rivaroxaban 15 mg | 1232082 | No |
| Rivaroxaban 20 mg | 1232086 | No |
| Warfarin (all doses) | 855288–855350 | No |
| Amiodarone 200 mg | 833528 | No |

### LOINC Codes for AF Patients

| LOINC | Analyte | Available for AF |
|-------|---------|-----------------|
| 33914-3 | eGFR | No (in DB but not linked to AF pts) |
| 2160-0 | Serum creatinine | No (in DB but not linked to AF pts) |
| 4548-4 | HbA1c | No (in DB but not linked to AF pts) |
| 2093-3 | Total cholesterol | Yes (50 pts) |
| 2085-9 | HDL cholesterol | Yes (50 pts) |
| 13457-7 | LDL cholesterol | Yes (50 pts) |
| 2571-8 | Triglycerides | Yes (50 pts) |
| 30522-7 | hsCRP | Yes (48 pts) |
| 10839-9 | Troponin I | Yes (46 pts) |

### CPT Codes for Key Procedures (Not Found in DB)

| CPT | Description | Present |
|-----|-------------|---------|
| 93656 | Comprehensive EP + ablation | No |
| 93653 | EP study + SVT ablation | No |
| 33340 | Percutaneous LAAC | No |
| 90935 | Hemodialysis, single | No |
| 90937 | Hemodialysis, repeated | No |
