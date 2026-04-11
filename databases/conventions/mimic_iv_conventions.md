# MIMIC-IV (DuckDB) — Database Conventions

These conventions are mandatory. Agents MUST read and apply every rule
before writing any SQL or R code targeting MIMIC-IV.

Source: PhysioNet MIMIC-IV v3.1, Beth Israel Deaconess Medical Center
Engine: DuckDB (local file)
Access: PhysioNet credentialed access required

---

## 1. Date Shifting (CRITICAL)

All dates in MIMIC-IV are shifted into the future (roughly 2100-2200
range) for de-identification. Each patient has a unique, consistent
shift applied to all their records.

**Key rules:**
- **Date differences are preserved.** A 3-day ICU stay is still 3 days.
  Time intervals between events for the same patient are real.
- **Absolute calendar dates are meaningless.** Do NOT filter by calendar
  year (e.g., `WHERE YEAR(admittime) > 2015`). This will exclude patients
  arbitrarily based on their de-identification shift.
- **Use relative time.** Express durations as intervals from a reference
  event (e.g., days from ICU admission, hours from first vasopressor).
- **Cross-patient date comparisons are invalid.** Patient A's 2150-01-01
  and Patient B's 2150-01-01 are NOT the same real-world date.

### anchor_year Mapping

Each patient has an `anchor_year` in the `patients` table — the shifted
year corresponding to their first hospital admission year. To determine
the approximate real era of a patient's data:

```sql
-- anchor_year_group gives the real-world decade range
-- e.g., '2011 - 2013', '2017 - 2019'
SELECT anchor_year_group, COUNT(*) AS n
FROM patients
GROUP BY anchor_year_group
ORDER BY anchor_year_group
```

Use `anchor_year_group` if you need to restrict to a particular era
(e.g., post-2015 for ICD-10 coding consistency).

---

## 2. Age Handling

- `patients.anchor_age` = age at the patient's `anchor_year` (their
  first hospital admission year)
- For a specific admission, compute age as:
  ```sql
  anchor_age + (EXTRACT(YEAR FROM admittime) - anchor_year) AS age_at_admission
  ```
- **Ages > 89 are top-coded** as 91 in `anchor_age` for privacy. These
  patients may be anywhere from 89 to 100+. For geriatric studies, note
  this ceiling effect.
- For adult studies, filter: `anchor_age >= 18`
- For pediatric/neonatal exclusion: same filter, applied after computing
  age at the specific admission of interest

---

## 3. Join Key Hierarchy (CRITICAL)

MIMIC-IV has three levels of identifiers. Using the wrong join key is
the most common source of errors.

```
subject_id  (patient level — spans all admissions)
  └── hadm_id  (hospital admission level)
        └── stay_id  (ICU stay level — within a single admission)
```

### Which key to use where:

| Table | Join Key | Level |
|-------|----------|-------|
| `patients` | `subject_id` | Patient |
| `admissions` | `hadm_id`, `subject_id` | Admission |
| `diagnoses_icd` | `hadm_id` | Admission |
| `procedures_icd` | `hadm_id` | Admission |
| `labevents` | `hadm_id` (some rows have NULL hadm_id) | Admission |
| `prescriptions` | `hadm_id` | Admission |
| `pharmacy` | `hadm_id` | Admission |
| `emar` | `hadm_id` | Admission |
| `microbiologyevents` | `hadm_id` | Admission |
| `services` | `hadm_id` | Admission |
| `transfers` | `hadm_id` | Admission |
| `icustays` | `stay_id`, `hadm_id` | ICU stay |
| `chartevents` | `stay_id` | ICU stay |
| `inputevents` | `stay_id` | ICU stay |
| `outputevents` | `stay_id` | ICU stay |
| `procedureevents` | `stay_id` | ICU stay |

**Common mistake:** Joining `chartevents` (ICU) to `labevents` (hospital)
on `hadm_id` without accounting for multiple ICU stays per admission.
Always be explicit about which stay you mean.

**Multiple ICU stays per admission:** A patient may be admitted to the
ICU, discharged to the floor, and readmitted to the ICU within the same
hospital stay. This produces multiple `stay_id`s for one `hadm_id`.
Decide early whether your protocol analyzes the first ICU stay, the
last, or all stays.

**Readmissions:** The same `subject_id` may have multiple `hadm_id`s
across years. For new-user designs, check for prior admissions.

---

## 4. ICD Coding — Dual Version System

MIMIC-IV contains BOTH ICD-9 and ICD-10 codes. The `icd_version` column
in `diagnoses_icd` and `procedures_icd` indicates which system (9 or 10).

**Rules:**
- **Always include `icd_version` in WHERE clauses** when filtering by
  diagnosis or procedure codes
- ICD-9 codes appear in older admissions; ICD-10 in newer admissions
  (the transition happened ~2015 in real time, but shifted dates obscure
  this — use `anchor_year_group` to approximate)
- For maximum coverage, map equivalent codes in both systems. For
  simplicity, restrict to ICD-10 (`icd_version = 10`) and accept the
  loss of older admissions
- Use `d_icd_diagnoses` and `d_icd_procedures` to look up code
  descriptions: `SELECT long_title FROM d_icd_diagnoses WHERE icd_code = 'E11.9' AND icd_version = 10`
- **Validate all ICD-10 codes** via the ICD-10 MCP tool (`lookup_code`,
  `search_codes`) before finalizing any code list

### Diagnosis sequence numbers

`diagnoses_icd.seq_num` indicates the priority of the diagnosis for that
admission (1 = primary). For identifying the *reason for admission*, use
`seq_num = 1`. For comorbidity flags, search all `seq_num` values.

---

## 5. Medication Identification

MIMIC-IV has three medication-related tables with different purposes:

| Table | Contains | Use for |
|-------|----------|---------|
| `prescriptions` | Medication orders (what was ordered) | Treatment assignment in TTE |
| `pharmacy` | Dispensing details with NDC and sometimes RxNorm CUI | Drug code validation |
| `emar` | Actual administrations (what was given, when) | Precise treatment timing |

### Identification strategy:

1. **Start with `prescriptions`** for treatment assignment — it has
   `drug` (text name), `starttime`, `stoptime`, `route`, `dose_val_rx`
2. **Join to `pharmacy`** on `pharmacy_id` for standardized codes —
   `pharmacy.rxnorm` contains RxNorm CUIs (but may be NULL for some drugs)
3. **Use `emar`** for actual administration timing — `emar.charttime` is
   when the drug was actually given, `emar.event_txt` indicates if it was
   administered, held, or refused

### Drug matching:

- `prescriptions.drug` is a text field (e.g., "Norepinephrine",
  "Vancomycin"). Match by text pattern for initial cohort identification.
- For formal code validation, use `pharmacy.rxnorm` or `pharmacy.ndc`
- **Validate all drug identifications** via `get_rxcuis_for_drug()` MCP
  tool. Include both SCD (generic) and SBD (branded) forms.
- For ICU vasoactive drugs, `inputevents` is the definitive source —
  it has exact start/stop times and infusion rates

### Common ICU drug itemids (inputevents):

These are the `itemid` values in `inputevents` for common ICU medications.
Verify against `d_items` before using:

| Drug | Typical itemid(s) | Notes |
|------|-------------------|-------|
| Norepinephrine | 221906 | Most common vasopressor |
| Vasopressin | 222315 | Second-line vasopressor |
| Phenylephrine | 221749 | |
| Epinephrine | 221289 | |
| Dopamine | 221662 | |
| Propofol | 222168 | Sedation |
| Midazolam | 221668 | Sedation |
| Fentanyl | 221744 | Analgesia |
| Insulin | 223257, 223258, 223259, 223260, 223261, 223262 | Multiple formulations |
| Heparin | 225152, 225975 | Anticoagulation |

Always verify: `SELECT itemid, label FROM d_items WHERE label ILIKE '%norepinephrine%'`

---

## 6. Lab Identification

Labs are in `labevents`, with metadata in `d_labitems`.

### Lookup pattern:

```sql
-- Find itemid for a lab by name
SELECT itemid, label, fluid, category, loinc_code
FROM d_labitems
WHERE label ILIKE '%creatinine%'

-- Then query labevents
SELECT subject_id, hadm_id, charttime, valuenum, valueuom
FROM labevents
WHERE itemid = 50912  -- Creatinine
  AND valuenum IS NOT NULL
```

### Key rules:

- **Use `d_labitems.loinc_code`** for standardized identification when
  available. Some items have NULL LOINC — fall back to label text matching.
- **Always filter `valuenum IS NOT NULL`** for numeric analyses. The
  `value` column contains text (including non-numeric results like
  "POSITIVE", ">1000").
- **Watch for units.** Some labs have multiple `valueuom` values for the
  same `itemid`. Always check and standardize units.
- **Flag column:** `flag = 'abnormal'` indicates out-of-range values.
  `ref_range_lower` and `ref_range_upper` give the reference range.
- **Specimen matters.** The same test from different specimens (blood vs.
  urine) has different `itemid` values. Check `d_labitems.fluid`.

### Common lab itemids:

| Lab | itemid | LOINC | fluid |
|-----|--------|-------|-------|
| Creatinine | 50912 | 2160-0 | Blood |
| BUN | 51006 | 3094-0 | Blood |
| Glucose | 50931 | 2345-7 | Blood |
| Potassium | 50971 | 2823-3 | Blood |
| Sodium | 50983 | 2951-2 | Blood |
| Hemoglobin | 51222 | 718-7 | Blood |
| Platelet Count | 51265 | 777-3 | Blood |
| WBC | 51301 | 6690-2 | Blood |
| Lactate | 50813 | 2524-7 | Blood |
| Bilirubin, Total | 50885 | 1975-2 | Blood |
| Albumin | 50862 | 1751-7 | Blood |
| INR | 51237 | 6301-6 | Blood |

Always verify against `d_labitems` — itemids may differ across MIMIC versions.

---

## 7. Vitals (chartevents)

ICU vitals are in `chartevents`, with metadata in `d_items`.

### Key rules:

- **chartevents is very large (~330M rows).** NEVER run
  `SELECT * FROM chartevents`. Always filter by `itemid` AND time range.
- **Temperature is in Celsius**, not Fahrenheit. Normal = 36.5-37.5C.
- **Filter out implausible values:** e.g., HR < 0 or > 300,
  SBP < 0 or > 300, temp < 25 or > 45.
- **NULL and 0:** Some missing vitals are coded as 0 rather than NULL.
  Treat both as missing: `WHERE valuenum IS NOT NULL AND valuenum > 0`

### Common vital itemids:

| Vital | itemid(s) | Units |
|-------|-----------|-------|
| Heart Rate | 220045 | bpm |
| Systolic BP (arterial) | 220050 | mmHg |
| Diastolic BP (arterial) | 220051 | mmHg |
| Mean BP (arterial) | 220052 | mmHg |
| Systolic BP (non-invasive) | 220179 | mmHg |
| Diastolic BP (non-invasive) | 220180 | mmHg |
| Mean BP (non-invasive) | 220181 | mmHg |
| Respiratory Rate | 220210 | breaths/min |
| SpO2 | 220277 | % |
| Temperature (C) | 223761 | C |
| Temperature (F) | 223762 | F (convert!) |
| Weight (kg) | 224639 | kg |
| Height (cm) | 226730 | cm |
| GCS Total | 228112 | score |

---

## 8. Mortality and Outcome Ascertainment

### In-hospital mortality:

```sql
-- Method 1: hospital_expire_flag
SELECT * FROM admissions WHERE hospital_expire_flag = 1

-- Method 2: deathtime (more precise — gives time of death)
SELECT * FROM admissions WHERE deathtime IS NOT NULL
```

### All-cause mortality (including post-discharge):

```sql
-- patients.dod includes out-of-hospital deaths (from SSA Death Master File)
SELECT p.subject_id, p.dod, a.dischtime,
       EXTRACT(EPOCH FROM (p.dod - a.dischtime)) / 86400.0 AS days_to_death
FROM patients p
INNER JOIN admissions a ON p.subject_id = a.subject_id
WHERE p.dod IS NOT NULL
```

**Caveats:**
- `dod` is available for ~15-20% of patients (those who died and were
  captured by the Social Security Death Master File)
- Patients with NULL `dod` may be alive OR may have died but not been
  captured. This is right-censoring — handle appropriately in survival
  analyses.
- For time-to-event analyses, censor at the last known alive date
  (typically `dischtime`) if `dod` is NULL.

---

## 9. Time Zero for Target Trial Emulation

The choice of time zero is the most important design decision in a TTE.
MIMIC-IV supports several patterns:

### Treatment initiation studies:
- **Time zero = first drug administration** from `emar.charttime` or
  `inputevents.starttime`
- Verify the patient had no prior administration of the same drug class
  during the same admission (new-user design)
- For cross-admission new-user: check prior `hadm_id`s for the same
  `subject_id`

### Condition-onset studies:
- **Time zero = ICU admission** (`icustays.intime`) for ICU-onset conditions
- **Time zero = hospital admission** (`admissions.admittime`) for
  hospital-level analyses
- **Time zero = onset of condition** (e.g., first sepsis diagnosis,
  first vasopressor) — requires careful definition

### Alignment requirement:
Time zero must simultaneously serve as:
1. The point when eligibility is confirmed
2. The point when treatment is assigned
3. The start of follow-up

If these three do not align, document the discrepancy and assess
immortal time bias risk.

---

## 10. DuckDB SQL Patterns

MIMIC-IV in DuckDB uses standard SQL, not T-SQL.

### Key syntax differences from SQL Server:

| Operation | DuckDB | SQL Server |
|-----------|--------|------------|
| String concat | `\|\|` | `+` |
| Current date | `CURRENT_DATE` | `GETDATE()` |
| Date add | `col + INTERVAL '7 days'` | `DATEADD(day, 7, col)` |
| Date diff | `EXTRACT(EPOCH FROM (a - b)) / 86400` | `DATEDIFF(day, b, a)` |
| Top N rows | `LIMIT N` | `TOP N` |
| Temp tables | `CREATE TEMP TABLE t AS ...` | `SELECT INTO #t ...` |
| ISNULL | `COALESCE(col, default)` | `ISNULL(col, default)` |
| Boolean | `TRUE` / `FALSE` | `1` / `0` |
| Case-insensitive LIKE | `ILIKE` | N/A (LIKE is case-insensitive) |

### Table references:
- Bare table names: `SELECT * FROM patients` (no schema prefix)
- DuckDB is case-insensitive for identifiers by default

### CTEs preferred over temp tables:
```sql
WITH eligible AS (
  SELECT a.subject_id, a.hadm_id, a.admittime,
         p.anchor_age + (EXTRACT(YEAR FROM a.admittime) - p.anchor_year) AS age
  FROM admissions a
  INNER JOIN patients p ON a.subject_id = p.subject_id
),
treated AS (
  SELECT e.*, i.starttime AS treatment_start
  FROM eligible e
  INNER JOIN inputevents i ON e.hadm_id = ...
)
SELECT * FROM treated
```

---

## 11. Critical Filters

Apply these filters unless the protocol explicitly justifies otherwise:

- **Adult patients:** `anchor_age >= 18` or computed age at admission >= 18
- **Exclude short observation stays:** For treatment studies, require
  ICU LOS > 24 hours (`icustays.los > 1`) to ensure patients had
  opportunity to receive treatment
- **First ICU stay per admission:** Unless studying ICU readmissions,
  use `ROW_NUMBER() OVER (PARTITION BY hadm_id ORDER BY intime) = 1`
- **First admission per patient:** For new-user designs, use
  `ROW_NUMBER() OVER (PARTITION BY subject_id ORDER BY admittime) = 1`

---

## 12. Common Pitfalls

### Row duplication from joins
Multiple ICU stays per admission, multiple labs per patient, or multiple
diagnoses per admission can cause row duplication. Use
`ROW_NUMBER() ... WHERE rn = 1` or aggregate before joining.

### Prescriptions vs. administration
`prescriptions` = what was ordered. `emar` = what was actually given.
For TTE, use `emar` when possible — a prescription that was never
administered should not count as treatment.

### Lab timing
`labevents.charttime` is when the specimen was collected.
`labevents.storetime` is when the result was available. For clinical
decision-making analyses, `storetime` may be more relevant.

### Survivor bias in ICU analyses
Patients who die quickly in the ICU have fewer charted observations.
Requiring a minimum number of observations can inadvertently exclude the
sickest patients. Document this risk.

### chartevents performance
With ~330M rows, unfiltered queries on `chartevents` will be extremely
slow. Always filter by `itemid` first, then by time range. Create
indexes if needed for repeated queries.

---

## 13. Sample Size Guidance

| Condition | Approximate ICU stays | ICU mortality |
|-----------|----------------------|---------------|
| Sepsis (any) | 15,000-20,000 | ~20-25% |
| Heart failure | 5,000-8,000 | ~10-15% |
| Pneumonia | 5,000-7,000 | ~15-20% |
| Acute kidney injury | 10,000-15,000 | ~15-20% |
| Respiratory failure / ARDS | 8,000-12,000 | ~25-30% |
| GI bleeding | 3,000-5,000 | ~5-10% |
| Stroke | 3,000-5,000 | ~15-20% |
| Post-cardiac surgery | 5,000-8,000 | ~3-5% |
| Trauma | 3,000-5,000 | ~10-15% |
| Overall ICU | ~65,000 | ~10-12% |

These are approximate. Actual counts depend on how strictly eligibility
criteria are defined. Always verify with a feasibility query before
committing to a protocol design.

---

## 14. Recommended TTE Designs for MIMIC-IV

MIMIC-IV's timestamped treatment and outcome data make it ideal for
these TTE patterns:

**Strong designs:**
- Vasopressor initiation timing (early vs. late norepinephrine in sepsis)
- Ventilation strategy comparison (low vs. conventional tidal volume)
- Antibiotic timing (time from sepsis onset to first antibiotic)
- Transfusion thresholds (restrictive vs. liberal RBC transfusion)
- Renal replacement therapy timing (early vs. delayed initiation in AKI)
- Sedation protocols (propofol vs. midazolam/dexmedetomidine)

**Feasible designs:**
- Steroid use in septic shock (hydrocortisone vs. no steroid)
- Nutrition timing (early vs. late enteral nutrition)
- Beta-blocker continuation in sepsis
- Anticoagulation strategies in ICU

**Weaker designs (use with caution):**
- Anything requiring outpatient follow-up (MIMIC has limited post-discharge data)
- Chronic disease management (MIMIC captures acute episodes, not longitudinal care)
- Drug dose optimization (doses vary by clinical context — confounding by indication is severe)
