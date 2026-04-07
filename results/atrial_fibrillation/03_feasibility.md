# Phase 2: Dataset Feasibility Assessment — Atrial Fibrillation

**Target dataset:** PCORnet CDW (institutional Clinical Data Warehouse, MS SQL Server)
**Assessment date:** 2026-04-06
**Data profile source:** `CDW_data_profile.md` (generated 2026-04-05)

---

## Executive Summary

All four approved questions are assessed against the PCORnet CDW. The CDW contains
**86,308 patients with atrial fibrillation** (ICD-10 I48.x), **~20,000 patients
with OAC prescriptions** (apixaban 6,664 + rivaroxaban 3,410 + warfarin 9,689),
and robust lab/vital sign coverage. Key constraints include moderate PRESCRIBING
table volume (1.29M patients total, 16.5M rows) compared to DIAGNOSIS (4.39M
patients, 152M rows), absent INR data under the currently-mapped LOINC code
(requires re-mapping to 6301-6), and limited dose-level granularity for the
underdosing question.

**Feasibility rankings (best to worst):**
1. **Q3 — Apixaban vs Rivaroxaban in AF+CKD:** FEASIBLE
2. **Q4 — Early Rhythm Control vs Rate Control in Elderly AF:** FEASIBLE
3. **Q1 — OAC vs No OAC at Low CHA₂DS₂-VASc:** PARTIALLY FEASIBLE
4. **Q2 — DOAC Underdosing vs Guideline-Concordant Dosing:** PARTIALLY FEASIBLE

---

## CDW Overview (Key Data Profile Facts)

| Parameter | Value | Source |
|-----------|-------|--------|
| Total patients in DEMOGRAPHIC | 10,091,847 | §1 |
| AF patients (I48.x, ICD-10) | 86,308 | §14 |
| PRESCRIBING: distinct patients | 1,293,303 | §1 |
| PRESCRIBING: total rows | 16,514,110 | §1 |
| PRESCRIBING: earliest data | 2004-04 | §1 |
| RXNORM_CUI completeness | 98.6% non-NULL | §12 |
| RX_DOSE_ORDERED completeness | 87.5% non-NULL | §12 |
| RX_DAYS_SUPPLY completeness | 42.8% non-NULL | §12 |
| RX_END_DATE completeness | 47.6% non-NULL | §12 |
| ICD-10 transition | Oct 2015 (ICD-9 dominant before; ICD-10 dominant after) | §4 |
| Epic go-live | ~2019-2020 (legacy encounters drop sharply after 2021) | §3 |
| Death records | 113,105 patients | §11 |
| MED_ADMIN: earliest data | 2021-04 (Epic-only, 157K patients) | §1 |

### Key Medication Counts (from CDW data profile §15)

| Drug | Patients | Prescriptions |
|------|----------|---------------|
| Apixaban | 6,664 | 16,263 |
| Rivaroxaban | 3,410 | 7,652 |
| Dabigatran | 160 | 436 |
| Edoxaban | <11 | 13 |
| Warfarin | 9,689 | 19,130 |
| Amiodarone | 9,070 | 16,291 |
| Flecainide | 3,438 | 8,828 |
| Sotalol | 2,001 | 4,672 |
| Dronedarone | 148 | 335 |
| Metoprolol | 69,216 | 169,143 |
| Diltiazem | 6,626 | 13,259 |
| Digoxin | 5,069 | 7,754 |

### Key Condition Counts (from CDW data profile §14)

| Condition | ICD-10 | Patients |
|-----------|--------|----------|
| Atrial fibrillation | I48.x | 86,308 |
| Heart failure | I50.x | 105,812 |
| Ischemic stroke | I63.x | 65,747 |
| Hypertension | I10-I16 | 487,523 |
| Type 2 diabetes | E11.x | 242,522 |
| CKD stage 3 | N18.3x | 38,009 |
| CKD stage 4 | N18.4 | 13,766 |
| CKD stage 5 | N18.5 | 7,008 |
| ESRD / dialysis | N18.6, Z99.2 | 31,705 |
| Major bleeding | various | 10,580 |
| VTE / PE | I26.x, I82.x | 48,396 |
| Dementia | F01-F03, G30 | 29,093 |

---

## Q1: OAC vs No OAC at CHA₂DS₂-VASc = 1 (Men) / 2 (Women)

### Clinical Context

Patients with non-valvular AF (NVAF) at the threshold CHA₂DS₂-VASc score
represent a genuine clinical equipoise zone. Guidelines offer a IIb
recommendation (weak, "may consider") for OAC in this group. The target trial
would emulate an RCT of any OAC (DOAC or warfarin) vs. no anticoagulation.

### Variable Mapping

| Protocol Element | CDW Table | Column(s) | Codes / Logic |
|-----------------|-----------|-----------|---------------|
| **Population: NVAF** | CDW.dbo.DIAGNOSIS | DX, DX_TYPE | DX LIKE 'I48%' AND DX_TYPE = '10' |
| **Exclude valvular AF** | CDW.dbo.DIAGNOSIS | DX | Exclude: I05.0, I05.1, I05.2, I05.9 (rheumatic mitral stenosis); I06.x, I07.x, I08.x (rheumatic valve); Z95.2, Z95.3, Z95.4 (prosthetic valve) |
| **Age** | CDW.dbo.DEMOGRAPHIC | BIRTH_DATE | DATEDIFF(year, BIRTH_DATE, index_date) |
| **Sex** | CDW.dbo.DEMOGRAPHIC | SEX | 'M' or 'F' |
| **CHA₂DS₂-VASc = 1 (men) / 2 (women)** | Multiple | See below | Computed from components |
| **Exposure: OAC initiation** | CDW.dbo.PRESCRIBING | RXNORM_CUI, RX_ORDER_DATE | Any DOAC or warfarin SCD/SBD RXCUI (see Appendix A) |
| **Comparator: No OAC** | CDW.dbo.PRESCRIBING | — | Absence of OAC prescription within grace period |
| **Outcome: Ischemic stroke/SE** | CDW.dbo.DIAGNOSIS | DX | DX LIKE 'I63%' (ischemic stroke) OR DX LIKE 'I74%' (arterial embolism/thrombosis) |
| **Outcome: Major bleeding** | CDW.dbo.DIAGNOSIS | DX | I60.x (SAH), I61.x (intracerebral), I62.x (nontraumatic intracranial), K92.0 (hematemesis), K92.1 (melena), K92.2 (GI hemorrhage NOS), K62.5 (rectal hemorrhage), K66.1 (hemoperitoneum), N93.8-N93.9 (uterine bleeding), D68.32 (hemorrhagic disorder due to anticoag), R31.x (hematuria) |
| **Outcome: All-cause mortality** | CDW.dbo.DEATH | DEATH_DATE | Any death record |

#### CHA₂DS₂-VASc Component Mapping

| Component | Points | CDW Source | Codes |
|-----------|--------|------------|-------|
| CHF | 1 | DIAGNOSIS | I50.x |
| Hypertension | 1 | DIAGNOSIS | I10, I11.x, I12.x, I13.x, I15.x, I16.x |
| Age ≥ 75 | 2 | DEMOGRAPHIC | BIRTH_DATE |
| Diabetes | 1 | DIAGNOSIS | E10.x, E11.x, E13.x |
| Stroke/TIA/TE | 2 | DIAGNOSIS | I63.x, G45.x (TIA), I74.x |
| Vascular disease | 1 | DIAGNOSIS | I21.x (MI), I70.x (atherosclerosis), I71.x (aortic aneurysm), I73.9 (PVD) |
| Age 65-74 | 1 | DEMOGRAPHIC | BIRTH_DATE |
| Female sex | 1 | DEMOGRAPHIC | SEX = 'F' |

### Sample Size Estimate

- **AF population:** 86,308 patients with I48.x
- **NVAF subset (exclude valvular):** Rheumatic valve disease is relatively rare; estimate ~80,000–83,000 NVAF patients
- **CHA₂DS₂-VASc = 1 (men) or 2 (women):** This is a narrow score window. In published literature, ~15–20% of AF patients fall in this range. Estimate: **12,000–16,000 patients** in the eligible score range.
- **With OAC prescription in CDW:** Total OAC patients ~20,000 (warfarin 9,689 + apixaban 6,664 + rivaroxaban 3,410 + dabigatran 160). However, not all of these have AF — OAC is prescribed for VTE and other indications too. The intersection of AF + OAC + CHA₂DS₂-VASc = 1/2 is substantially smaller.
- **Estimated eligible + treated:** ~2,000–4,000 OAC-treated patients with the target score
- **Estimated eligible + untreated:** ~8,000–12,000 patients with AF and CHA₂DS₂-VASc = 1/2 who never received OAC

### Time-Zero Definition

**Time zero = date of the first qualifying encounter** where a patient has:
1. An AF diagnosis (I48.x)
2. CHA₂DS₂-VASc = 1 (men) / 2 (women) based on all prior diagnoses
3. No prior OAC prescription (new-user design)
4. No exclusion criteria (valvular disease, prior stroke/TIA, active cancer)

At time zero, patients are classified based on whether an OAC prescription
appears within a ±7-day grace period. This emulates the "intent to treat at
the point of clinical decision."

### Study Period

**Proposed: 2016-01-01 to 2025-12-31**

Justification:
- ICD-10 fully in effect from 2016 (§4: only 36 ICD-9 patients in 2016 vs. 591,526 ICD-10)
- Prescribing data available from 2004, but ICD-10 coding needed for precise AF subtyping
- DOAC adoption accelerated after 2012-2015; warfarin data extends earlier
- This period spans both AllScripts (pre-2020) and Epic (post-2020) eras. Legacy encounter filtering (`RAW_ENC_TYPE <> 'Legacy Encounter'`) is REQUIRED.
- Sensitivity analysis restricted to 2021+ (post-Epic only) recommended

### Exposure Definition

```sql
-- OAC exposure: any DOAC or warfarin prescription within ±7 days of time zero
SELECT DISTINCT p.PATID
FROM CDW.dbo.PRESCRIBING p
WHERE p.RXNORM_CUI IN (
  -- Apixaban (SCD + SBD): see Appendix A for full list
  '1364435','1364445','1364441','1364447',
  -- Rivaroxaban (SCD + SBD)
  '1114198','1232082','1232086','2059015',
  '1114202','1232084','1232088','2059017',
  -- Dabigatran (SCD + SBD)
  '1037179','1723476','1037045','1037181','1723478','1037049',
  -- Edoxaban (SCD + SBD)
  '1599543','1599551','1599555','1599549','1599553','1599557',
  -- Warfarin (SCD + SBD): see Appendix A for full 29-code list
  '855288','855302','855312','855318','855324','855332','855338',
  '855344','855296','855350',
  '855290','855304','855314','855320','855326','855334','855340',
  '855346','855298',
  '855292','855306','855316','855322','855328','855336','855342',
  '855348','855300'
)
AND p.RX_ORDER_DATE BETWEEN '2016-01-01' AND GETDATE()
```

### Outcome Definition

- **Ischemic stroke / systemic embolism:** First occurrence of I63.x or I74.x after time zero, identified in DIAGNOSIS linked to an IP or ED encounter (ENC_TYPE IN ('IP','EI','ED'))
- **Major bleeding:** First occurrence of intracranial hemorrhage (I60.x, I61.x, I62.x) or GI bleeding (K92.0, K92.1, K92.2) or other major bleeding codes, linked to IP/ED encounter
- **All-cause mortality:** DEATH_DATE from CDW.dbo.DEATH (113,105 patients with death records; wrapping in ROW_NUMBER to deduplicate)

### Key Confounders Available

| Confounder | CDW Source | Availability |
|------------|-----------|-------------|
| Age, sex, race, ethnicity | DEMOGRAPHIC | 100% complete |
| BMI | VITAL (ORIGINAL_BMI) | 2.36M patients |
| Blood pressure | VITAL (SYSTOLIC, DIASTOLIC) | 1.22M patients |
| Serum creatinine / eGFR | LAB_RESULT_CM (2160-0, 48642-3) | 572K / 167K patients |
| Hemoglobin | LAB_RESULT_CM (718-7) | 604K patients |
| HbA1c | LAB_RESULT_CM (4548-4) | 332K patients |
| Comorbidities (HF, HTN, DM, CKD, prior bleed, VTE) | DIAGNOSIS | Good coverage per §14 |
| Medications (beta-blockers, antiplatelets, statins) | PRESCRIBING | Available via RXNORM_CUI |
| Smoking | VITAL (SMOKING) | 2.55M patients; BUT 99.8% are 'UN' or 'NI' — **effectively unusable** |

### Positivity Assessment

**CONCERN:** Positivity is the key challenge. At CHA₂DS₂-VASc = 1 (men) / 2 (women),
the guideline recommendation is equivocal — meaning many clinicians do NOT prescribe OAC
at this score. This creates a natural comparator group (no OAC). However:
- The **treated (OAC) arm** may be small (~2,000–4,000) because many clinicians
  defer OAC at this threshold
- The **untreated arm** is likely larger but may be contaminated by patients who
  subsequently start OAC (requiring censoring or ITT approach)
- Positivity violations may occur in subgroups (e.g., very young men with lone AF
  and CHA₂DS₂-VASc = 1 from age alone — almost none receive OAC)

### Data Gaps

1. **Smoking data is effectively absent** (99.8% unknown/NI) — cannot use as confounder
2. **Aspirin/antiplatelet use** may be underrepresented in PRESCRIBING if patients purchase OTC; cannot reliably identify the "aspirin-only" strategy
3. **No INR data under current mapping** (LOINC 30313-1 is mapped incorrectly — it is arterial hemoglobin, NOT INR). Must query 6301-6, 34714-6, 38875-1 for actual INR data. This affects warfarin-specific analyses.
4. **PAYER_TYPE_PRIMARY is 0% populated** (§3e) — cannot adjust for insurance type
5. **RX_DAYS_SUPPLY only 42.8% complete** — hard to determine treatment duration/persistence
6. **Score computation complexity:** CHA₂DS₂-VASc requires looking back through all prior diagnoses, which is computationally intensive and depends on prior care being captured in this CDW

### Feasibility Verdict: PARTIALLY FEASIBLE

**Rating rationale:** The population exists (86K AF patients, ~12–16K at target score),
but the narrow CHA₂DS₂-VASc window combined with moderate OAC prescription counts
yields a treated group of only ~2,000–4,000 patients. This is borderline for
time-to-event analyses with multiple outcomes and subgroups. The inability to capture
aspirin use (OTC) and the absent smoking data limit confounder adjustment. The study
is feasible as a primary analysis but may lack power for subgroup analyses.

---

## Q2: DOAC Underdosing vs Guideline-Concordant Dosing

### Clinical Context

Inappropriate dose reduction of DOACs (particularly apixaban 2.5mg when 5mg is indicated,
and rivaroxaban 15mg when 20mg is indicated) is associated with worse outcomes in
observational studies. The key challenge is distinguishing appropriate dose reduction
(per label criteria: age ≥ 80, weight ≤ 60kg, creatinine ≥ 1.5mg/dL for apixaban;
CrCl 15-50 for rivaroxaban) from inappropriate underdosing.

### Variable Mapping

| Protocol Element | CDW Table | Column(s) | Codes / Logic |
|-----------------|-----------|-----------|---------------|
| **Population: NVAF + new DOAC** | DIAGNOSIS + PRESCRIBING | DX, RXNORM_CUI | AF (I48.x) + first DOAC Rx |
| **Dose identification** | CDW.dbo.PRESCRIBING | RXNORM_CUI, RX_DOSE_ORDERED | **RXNORM_CUI distinguishes formulations by dose** (e.g., apixaban 2.5mg = RXCUI 1364435 vs 5mg = 1364445) |
| **Dose-reduction criteria (apixaban)** | DEMOGRAPHIC + LAB_RESULT_CM + VITAL | BIRTH_DATE, RESULT_NUM (creatinine 2160-0), WT | Age ≥ 80 AND/OR weight ≤ 60kg AND/OR serum Cr ≥ 1.5 (need ≥2 of 3) |
| **Dose-reduction criteria (rivaroxaban)** | LAB_RESULT_CM | RESULT_NUM (eGFR 48642-3, 62238-1) | CrCl 15-50 mL/min |
| **Exposure: Inappropriately reduced dose** | Derived | — | Low-dose RXCUI + NOT meeting dose-reduction criteria |
| **Comparator: Guideline-concordant dose** | Derived | — | Standard-dose RXCUI OR low-dose RXCUI + meeting criteria |
| **Outcome: Stroke/SE** | DIAGNOSIS | DX | I63.x, I74.x (IP/ED encounters) |
| **Outcome: Major bleeding** | DIAGNOSIS | DX | I60.x, I61.x, I62.x, K92.x |
| **Outcome: Mortality** | DEATH | DEATH_DATE | Death record |

### Sample Size Estimate

- **Apixaban new users in CDW:** 6,664 patients total (not all new-users with AF; some may be for VTE)
- **Rivaroxaban new users in CDW:** 3,410 patients total
- **Combined DOAC new users with AF:** Need intersection of AF (86,308) with DOAC Rx (~10,074). Estimate ~6,000–8,000 AF patients with a DOAC prescription.
- **Dose-specific breakdown (apixaban):**
  - RXCUI 1364435 / 1364441 = 2.5mg (reduced dose)
  - RXCUI 1364445 / 1364447 = 5mg (standard dose)
  - The proportion inappropriately underdosed in the literature is ~10–15% of total DOAC users
  - Estimated inappropriately underdosed: **600–1,000 patients**
- **Dose-specific breakdown (rivaroxaban):**
  - RXCUI 1232082 / 1232084 = 15mg (reduced dose for AF)
  - RXCUI 1232086 / 1232088 = 20mg (standard dose for AF)
  - Estimated inappropriately underdosed: **300–500 patients**

### Time-Zero Definition

**Time zero = date of first DOAC prescription** (RX_ORDER_DATE for the first DOAC
RXCUI) in a patient with prior AF diagnosis (I48.x). This is a new-user design —
patients with any prior DOAC prescription are excluded (washout period of ≥365 days).

### Study Period

**Proposed: 2016-01-01 to 2025-12-31**

- Apixaban FDA-approved for AF: December 2012; rivaroxaban: November 2011
- Meaningful DOAC prescribing volume begins ~2014-2015 in this CDW
- ICD-10 coding from 2016 enables reliable AF and comorbidity identification

### Exposure Definition

The critical insight is that **RXNORM_CUI encodes the dose directly** — each dose
strength has its own SCD/SBD RXCUI. So we do NOT need RX_DOSE_ORDERED (which is
87.5% complete) as the primary dose identifier:

```sql
-- Apixaban dose classification via RXCUI
CASE
  WHEN RXNORM_CUI IN ('1364435','1364441') THEN 'apixaban_2.5mg'  -- reduced
  WHEN RXNORM_CUI IN ('1364445','1364447') THEN 'apixaban_5mg'    -- standard
  WHEN RXNORM_CUI IN ('1232082','1232084') THEN 'rivaroxaban_15mg' -- reduced (AF)
  WHEN RXNORM_CUI IN ('1232086','1232088') THEN 'rivaroxaban_20mg' -- standard (AF)
END AS doac_dose_group
```

To classify as "inappropriately reduced," we check the dose-reduction criteria:

**Apixaban 2.5mg is appropriate IF** the patient meets ≥2 of:
1. Age ≥ 80 (from DEMOGRAPHIC.BIRTH_DATE)
2. Weight ≤ 60 kg (from VITAL.WT — 914K patients have weight data)
3. Serum creatinine ≥ 1.5 mg/dL (from LAB_RESULT_CM, LOINC 2160-0 — 572K patients)

**Rivaroxaban 15mg is appropriate IF** CrCl 15–50 mL/min (derived from creatinine + age + weight + sex via Cockcroft-Gault).

### Key Confounders Available

Same as Q1 (demographics, comorbidities, labs, vitals), plus:
- **Prescriber specialty** (PROVIDER.PROVIDER_SPECIALTY_PRIMARY) — cardiologists vs. PCPs may dose differently
- **HAS-BLED score components:** hypertension, renal dysfunction, liver dysfunction, prior stroke, prior bleeding, age > 65, drug/alcohol use, antiplatelet use

### Positivity Assessment

**MAJOR CONCERN:** The inappropriately underdosed group is estimated at only
~600–1,000 patients for apixaban and ~300–500 for rivaroxaban. After applying
the new-user restriction and requiring AF diagnosis, these numbers may shrink further.
This is borderline for robust causal inference, especially for rare outcomes
like intracranial hemorrhage.

**STRENGTH:** Within the CDW, RXNORM_CUI directly encodes dose, so exposure
misclassification is minimal. This is a cleaner signal than relying on RX_DOSE_ORDERED.

### Data Gaps

1. **Weight data availability:** VITAL.WT has 914K patients, but completeness around
   the index date for DOAC users specifically is unknown. Missing weight prevents
   classifying apixaban dose appropriateness (need ≥2 of 3 criteria).
2. **CrCl vs eGFR:** The apixaban label uses serum creatinine (well-populated at 572K),
   but the rivaroxaban label uses CrCl (Cockcroft-Gault), which requires weight data.
3. **Frequency information:** RX_FREQUENCY could confirm BID vs QD dosing, but its
   completeness is not reported in the data profile. Apixaban 2.5mg BID (AF) vs
   2.5mg BID (VTE prophylaxis) may need disambiguation.
4. **Indication for DOAC:** Patients prescribed a DOAC for VTE (not AF) would be
   misclassified. Must require a prior AF diagnosis to minimize this.
5. **RX_DAYS_SUPPLY only 42.8% complete** — persistence/adherence analysis is limited

### Feasibility Verdict: PARTIALLY FEASIBLE

**Rating rationale:** The RXCUI-based dose classification is a clean approach. However,
the inappropriately-underdosed subgroup is small (estimated 600–1,000 for apixaban),
and the study requires three pieces of data (age, weight, creatinine) to classify
appropriateness — patients missing weight data cannot be classified. The study is
feasible for apixaban (larger N) but may struggle for rivaroxaban alone. A combined
apixaban + rivaroxaban analysis would improve power. Recommend restricting to
apixaban initially and considering rivaroxaban as a sensitivity analysis.

---

## Q3: Apixaban vs Rivaroxaban in AF with CKD Stage 3b–5

### Clinical Context

No head-to-head RCT has compared apixaban vs rivaroxaban in AF patients with
moderate-to-severe CKD (eGFR < 45). Observational studies (ARISTOPHANES sub-analyses,
COMBINE-AF) suggest possible apixaban superiority for safety, but CKD subgroup
data is limited. This is a clinically critical question because CKD patients are at
simultaneous elevated risk for stroke AND bleeding.

### Variable Mapping

| Protocol Element | CDW Table | Column(s) | Codes / Logic |
|-----------------|-----------|-----------|---------------|
| **Population: NVAF** | CDW.dbo.DIAGNOSIS | DX, DX_TYPE | DX LIKE 'I48%' AND DX_TYPE = '10' |
| **CKD 3b-5** | CDW.dbo.DIAGNOSIS + LAB_RESULT_CM | DX, RESULT_NUM | DX: N18.32 (3b), N18.4, N18.5 OR eGFR < 45 via LAB (LOINC 48642-3, 62238-1, 33914-3) |
| **Exclude ESRD/dialysis** | CDW.dbo.DIAGNOSIS + PROCEDURES | DX, PX | N18.6, Z99.2; CPT 90935-90940, 90945, 90947 (dialysis) |
| **Exclude valvular AF** | CDW.dbo.DIAGNOSIS | DX | Same as Q1 |
| **Exposure: Apixaban** | CDW.dbo.PRESCRIBING | RXNORM_CUI | RXCUI IN ('1364435','1364445','1364441','1364447') |
| **Comparator: Rivaroxaban** | CDW.dbo.PRESCRIBING | RXNORM_CUI | RXCUI IN ('1114198','1232082','1232086','1114202','1232084','1232088','2059015','2059017') |
| **Outcome: Stroke/SE** | CDW.dbo.DIAGNOSIS | DX | I63.x, I74.x (IP/ED encounter) |
| **Outcome: Major bleeding** | CDW.dbo.DIAGNOSIS | DX | I60-I62 (intracranial), K92.0-K92.2 (GI) |
| **Outcome: GI bleeding** | CDW.dbo.DIAGNOSIS | DX | K92.0, K92.1, K92.2, K62.5, K25.0, K25.4, K26.0, K26.4, K27.0, K27.4, K28.0, K28.4, K29.01, K31.811 |
| **Outcome: Mortality** | CDW.dbo.DEATH | DEATH_DATE | Death record |

### Sample Size Estimate

- **AF patients:** 86,308
- **AF + CKD stage 3 (N18.3x):** The CDW has 38,009 CKD stage 3 patients overall. The intersection with AF: in the literature, ~20–30% of AF patients have CKD. CKD stage 3b-5 specifically is a subset. Estimate: **8,000–15,000 AF + CKD 3b-5 patients** (using both diagnosis codes and eGFR < 45).
- **Alternative eGFR-based ascertainment:** 167,036 patients have eGFR data (48642-3); the fraction with eGFR < 45 AND AF would add patients without an N18.x code. This dual ascertainment (Dx OR lab) substantially improves capture.
- **Apixaban users with AF + CKD:** ~1,500–2,500 (based on 6,664 total apixaban × ~25% CKD overlap × AF filter)
- **Rivaroxaban users with AF + CKD:** ~700–1,200 (based on 3,410 total rivaroxaban × ~25% CKD overlap × AF filter)
- **Total analytic cohort:** ~2,200–3,700 patients (both arms)

### Time-Zero Definition

**Time zero = date of first DOAC prescription** (apixaban or rivaroxaban) in a
patient who has:
1. Prior or concurrent AF diagnosis (I48.x)
2. Evidence of CKD 3b-5: either N18.32/N18.4/N18.5 diagnosis OR eGFR < 45 within
   180 days before the prescription date
3. No prior DOAC use (new-user design, 365-day washout)
4. No ESRD/dialysis (N18.6, Z99.2, dialysis CPT codes)

### Study Period

**Proposed: 2016-01-01 to 2025-12-31**

- Apixaban label for AF: Dec 2012; rivaroxaban for AF: Nov 2011
- ICD-10 for CKD staging (N18.3x subcodes for 3a vs 3b) requires ICD-10
- The 2016+ period ensures clean ICD-10 coding

### Exposure Definition

```sql
-- First DOAC prescription
SELECT p.PATID,
       p.RX_ORDER_DATE AS index_date,
       CASE WHEN p.RXNORM_CUI IN ('1364435','1364445','1364441','1364447')
            THEN 1 ELSE 0 END AS apixaban_arm
FROM CDW.dbo.PRESCRIBING p
WHERE p.RXNORM_CUI IN (
  '1364435','1364445','1364441','1364447',  -- apixaban
  '1114198','1232082','1232086',             -- rivaroxaban SCD
  '1114202','1232084','1232088'              -- rivaroxaban SBD
)
AND p.RX_ORDER_DATE BETWEEN '2016-01-01' AND GETDATE()
```

### CKD Ascertainment (Dual Strategy)

```sql
-- Strategy 1: Diagnosis-based
SELECT DISTINCT d.PATID
FROM CDW.dbo.DIAGNOSIS d
INNER JOIN CDW.dbo.ENCOUNTER e ON d.ENCOUNTERID = e.ENCOUNTERID
  AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
WHERE d.DX IN ('N18.32','N18.4','N18.5')  -- CKD 3b, 4, 5
  AND d.DX_TYPE = '10'
  AND d.ADMIT_DATE BETWEEN '2016-01-01' AND GETDATE()

UNION

-- Strategy 2: Lab-based (eGFR < 45)
SELECT DISTINCT l.PATID
FROM CDW.dbo.LAB_RESULT_CM l
WHERE l.LAB_LOINC IN ('48642-3','62238-1','33914-3','98979-8')
  AND l.RESULT_NUM IS NOT NULL
  AND l.RESULT_NUM > 0 AND l.RESULT_NUM < 45
  AND l.RESULT_DATE BETWEEN '2016-01-01' AND GETDATE()
```

### Key Confounders Available

| Confounder | CDW Source | Notes |
|------------|-----------|-------|
| Age, sex, race | DEMOGRAPHIC | Complete |
| eGFR (continuous) | LAB_RESULT_CM | 167K patients (48642-3); use most recent before index |
| Serum creatinine | LAB_RESULT_CM (2160-0) | 572K patients |
| BMI | VITAL | 2.36M patients |
| Blood pressure | VITAL | 1.22M patients |
| HbA1c | LAB_RESULT_CM (4548-4) | 332K patients |
| Hemoglobin | LAB_RESULT_CM (718-7) | 604K patients (for anemia as bleeding predictor) |
| Platelets | LAB_RESULT_CM (777-3) | 355K patients |
| ALT, AST, bilirubin | LAB_RESULT_CM | 484K/432K/554K patients |
| Comorbidities | DIAGNOSIS | Diabetes, HF, prior stroke/TIA, prior bleeding, hypertension |
| Concomitant meds | PRESCRIBING | Antiplatelet, statin, ACEi/ARB, beta-blocker |
| NT-proBNP | LAB_RESULT_CM (33762-6) | Only 4,714 patients — sparse |

### Positivity Assessment

**FAVORABLE:** Both apixaban and rivaroxaban are commonly prescribed in AF patients
with CKD. In the CDW:
- Apixaban: 6,664 total patients → estimated ~1,500–2,500 with CKD 3b-5
- Rivaroxaban: 3,410 total patients → estimated ~700–1,200 with CKD 3b-5

This 2:1 ratio favoring apixaban is consistent with national prescribing trends
post-2018 (apixaban became the dominant DOAC). Positivity is expected to be
reasonable — both drugs are genuinely used in this population. The main concern
is whether rivaroxaban use is sufficient in severe CKD (stage 4-5), where
apixaban is preferred per guidelines.

### Data Gaps

1. **CKD staging specificity:** N18.3 subcodes (N18.30 unspecified, N18.31 stage 3a,
   N18.32 stage 3b) were introduced with ICD-10. Some providers may use N18.3
   (unspecified) without specifying 3a vs 3b. Need to decide whether to include N18.3
   unspecified (with eGFR verification) or exclude it.
2. **Proteinuria/UACR:** Not in the CDW data profile as a top LOINC. Limited ability
   to adjust for proteinuria severity.
3. **Dialysis status:** Must actively exclude patients who start dialysis during
   follow-up (censoring event)
4. **Smoking:** Unusable (99.8% unknown)
5. **NT-proBNP:** Too sparse (4,714 patients) for reliable adjustment

### Feasibility Verdict: FEASIBLE

**Rating rationale:** This is the strongest candidate. The population is well-defined
using both ICD codes and eGFR lab data (dual ascertainment). Both DOAC arms have
reasonable prescription counts. Confounders (eGFR, creatinine, demographics,
comorbidities, concomitant meds) are well-populated. The active comparator design
(apixaban vs rivaroxaban) avoids the confounding-by-indication problems of
treated-vs-untreated comparisons. The estimated N of 2,200–3,700 is adequate for
the composite primary outcome (stroke/SE + major bleeding). Recommend this as
the lead protocol.

---

## Q4: Early Rhythm Control vs Rate Control in Elderly AF (Age ≥ 80)

### Clinical Context

The EAST-AFNET 4 trial showed early rhythm control was superior to rate control in
AF patients diagnosed within 12 months, but enrolled few patients ≥ 80 years old.
Elderly patients have higher procedural risk but also higher stroke risk. Whether
the EAST-AFNET 4 benefit extends to octogenarians is unknown.

### Variable Mapping

| Protocol Element | CDW Table | Column(s) | Codes / Logic |
|-----------------|-----------|-----------|---------------|
| **Population: AF, age ≥ 80** | DIAGNOSIS + DEMOGRAPHIC | DX, BIRTH_DATE | DX LIKE 'I48%' AND age ≥ 80 at index |
| **Newly diagnosed AF** | DIAGNOSIS | DX, ADMIT_DATE | First I48.x code with no prior I48.x in ≥365 days |
| **Exposure: Early rhythm control** | PRESCRIBING + PROCEDURES | RXNORM_CUI, PX | **AAD Rx** (amiodarone, flecainide, sotalol, dronedarone, dofetilide, propafenone) OR **cardioversion** (CPT 92960) OR **catheter ablation** (CPT 93656) within 12 months of AF diagnosis |
| **Comparator: Rate control** | PRESCRIBING | RXNORM_CUI | Beta-blocker (metoprolol) OR CCB (diltiazem, verapamil) OR digoxin; AND no AAD/cardioversion/ablation within 12 months |
| **Outcome: CV death** | DEATH + DEATH_CAUSE | DEATH_DATE, DEATH_CAUSE | Death with cardiovascular cause (I-codes in DEATH_CAUSE) |
| **Outcome: Stroke** | DIAGNOSIS | DX | I63.x (ischemic), I61.x (hemorrhagic) |
| **Outcome: HF hospitalization** | DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I50.x with IP/EI encounter |
| **Composite outcome** | Derived | — | First of: CV death, stroke, or HF hospitalization |

### Sample Size Estimate

- **AF patients:** 86,308
- **Age ≥ 80 subset:** In the general AF population, ~25–30% are ≥ 80. Estimate: **21,000–26,000 AF patients ≥ 80**.
- **Newly diagnosed (first AF code in CDW):** Depends on lookback window; with a 365-day washout, estimate ~60% have a "new" AF code. Estimate: **12,000–16,000 newly diagnosed AF patients ≥ 80**.
- **Early rhythm control arm:**
  - Amiodarone: 9,070 patients total; ~30% might be ≥80 with AF → ~2,700
  - Flecainide: 3,438 total → ~400–600 age ≥80
  - Sotalol: 2,001 total → ~200–400 age ≥80
  - Cardioversion (CPT 92960): need to query PROCEDURES; likely ~1,000–3,000 ≥80
  - Ablation (CPT 93656): rare in ≥80 population; likely <200
  - **Estimated rhythm control arm: ~3,000–5,000 patients**
- **Rate control arm:**
  - Metoprolol: 69,216 total — very large, but most are for hypertension, not AF
  - Diltiazem: 6,626 total → some AF indication
  - Digoxin: 5,069 total → commonly used for AF rate control in elderly
  - Need intersection with AF + ≥80 + no AAD. This should be the larger arm.
  - **Estimated rate control arm: ~6,000–10,000 patients**

### Time-Zero Definition

**Time zero = date of first AF diagnosis** (first I48.x code) in a patient age ≥ 80,
with no prior AF code in the preceding 365 days. Treatment strategy is classified
based on medications/procedures received within 12 months after time zero:

- **Early rhythm control:** AAD prescription OR cardioversion OR ablation within 12 months
- **Rate control:** Only rate-control agents (beta-blockers, CCBs, digoxin) without any AAD/cardioversion/ablation within 12 months

This creates a classification window, after which outcomes are assessed. This is a
"grace period" approach to handle the fact that rhythm control decisions may be made
weeks to months after diagnosis.

### Study Period

**Proposed: 2016-01-01 to 2024-12-31** (ending 2024 to allow 12-month classification + follow-up)

- Requires ICD-10 for AF subtyping
- 12-month classification window means patients entering after 2024 would not have complete classification data

### Exposure Definition — Rhythm Control

```sql
-- AAD medications (amiodarone, flecainide, sotalol, dronedarone, dofetilide, propafenone)
SELECT DISTINCT p.PATID
FROM CDW.dbo.PRESCRIBING p
WHERE p.RXNORM_CUI IN (
  -- Amiodarone oral (SCD + SBD)
  '835956','833528','835960','834348','833530','835958','834346','834350',
  -- Flecainide
  '886662','886666','886671',
  -- Sotalol (all oral formulations including AF-labeled)
  '904634','1923426','1923422','1923424','904632','904589',
  '1922765','1922720','1922763',
  '904605','904571','904583','904593',
  '1923427','1923423','1923425','904591',
  '1922766','1922721','1922764',
  -- Dronedarone
  '854856','854859',
  -- Dofetilide
  '310003','310004','310005','284404','284405','285016',
  -- Propafenone (IR + ER)
  '861424','861427','861430','861156','861164','861171',
  '861159','861167','861173'
)

UNION

-- Cardioversion or catheter ablation
SELECT DISTINCT pr.PATID
FROM CDW.dbo.PROCEDURES pr
WHERE pr.PX IN ('92960','92961','93656','93657')
  AND pr.PX_TYPE = 'CH'
```

### Exposure Definition — Rate Control

```sql
-- Rate control agents: metoprolol, diltiazem, verapamil, digoxin
SELECT DISTINCT p.PATID
FROM CDW.dbo.PRESCRIBING p
WHERE p.RXNORM_CUI IN (
  -- Metoprolol tartrate IR (representative SCD codes)
  '866924','866514','866511','2723025','1606347','1606349',
  -- Metoprolol succinate ER
  '866427','866436','866412','866419',
  '866429','866438','866414','866421',
  -- Diltiazem IR + ER (representative subset)
  '833217','831103','831102','831054',
  '830861','830845','830837','830801','830795','831359',
  '830874','830877','830879','830882','830897','830900',
  -- Verapamil IR + ER (representative subset)
  '897722','897683','897666','901438','901446',
  '897584','897612','897618','897590','897624','897596','897630',
  '897659','897640','897649',
  -- Digoxin
  '197604','197606','245273','393245','309888','309889','260350','260351',
  '1245443','1245373'
)
```

### Key Confounders Available

| Confounder | CDW Source | Notes |
|------------|-----------|-------|
| Age (continuous) | DEMOGRAPHIC | Complete; all ≥80 by design |
| Sex, race, ethnicity | DEMOGRAPHIC | Complete |
| BMI, BP | VITAL | Good coverage |
| eGFR / creatinine | LAB_RESULT_CM | 167K / 572K |
| HbA1c | LAB_RESULT_CM | 332K (for diabetes) |
| Hemoglobin | LAB_RESULT_CM | 604K |
| Prior HF | DIAGNOSIS (I50.x) | 105,812 patients |
| Prior stroke/TIA | DIAGNOSIS (I63.x, G45.x) | 65,747 + |
| Hypertension | DIAGNOSIS (I10-I16) | 487,523 |
| CKD | DIAGNOSIS + LAB | Available |
| OAC use | PRESCRIBING | Track as concomitant |
| NT-proBNP | LAB_RESULT_CM (33762-6) | Sparse (4,714) |

### Positivity Assessment

**FAVORABLE:** Both rhythm control and rate control strategies are commonly
used in elderly AF patients. The data profile shows substantial AAD prescribing
(amiodarone 9,070 patients is the largest) and very large rate control volumes
(metoprolol 69,216). The critical question is whether rhythm control is used
in octogenarians — in practice, amiodarone is commonly used in the elderly (it
has fewer hemodynamic side effects than other AADs), while flecainide and sotalol
are used less. Cardioversion is also performed in the elderly, though ablation
is rare above 80.

**The rate-control arm will be much larger than rhythm control** (~6,000–10,000
vs ~3,000–5,000), which is expected and can be handled with IPW.

### Data Gaps

1. **AF type (paroxysmal vs persistent):** ICD-10 I48.0 (paroxysmal) vs I48.1x
   (persistent) vs I48.2x (chronic/permanent) could distinguish AF type, but coding
   practices vary. "Newly diagnosed" is defined by first code date, not clinical onset.
2. **Symptom severity:** No EHRA symptom score in the CDW. Cannot adjust for symptom-driven treatment selection (symptomatic patients more likely to get rhythm control).
3. **LVEF (ejection fraction):** Not captured as a structured variable. Would need
   NLP on echocardiography reports, which is not available.
4. **Left atrial size:** Not captured (requires echo data)
5. **Smoking:** Unusable (99.8% unknown)
6. **CV death vs all-cause death:** DEATH_CAUSE table exists but may be incompletely
   populated. Need to verify DEATH_CAUSE completeness for cause-of-death analysis.
   If sparse, use all-cause mortality instead of CV death as the death component.
7. **Treatment crossover:** Rate-control patients who later switch to rhythm control
   (or vice versa) create classification challenges. The "12-month classification
   window" approach handles initial strategy, but ITT vs per-protocol analyses
   will differ.

### Feasibility Verdict: FEASIBLE

**Rating rationale:** Large eligible population (~12,000–16,000 newly diagnosed AF ≥80),
both treatment arms are well-populated, and confounders are reasonably available.
The main limitation is inability to adjust for symptom severity and LVEF, which are
strong drivers of rhythm vs rate control selection. The composite outcome
(CV death + stroke + HF hospitalization) is clinically meaningful and each component
is capturable in the CDW (though CV-specific death may need to fall back to
all-cause mortality if DEATH_CAUSE is poorly populated). This is the second-strongest
candidate.

---

## Feasibility Ranking Summary

| Rank | Question | Verdict | Est. N | Key Strength | Key Limitation |
|------|----------|---------|--------|-------------|----------------|
| 1 | **Q3: Apixaban vs Rivaroxaban in AF+CKD** | FEASIBLE | 2,200–3,700 | Active comparator; dual Dx+lab CKD ascertainment; good confounder coverage | Rivaroxaban arm smaller; CKD staging precision |
| 2 | **Q4: Early Rhythm vs Rate Control ≥80** | FEASIBLE | 9,000–15,000 | Large population; well-populated arms; strong clinical relevance | Cannot adjust for LVEF/symptoms; treatment crossover |
| 3 | **Q1: OAC vs No OAC at Low CHA₂DS₂-VASc** | PARTIALLY FEASIBLE | 12,000–16,000 eligible; ~2,000–4,000 treated | Real clinical equipoise; clean causal question | Small treated arm; aspirin/OTC not captured; confounding by indication |
| 4 | **Q2: DOAC Underdosing** | PARTIALLY FEASIBLE | 600–1,500 underdosed | RXCUI encodes dose directly; clean exposure classification | Very small inappropriately-underdosed group; requires weight+creatinine+age for all patients |

---

## Appendix A: Complete Clinical Code Reference

### A.1 ICD-10-CM Diagnosis Codes

#### Atrial Fibrillation (I48.x)
| Code | Description | Billable |
|------|-------------|----------|
| I48.0 | Paroxysmal atrial fibrillation | Yes |
| I48.11 | Longstanding persistent atrial fibrillation | Yes |
| I48.19 | Other persistent atrial fibrillation | Yes |
| I48.20 | Chronic atrial fibrillation, unspecified | Yes |
| I48.21 | Permanent atrial fibrillation | Yes |
| I48.91 | Unspecified atrial fibrillation | Yes |
| I48.92 | Unspecified atrial flutter | Yes |
| I48.1 | Persistent atrial fibrillation (header) | No — use I48.11/I48.19 |
| I48.2 | Chronic atrial fibrillation (header) | No — use I48.20/I48.21 |

**SQL pattern:** `DX LIKE 'I48%' AND DX_TYPE = '10'` captures all. For AF specifically
(excluding flutter), exclude I48.3, I48.4, I48.92.

#### Ischemic Stroke (I63.x)
Use `DX LIKE 'I63%'` — all subcodes (I63.0 through I63.9) are billable and cover
cerebral infarction by mechanism (thrombosis, embolism, occlusion).

#### Systemic Embolism (I74.x)
| Code | Description |
|------|-------------|
| I74.0x | Embolism and thrombosis of abdominal aorta |
| I74.1x | Embolism and thrombosis of other and unspecified parts of aorta |
| I74.2 | Embolism and thrombosis of arteries of upper extremities |
| I74.3 | Embolism and thrombosis of arteries of lower extremities |
| I74.5 | Embolism and thrombosis of iliac artery |
| I74.8 | Embolism and thrombosis of other arteries |
| I74.9 | Embolism and thrombosis of unspecified artery |

#### Heart Failure (I50.x)
| Code Range | Description |
|------------|-------------|
| I50.1 | Left ventricular failure, unspecified |
| I50.2x | Systolic (HFrEF) heart failure |
| I50.3x | Diastolic (HFpEF) heart failure |
| I50.4x | Combined systolic and diastolic |
| I50.8xx | Other heart failure (right HF, biventricular, etc.) |
| I50.9 | Heart failure, unspecified |

#### CKD Stages (N18.x)
| Code | Description |
|------|-------------|
| N18.1 | CKD stage 1 |
| N18.2 | CKD stage 2 |
| N18.30 | CKD stage 3, unspecified |
| N18.31 | CKD stage 3a |
| N18.32 | CKD stage 3b |
| N18.4 | CKD stage 4 |
| N18.5 | CKD stage 5 |
| N18.6 | ESRD |
| N18.9 | CKD, unspecified |

#### Intracranial Hemorrhage
| Code Range | Description |
|------------|-------------|
| I60.x | Subarachnoid hemorrhage |
| I61.x | Nontraumatic intracerebral hemorrhage |
| I62.x | Other nontraumatic intracranial hemorrhage |

#### GI Bleeding
| Code | Description |
|------|-------------|
| K92.0 | Hematemesis |
| K92.1 | Melena |
| K92.2 | Gastrointestinal hemorrhage, unspecified |
| K62.5 | Hemorrhage of anus and rectum |
| K25.0 | Acute gastric ulcer with hemorrhage |
| K25.4 | Chronic gastric ulcer with hemorrhage |
| K26.0 | Acute duodenal ulcer with hemorrhage |
| K26.4 | Chronic duodenal ulcer with hemorrhage |
| K27.0 | Acute peptic ulcer with hemorrhage |
| K27.4 | Chronic peptic ulcer with hemorrhage |
| K29.01 | Acute gastritis with bleeding |

#### Valvular Heart Disease (Exclusion Criteria)
| Code Range | Description |
|------------|-------------|
| I05.0 | Rheumatic mitral stenosis |
| I05.1 | Rheumatic mitral insufficiency |
| I05.2 | Rheumatic mitral stenosis with insufficiency |
| I05.8, I05.9 | Other/unspecified rheumatic mitral valve disease |
| I06.x | Rheumatic aortic valve disease |
| I07.x | Rheumatic tricuspid valve disease |
| I08.x | Multiple valve disease |
| Z95.2 | Presence of prosthetic heart valve |
| Z95.3 | Presence of xenogenic heart valve |
| Z95.4 | Presence of other heart valve replacement |

#### CHA₂DS₂-VASc Components
| Component | ICD-10 Codes |
|-----------|-------------|
| Hypertension | I10, I11.x, I12.x, I13.x, I15.x, I16.x |
| Diabetes | E10.x, E11.x, E13.x |
| Heart failure | I50.x |
| Prior stroke/TIA | I63.x, G45.x |
| Prior TE | I74.x |
| Vascular disease | I21.x (MI), I25.x (chronic IHD), I70.x (atherosclerosis), I71.x (aortic aneurysm), I73.9 (PVD) |

### A.2 RxNorm CUIs (SCD + SBD)

#### Apixaban
| RXCUI | Description |
|-------|-------------|
| 1364435 | apixaban 2.5 MG Oral Tablet (SCD) |
| 1364445 | apixaban 5 MG Oral Tablet (SCD) |
| 1364441 | apixaban 2.5 MG Oral Tablet [Eliquis] (SBD) |
| 1364447 | apixaban 5 MG Oral Tablet [Eliquis] (SBD) |

#### Rivaroxaban
| RXCUI | Description |
|-------|-------------|
| 1114198 | rivaroxaban 10 MG Oral Tablet (SCD) |
| 1232082 | rivaroxaban 15 MG Oral Tablet (SCD) |
| 1232086 | rivaroxaban 20 MG Oral Tablet (SCD) |
| 2059015 | rivaroxaban 2.5 MG Oral Tablet (SCD) |
| 1114202 | rivaroxaban 10 MG Oral Tablet [Xarelto] (SBD) |
| 1232084 | rivaroxaban 15 MG Oral Tablet [Xarelto] (SBD) |
| 1232088 | rivaroxaban 20 MG Oral Tablet [Xarelto] (SBD) |
| 2059017 | rivaroxaban 2.5 MG Oral Tablet [Xarelto] (SBD) |

#### Dabigatran
| RXCUI | Description |
|-------|-------------|
| 1037179 | dabigatran etexilate 75 MG Oral Capsule (SCD) |
| 1723476 | dabigatran etexilate 110 MG Oral Capsule (SCD) |
| 1037045 | dabigatran etexilate 150 MG Oral Capsule (SCD) |
| 1037181 | dabigatran etexilate 75 MG Oral Capsule [Pradaxa] (SBD) |
| 1723478 | dabigatran etexilate 110 MG Oral Capsule [Pradaxa] (SBD) |
| 1037049 | dabigatran etexilate 150 MG Oral Capsule [Pradaxa] (SBD) |

#### Edoxaban
| RXCUI | Description |
|-------|-------------|
| 1599543 | edoxaban 15 MG Oral Tablet (SCD) |
| 1599551 | edoxaban 30 MG Oral Tablet (SCD) |
| 1599555 | edoxaban 60 MG Oral Tablet (SCD) |
| 1599549 | edoxaban 15 MG Oral Tablet [Savaysa] (SBD) |
| 1599553 | edoxaban 30 MG Oral Tablet [Savaysa] (SBD) |
| 1599557 | edoxaban 60 MG Oral Tablet [Savaysa] (SBD) |

#### Warfarin
| RXCUI | Description |
|-------|-------------|
| 855350 | warfarin sodium 0.5 MG Oral Tablet (SCD) |
| 855288 | warfarin sodium 1 MG Oral Tablet (SCD) |
| 855302 | warfarin sodium 2 MG Oral Tablet (SCD) |
| 855312 | warfarin sodium 2.5 MG Oral Tablet (SCD) |
| 855318 | warfarin sodium 3 MG Oral Tablet (SCD) |
| 855324 | warfarin sodium 4 MG Oral Tablet (SCD) |
| 855332 | warfarin sodium 5 MG Oral Tablet (SCD) |
| 855338 | warfarin sodium 6 MG Oral Tablet (SCD) |
| 855344 | warfarin sodium 7.5 MG Oral Tablet (SCD) |
| 855296 | warfarin sodium 10 MG Oral Tablet (SCD) |
| 855290 | warfarin sodium 1 MG [Coumadin] (SBD) |
| 855304 | warfarin sodium 2 MG [Coumadin] (SBD) |
| 855314 | warfarin sodium 2.5 MG [Coumadin] (SBD) |
| 855320 | warfarin sodium 3 MG [Coumadin] (SBD) |
| 855326 | warfarin sodium 4 MG [Coumadin] (SBD) |
| 855334 | warfarin sodium 5 MG [Coumadin] (SBD) |
| 855340 | warfarin sodium 6 MG [Coumadin] (SBD) |
| 855346 | warfarin sodium 7.5 MG [Coumadin] (SBD) |
| 855298 | warfarin sodium 10 MG [Coumadin] (SBD) |
| 855292 | warfarin sodium 1 MG [Jantoven] (SBD) |
| 855306 | warfarin sodium 2 MG [Jantoven] (SBD) |
| 855316 | warfarin sodium 2.5 MG [Jantoven] (SBD) |
| 855322 | warfarin sodium 3 MG [Jantoven] (SBD) |
| 855328 | warfarin sodium 4 MG [Jantoven] (SBD) |
| 855336 | warfarin sodium 5 MG [Jantoven] (SBD) |
| 855342 | warfarin sodium 6 MG [Jantoven] (SBD) |
| 855348 | warfarin sodium 7.5 MG [Jantoven] (SBD) |
| 855300 | warfarin sodium 10 MG [Jantoven] (SBD) |

#### Amiodarone (Oral)
| RXCUI | Description |
|-------|-------------|
| 835956 | amiodarone HCl 100 MG Oral Tablet (SCD) |
| 833528 | amiodarone HCl 200 MG Oral Tablet (SCD) |
| 835960 | amiodarone HCl 300 MG Oral Tablet (SCD) |
| 834348 | amiodarone HCl 400 MG Oral Tablet (SCD) |
| 833530 | amiodarone HCl 200 MG [Cordarone] (SBD) |
| 835958 | amiodarone HCl 100 MG [Pacerone] (SBD) |
| 834346 | amiodarone HCl 200 MG [Pacerone] (SBD) |
| 834350 | amiodarone HCl 400 MG [Pacerone] (SBD) |

#### Flecainide
| RXCUI | Description |
|-------|-------------|
| 886662 | flecainide acetate 50 MG Oral Tablet (SCD) |
| 886666 | flecainide acetate 100 MG Oral Tablet (SCD) |
| 886671 | flecainide acetate 150 MG Oral Tablet (SCD) |

#### Sotalol (Including AF-Labeled Formulations)
| RXCUI | Description |
|-------|-------------|
| 904634 | sotalol HCl 40 MG Oral Tablet (SCD) |
| 1923426 | sotalol HCl 80 MG Oral Tablet (SCD) |
| 1923422 | sotalol HCl 120 MG Oral Tablet (SCD) |
| 1923424 | sotalol HCl 160 MG Oral Tablet (SCD) |
| 904632 | sotalol HCl 200 MG Oral Tablet (SCD) |
| 904589 | sotalol HCl 240 MG Oral Tablet (SCD) |
| 1922765 | AF sotalol HCl 80 MG Oral Tablet (SCD) |
| 1922720 | AF sotalol HCl 120 MG Oral Tablet (SCD) |
| 1922763 | AF sotalol HCl 160 MG Oral Tablet (SCD) |
| 904605 | sotalol HCl 80 MG [Sorine] (SBD) |
| 904571 | sotalol HCl 120 MG [Sorine] (SBD) |
| 904583 | sotalol HCl 160 MG [Sorine] (SBD) |
| 904593 | sotalol HCl 240 MG [Sorine] (SBD) |
| 1923427 | sotalol HCl 80 MG [Betapace] (SBD) |
| 1923423 | sotalol HCl 120 MG [Betapace] (SBD) |
| 1923425 | sotalol HCl 160 MG [Betapace] (SBD) |
| 904591 | sotalol HCl 240 MG [Betapace] (SBD) |
| 1922766 | AF sotalol HCl 80 MG [Betapace] (SBD) |
| 1922721 | AF sotalol HCl 120 MG [Betapace] (SBD) |
| 1922764 | AF sotalol HCl 160 MG [Betapace] (SBD) |

#### Dronedarone
| RXCUI | Description |
|-------|-------------|
| 854856 | dronedarone 400 MG Oral Tablet (SCD) |
| 854859 | dronedarone 400 MG Oral Tablet [Multaq] (SBD) |

#### Dofetilide
| RXCUI | Description |
|-------|-------------|
| 310003 | dofetilide 0.125 MG Oral Capsule (SCD) |
| 310004 | dofetilide 0.25 MG Oral Capsule (SCD) |
| 310005 | dofetilide 0.5 MG Oral Capsule (SCD) |
| 284404 | dofetilide 0.125 MG [Tikosyn] (SBD) |
| 284405 | dofetilide 0.25 MG [Tikosyn] (SBD) |
| 285016 | dofetilide 0.5 MG [Tikosyn] (SBD) |

#### Propafenone
| RXCUI | Description |
|-------|-------------|
| 861424 | propafenone HCl 150 MG Oral Tablet (SCD) |
| 861427 | propafenone HCl 225 MG Oral Tablet (SCD) |
| 861430 | propafenone HCl 300 MG Oral Tablet (SCD) |
| 861156 | 12 HR propafenone HCl 225 MG ER Capsule (SCD) |
| 861164 | 12 HR propafenone HCl 325 MG ER Capsule (SCD) |
| 861171 | 12 HR propafenone HCl 425 MG ER Capsule (SCD) |
| 861159 | 12 HR propafenone HCl 225 MG ER [Rythmol] (SBD) |
| 861167 | 12 HR propafenone HCl 325 MG ER [Rythmol] (SBD) |
| 861173 | 12 HR propafenone HCl 425 MG ER [Rythmol] (SBD) |

#### Metoprolol (Representative Subset)
| RXCUI | Description |
|-------|-------------|
| 866924 | metoprolol tartrate 25 MG (SCD) |
| 866514 | metoprolol tartrate 50 MG (SCD) |
| 866511 | metoprolol tartrate 100 MG (SCD) |
| 866427 | 24 HR metoprolol succinate 25 MG ER (SCD) |
| 866436 | 24 HR metoprolol succinate 50 MG ER (SCD) |
| 866412 | 24 HR metoprolol succinate 100 MG ER (SCD) |
| 866419 | 24 HR metoprolol succinate 200 MG ER (SCD) |
| 866429 | metoprolol succinate 25 MG ER [Toprol] (SBD) |
| 866438 | metoprolol succinate 50 MG ER [Toprol] (SBD) |
| 866414 | metoprolol succinate 100 MG ER [Toprol] (SBD) |
| 866421 | metoprolol succinate 200 MG ER [Toprol] (SBD) |

#### Diltiazem (Representative Subset)
| RXCUI | Description |
|-------|-------------|
| 833217 | diltiazem 30 MG Oral Tablet (SCD) |
| 831103 | diltiazem 60 MG Oral Tablet (SCD) |
| 831102 | diltiazem 90 MG Oral Tablet (SCD) |
| 831054 | diltiazem 120 MG Oral Tablet (SCD) |
| 830861 | 24 HR diltiazem 120 MG ER Capsule (SCD) |
| 830845 | 24 HR diltiazem 180 MG ER Capsule (SCD) |
| 830837 | 24 HR diltiazem 240 MG ER Capsule (SCD) |
| 830801 | 24 HR diltiazem 300 MG ER Capsule (SCD) |
| 830795 | 24 HR diltiazem 360 MG ER Capsule (SCD) |

#### Verapamil (Representative Subset)
| RXCUI | Description |
|-------|-------------|
| 897722 | verapamil 40 MG Oral Tablet (SCD) |
| 897683 | verapamil 80 MG Oral Tablet (SCD) |
| 897666 | verapamil 120 MG Oral Tablet (SCD) |
| 897584 | 24 HR verapamil 100 MG ER Capsule (SCD) |
| 897612 | 24 HR verapamil 120 MG ER Capsule (SCD) |
| 897618 | 24 HR verapamil 180 MG ER Capsule (SCD) |
| 897624 | 24 HR verapamil 240 MG ER Capsule (SCD) |

#### Digoxin
| RXCUI | Description |
|-------|-------------|
| 245273 | digoxin 0.0625 MG Oral Tablet (SCD) |
| 197604 | digoxin 0.125 MG Oral Tablet (SCD) |
| 197606 | digoxin 0.25 MG Oral Tablet (SCD) |
| 393245 | digoxin 0.05 MG/ML Oral Solution (SCD) |
| 309888 | digoxin 0.125 MG [Lanoxin] (SBD) |
| 309889 | digoxin 0.25 MG [Lanoxin] (SBD) |
| 260350 | digoxin 0.125 MG [Digitek] (SBD) |
| 260351 | digoxin 0.25 MG [Digitek] (SBD) |

### A.3 LOINC Codes

| LOINC | Lab Test | CDW Patients | Notes |
|-------|----------|-------------|-------|
| 2160-0 | Serum creatinine | 572,583 | Primary renal function marker |
| 48642-3 | eGFR (CKD-EPI/MDRD, non-Black) | 167,036 | Primary eGFR code |
| 62238-1 | eGFR (CKD-EPI) | TBD | Also query this code |
| 33914-3 | eGFR (MDRD) | 36,067 | Older equation |
| 98979-8 | eGFR (CKD-EPI 2021, race-free) | TBD | Newer race-free equation |
| 6301-6 | INR (platelet poor plasma) | TBD | **Correct INR code — query this** |
| 34714-6 | INR (whole blood, POC) | TBD | Point-of-care INR |
| 38875-1 | INR (PPP or blood) | TBD | Combined specimen code |
| 718-7 | Hemoglobin | 604,651 | CBC hemoglobin |
| 777-3 | Platelets (automated) | 355,519 | Automated count |
| 4548-4 | HbA1c | 332,556 | Diabetes assessment |
| 1742-6 | ALT | 484,206 | Liver function |
| 1920-8 | AST | 432,663 | Liver function |
| 1975-2 | Total bilirubin | 554,750 | Liver function |
| 33762-6 | NT-proBNP | 4,714 | HF biomarker (sparse) |
| 30934-4 | BNP | TBD | Alternative HF biomarker |
| 3016-3 | TSH | TBD | Thyroid function |
| 2823-3 | Potassium | 569,683 | Electrolyte |

**CRITICAL NOTE:** LOINC 30313-1 (listed as "INR" in the data profile) is actually
**arterial hemoglobin**, NOT INR. This explains the <11 patient count. The correct
INR LOINCs are 6301-6, 34714-6, and 38875-1 — these must be queried to determine
actual INR data availability.

### A.4 CPT/HCPCS Procedure Codes

| CPT | Description | Relevance |
|-----|-------------|-----------|
| 92960 | Cardioversion, external | Rhythm control (Q4) |
| 92961 | Cardioversion, internal | Rhythm control (Q4) |
| 93656 | Catheter ablation, pulmonary vein isolation | Rhythm control (Q4) |
| 93657 | Additional catheter ablation (add-on) | Rhythm control (Q4) |
| 93306 | TTE with Doppler, complete | Confounder (echo) |
| 93312 | TEE, complete | Pre-cardioversion TEE |
| 93000 | 12-lead ECG | AF diagnosis confirmation |
| 33340 | Percutaneous LAA closure (Watchman) | Exclusion criterion |

---

## Appendix B: Cross-Cutting Methodological Notes

### B.1 Legacy Encounter Filtering

All queries MUST include:
```sql
INNER JOIN CDW.dbo.ENCOUNTER e ON d.ENCOUNTERID = e.ENCOUNTERID
  AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
  AND e.ADMIT_DATE BETWEEN '2016-01-01' AND GETDATE()
```

The CDW contains 12.8M legacy encounter records (§3a) from the AllScripts→Epic
migration. These are duplicates and must be filtered to prevent double-counting.

### B.2 Date Quality Guards

All date-filtered queries must include explicit date bounds:
```sql
WHERE some_date BETWEEN '2016-01-01' AND GETDATE()
```

The CDW contains junk dates from 1820 to 3019 (§2). Year 1900 has ~40K patients
(EHR default date). Future dates beyond 2027 are errors.

### B.3 Smoking Data Limitation

VITAL.SMOKING is 99.8% 'UN' or 'NI' (§10). This variable is **not usable** as
a confounder in any of these studies. If smoking status is critical for a
particular analysis, consider using diagnosis codes for tobacco use disorder
(F17.x, Z72.0, Z87.891) as a proxy, though this captures only documented
smoking-related conditions, not current smoking status.

### B.4 PAYER_TYPE_PRIMARY

This column is 0% populated (§3e). Insurance status cannot be used as a variable.

### B.5 Death Data

113,105 patients have death records (§11). Death sources: L (local/EHR) = 64,393;
D (death registry/vital statistics) = 38,831; N (NDI/national) = 28,182. The
DEATH table may have multiple records per patient — always use ROW_NUMBER()
PARTITION BY PATID to deduplicate.

### B.6 Database Connection

```r
con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")
```

All tables: `CDW.dbo.TABLE_NAME` (e.g., `CDW.dbo.PRESCRIBING`, `CDW.dbo.DIAGNOSIS`).
