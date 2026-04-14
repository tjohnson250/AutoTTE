# Feasibility Assessment: Atrial Fibrillation Questions vs synthetic_pcornet

**Database:** PCORnet Synthetic CDW (synthetic_pcornet)
**CDM:** PCORnet v6.0 | **Engine:** DuckDB | **Mode:** online
**Assessment date:** 2026-04-13

---

## Database Summary

| Metric | Value |
|--------|-------|
| Total patients | 500 |
| AF patients (I48.91) | 50 |
| Diagnosis rows | 13,055 (100% ICD-10) |
| Prescriptions | 3,504 (27 distinct RxNorm CUIs) |
| Procedures | 11,773 (100% CPT/HCPCS) |
| Lab results | 7,946 (15 distinct LOINCs) |
| Vitals | 3,550 |
| Deaths | 32 (1 among AF patients) |
| Missing PCORnet tables | CONDITION, MED_ADMIN, DISPENSING, DEATH_CAUSE, ENROLLMENT |

### AF Cohort Profile

All 50 AF patients belong to the **"cardiac" clinical profile** and share a
uniform comorbidity pattern:

| Characteristic | Value |
|---------------|-------|
| Mean age (F / M) | 71.6 / 66.6 years |
| Sex (F / M) | 26 / 24 |
| AF code | I48.91 only (unspecified AF) |
| Heart failure (I50.9) | 50/50 (100%) |
| CAD (I25.10) | 50/50 (100%) |
| Hypertension (I10) | 50/50 (100%) |
| Type 2 diabetes (E11.9) | 50/50 (100%) |
| Hyperlipidemia (E78.5) | 50/50 (100%) |
| CKD | 0/50 (0%) |
| Cirrhosis | 0/50 (0%) |
| Cancer | 0/50 (0%) |

### Medication Formulary (AF patients)

| RxNorm CUI | Drug | AF patients with Rx |
|-----------|------|-------------------|
| 83367 | Atorvastatin | 44 |
| 1191 | Aspirin | 43 |
| 29046 | Lisinopril | 34 |
| 6918 | Metoprolol succinate | 29 |
| 17767 | Amlodipine | 21 |
| 32968 | Clopidogrel | 17 |
| 8787 | Furosemide | 12 |

**Missing from formulary (entire database):**
- **DOACs:** apixaban, rivaroxaban, edoxaban, dabigatran — 0 prescriptions
- **Warfarin** — 0 prescriptions
- **Antiarrhythmic drugs:** amiodarone, flecainide, sotalol, dronedarone, dofetilide, propafenone — 0 prescriptions
- **Digoxin** — 0 prescriptions
- **Diltiazem / Verapamil** — 0 prescriptions

### Procedure Codes (AF patients)

All 50 AF patients have echocardiogram (CPT 93306). No ablation procedures
(CPT 93653–93657) exist in the entire database.

### Lab Data (AF patients)

| LOINC | Analyte | AF patients | Results |
|-------|---------|-------------|---------|
| 2085-9 | HDL cholesterol | 50 | 413 |
| 13457-7 | LDL cholesterol | 50 | 391 |
| 2093-3 | Total cholesterol | 50 | 379 |
| 2571-8 | Triglycerides | 50 | 406 |
| 30522-7 | CRP | 48 | 185 |
| 10839-9 | Troponin I | 46 | 107 |

**Missing labs for AF patients:** eGFR (33914-3), creatinine (2160-0), HbA1c
(4548-4), glucose (2345-7), BUN, INR, bilirubin, albumin, TSH. The eGFR LOINC
exists in the database (117 patients) but none overlap with AF patients.

### Outcome Data

| Outcome | Patients (entire DB) | AF patients |
|---------|---------------------|-------------|
| Stroke (I63, I64, G45) | 0 | 0 |
| Intracranial hemorrhage (I61, I62) | 0 | 0 |
| GI bleeding (K25–K28, K92) | 0 | 0 |
| Other bleeding (D62, D68) | 0 | 0 |
| Death | 32 | 1 |
| HF hospitalization (I50.9 + IP encounter) | constructable | constructable |

---

## Per-Question Feasibility

### Q1: Early Rhythm Control vs Rate Control in Newly Diagnosed AF

**Rating: NOT FEASIBLE**

#### Exposure Assessment

| Treatment arm | Required | Available |
|--------------|----------|-----------|
| Rhythm control (AADs) | Amiodarone, flecainide, sotalol, dronedarone RxNorm CUIs | **0 prescriptions** |
| Rhythm control (ablation) | CPT 93653–93657 | **0 procedures** |
| Rate control | Metoprolol, diltiazem, verapamil, digoxin | Metoprolol only (29 pts) |

#### Blocking Issues

1. **No rhythm control arm:** Zero AAD prescriptions and zero ablation procedures
   in the entire database. Cannot form a treatment group.
2. **No composite outcome components:** Zero stroke, zero CV death (only 1 death
   among AF patients with no cause-of-death table), zero ACS diagnoses.
3. **HF hospitalization** is the only constructable outcome component (I50.9 + IP
   encounters), but it cannot serve as a standalone endpoint for this question.

#### Variable Mapping

| Protocol concept | Table.Column | Status |
|-----------------|-------------|--------|
| AF diagnosis | DIAGNOSIS.DX = 'I48.91' | Available (50 pts) |
| AAD prescription | PRESCRIBING.RXNORM_CUI | **MISSING** — no AAD CUIs |
| Ablation procedure | PROCEDURES.PX | **MISSING** — no ablation CPTs |
| Rate control drug | PRESCRIBING.RXNORM_CUI = '6918' | Partial (metoprolol only) |
| Stroke outcome | DIAGNOSIS.DX LIKE 'I63%' | **MISSING** — 0 events |
| CV death | DEATH + cause codes | **MISSING** — no DEATH_CAUSE table |
| HF hospitalization | DIAGNOSIS + ENCOUNTER (IP) | Available |
| CHA₂DS₂-VASc score | Demographics + comorbidities | Partially constructable |

#### Positivity: VIOLATED

Cannot assess — only one treatment arm (rate control) is observable.

---

### Q2: Catheter Ablation vs Antiarrhythmic Drugs in AF + HFpEF

**Rating: NOT FEASIBLE**

#### Exposure Assessment

| Treatment arm | Required | Available |
|--------------|----------|-----------|
| Catheter ablation | CPT 93653–93657 | **0 procedures** |
| AAD therapy | Amiodarone, flecainide, sotalol, etc. | **0 prescriptions** |

#### Blocking Issues

1. **Neither treatment arm exists.** Zero ablation procedures, zero AAD
   prescriptions in the entire database.
2. **HFpEF cannot be defined.** All 50 AF patients have unspecified HF (I50.9),
   but LVEF is not available — no echocardiographic result data in structured
   tables, only the procedure code (93306). HFpEF (LVEF ≥ 50%) cannot be
   distinguished from HFrEF.
3. **Outcome data absent:** No stroke or death (beyond 1 patient) events.

#### Variable Mapping

| Protocol concept | Table.Column | Status |
|-----------------|-------------|--------|
| AF diagnosis | DIAGNOSIS.DX = 'I48.91' | Available (50 pts) |
| HFpEF | DIAGNOSIS.DX + LVEF | **INCOMPLETE** — I50.9 only, no LVEF |
| Ablation | PROCEDURES.PX | **MISSING** |
| AAD prescription | PRESCRIBING.RXNORM_CUI | **MISSING** |
| All-cause death | DEATH.DEATH_DATE | Available (1 AF death) |
| HF hospitalization | DIAGNOSIS + ENCOUNTER | Available |

#### Positivity: VIOLATED

No treatment exposure observable in either arm.

---

### Q3: Apixaban vs Rivaroxaban in AF + Advanced CKD (eGFR < 30)

**Rating: NOT FEASIBLE**

#### Population Assessment

| Criterion | Required | Available |
|-----------|----------|-----------|
| AF diagnosis | I48.x | 50 patients (I48.91) |
| CKD diagnosis | N18.4–N18.6 (advanced) | **0 patients** (only N18.3 exists: 104 patients, none with AF) |
| eGFR < 30 | Lab LOINC 33914-3 | **0 AF patients with eGFR labs** |
| AF + CKD overlap | Both diagnoses | **0 patients** |

#### Exposure Assessment

| Treatment arm | Required | Available |
|--------------|----------|-----------|
| Apixaban | RxNorm CUIs for apixaban | **0 prescriptions** |
| Rivaroxaban | RxNorm CUIs for rivaroxaban | **0 prescriptions** |

#### Blocking Issues

1. **Zero AF + CKD patients.** The clinical profiles are siloed: AF patients are
   in the "cardiac" profile (n=50), CKD patients are in other profiles (n=104),
   with zero overlap.
2. **No DOAC prescriptions** in the entire database.
3. **No eGFR labs for AF patients.** eGFR (33914-3) exists for 117 non-AF
   patients. Even if AF-CKD overlap existed, advanced CKD (eGFR < 30) would
   yield only ~14 patients database-wide.
4. **No bleeding or stroke outcomes** for the primary endpoint.

#### Variable Mapping

| Protocol concept | Table.Column | Status |
|-----------------|-------------|--------|
| AF diagnosis | DIAGNOSIS.DX = 'I48.91' | Available (50 pts) |
| CKD stage ≥ 4 | DIAGNOSIS.DX LIKE 'N18.4%' or 'N18.5%' | **MISSING** |
| eGFR < 30 | LAB_RESULT_CM.RESULT_NUM (LOINC 33914-3) | **MISSING** for AF pts |
| Apixaban Rx | PRESCRIBING.RXNORM_CUI | **MISSING** |
| Rivaroxaban Rx | PRESCRIBING.RXNORM_CUI | **MISSING** |
| Major bleeding | DIAGNOSIS.DX | **MISSING** — 0 events |
| Stroke / SE | DIAGNOSIS.DX LIKE 'I63%' | **MISSING** — 0 events |

#### Positivity: VIOLATED

No eligible population and no treatment exposure.

---

### Q4: DOACs vs Warfarin in AF + Liver Cirrhosis

**Rating: NOT FEASIBLE**

#### Population Assessment

| Criterion | Required | Available |
|-----------|----------|-----------|
| AF diagnosis | I48.x | 50 patients |
| Cirrhosis | K70.x, K71.x, K74.x, K76.x | **0 diagnoses in entire database** |
| AF + cirrhosis | Both diagnoses | **0 patients** |

#### Exposure Assessment

| Treatment arm | Required | Available |
|--------------|----------|-----------|
| DOACs (apixaban/rivaroxaban) | RxNorm CUIs | **0 prescriptions** |
| Warfarin | RxNorm CUI for warfarin | **0 prescriptions** |

#### Blocking Issues

1. **Zero cirrhosis diagnoses** in the entire database. No K70.x, K71.x, K74.x,
   or K76.x codes exist.
2. **No anticoagulant prescriptions** of any kind.
3. **No liver function labs** (bilirubin, albumin, INR not in the LOINC set).
   Child-Pugh staging would be impossible even if cirrhosis patients existed.
4. **No bleeding or stroke outcomes.**

#### Variable Mapping

| Protocol concept | Table.Column | Status |
|-----------------|-------------|--------|
| AF diagnosis | DIAGNOSIS.DX = 'I48.91' | Available (50 pts) |
| Cirrhosis | DIAGNOSIS.DX LIKE 'K74%' etc. | **MISSING** — 0 rows |
| DOAC Rx | PRESCRIBING.RXNORM_CUI | **MISSING** |
| Warfarin Rx | PRESCRIBING.RXNORM_CUI | **MISSING** |
| Bilirubin / Albumin / INR | LAB_RESULT_CM | **MISSING** |
| Major bleeding | DIAGNOSIS.DX | **MISSING** |
| Stroke / SE | DIAGNOSIS.DX | **MISSING** |

#### Positivity: VIOLATED

No eligible population and no treatment exposure.

---

### Q5: DOACs (Apixaban vs Rivaroxaban) in AF + Active Cancer

**Rating: NOT FEASIBLE**

#### Population Assessment

| Criterion | Required | Available |
|-----------|----------|-----------|
| AF diagnosis | I48.x | 50 patients |
| Active cancer | C00–C97 | **0 diagnoses in entire database** |
| AF + cancer | Both diagnoses | **0 patients** |

#### Exposure Assessment

| Treatment arm | Required | Available |
|--------------|----------|-----------|
| Apixaban | RxNorm CUIs | **0 prescriptions** |
| Rivaroxaban | RxNorm CUIs | **0 prescriptions** |

#### Blocking Issues

1. **Zero cancer diagnoses** in the entire database. No ICD-10 C-codes exist.
2. **No DOAC prescriptions.**
3. **No bleeding or stroke outcomes.**

#### Variable Mapping

| Protocol concept | Table.Column | Status |
|-----------------|-------------|--------|
| AF diagnosis | DIAGNOSIS.DX = 'I48.91' | Available (50 pts) |
| Cancer diagnosis | DIAGNOSIS.DX LIKE 'C%' | **MISSING** — 0 rows |
| Apixaban Rx | PRESCRIBING.RXNORM_CUI | **MISSING** |
| Rivaroxaban Rx | PRESCRIBING.RXNORM_CUI | **MISSING** |
| Major bleeding | DIAGNOSIS.DX | **MISSING** |
| Stroke / SE | DIAGNOSIS.DX | **MISSING** |

#### Positivity: VIOLATED

No eligible population and no treatment exposure.

---

## Summary

| Q# | Question | AF pts | Comorbidity overlap | Exposure available | Outcome available | Rating |
|----|----------|--------|--------------------|--------------------|-------------------|--------|
| Q1 | Early rhythm vs rate control | 50 | N/A | Rate ctrl only (29 pts metoprolol); **no rhythm ctrl** | HF hosp only; no stroke/death | **NOT FEASIBLE** |
| Q2 | Ablation vs AADs in AF + HFpEF | 50 | 50 HF (unspecified; **no LVEF**) | **Neither arm** | HF hosp only | **NOT FEASIBLE** |
| Q3 | Apixaban vs rivaroxaban in AF + CKD | 50 | **0 AF+CKD** | **No DOACs** | **None** | **NOT FEASIBLE** |
| Q4 | DOACs vs warfarin in AF + cirrhosis | 50 | **0 cirrhosis in DB** | **No OACs** | **None** | **NOT FEASIBLE** |
| Q5 | Apixaban vs rivaroxaban in AF + cancer | 50 | **0 cancer in DB** | **No DOACs** | **None** | **NOT FEASIBLE** |

## Root Cause Analysis

The synthetic_pcornet database was generated with **siloed clinical profiles**
(cardiac, diabetic, respiratory, mental_health, multimorbid, healthy). The
"cardiac" profile (n=53, of which 50 have AF) includes common chronic disease
diagnoses (HTN, DM, HLD, CAD, HF) and standard primary care medications
(statins, aspirin, ACE inhibitors, beta-blockers), but:

1. **No anticoagulants or antiarrhythmic drugs** are in the formulary (27
   RxNorm CUIs, all generic chronic disease medications).
2. **No specialty procedure codes** (ablation, cardioversion) exist.
3. **Comorbidity profiles don't cross clinical boundaries** — AF patients have
   zero CKD, cirrhosis, or cancer overlap.
4. **No stroke, bleeding, or cardiovascular death** outcome diagnoses exist
   in any patient.
5. **Lab coverage for AF patients** is limited to lipids, CRP, and troponin —
   no renal, hepatic, or metabolic labs.

## Recommendation for Original Questions

**None of the 5 original literature-derived questions are feasible against this database.** All require exposure data (DOACs, AADs, ablation) and outcome data (stroke, bleeding) entirely absent from synthetic_pcornet.

---

## Alternative Feasible Question (Coordinator-Identified)

Given the data available, the coordinator identified a modified question that IS feasible:

### Q-Alt: Beta-Blocker (Metoprolol) Initiation in AF + Heart Failure → HF Hospitalization

**Rating: PARTIALLY FEASIBLE (suitable for methodological demonstration)**

#### PICO Formulation

| Element | Specification |
|---------|--------------|
| **Population** | Adults with AF (I48.91) and HF (I50.9) in synthetic_pcornet (n=50) |
| **Intervention** | Metoprolol succinate initiation (RxNorm CUI 6918) |
| **Comparator** | No beta-blocker therapy |
| **Outcome** | HF hospitalization (inpatient encounter + I50.x diagnosis) |
| **Time zero** | First AF diagnosis encounter |
| **Follow-up** | Until end of data |

#### Causal Contrast

*What is the effect of initiating metoprolol, compared to no beta-blocker, on the risk of HF hospitalization in patients with AF and heart failure?*

**Estimand:** ATE

#### Clinical Rationale

Beta-blocker use in AF with HF is a real clinical question with evolving evidence. CASTLE-AF showed ablation superiority over drugs including beta-blockers. The AF-CHF trial found no mortality benefit for rhythm control, but rate control (including beta-blockers) remains first-line. Recent data questions strict rate control targets. This is not a trivial question.

#### Data Availability

| Data element | Table.Column | Available | Count |
|-------------|-------------|-----------|-------|
| AF diagnosis | DIAGNOSIS.DX = 'I48.91' | Yes | 50 pts |
| HF diagnosis | DIAGNOSIS.DX = 'I50.9' | Yes | 50 pts (100% overlap) |
| Metoprolol Rx | PRESCRIBING.RXNORM_CUI = '6918' | Yes | 29 pts |
| No beta-blocker | Absence of '6918' | Yes | 21 pts |
| HF hospitalization | ENCOUNTER(ENC_TYPE='IP') + DIAGNOSIS('I50%') | Constructable | Need to verify |
| Age | DEMOGRAPHIC.BIRTH_DATE | Yes | 100% |
| Sex | DEMOGRAPHIC.SEX | Yes | 100% |
| Race/ethnicity | DEMOGRAPHIC.RACE, HISPANIC | Yes | 100% |
| Comorbidities | DIAGNOSIS (HTN, DM, CAD, HLD) | Yes | 100% for cardiac profile |
| Other meds | PRESCRIBING (atorvastatin, aspirin, lisinopril, amlodipine, clopidogrel, furosemide) | Yes | Varying coverage |
| Vitals | VITAL (BP, BMI, HR) | Yes | 100% complete |
| Labs | LAB_RESULT_CM (lipids, CRP, troponin) | Yes | High coverage |

#### Positivity Assessment

- Metoprolol arm: 29 patients (58%)
- No beta-blocker arm: 21 patients (42%)
- Reasonable balance (not deterministic)

#### Limitations (Critical)

1. **Sample size (n=50):** Severely underpowered for any meaningful inference. Results will be statistically non-significant regardless of effect size. This is a methodological demonstration only.
2. **Synthetic data:** All associations are artificial. Results have no clinical validity.
3. **Uniform comorbidity profile:** All 50 patients have identical comorbidities (HTN, DM, CAD, HLD, HF), limiting confounder variability.
4. **Limited confounder set:** No renal function, no thyroid function, no anticoagulation status.
5. **Single HF type:** All HF is coded as I50.9 (unspecified); cannot distinguish HFpEF from HFrEF.
6. **One death only:** Mortality endpoints are not viable.
7. **Not from the literature-derived question set:** This question was identified based on data availability, not evidence gap analysis.

#### Recommendation

Advance this modified question to protocol generation as a **methodological demonstration** of the TTE pipeline on PCORnet CDM data. The protocol will be rigorous in design even though the synthetic data cannot produce clinically meaningful results. This demonstrates the system's ability to generate complete, executable TTE protocols against a real CDM structure.
