# MIMIC-IV v3.1 — Data Profile

Source: PhysioNet, Beth Israel Deaconess Medical Center (BIDMC), Boston, MA
Access: PhysioNet credentialed access (CITI training required)
Study period: 2008-2022 (dates shifted for de-identification; intervals preserved)

## 1. Overall Sample Size

| Metric | Approximate Count |
|--------|-------------------|
| Unique patients (hosp module) | ~190,000 |
| Unique patients with ICU data | ~50,000 |
| Hospital admissions | ~300,000 |
| ICU stays | ~65,000 |
| Emergency department visits | ~210,000 |

## 2. Demographics (ICU patients)

### Age Distribution (at ICU admission)

| Age Group | Approx N | % of ICU stays |
|-----------|----------|----------------|
| 18-39 | ~8,000 | ~12% |
| 40-59 | ~15,000 | ~23% |
| 60-79 | ~28,000 | ~43% |
| 80+ (top-coded at 91) | ~14,000 | ~22% |

Median age: ~66 years

### Gender

| Gender | Approx N | % |
|--------|----------|---|
| Male | ~36,000 | ~55% |
| Female | ~29,000 | ~45% |

### Race/Ethnicity

| Race | Approx % |
|------|----------|
| White | ~65% |
| Black/African American | ~12% |
| Hispanic/Latino | ~5% |
| Asian | ~3% |
| Other/Unknown | ~15% |

Note: Race data quality varies. ~10% of patients have Unknown race.

### Insurance

| Insurance | Approx % |
|-----------|----------|
| Medicare | ~50% |
| Medicaid | ~10% |
| Other (private, self-pay) | ~40% |

## 3. ICU Characteristics

### ICU Type Distribution

| Care Unit | Approx % of ICU stays |
|-----------|-----------------------|
| Medical ICU (MICU) | ~30% |
| Surgical ICU (SICU) | ~15% |
| Cardiac Vascular ICU (CVICU) | ~15% |
| Coronary Care Unit (CCU) | ~10% |
| Trauma SICU (TSICU) | ~10% |
| Medical/Surgical ICU | ~10% |
| Neuro ICU | ~5% |
| Other | ~5% |

### ICU Length of Stay

| LOS | Approx % |
|-----|----------|
| < 1 day | ~15% |
| 1-3 days | ~40% |
| 3-7 days | ~25% |
| 7-14 days | ~12% |
| > 14 days | ~8% |

Median ICU LOS: ~2.1 days
Mean ICU LOS: ~4.5 days

## 4. Mortality

| Metric | Rate |
|--------|------|
| In-hospital mortality (overall) | ~8-10% |
| ICU mortality | ~10-12% |
| 30-day mortality (from dod) | ~12-15% |
| 1-year mortality (from dod) | ~25-30% |

Note: Post-discharge mortality (`patients.dod`) is available for patients
captured by the Social Security Death Master File. Coverage is incomplete —
patients with NULL `dod` may be alive or uncaptured.

## 5. Lab Coverage

### Top Labs by Volume (labevents)

| Lab Test | Approx Records | Approx Patients | LOINC |
|----------|----------------|-----------------|-------|
| Glucose | ~2.5M | ~150K | 2345-7 |
| Potassium | ~2.2M | ~150K | 2823-3 |
| Sodium | ~2.2M | ~150K | 2951-2 |
| Creatinine | ~2.0M | ~150K | 2160-0 |
| BUN | ~1.8M | ~150K | 3094-0 |
| Hemoglobin | ~1.5M | ~140K | 718-7 |
| WBC | ~1.5M | ~140K | 6690-2 |
| Platelet Count | ~1.5M | ~140K | 777-3 |
| Chloride | ~1.4M | ~130K | 2075-0 |
| Bicarbonate | ~1.3M | ~130K | 1963-8 |
| Hematocrit | ~1.2M | ~130K | 4544-3 |
| Calcium, Total | ~1.0M | ~120K | 17861-6 |
| Magnesium | ~900K | ~100K | 19123-9 |
| Phosphate | ~700K | ~90K | 2777-1 |
| Albumin | ~500K | ~80K | 1751-7 |
| Lactate | ~500K | ~50K | 2524-7 |
| Bilirubin, Total | ~500K | ~70K | 1975-2 |
| INR | ~400K | ~60K | 6301-6 |
| Troponin T | ~300K | ~50K | 6598-7 |
| Procalcitonin | ~100K | ~30K | 33959-8 |

Total lab observations: ~125M across ~800 distinct lab types.

## 6. Medication Coverage

### Prescriptions Table

- ~17M prescription records across all admissions
- Common drug classes: antibiotics, vasopressors, sedatives, analgesics,
  anticoagulants, insulin, antihypertensives, proton pump inhibitors

### eMAR (Electronic Medication Administration Record)

- ~27M administration records
- Captures actual administration (vs. orders in prescriptions)
- `event_txt` = 'Administered' confirms drug was given

### ICU Input Events

- ~7M records for IV medications and fluids
- Includes infusion rates and amounts for vasopressors, sedatives,
  insulin drips, IV fluids
- Timestamped start/stop for each infusion segment

### Common ICU Medications (inputevents)

| Drug Category | Example Drugs | Approx ICU Patients |
|---------------|---------------|---------------------|
| Vasopressors | Norepinephrine, Vasopressin, Phenylephrine | ~15,000 |
| Sedatives | Propofol, Midazolam, Dexmedetomidine | ~25,000 |
| Analgesics | Fentanyl, Morphine, Hydromorphone | ~30,000 |
| Insulin (drip) | Regular insulin | ~10,000 |
| Antibiotics (IV) | Vancomycin, Piperacillin-Tazobactam, Cefepime | ~30,000 |
| Anticoagulants | Heparin (drip) | ~15,000 |
| IV Fluids | Normal saline, Lactated Ringer's | ~50,000 |

## 7. Vitals Coverage (chartevents, ICU patients only)

| Vital Sign | Approx Records | Frequency |
|------------|----------------|-----------|
| Heart Rate | ~30M | Hourly |
| Systolic BP | ~25M | Hourly |
| Respiratory Rate | ~25M | Hourly |
| SpO2 | ~30M | Continuous |
| Temperature | ~8M | Every 4-6 hours |
| GCS | ~5M | Every 2-4 hours |

Total chartevents: ~330M records across ~4,000 distinct item types.

## 8. Diagnoses Coverage

- ~700K diagnosis records across all admissions
- Both ICD-9 and ICD-10 codes present (icd_version column)
- Median diagnoses per admission: ~10-12

### Common ICU Diagnoses (ICD-10)

| Condition | ICD-10 Prefix | Approx ICU Stays |
|-----------|---------------|------------------|
| Sepsis | A41, R65.2 | 15,000-20,000 |
| Heart failure | I50 | 5,000-8,000 |
| Acute kidney injury | N17 | 10,000-15,000 |
| Pneumonia | J18, J15, J13 | 5,000-7,000 |
| Respiratory failure | J96 | 8,000-12,000 |
| Atrial fibrillation | I48 | 8,000-10,000 |
| Acute MI | I21 | 3,000-5,000 |
| GI bleeding | K92, K25-K28 | 3,000-5,000 |
| Stroke | I63, I61 | 3,000-5,000 |
| Cirrhosis/liver failure | K74, K72 | 2,000-4,000 |

## 9. Microbiology Coverage

- ~600K microbiology specimens
- ~200K positive cultures
- Includes blood cultures, urine cultures, respiratory cultures,
  wound cultures
- Antibiotic susceptibility data (S/R/I interpretation)

## 10. Limitations

- **Single center.** All data from Beth Israel Deaconess Medical Center.
  Practice patterns, patient population, and formulary reflect one
  academic medical center in Boston. Generalizability to community
  hospitals or non-US settings is limited.

- **ICU-biased.** The icu module covers only ICU stays. Hospital-wide
  data (hosp module) is broader but less granular. Analyses targeting
  ICU populations are well-supported; general inpatient analyses have
  fewer vital signs and medication administration details.

- **De-identified dates.** Calendar year analyses are not possible.
  Secular trends (e.g., sepsis bundle adoption over time) cannot be
  studied directly. Use `anchor_year_group` as an approximate era proxy.

- **Age top-coding.** Patients aged >89 have `anchor_age = 91`. This
  compresses the age distribution at the upper end, affecting geriatric
  subgroup analyses.

- **Incomplete post-discharge mortality.** `patients.dod` relies on
  Social Security Death Master File linkage, which has known gaps.
  Patients with NULL `dod` may be alive or may have died without
  capture. This creates informative censoring risk in survival analyses.

- **No outpatient data.** MIMIC captures hospital encounters only.
  Pre-admission medications, outpatient labs, and post-discharge
  follow-up are not available (except limited `omr` data).

- **ICD coding quality.** Diagnosis and procedure codes are assigned
  by coders after discharge, not at the bedside. Coding accuracy and
  completeness vary. Use lab and vital sign data to supplement ICD-based
  case definitions where possible.

- **Medication reconciliation.** The prescriptions table reflects orders,
  not necessarily what the patient actually received. Use eMAR for
  confirmed administration. For ICU medications, inputevents is the
  gold standard.
