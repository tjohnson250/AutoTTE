# Phase 2: Dataset Feasibility Assessment — Type 2 Diabetes

**Target dataset:** PCORnet CDW (institutional Clinical Data Warehouse, MS SQL Server)
**Assessment date:** 2026-04-15
**Data profile source:** `secure_pcornet_cdw_profile.md` (generated 2026-04-05)
**Database ID:** secure_pcornet_cdw | CDM: PCORnet v6.1 | Engine: MSSQL | Mode: OFFLINE

---

## Executive Summary

This assessment evaluates seven approved research questions against the Secure PCORnet
CDW, all centered on canagliflozin cardiovascular outcomes in type 2 diabetes. The CDW
contains **242,522 patients with type 2 diabetes** (ICD-10 E11.x) and robust laboratory,
vital sign, and diagnosis data. However, the assessment reveals a **critical feasibility
barrier**: the PRESCRIBING table contains only **142 patients with canagliflozin
prescriptions** (380 total prescription records). This is far below the minimum needed for
any time-to-event analysis of MACE outcomes, which are rare events requiring thousands of
patients per arm.

For context, the CANVAS trial (which established canagliflozin's CV benefit) enrolled
10,142 patients with a median follow-up of 3.6 years, yielding a MACE rate of ~26.9 per
1,000 patient-years. With 142 canagliflozin patients in this single-institution CDW, we
would expect fewer than ~10 total MACE events across all follow-up time — far too few for
any causal inference analysis.

**Feasibility verdict by question:**

| # | Question | Verdict | Limiting Factor |
|---|----------|---------|-----------------|
| 1 | Canagliflozin vs DPP-4i for 3P-MACE | **NOT FEASIBLE** | Canagliflozin N = 142 |
| 2 | Canagliflozin vs 2nd-Gen SU for 3P-MACE | **NOT FEASIBLE** | Canagliflozin N = 142 |
| 3 | Individual MACE Components | **NOT FEASIBLE** | Even less power than composite |
| 4 | Heart Failure Hospitalization | **NOT FEASIBLE** | Canagliflozin N = 142 |
| 5 | Safety Profile (amputation, DKA, genital infections) | **MARGINALLY FEASIBLE** | Only for genital infections (highest incidence) |
| 6 | CKD Subgroup | **NOT FEASIBLE** | Subgroup of already-tiny canagliflozin arm |
| 7 | ASCVD Subgroup | **NOT FEASIBLE** | Subgroup of already-tiny canagliflozin arm |

**Recommendation:** The study as described in the study description is not feasible in this
CDW. We recommend one of the following alternatives (detailed in Section 10):

1. **Expand exposure to SGLT2 inhibitor class** (canagliflozin + empagliflozin +
   dapagliflozin = ~9,833 patients) — changes the question from canagliflozin-specific
   to SGLT2i-class-level, but is feasible
2. **Use a multi-site PCORnet query** — the CDW network supports distributed queries
   across partner institutions, which would increase canagliflozin N by 10-50x
3. **Pivot to empagliflozin as the index drug** (6,526 patients) — still below ideal
   but more realistic for a single institution

---

## 1. Database Overview

### 1.1 Key Table Statistics

| Table | Distinct Patients | Rows | Date Range | Key Column |
|-------|-------------------|------|------------|------------|
| DEMOGRAPHIC | 10,091,847 | 10,091,847 | — | PATID (PK) |
| ENCOUNTER | 5,315,029 | 211,822,838 | 1820–3019* | ADMIT_DATE |
| DIAGNOSIS | 4,394,248 | 152,125,158 | 1899–2034* | DX, DX_TYPE |
| PROCEDURES | 4,475,979 | 158,790,455 | 1900–2033* | PX, PX_TYPE |
| PRESCRIBING | 1,293,303 | 16,514,110 | 2004-04 – 2026-04 | RXNORM_CUI |
| DISPENSING | 1,271,915 | 64,151,827 | 2006-12 – 2026-04 | NDC |
| LAB_RESULT_CM | 1,466,580 | 182,979,640 | 1900–2026* | LAB_LOINC |
| VITAL | 2,549,495 | 39,508,053 | 1754–2026* | MEASURE_DATE |
| ENROLLMENT | 5,314,626 | 5,314,626 | 2000-01 – 2026-04 | ENR_START_DATE |
| DEATH | 113,105 | 131,406 | 1926–2026 | DEATH_DATE |
| DEATH_CAUSE | — | — | — | DEATH_CAUSE, DEATH_CAUSE_CODE |
| MED_ADMIN | 156,993 | 4,869,369 | 2021-04 – 2026-04 | MEDADMIN_CODE |
| CONDITION | 1,480,087 | 26,830,777 | 1842–2026 | CONDITION |

*Contains junk dates; realistic clinical data begins ~2005; full volume ~2010+.

### 1.2 EHR Migration Context

- **AllScripts era:** Primary EHR through ~2019-2020
- **Epic go-live:** ~2019-2020; Epic became primary feed
- **Legacy encounters:** 12.8M duplicate records flagged as `RAW_ENC_TYPE = 'Legacy Encounter'`
  — MUST be filtered in all queries
- **ICD-10 transition:** October 1, 2015; ICD-10 dominant from 2016 onward

### 1.3 Key Condition Prevalence (from data profile §14)

| Condition | ICD-10 Pattern | Patients |
|-----------|---------------|----------|
| Type 2 diabetes | E11.x | 242,522 |
| Hypertension | I10-I16 | 487,523 |
| Heart failure | I50.x | 105,812 |
| Ischemic stroke | I63.x | 65,747 |
| Atrial fibrillation | I48.x | 86,308 |
| CKD stage 3 | N18.3x | 38,009 |
| CKD stage 4 | N18.4 | 13,766 |
| CKD stage 5 | N18.5 | 7,008 |
| ESRD / dialysis | N18.6, Z99.2 | 31,705 |
| Obesity | E66.x | 242,404 |
| COPD | J44.x | 38,756 |
| VTE / PE | I26.x, I82.x | 48,396 |
| Major bleeding | various | 10,580 |

### 1.4 Key Medication Counts (from data profile §15)

| Drug | Patients | Prescriptions | Class |
|------|----------|---------------|-------|
| **Canagliflozin** | **142** | **380** | **SGLT2i (study drug)** |
| Empagliflozin | 6,526 | 20,145 | SGLT2i |
| Dapagliflozin | 3,165 | 9,585 | SGLT2i |
| Metformin | 84,280 | 241,943 | Biguanide |
| Semaglutide | 7,053 | 17,373 | GLP-1 RA |

**NOTE:** DPP-4 inhibitors (sitagliptin, linagliptin, saxagliptin, alogliptin) and
2nd-generation sulfonylureas (glipizide, glimepiride, glyburide) are NOT included in the
data profile's medication search. Patient counts for these comparator classes are unknown
from the profile and must be estimated (see Section 5).

### 1.5 Key Lab Coverage (from data profile §16)

| LOINC | Lab Test | Patients | Results |
|-------|----------|----------|---------|
| 4548-4 | HbA1c | 332,556 | 1,164,877 |
| 2160-0 | Serum creatinine | 572,583 | 3,007,734 |
| 48642-3 | eGFR (MDRD) | 167,036 | 837,059 |
| 33914-3 | eGFR (MDRD, legacy) | 36,067 | 98,391 |
| 2093-3 | Total cholesterol | 337,620 | 1,158,138 |
| 2571-8 | Triglycerides | 337,485 | 1,157,751 |
| 2085-9 | HDL cholesterol | 332,287 | 960,780 |
| 13457-7 | LDL cholesterol (calc) | 242,238 | 744,557 |
| 718-7 | Hemoglobin | 604,651 | 2,890,124 |
| 2823-3 | Potassium | 569,683 | 3,032,948 |
| 1742-6 | ALT | 484,206 | 1,952,555 |
| 1920-8 | AST | 432,663 | 1,684,334 |
| 33762-6 | NT-proBNP | 4,714 | 9,286 |

### 1.6 Prescribing Table Completeness (from data profile §12)

| Column | % Non-NULL | Implication |
|--------|-----------|-------------|
| RXNORM_CUI | 98.6% | Good — primary drug identifier is well-populated |
| RX_ORDER_DATE | 100% | Good — time-zero anchor available |
| RX_START_DATE | 100% | Good — alternative date |
| RX_END_DATE | 47.6% | Poor — treatment duration hard to determine |
| RX_DAYS_SUPPLY | 42.8% | Poor — adherence/persistence analysis limited |
| RX_DOSE_ORDERED | 87.5% | Moderate — but RXCUI encodes dose directly |
| RX_QUANTITY | 73.3% | Moderate |

---

## 2. Exposure Mapping

### 2.1 Canagliflozin (Intervention)

**Primary table:** CDW.dbo.PRESCRIBING (RXNORM_CUI)
**Secondary table:** CDW.dbo.DISPENSING (NDC — requires NDC-to-RxNorm crosswalk)
**Tertiary table:** CDW.dbo.EXTERNAL_MEDS (RXNORM_CUI — external medication reconciliation)

#### RxNorm CUIs — Single-Ingredient Canagliflozin (SCD + SBD)

| RxCUI | Description | Type |
|-------|-------------|------|
| 1373463 | canagliflozin 100 MG Oral Tablet | SCD |
| 1373471 | canagliflozin 300 MG Oral Tablet | SCD |
| 1373469 | canagliflozin 100 MG Oral Tablet [Invokana] | SBD |
| 1373473 | canagliflozin 300 MG Oral Tablet [Invokana] | SBD |

#### Combination Products (Canagliflozin + Metformin — Invokamet)

Patients on Invokamet (canagliflozin/metformin) should be captured as canagliflozin
users. Including these may modestly increase the canagliflozin arm.

| RxCUI | Description | Type |
|-------|-------------|------|
| 1545150 | canagliflozin 50 MG / metformin 500 MG | SCD |
| 1545157 | canagliflozin 50 MG / metformin 1000 MG | SCD |
| 1545161 | canagliflozin 150 MG / metformin 500 MG | SCD |
| 1545164 | canagliflozin 150 MG / metformin 1000 MG | SCD |
| 1545156 | canagliflozin 50 MG / metformin 500 MG [Invokamet] | SBD |
| 1545159 | canagliflozin 50 MG / metformin 1000 MG [Invokamet] | SBD |
| 1545163 | canagliflozin 150 MG / metformin 500 MG [Invokamet] | SBD |
| 1545166 | canagliflozin 150 MG / metformin 1000 MG [Invokamet] | SBD |
| 1810997 | canagliflozin 50 MG / metformin ER 500 MG [Invokamet XR] | SBD |
| 1811003 | canagliflozin 50 MG / metformin ER 1000 MG [Invokamet XR] | SBD |
| 1811007 | canagliflozin 150 MG / metformin ER 500 MG [Invokamet XR] | SBD |
| 1811011 | canagliflozin 150 MG / metformin ER 1000 MG [Invokamet XR] | SBD |

**CDW patient count:** 142 patients (from RAW_RX_MED_NAME search; may increase modestly
if combination products and EXTERNAL_MEDS are included).

```sql
-- Canagliflozin exposure identification
SELECT DISTINCT p.PATID, p.RX_ORDER_DATE, p.RXNORM_CUI
FROM CDW.dbo.PRESCRIBING p
WHERE p.RXNORM_CUI IN (
  -- Single-ingredient canagliflozin
  '1373463','1373471','1373469','1373473',
  -- Canagliflozin/metformin combinations (Invokamet, Invokamet XR)
  '1545150','1545157','1545161','1545164',
  '1545156','1545159','1545163','1545166',
  '1810997','1811003','1811007','1811011'
)
AND p.RX_ORDER_DATE BETWEEN '2013-03-29' AND GETDATE()  -- FDA approval date
```

### 2.2 DPP-4 Inhibitors (Primary Comparator)

#### Sitagliptin (Januvia)

| RxCUI | Description | Type |
|-------|-------------|------|
| 665033 | sitagliptin 100 MG Oral Tablet | SCD |
| 665038 | sitagliptin 25 MG Oral Tablet | SCD |
| 665042 | sitagliptin 50 MG Oral Tablet | SCD |
| 2709603 | sitagliptin phosphate 100 MG Oral Tablet | SCD |
| 2709608 | sitagliptin phosphate 50 MG Oral Tablet | SCD |
| 2709612 | sitagliptin phosphate 25 MG Oral Tablet | SCD |
| 665036 | sitagliptin phosphate 100 MG Oral Tablet [Januvia] | SBD |
| 665040 | sitagliptin phosphate 25 MG Oral Tablet [Januvia] | SBD |
| 665044 | sitagliptin phosphate 50 MG Oral Tablet [Januvia] | SBD |
| 2670447 | sitagliptin 100 MG Oral Tablet [Zituvio] | SBD |
| 2670449 | sitagliptin 25 MG Oral Tablet [Zituvio] | SBD |
| 2670451 | sitagliptin 50 MG Oral Tablet [Zituvio] | SBD |

#### Linagliptin (Tradjenta)

| RxCUI | Description | Type |
|-------|-------------|------|
| 1100702 | linagliptin 5 MG Oral Tablet | SCD |
| 1100706 | linagliptin 5 MG Oral Tablet [Tradjenta] | SBD |

#### Saxagliptin (Onglyza)

| RxCUI | Description | Type |
|-------|-------------|------|
| 858036 | saxagliptin 5 MG Oral Tablet | SCD |
| 858042 | saxagliptin 2.5 MG Oral Tablet | SCD |
| 858040 | saxagliptin 5 MG Oral Tablet [Onglyza] | SBD |
| 858044 | saxagliptin 2.5 MG Oral Tablet [Onglyza] | SBD |

#### Alogliptin (Nesina)

| RxCUI | Description | Type |
|-------|-------------|------|
| 1368006 | alogliptin 25 MG Oral Tablet | SCD |
| 1368018 | alogliptin 6.25 MG Oral Tablet | SCD |
| 1368034 | alogliptin 12.5 MG Oral Tablet | SCD |
| 1368012 | alogliptin 25 MG Oral Tablet [Nesina] | SBD |
| 1368020 | alogliptin 6.25 MG Oral Tablet [Nesina] | SBD |
| 1368036 | alogliptin 12.5 MG Oral Tablet [Nesina] | SBD |

**CDW patient count:** Unknown from profile. Estimated 8,000–20,000 total DPP-4i patients
based on: (a) 242,522 T2D patients, (b) DPP-4i market share ~8–15% of second-line T2D
therapy, (c) the CDW's PRESCRIBING table covers 1.29M patients total. Sitagliptin likely
accounts for ~60% of DPP-4i use.

```sql
-- DPP-4 inhibitor exposure identification (single-ingredient only)
SELECT DISTINCT p.PATID, p.RX_ORDER_DATE,
  CASE
    WHEN p.RXNORM_CUI IN ('665033','665038','665042','2709603','2709608','2709612',
                           '665036','665040','665044','2670447','2670449','2670451')
         THEN 'sitagliptin'
    WHEN p.RXNORM_CUI IN ('1100702','1100706') THEN 'linagliptin'
    WHEN p.RXNORM_CUI IN ('858036','858042','858040','858044') THEN 'saxagliptin'
    WHEN p.RXNORM_CUI IN ('1368006','1368018','1368034','1368012','1368020','1368036')
         THEN 'alogliptin'
  END AS dpp4i_drug
FROM CDW.dbo.PRESCRIBING p
WHERE p.RXNORM_CUI IN (
  -- Sitagliptin (SCD + SBD)
  '665033','665038','665042','2709603','2709608','2709612',
  '665036','665040','665044','2670447','2670449','2670451',
  -- Linagliptin (SCD + SBD)
  '1100702','1100706',
  -- Saxagliptin (SCD + SBD)
  '858036','858042','858040','858044',
  -- Alogliptin (SCD + SBD)
  '1368006','1368018','1368034','1368012','1368020','1368036'
)
AND p.RX_ORDER_DATE BETWEEN '2006-10-01' AND GETDATE()
```

### 2.3 Second-Generation Sulfonylureas (Secondary Comparator)

#### Glipizide (Glucotrol)

| RxCUI | Description | Type |
|-------|-------------|------|
| 310488 | glipizide 10 MG Oral Tablet | SCD |
| 310490 | glipizide 5 MG Oral Tablet | SCD |
| 379804 | glipizide 2.5 MG Oral Tablet | SCD |
| 2737151 | glipizide 15 MG Oral Tablet | SCD |
| 315107 | 24 HR glipizide 10 MG ER Oral Tablet | SCD |
| 314006 | 24 HR glipizide 5 MG ER Oral Tablet | SCD |
| 310489 | 24 HR glipizide 2.5 MG ER Oral Tablet | SCD |
| 205828 | glipizide 5 MG Oral Tablet [Glucotrol] | SBD |
| 865568 | 24 HR glipizide 10 MG ER [Glucotrol] | SBD |
| 865571 | 24 HR glipizide 2.5 MG ER [Glucotrol] | SBD |
| 865573 | 24 HR glipizide 5 MG ER [Glucotrol] | SBD |

#### Glimepiride (Amaryl)

| RxCUI | Description | Type |
|-------|-------------|------|
| 199245 | glimepiride 1 MG Oral Tablet | SCD |
| 199246 | glimepiride 2 MG Oral Tablet | SCD |
| 199247 | glimepiride 4 MG Oral Tablet | SCD |
| 153842 | glimepiride 3 MG Oral Tablet | SCD |
| 1361493 | glimepiride 6 MG Oral Tablet | SCD |
| 1361495 | glimepiride 8 MG Oral Tablet | SCD |
| 153843 | glimepiride 1 MG [Amaryl] | SBD |
| 153591 | glimepiride 2 MG [Amaryl] | SBD |
| 153845 | glimepiride 4 MG [Amaryl] | SBD |

#### Glyburide (Glynase, formerly Diabeta/Micronase)

| RxCUI | Description | Type |
|-------|-------------|------|
| 197737 | glyburide 1.25 MG Oral Tablet | SCD |
| 310534 | glyburide 2.5 MG Oral Tablet | SCD |
| 310537 | glyburide 5 MG Oral Tablet | SCD |
| 314000 | glyburide 1.5 MG Oral Tablet (micronized) | SCD |
| 310536 | glyburide 3 MG Oral Tablet (micronized) | SCD |
| 310539 | glyburide 6 MG Oral Tablet (micronized) | SCD |
| 252960 | glyburide 4.5 MG Oral Tablet | SCD |
| 430102 | glyburide 3.5 MG Oral Tablet | SCD |
| 430103 | glyburide 1.75 MG Oral Tablet | SCD |
| 881407 | glyburide 1.5 MG [Glynase] | SBD |
| 881409 | glyburide 3 MG [Glynase] | SBD |
| 881411 | glyburide 6 MG [Glynase] | SBD |

**CDW patient count:** Unknown from profile. Estimated 15,000–35,000 total SU patients.
Sulfonylureas are among the most commonly prescribed T2D drugs historically, though use
has declined in the SGLT2i/GLP-1 RA era. Glipizide likely dominates in this CDW due to
formulary preferences.

### 2.4 New-User Identification

The new-user (incident user) design requires identifying the **first prescription** of
the study drug with no prior use during a washout period.

**Approach:**
1. For each patient with a canagliflozin/comparator RXCUI, find the earliest
   RX_ORDER_DATE (or RX_START_DATE)
2. Verify no prior prescription of the same drug class during a 180-day washout
3. Require ≥180 days continuous enrollment before the first prescription (cohort entry)

**Tables for new-user identification:**
- CDW.dbo.PRESCRIBING: RX_ORDER_DATE, RXNORM_CUI
- CDW.dbo.ENROLLMENT: ENR_START_DATE, ENR_END_DATE

**Continuous enrollment check:**
```sql
-- Verify 180-day continuous enrollment before cohort entry
SELECT p.PATID, p.RX_ORDER_DATE AS index_date
FROM CDW.dbo.PRESCRIBING p
INNER JOIN CDW.dbo.ENROLLMENT e ON p.PATID = e.PATID
  AND e.ENR_START_DATE <= DATEADD(day, -180, p.RX_ORDER_DATE)
  AND (e.ENR_END_DATE >= p.RX_ORDER_DATE OR e.ENR_END_DATE IS NULL)
WHERE p.RXNORM_CUI IN (/* canagliflozin codes */)
  AND p.RX_ORDER_DATE BETWEEN '2013-03-29' AND GETDATE()
  -- No prior canagliflozin in washout
  AND NOT EXISTS (
    SELECT 1 FROM CDW.dbo.PRESCRIBING p2
    WHERE p2.PATID = p.PATID
    AND p2.RXNORM_CUI IN (/* canagliflozin codes */)
    AND p2.RX_ORDER_DATE < p.RX_ORDER_DATE
    AND p2.RX_ORDER_DATE >= DATEADD(day, -180, p.RX_ORDER_DATE)
  )
```

---

## 3. Outcome Mapping

### 3.1 Three-Point MACE (Primary Outcome)

3P-MACE is a composite of: (1) cardiovascular death, (2) nonfatal myocardial infarction,
(3) nonfatal stroke. The first occurrence of any component after time zero defines the
event.

#### 3.1a. Myocardial Infarction

**Table:** CDW.dbo.DIAGNOSIS
**Requirement:** DX_TYPE = '10' AND encounter type IP or ED (ENC_TYPE IN ('IP','EI','ED'))

| Code Pattern | Description | Notes |
|-------------|-------------|-------|
| I21.0x | STEMI of anterior wall | I21.01, I21.02, I21.09 |
| I21.1x | STEMI of inferior wall | I21.11, I21.19 |
| I21.2x | STEMI of other sites | I21.21, I21.29 |
| I21.3 | STEMI unspecified site | Billable |
| I21.4 | NSTEMI | Billable |
| I21.9 | Acute MI, unspecified | Billable |
| I21.A1 | MI type 2 (demand ischemia) | **Consider excluding** — different etiology |
| I22.x | Subsequent MI (within 28 days) | I22.0, I22.1, I22.2, I22.8, I22.9 |

**SQL pattern:**
```sql
-- Nonfatal MI
WHERE d.DX LIKE 'I21%' AND d.DX_TYPE = '10'
  AND d.DX NOT IN ('I21.A1','I21.A9','I21.B')  -- Exclude type 2/other MI
  AND e.ENC_TYPE IN ('IP','EI','ED')
  AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
```

**Note:** Type 2 MI (I21.A1, demand ischemia) should be excluded from the primary MACE
definition for consistency with CANVAS trial methodology, which counted only spontaneous
(Type 1) MI. Include Type 2 MI in sensitivity analysis.

#### 3.1b. Ischemic Stroke (Nonfatal)

**Table:** CDW.dbo.DIAGNOSIS
**Requirement:** DX_TYPE = '10' AND IP/ED encounter

| Code Pattern | Description |
|-------------|-------------|
| I63.0x | Cerebral infarction due to thrombosis of precerebral arteries |
| I63.1x | Cerebral infarction due to embolism of precerebral arteries |
| I63.2x | Cerebral infarction due to unspecified occlusion of precerebral arteries |
| I63.3x | Cerebral infarction due to thrombosis of cerebral arteries |
| I63.4x | Cerebral infarction due to embolism of cerebral arteries |
| I63.5x | Cerebral infarction due to unspecified occlusion of cerebral arteries |
| I63.6 | Cerebral infarction due to cerebral venous thrombosis |
| I63.8x | Other cerebral infarction |
| I63.9 | Cerebral infarction, unspecified |

**SQL pattern:**
```sql
-- Nonfatal ischemic stroke
WHERE d.DX LIKE 'I63%' AND d.DX_TYPE = '10'
  AND e.ENC_TYPE IN ('IP','EI','ED')
  AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
```

**Exclude from MACE:** Hemorrhagic stroke (I60.x subarachnoid, I61.x intracerebral) is
not part of the 3P-MACE definition used in CANVAS, but should be tracked as a safety
outcome.

#### 3.1c. Cardiovascular Death

**Tables:** CDW.dbo.DEATH + CDW.dbo.DEATH_CAUSE

The CDW has 113,105 patients with death records from three sources:
- L (local/EHR): 64,393 patients
- D (death registry/vital statistics): 38,831 patients
- N (NDI/national): 28,182 patients

**CV death definition:** Death with a cardiovascular cause code in DEATH_CAUSE:

| Cause Code Pattern | Description |
|-------------------|-------------|
| I20–I25 | Ischemic heart diseases |
| I46 | Cardiac arrest |
| I50 | Heart failure |
| I60–I69 | Cerebrovascular diseases |
| I71 | Aortic aneurysm/dissection |

```sql
-- CV death
LEFT JOIN (
  SELECT d.PATID, d.DEATH_DATE,
    ROW_NUMBER() OVER (PARTITION BY d.PATID ORDER BY d.DEATH_DATE) AS rn
  FROM CDW.dbo.DEATH d
) death ON t.PATID = death.PATID AND death.rn = 1
LEFT JOIN CDW.dbo.DEATH_CAUSE dc ON death.PATID = dc.PATID
  AND dc.DEATH_CAUSE_CODE = '10'  -- ICD-10 cause
  AND (dc.DEATH_CAUSE LIKE 'I2[0-5]%' OR dc.DEATH_CAUSE LIKE 'I46%'
       OR dc.DEATH_CAUSE LIKE 'I50%' OR dc.DEATH_CAUSE LIKE 'I6%'
       OR dc.DEATH_CAUSE LIKE 'I71%')
```

**Limitation:** DEATH_CAUSE completeness is unknown. If sparsely populated, the protocol
should fall back to all-cause mortality as the death component, with CV death as a
sensitivity analysis.

### 3.2 Heart Failure Hospitalization (Secondary Outcome)

**Tables:** CDW.dbo.DIAGNOSIS + CDW.dbo.ENCOUNTER
**Requirement:** I50.x as primary or secondary discharge diagnosis on an IP/EI encounter

| Code | Description | HF Subtype |
|------|-------------|------------|
| I50.1 | Left ventricular failure, unspecified | Unspecified |
| I50.20–I50.23 | Systolic HF (acute, chronic, acute on chronic) | HFrEF |
| I50.30–I50.33 | Diastolic HF (acute, chronic, acute on chronic) | HFpEF |
| I50.40–I50.43 | Combined systolic + diastolic | Combined |
| I50.810–I50.814 | Right heart failure | Right HF |
| I50.82 | Biventricular heart failure | Biventricular |
| I50.84 | End-stage heart failure | End-stage |
| I50.89 | Other heart failure | Other |
| I50.9 | Heart failure, unspecified | Unspecified |

```sql
-- HHF: heart failure diagnosis during inpatient encounter
WHERE d.DX LIKE 'I50%' AND d.DX_TYPE = '10'
  AND e.ENC_TYPE IN ('IP','EI')
  AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
  AND e.ADMIT_DATE BETWEEN '2016-01-01' AND GETDATE()
```

### 3.3 Safety Outcomes

#### Lower-Extremity Amputation

**Tables:** CDW.dbo.PROCEDURES
**Code types:** PX_TYPE = 'CH' (CPT/HCPCS) and PX_TYPE = '10' (ICD-10-PCS)

| Code | Description | Level |
|------|-------------|-------|
| **CPT (PX_TYPE = 'CH'):** | | |
| 27590–27598 | Above-knee amputation / knee disarticulation | Major |
| 27880–27889 | Below-knee amputation | Major |
| 28800, 28805 | Midtarsal / transmetatarsal amputation | Minor |
| 28810 | Ray amputation (metatarsal + toe) | Minor |
| 28820 | Toe amputation, metatarsophalangeal joint | Minor |
| 28825 | Toe amputation, interphalangeal joint | Minor |

**CANVAS context:** The CANVAS program reported significantly increased amputation risk
with canagliflozin (HR 1.97; 6.3 vs 3.4 per 1000 PY), primarily toe and metatarsal
amputations. This was a key safety signal that led to an FDA boxed warning (later removed).

#### Diabetic Ketoacidosis (DKA)

| Code | Description | Billable |
|------|-------------|----------|
| E11.10 | T2D with ketoacidosis without coma | Yes |
| E11.11 | T2D with ketoacidosis with coma | Yes |
| E13.10 | Other DM with ketoacidosis without coma | Yes |
| E13.11 | Other DM with ketoacidosis with coma | Yes |

**Note:** Euglycemic DKA is a recognized SGLT2i class effect. These ICD-10 codes
capture DKA regardless of glucose level.

#### Genital Mycotic Infections

| Code | Description | Billable |
|------|-------------|----------|
| B37.31 | Acute candidiasis of vulva and vagina | Yes |
| B37.32 | Chronic candidiasis of vulva and vagina | Yes |
| B37.42 | Candidal balanitis | Yes |
| B37.49 | Other urogenital candidiasis | Yes |
| N76.0 | Acute vaginitis | Yes |
| N77.1 | Vaginitis in diseases classified elsewhere | Yes |
| N48.1 | Balanoposthitis | Yes |

**Note:** B37.3 (parent code) is non-billable; use B37.31/B37.32 instead.

**SGLT2i context:** Genital infections are the most common adverse effect (~10–12% in
women, ~4–5% in men) due to glucosuria. This is the safety outcome most likely to have
adequate events even with small sample sizes.

#### Acute Kidney Injury

| Code | Description | Billable |
|------|-------------|----------|
| N17.0 | AKI with tubular necrosis | Yes |
| N17.1 | AKI with acute cortical necrosis | Yes |
| N17.2 | AKI with medullary necrosis | Yes |
| N17.8 | Other acute kidney failure | Yes |
| N17.9 | AKI, unspecified | Yes |

---

## 4. Confounder Mapping

### 4.1 Available Confounders

| Confounder | CDW Table | Column(s) | Coverage | Notes |
|------------|-----------|-----------|----------|-------|
| **Demographics** | | | | |
| Age | DEMOGRAPHIC | BIRTH_DATE | 100% | DATEDIFF(year, BIRTH_DATE, index_date) |
| Sex | DEMOGRAPHIC | SEX | 100% | F=5.38M, M=4.64M |
| Race | DEMOGRAPHIC | RACE | 100%* | PCORnet coded; OT=2.5M, UN/NI=2.3M |
| Hispanic ethnicity | DEMOGRAPHIC | HISPANIC | 100%* | OT=1.86M, NI/UN=1.57M |
| **Vitals** | | | | |
| BMI | VITAL | ORIGINAL_BMI | 2.36M pts | 15.5M measurements |
| Systolic/Diastolic BP | VITAL | SYSTOLIC, DIASTOLIC | 1.22M pts | 10.1M measurements |
| Height / Weight | VITAL | HT, WT | 894K / 914K pts | |
| Smoking | VITAL | SMOKING | **UNUSABLE** | 99.8% 'UN' or 'NI' |
| **Labs** | | | | |
| HbA1c | LAB_RESULT_CM | LOINC 4548-4 | 332K pts | Key T2D confounder |
| Serum creatinine | LAB_RESULT_CM | LOINC 2160-0 | 572K pts | eGFR derivation |
| eGFR | LAB_RESULT_CM | LOINC 48642-3 | 167K pts | CKD staging |
| Total cholesterol | LAB_RESULT_CM | LOINC 2093-3 | 337K pts | Lipid panel |
| Triglycerides | LAB_RESULT_CM | LOINC 2571-8 | 337K pts | Lipid panel |
| HDL | LAB_RESULT_CM | LOINC 2085-9 | 332K pts | Lipid panel |
| LDL (calculated) | LAB_RESULT_CM | LOINC 13457-7 | 242K pts | Lipid panel |
| Hemoglobin | LAB_RESULT_CM | LOINC 718-7 | 604K pts | Anemia assessment |
| Potassium | LAB_RESULT_CM | LOINC 2823-3 | 569K pts | Electrolytes |
| ALT | LAB_RESULT_CM | LOINC 1742-6 | 484K pts | Hepatic function |
| AST | LAB_RESULT_CM | LOINC 1920-8 | 432K pts | Hepatic function |
| NT-proBNP | LAB_RESULT_CM | LOINC 33762-6 | **4,714 pts** | Too sparse for routine use |
| **Comorbidities** (via DIAGNOSIS) | | | | |
| Hypertension | DIAGNOSIS | I10–I16 | 487,523 pts | |
| Heart failure | DIAGNOSIS | I50.x | 105,812 pts | |
| Atrial fibrillation | DIAGNOSIS | I48.x | 86,308 pts | |
| CKD (any stage) | DIAGNOSIS | N18.x | ~90K pts (stages 3-6) | |
| Prior MI | DIAGNOSIS | I21.x, I25.2 | Available | |
| Prior stroke | DIAGNOSIS | I63.x | 65,747 pts | |
| COPD | DIAGNOSIS | J44.x | 38,756 pts | |
| Obesity | DIAGNOSIS | E66.x | 242,404 pts | |
| Dyslipidemia | DIAGNOSIS | E78.x | Available | E78.5 = 246,519 pts |
| PAD / PVD | DIAGNOSIS | I70.x, I73.9 | Available | |
| VTE / PE | DIAGNOSIS | I26.x, I82.x | 48,396 pts | |
| **Concomitant Medications** (via PRESCRIBING) | | | | |
| Metformin | PRESCRIBING | RXNORM_CUI | 84,280 pts | Background therapy |
| Insulin | PRESCRIBING | RXNORM_CUI | Available | Via RAW_RX_MED_NAME search |
| Statins | PRESCRIBING | RXNORM_CUI | Available | |
| ACEi/ARBs | PRESCRIBING | RXNORM_CUI | Available | CV protection |
| Beta-blockers | PRESCRIBING | RXNORM_CUI | Available | Metoprolol=69,216 pts |
| Antiplatelets | PRESCRIBING | RXNORM_CUI | Partial | OTC aspirin not captured |

### 4.2 Missing or Unusable Confounders

| Confounder | Status | Impact |
|------------|--------|--------|
| **Smoking** | UNUSABLE (99.8% unknown) | Cannot adjust for smoking. Use F17.x/Z72.0/Z87.891 as proxy for documented tobacco use disorder |
| **LVEF / Echocardiography** | NOT AVAILABLE as structured data | Cannot distinguish HFrEF vs HFpEF precisely; rely on ICD subtyping (I50.2x vs I50.3x) |
| **Insurance / payer type** | 0% populated (PAYER_TYPE_PRIMARY) | Cannot adjust for socioeconomic/access |
| **OTC aspirin** | NOT CAPTURED in PRESCRIBING | Underestimates antiplatelet use |
| **Duration of diabetes** | DERIVABLE but imprecise | Can estimate from first E11.x code, but true onset precedes diagnosis coding |
| **Albuminuria / UACR** | NOT in top LOINCs | Limited CKD characterization beyond eGFR staging |
| **NT-proBNP** | SPARSE (4,714 patients) | Cannot use as routine confounder |

---

## 5. Sample Size Estimates

### 5.1 Canagliflozin Arm (Critical Limitation)

Starting population: **142 patients** with any canagliflozin prescription

Expected attrition through eligibility criteria:

| Step | Estimated N | Rationale |
|------|-------------|-----------|
| Any canagliflozin Rx | 142 | Profile §15 |
| + Including Invokamet combinations | ~150–170 | ~10–20% additional from combos |
| + Including EXTERNAL_MEDS table | ~160–200 | Modest additional from med reconciliation |
| Restrict to patients with T2D (E11.x) | ~140–180 | Most canagliflozin is for T2D |
| New users (no prior canagliflozin) | ~120–160 | ~10–15% are refills/renewals |
| 180-day continuous enrollment | ~90–130 | ~20–30% attrition for enrollment gaps |
| Post-ICD-10 (≥2016) | ~80–120 | Canagliflozin FDA approved 2013; most use is post-2016 |
| **Final analytic cohort (canagliflozin arm)** | **~80–120** | |

### 5.2 DPP-4 Inhibitor Arm (Estimated)

| Step | Estimated N | Rationale |
|------|-------------|-----------|
| Any DPP-4i Rx (all 4 drugs) | ~8,000–20,000 | Based on T2D prevalence and DPP-4i market share |
| Restrict to T2D | ~7,000–18,000 | DPP-4i is almost exclusively for T2D |
| New users | ~5,000–14,000 | |
| 180-day continuous enrollment | ~3,500–10,000 | |
| Post-ICD-10 (≥2016) | ~3,000–9,000 | |

### 5.3 Sulfonylurea Arm (Estimated)

| Step | Estimated N | Rationale |
|------|-------------|-----------|
| Any 2nd-gen SU Rx (3 drugs) | ~15,000–35,000 | SUs are among the most prescribed T2D drugs |
| Restrict to T2D | ~14,000–32,000 | |
| New users | ~10,000–24,000 | |
| 180-day continuous enrollment | ~7,000–17,000 | |
| Post-ICD-10 (≥2016) | ~5,000–14,000 | |

### 5.4 Expected MACE Events (Power Analysis Context)

Using CANVAS trial MACE rates (26.9 per 1000 PY in canagliflozin, 31.5 per 1000 PY in
comparators) and assuming median 2 years of follow-up in this CDW:

| Arm | Est. N | Est. PY | Expected MACE Events |
|-----|--------|---------|---------------------|
| Canagliflozin | ~100 | ~200 | **~5–6** |
| DPP-4i | ~6,000 | ~12,000 | ~378 |
| Sulfonylurea | ~10,000 | ~20,000 | ~630 |

**~5–6 events in the canagliflozin arm is wholly inadequate** for Cox regression, IPW, or
any causal inference method. A minimum of ~100 events per arm is generally required for
stable HR estimation; ~50 events is an absolute lower bound for very simple models.

---

## 6. Positivity Assessment

### 6.1 Overall Treatment Arm Balance

**CRITICAL IMBALANCE:** The canagliflozin arm (N~100) would be dwarfed by either
comparator arm (DPP-4i N~6,000, SU N~10,000) at a ratio of approximately 1:60 to 1:100.
While IPW can handle moderate arm imbalances, ratios beyond ~1:10 produce extreme weights
and highly unstable estimates.

### 6.2 Within-Subgroup Positivity

For the proposed subgroup analyses (CKD, ASCVD):

| Subgroup | Canagliflozin Est. N | Feasibility |
|----------|---------------------|-------------|
| CKD (N18.3x–N18.5 or eGFR < 60) | ~15–25 | NOT FEASIBLE |
| ASCVD (I25.x, I63.x history, I70.x) | ~20–35 | NOT FEASIBLE |
| HF (I50.x) | ~10–20 | NOT FEASIBLE |

Positivity violations are guaranteed in these small subgroups — many covariate strata will
have zero canagliflozin patients.

---

## 7. Time-Zero Definition

**Time zero = date of first qualifying prescription** (RX_ORDER_DATE) for canagliflozin
or the comparator drug (DPP-4i or SU) in a patient who meets all eligibility criteria.

### 7.1 Eligibility at Time Zero

At the time of the first qualifying prescription, the patient must have:

1. **Type 2 diabetes diagnosis:** At least one E11.x code (DX_TYPE = '10') on or before
   the prescription date
2. **Adult age:** ≥18 years at time zero
3. **New user status:** No prior prescription of the same drug class during the 180-day
   washout period
4. **Continuous enrollment:** ≥180 days continuous enrollment before time zero
   (ENR_START_DATE ≤ time zero − 180 days)
5. **No exclusions:** See below

### 7.2 Exclusion Criteria

| Exclusion | CDW Source | Codes |
|-----------|-----------|-------|
| Type 1 diabetes | DIAGNOSIS | E10.x |
| Gestational diabetes | DIAGNOSIS | O24.x |
| ESRD / dialysis | DIAGNOSIS + PROCEDURES | N18.6, Z99.2; CPT 90935-90940 |
| Prior SGLT2i use (for canagliflozin arm) | PRESCRIBING | Any SGLT2i RXCUI in washout |
| Active cancer (past 12 months) | DIAGNOSIS | C00–C97 |
| Age < 18 | DEMOGRAPHIC | BIRTH_DATE |

### 7.3 Follow-Up Start

Follow-up begins the **day after drug initiation** (time zero + 1 day), consistent with
the study description and the CANVAS trial design. Patients are followed until the earliest
of: (a) outcome event, (b) death, (c) treatment discontinuation + grace period (if
as-treated analysis), (d) end of continuous enrollment, (e) end of study period.

### 7.4 Treatment Duration

Treatment duration is challenging to determine because:
- RX_END_DATE is only 47.6% populated
- RX_DAYS_SUPPLY is only 42.8% populated

**Recommended approach for as-treated analysis:** Use RX_END_DATE when available; otherwise
derive from RX_DAYS_SUPPLY (when available); otherwise apply a 90-day prescription duration
assumption with a 30-day grace period. For ITT analysis, censor only at enrollment end/death.

---

## 8. Per-Question Feasibility Assessment

### Q1: Canagliflozin vs DPP-4i for 3P-MACE (PRIMARY) — NOT FEASIBLE

| Parameter | Assessment |
|-----------|------------|
| Canagliflozin arm N | ~80–120 after eligibility |
| DPP-4i arm N | ~3,000–9,000 (estimated) |
| Expected MACE events (canagliflozin) | ~5–6 |
| Arm ratio | ~1:40 to 1:75 |
| Minimum needed for stable estimation | ~500+ per arm with ~100+ events |
| **Verdict** | **NOT FEASIBLE** — canagliflozin arm is 10-50x too small |

**Key issue:** This is a single-institution CDW. Canagliflozin lost significant market
share after the 2017 CANVAS amputation signal and the subsequent FDA boxed warning (later
removed in 2020). Empagliflozin (6,526 patients) and dapagliflozin (3,165 patients)
dominate SGLT2i prescribing at this institution.

### Q2: Canagliflozin vs 2nd-Gen SU for 3P-MACE (SECONDARY) — NOT FEASIBLE

| Parameter | Assessment |
|-----------|------------|
| Canagliflozin arm N | ~80–120 |
| SU arm N | ~5,000–14,000 (estimated) |
| Expected MACE events (canagliflozin) | ~5–6 |
| **Verdict** | **NOT FEASIBLE** — same canagliflozin limitation |

### Q3: Individual MACE Components — NOT FEASIBLE

Individual MI, stroke, and CV death events are each rarer than the composite. With ~5–6
total MACE events expected in the canagliflozin arm, individual components would have
~1–3 events each. Not feasible.

### Q4: Heart Failure Hospitalization — NOT FEASIBLE

HHF is a secondary outcome with rates comparable to MACE (~15–20 per 1000 PY in T2D
populations). Expected HHF events in the canagliflozin arm: ~3–4. Not feasible.

### Q5: Safety Profile — MARGINALLY FEASIBLE (genital infections only)

| Safety Outcome | Expected Rate | Expected Events (N=100) | Verdict |
|----------------|---------------|------------------------|---------|
| Genital infections | ~100–120 per 1000 PY | ~20–24 | **Marginally feasible** |
| Amputation | ~6 per 1000 PY | ~1–2 | Not feasible |
| DKA | ~1–2 per 1000 PY | ~0–1 | Not feasible |
| AKI | ~10–15 per 1000 PY | ~2–3 | Not feasible |

Only genital mycotic infections occur frequently enough to produce a meaningful number
of events in a cohort of ~100 canagliflozin patients. Even this would be a descriptive
analysis rather than a formal TTE with robust causal inference.

### Q6: CKD Subgroup — NOT FEASIBLE

The intersection of canagliflozin users (~100) with CKD (any stage) would yield ~15–25
patients. Not feasible for any subgroup analysis.

### Q7: ASCVD Subgroup — NOT FEASIBLE

The intersection of canagliflozin users (~100) with established ASCVD would yield ~20–35
patients. Not feasible.

---

## 9. Data Gaps and Limitations

### 9.1 Critical Gaps

| Gap | Impact | Severity |
|-----|--------|----------|
| **Canagliflozin N = 142** | Study is not feasible as designed | **FATAL** |
| **DPP-4i/SU counts unknown from profile** | Cannot confirm comparator arm sizes | High (but likely adequate) |
| **DEATH_CAUSE completeness unknown** | CV death may not be distinguishable from all-cause death | High |
| **Smoking data unusable** (99.8% UN/NI) | Cannot adjust for smoking, a major CV risk factor | High |

### 9.2 Moderate Gaps

| Gap | Impact | Severity |
|-----|--------|----------|
| RX_DAYS_SUPPLY 42.8% populated | Treatment duration/persistence hard to determine | Moderate |
| RX_END_DATE 47.6% populated | As-treated censoring imprecise | Moderate |
| PAYER_TYPE_PRIMARY 0% populated | Cannot adjust for insurance status | Moderate |
| NT-proBNP sparse (4,714 pts) | Cannot use HF biomarker as confounder | Moderate |
| OTC aspirin not captured | Antiplatelet use underestimated | Moderate |
| Albuminuria/UACR not in top LOINCs | CKD characterization limited to eGFR | Moderate |

### 9.3 Minor Gaps

| Gap | Impact | Severity |
|-----|--------|----------|
| Legacy encounter filtering required | Adds complexity but well-documented | Low |
| ICD-9/10 transition (pre-2016 data) | Mitigated by restricting to ≥2016 | Low |
| Junk dates (1820–3019) | Mitigated by explicit date bounds | Low |
| MED_ADMIN limited to 2021+ (Epic only) | Inpatient meds incomplete pre-2021 | Low |

---

## 10. Alternative Study Designs (Recommendations)

Given the fatal feasibility barrier of canagliflozin N = 142, we recommend the following
alternatives:

### 10.1 Alternative A: SGLT2 Inhibitor Class-Level Analysis (RECOMMENDED)

**Expand the intervention to all SGLT2 inhibitors:**
- Canagliflozin: 142 patients
- Empagliflozin: 6,526 patients
- Dapagliflozin: 3,165 patients
- **Total SGLT2i: ~9,833 patients**

This changes the research question from "canagliflozin-specific" to "SGLT2i class effect"
but is substantially more feasible. After applying eligibility criteria, the SGLT2i arm
would have an estimated 4,000–7,000 new users — adequate for MACE analysis.

**Advantages:**
- Adequate sample size for primary and secondary outcomes
- Consistent with published class-level analyses (CVD-REAL, EASEL)
- Clinically relevant — the class effect is the current standard of care question

**Disadvantages:**
- Cannot isolate canagliflozin-specific effects (e.g., amputation risk)
- Heterogeneity across SGLT2i molecules (different selectivity profiles)
- Sensitivity analysis by individual SGLT2i would still be underpowered for canagliflozin

### 10.2 Alternative B: Empagliflozin as Index Drug

**Replace canagliflozin with empagliflozin** (6,526 patients):
- After eligibility: estimated ~3,000–4,500 new empagliflozin users
- Expected MACE events: ~160–240 over 2 years
- Ratio to DPP-4i: ~1:2 to 1:3 (much more balanced)

**Advantages:**
- Preserves molecule-specific question
- EMPA-REG OUTCOME data provides strong trial benchmark (HR 0.86 for MACE)
- Adequate power for primary composite

**Disadvantages:**
- Not the question specified in the study description
- Empagliflozin FDA approval for T2D was in 2014 (JARDIANCE)

### 10.3 Alternative C: Multi-Site PCORnet Query

**Leverage the PCORnet distributed network** to query canagliflozin across multiple
institutions. A 10-site query with similar canagliflozin prescribing rates would yield
~1,420 patients; a 50-site query (large PCORnet network) could yield ~7,100+ patients.

**Advantages:**
- Preserves the canagliflozin-specific question exactly as described
- PCORnet infrastructure supports distributed queries without data sharing
- Largest possible sample size for the specific question

**Disadvantages:**
- Requires governance approval and multi-site coordination
- Heterogeneous data quality across sites
- Longer timeline to execute

### 10.4 Alternative D: Hybrid SGLT2i Class + Canagliflozin Sensitivity

**Primary analysis:** SGLT2i class vs DPP-4i
**Pre-specified sensitivity analysis:** Canagliflozin-only subgroup

This provides the best of both worlds — a well-powered class-level analysis with a
transparent canagliflozin-specific subgroup. The canagliflozin subgroup will be descriptive
(underpowered for formal inference) but can report point estimates with wide confidence
intervals.

---

## 11. Feasibility Verdict Summary

| Question | Verdict | Confidence | Recommended Action |
|----------|---------|------------|-------------------|
| Q1: Canagliflozin vs DPP-4i (3P-MACE) | **NOT FEASIBLE** | High | Adopt Alternative A or D |
| Q2: Canagliflozin vs SU (3P-MACE) | **NOT FEASIBLE** | High | Adopt Alternative A or D |
| Q3: Individual MACE Components | **NOT FEASIBLE** | High | Feasible only under Alt A |
| Q4: HHF | **NOT FEASIBLE** | High | Feasible only under Alt A |
| Q5: Safety (genital infections) | **MARGINALLY FEASIBLE** | Moderate | Proceed with descriptive analysis |
| Q6: CKD Subgroup | **NOT FEASIBLE** | High | Feasible only under Alt A with large SGLT2i arm |
| Q7: ASCVD Subgroup | **NOT FEASIBLE** | High | Feasible only under Alt A with large SGLT2i arm |

**Overall recommendation:** Proceed with **Alternative D** (SGLT2i class primary + canagliflozin
sensitivity) as the best balance between clinical relevance, statistical rigor, and the original
study description's intent. This preserves the DPP-4i primary comparator and SU secondary
comparator as specified, while ensuring adequate power. The coordinator and investigator should
discuss whether this modification is acceptable before proceeding to Phase 3 (Protocol Generation).

---

## Appendix A: Complete RxNorm Code Reference

### A.1 Canagliflozin — Single Ingredient

| RxCUI | Description | Type |
|-------|-------------|------|
| 1373463 | canagliflozin 100 MG Oral Tablet | SCD |
| 1373471 | canagliflozin 300 MG Oral Tablet | SCD |
| 1373469 | canagliflozin 100 MG Oral Tablet [Invokana] | SBD |
| 1373473 | canagliflozin 300 MG Oral Tablet [Invokana] | SBD |

### A.2 Canagliflozin/Metformin — Combination Products

| RxCUI | Description | Type |
|-------|-------------|------|
| 1545150 | canagliflozin 50 MG / metformin 500 MG Oral Tablet | SCD |
| 1545157 | canagliflozin 50 MG / metformin 1000 MG Oral Tablet | SCD |
| 1545161 | canagliflozin 150 MG / metformin 500 MG Oral Tablet | SCD |
| 1545164 | canagliflozin 150 MG / metformin 1000 MG Oral Tablet | SCD |
| 1545156 | canagliflozin 50 MG / metformin 500 MG [Invokamet] | SBD |
| 1545159 | canagliflozin 50 MG / metformin 1000 MG [Invokamet] | SBD |
| 1545163 | canagliflozin 150 MG / metformin 500 MG [Invokamet] | SBD |
| 1545166 | canagliflozin 150 MG / metformin 1000 MG [Invokamet] | SBD |
| 1810997 | canagliflozin 50 MG / metformin ER 500 MG | SCD |
| 1811003 | canagliflozin 50 MG / metformin ER 1000 MG | SCD |
| 1811007 | canagliflozin 150 MG / metformin ER 500 MG | SCD |
| 1811011 | canagliflozin 150 MG / metformin ER 1000 MG | SCD |
| 1810999 | canagliflozin 50 MG / metformin ER 500 MG [Invokamet XR] | SBD |
| 1811003 | canagliflozin 50 MG / metformin ER 1000 MG [Invokamet XR] | SBD |
| 1811007 | canagliflozin 150 MG / metformin ER 500 MG [Invokamet XR] | SBD |
| 1811011 | canagliflozin 150 MG / metformin ER 1000 MG [Invokamet XR] | SBD |

### A.3 Empagliflozin (for Alternative A/D)

| RxCUI | Description | Type |
|-------|-------------|------|
| 1545653 | empagliflozin 10 MG Oral Tablet | SCD |
| 1545658 | empagliflozin 25 MG Oral Tablet | SCD |
| 1545655 | empagliflozin 10 MG Oral Tablet [Jardiance] | SBD |
| 1545660 | empagliflozin 25 MG Oral Tablet [Jardiance] | SBD |

### A.4 Dapagliflozin (for Alternative A/D)

| RxCUI | Description | Type |
|-------|-------------|------|
| 1488564 | dapagliflozin 5 MG Oral Tablet | SCD |
| 1488569 | dapagliflozin 10 MG Oral Tablet | SCD |
| 1488566 | dapagliflozin 5 MG Oral Tablet [Farxiga] | SBD |
| 1488571 | dapagliflozin 10 MG Oral Tablet [Farxiga] | SBD |

### A.5 DPP-4 Inhibitors (Primary Comparator)

**Sitagliptin:**

| RxCUI | Description | Type |
|-------|-------------|------|
| 665033 | sitagliptin 100 MG Oral Tablet | SCD |
| 665038 | sitagliptin 25 MG Oral Tablet | SCD |
| 665042 | sitagliptin 50 MG Oral Tablet | SCD |
| 2709603 | sitagliptin phosphate 100 MG Oral Tablet | SCD |
| 2709608 | sitagliptin phosphate 50 MG Oral Tablet | SCD |
| 2709612 | sitagliptin phosphate 25 MG Oral Tablet | SCD |
| 665036 | sitagliptin phosphate 100 MG [Januvia] | SBD |
| 665040 | sitagliptin phosphate 25 MG [Januvia] | SBD |
| 665044 | sitagliptin phosphate 50 MG [Januvia] | SBD |
| 2670447 | sitagliptin 100 MG [Zituvio] | SBD |
| 2670449 | sitagliptin 25 MG [Zituvio] | SBD |
| 2670451 | sitagliptin 50 MG [Zituvio] | SBD |

**Linagliptin:**

| RxCUI | Description | Type |
|-------|-------------|------|
| 1100702 | linagliptin 5 MG Oral Tablet | SCD |
| 1100706 | linagliptin 5 MG Oral Tablet [Tradjenta] | SBD |

**Saxagliptin:**

| RxCUI | Description | Type |
|-------|-------------|------|
| 858036 | saxagliptin 5 MG Oral Tablet | SCD |
| 858042 | saxagliptin 2.5 MG Oral Tablet | SCD |
| 858040 | saxagliptin 5 MG Oral Tablet [Onglyza] | SBD |
| 858044 | saxagliptin 2.5 MG Oral Tablet [Onglyza] | SBD |

**Alogliptin:**

| RxCUI | Description | Type |
|-------|-------------|------|
| 1368006 | alogliptin 25 MG Oral Tablet | SCD |
| 1368018 | alogliptin 6.25 MG Oral Tablet | SCD |
| 1368034 | alogliptin 12.5 MG Oral Tablet | SCD |
| 1368012 | alogliptin 25 MG Oral Tablet [Nesina] | SBD |
| 1368020 | alogliptin 6.25 MG Oral Tablet [Nesina] | SBD |
| 1368036 | alogliptin 12.5 MG Oral Tablet [Nesina] | SBD |

### A.6 2nd-Generation Sulfonylureas (Secondary Comparator)

**Glipizide:**

| RxCUI | Description | Type |
|-------|-------------|------|
| 310488 | glipizide 10 MG Oral Tablet | SCD |
| 310490 | glipizide 5 MG Oral Tablet | SCD |
| 379804 | glipizide 2.5 MG Oral Tablet | SCD |
| 2737151 | glipizide 15 MG Oral Tablet | SCD |
| 315107 | 24 HR glipizide 10 MG ER | SCD |
| 314006 | 24 HR glipizide 5 MG ER | SCD |
| 310489 | 24 HR glipizide 2.5 MG ER | SCD |
| 205828 | glipizide 5 MG [Glucotrol] | SBD |
| 865568 | 24 HR glipizide 10 MG ER [Glucotrol] | SBD |
| 865571 | 24 HR glipizide 2.5 MG ER [Glucotrol] | SBD |
| 865573 | 24 HR glipizide 5 MG ER [Glucotrol] | SBD |

**Glimepiride:**

| RxCUI | Description | Type |
|-------|-------------|------|
| 199245 | glimepiride 1 MG Oral Tablet | SCD |
| 199246 | glimepiride 2 MG Oral Tablet | SCD |
| 199247 | glimepiride 4 MG Oral Tablet | SCD |
| 153842 | glimepiride 3 MG Oral Tablet | SCD |
| 1361493 | glimepiride 6 MG Oral Tablet | SCD |
| 1361495 | glimepiride 8 MG Oral Tablet | SCD |
| 153843 | glimepiride 1 MG [Amaryl] | SBD |
| 153591 | glimepiride 2 MG [Amaryl] | SBD |
| 153845 | glimepiride 4 MG [Amaryl] | SBD |

**Glyburide:**

| RxCUI | Description | Type |
|-------|-------------|------|
| 197737 | glyburide 1.25 MG Oral Tablet | SCD |
| 310534 | glyburide 2.5 MG Oral Tablet | SCD |
| 310537 | glyburide 5 MG Oral Tablet | SCD |
| 314000 | glyburide 1.5 MG (micronized) | SCD |
| 310536 | glyburide 3 MG (micronized) | SCD |
| 310539 | glyburide 6 MG (micronized) | SCD |
| 252960 | glyburide 4.5 MG Oral Tablet | SCD |
| 430102 | glyburide 3.5 MG Oral Tablet | SCD |
| 430103 | glyburide 1.75 MG Oral Tablet | SCD |
| 881407 | glyburide 1.5 MG [Glynase] | SBD |
| 881409 | glyburide 3 MG [Glynase] | SBD |
| 881411 | glyburide 6 MG [Glynase] | SBD |

---

## Appendix B: ICD-10-CM Code Reference

### B.1 MACE Components

**Acute MI:** `DX LIKE 'I21%'` (exclude I21.A1 for primary; include in sensitivity)
**Subsequent MI:** `DX LIKE 'I22%'`
**Ischemic Stroke:** `DX LIKE 'I63%'`
**CV Death causes:** I20-I25, I46, I50, I60-I69, I71

### B.2 Heart Failure Hospitalization

`DX LIKE 'I50%'` with ENC_TYPE IN ('IP','EI')

### B.3 Type 2 Diabetes

`DX LIKE 'E11%'` AND DX_TYPE = '10'

### B.4 CKD Staging

| Code | Stage | eGFR Range |
|------|-------|------------|
| N18.1 | 1 | ≥90 |
| N18.2 | 2 | 60–89 |
| N18.30 | 3, unspecified | 30–59 |
| N18.31 | 3a | 45–59 |
| N18.32 | 3b | 30–44 |
| N18.4 | 4 | 15–29 |
| N18.5 | 5 | <15 |
| N18.6 | ESRD | Dialysis |
| N18.9 | Unspecified | — |

### B.5 ASCVD

`DX LIKE 'I25%'` (chronic IHD) OR `DX LIKE 'I21%'` OR `DX IN ('I25.2')` (old MI)
OR `DX LIKE 'I70%'` (atherosclerosis) OR `DX = 'I73.9'` (PVD)
OR `DX = 'Z86.73'` (history of TIA/stroke)

### B.6 Safety Outcomes

**DKA:** `DX IN ('E11.10','E11.11','E13.10','E13.11')`
**Genital infections:** `DX IN ('B37.31','B37.32','B37.42','B37.49','N76.0','N77.1','N48.1')`
**AKI:** `DX LIKE 'N17%'`
**Amputation:** PX IN ('27590'-'27598','27880'-'27889','28800','28805','28810','28820','28825') with PX_TYPE = 'CH'

### B.7 Comorbidities (Confounders)

| Comorbidity | ICD-10 Pattern |
|-------------|---------------|
| Hypertension | I10, I11.x, I12.x, I13.x, I15.x, I16.x |
| Atrial fibrillation | I48.x |
| Heart failure | I50.x |
| COPD | J44.x |
| Obesity | E66.x |
| Dyslipidemia | E78.x |
| PAD | I70.x, I73.9 |
| VTE / PE | I26.x, I82.x |
| Prior MI | I21.x, I25.2 |
| Prior stroke | I63.x, Z86.73, I69.3x |
| Tobacco use disorder | F17.x, Z72.0, Z87.891 (proxy for smoking) |

---

## Appendix C: LOINC Codes

| LOINC | Lab Test | CDW Patients | Notes |
|-------|----------|-------------|-------|
| 4548-4 | HbA1c | 332,556 | Primary glycemic control marker |
| 2160-0 | Serum creatinine | 572,583 | Renal function / eGFR derivation |
| 48642-3 | eGFR (MDRD, non-Black) | 167,036 | Primary eGFR code in CDW |
| 33914-3 | eGFR (MDRD, legacy) | 36,067 | Older equation; DISCOURAGED status |
| 62238-1 | eGFR (CKD-EPI, original) | TBD | May be present if lab recently updated |
| 98979-8 | eGFR (CKD-EPI 2021, race-free) | TBD | Current standard; check availability |
| 2093-3 | Total cholesterol | 337,620 | Lipid panel |
| 2571-8 | Triglycerides | 337,485 | Lipid panel |
| 2085-9 | HDL cholesterol | 332,287 | Lipid panel |
| 13457-7 | LDL cholesterol (calc) | 242,238 | Lipid panel |
| 718-7 | Hemoglobin | 604,651 | Anemia screening |
| 777-3 | Platelets | 355,519 | Bleeding risk |
| 2823-3 | Potassium | 569,683 | Electrolytes |
| 1742-6 | ALT | 484,206 | Hepatic function |
| 1920-8 | AST | 432,663 | Hepatic function |
| 1975-2 | Total bilirubin | 554,750 | Hepatic function |
| 33762-6 | NT-proBNP | 4,714 | HF biomarker (sparse) |

---

## Appendix D: Cross-Cutting Methodological Notes

### D.1 Legacy Encounter Filtering (MANDATORY)

All queries MUST include:
```sql
INNER JOIN CDW.dbo.ENCOUNTER e ON d.ENCOUNTERID = e.ENCOUNTERID
  AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
  AND e.ADMIT_DATE BETWEEN '2016-01-01' AND GETDATE()
```

### D.2 Date Quality Guards (MANDATORY)

All date-filtered queries must include explicit date bounds. The CDW contains junk dates
from 1820 to 3019. Year 1900 has ~40K patients (EHR default).

### D.3 DEATH Table Deduplication (MANDATORY)

Always use ROW_NUMBER() PARTITION BY PATID when joining DEATH:
```sql
LEFT JOIN (
  SELECT d.PATID, d.DEATH_DATE,
    ROW_NUMBER() OVER (PARTITION BY d.PATID ORDER BY d.DEATH_DATE) AS rn
  FROM CDW.dbo.DEATH d
) death ON t.PATID = death.PATID AND death.rn = 1
```

### D.4 Smoking Data Limitation

VITAL.SMOKING is 99.8% 'UN' or 'NI'. Use tobacco use disorder codes (F17.x, Z72.0,
Z87.891) from DIAGNOSIS as a proxy.

### D.5 Column Case Normalization

After `dbGetQuery()`, always call `names(df) <- tolower(names(df))`.

### D.6 Database Connection

```r
library(DBI)
library(odbc)
con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")
on.exit(DBI::dbDisconnect(con))
```

All tables: `CDW.dbo.TABLE_NAME`

### D.7 Proposed Study Period

**Recommended: 2016-01-01 to 2025-12-31**

Justification:
- ICD-10 fully in effect from 2016
- Canagliflozin FDA approval: March 2013; meaningful prescribing volume from ~2014
- Post-ICD-10 ensures clean diagnosis coding
- Spans both AllScripts (pre-2020) and Epic (post-2020) eras
- Legacy encounter filtering is REQUIRED for the full period
