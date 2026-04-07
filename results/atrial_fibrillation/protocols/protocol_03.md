# Protocol 03: OAC vs No OAC at CHA₂DS₂-VASc = 1 (Men) / 2 (Women) in Atrial Fibrillation

**Target Trial Emulation Protocol**
**Date:** 2026-04-07
**Data Source:** PCORnet CDW (institutional Clinical Data Warehouse, MS SQL Server)
**Gap Score:** 9/10

---

## 1. Clinical Context and Evidence Gap

### Background

The decision to initiate oral anticoagulation (OAC) in atrial fibrillation (AF) patients at the guideline treatment threshold — CHA₂DS₂-VASc score of 1 for men or 2 for women — is the single most debated clinical decision in AF management. This threshold represents a genuine zone of clinical equipoise where guidelines offer only a weak recommendation (Class IIb, "may consider"), leaving the decision to individual clinician judgment.

CHA₂DS₂-VASc = 1 (men) or 2 (women) means the patient has exactly one non-sex stroke risk factor (heart failure, hypertension, diabetes, vascular disease, or age 65-74). The sex component contributes 1 point for women, so a score of 2 in women reflects the same underlying clinical risk burden as a score of 1 in men. At this threshold, the annual stroke risk is estimated at 1.3-2.2% without anticoagulation, which must be weighed against the 1-3% annual major bleeding risk with OAC.

### Why a Target Trial Emulation?

It is widely considered **unethical to randomize** patients at this threshold to no anticoagulation, because withholding OAC from a patient whose clinician has decided to prescribe it violates equipoise in the treating physician's judgment. The BRAIN-AF trial (PMID: 41501492) attempted to address this gap by randomizing CHA₂DS₂-VASc 0-1 patients to rivaroxaban vs placebo, but used reduced-dose rivaroxaban (15mg), targeted cognitive decline rather than stroke, and was stopped early for futility. No RCT has directly answered the question of whether full-dose OAC reduces stroke/SE in this specific population.

Target trial emulation using observational data is the ideal approach because:
1. The CDW captures real-world treatment decisions at this threshold
2. A natural comparator group exists (many clinicians defer OAC at this score)
3. The question is a causal contrast amenable to the Hernán & Robins framework
4. IPW can address confounding by indication (why some patients at the same score receive OAC and others do not)

### Guideline Context

- **2023 ACC/AHA/ACCP/HRS AF Guideline** (PMID: 38033089): CHA₂DS₂-VASc ≥ 2 in men / ≥ 3 in women → anticoagulation recommended (Class I). CHA₂DS₂-VASc = 1 in men / = 2 in women → "it may be reasonable to prescribe OAC" (Class IIb, Level B-NR).
- **2020 ESC AF Guidelines** (PMID: 32860505): Similar threshold; OAC "should be considered" at CHA₂DS₂-VASc ≥ 1 (men) / ≥ 2 (women) (Class IIa).
- **Key evidence gap:** No RCT or well-designed TTE has established whether OAC at this threshold produces a net clinical benefit.

### Existing Observational Evidence

- **Registry and cohort studies** (PMID: 27461573, 26547222): Show that untreated low-CHA₂DS₂-VASc patients have stroke rates of ~1-2%/year, but these are associational, not causal.
- **Danish nationwide cohort** (PMID: 26547222): CHA₂DS₂-VASc = 1 patients had stroke rate ~1.5%/year without treatment. OAC was associated with reduced stroke but increased bleeding.
- **BRAIN-AF** (PMID: 41501492): Rivaroxaban 15mg vs placebo in CHA₂DS₂-VASc 0-1. Stopped for futility on cognitive endpoint. Stroke was a secondary outcome; too few events to draw conclusions. Used reduced dose, not standard dose.

### Clinical Relevance

This protocol addresses the highest-priority question in AF management. Tens of thousands of patients annually present with newly diagnosed AF and CHA₂DS₂-VASc = 1 (men) / 2 (women). Clinicians currently make this decision based on individual patient factors and their own practice patterns, with no high-quality causal evidence to guide them. A TTE with proper confounding adjustment can provide the first formal causal estimate of the treatment effect in this population.

---

## 2. Target Trial Specification

### 2.1 Eligibility Criteria

**Inclusion:**
1. Adults aged ≥ 18 years
2. Documented non-valvular AF (ICD-10: I48.0, I48.11, I48.19, I48.20, I48.21, I48.91)
3. CHA₂DS₂-VASc score = 1 (men) or = 2 (women), computed from:
   - CHF (1 point): I50.x
   - Hypertension (1 point): I10, I11.x, I12.x, I13.x, I15.x, I16.x
   - Age ≥ 75 (2 points): from BIRTH_DATE
   - Diabetes (1 point): E10.x, E11.x, E13.x
   - Stroke/TIA/TE (2 points): I63.x, G45.x, I74.x
   - Vascular disease (1 point): I21.x, I25.x, I70.x, I71.x, I73.9
   - Age 65-74 (1 point): from BIRTH_DATE
   - Female sex (1 point): SEX = 'F'
4. No prior OAC prescription (new-user design)
5. At least one non-legacy encounter within 365 days before time zero

**Exclusion:**
1. Valvular AF: rheumatic mitral valve disease (I05.0-I05.9), rheumatic aortic/tricuspid/multiple valve disease (I06.x, I07.x, I08.x), prosthetic heart valve (Z95.2, Z95.3, Z95.4)
2. Prior stroke or TIA (I63.x, G45.x): These patients would score ≥ 3 on CHA₂DS₂-VASc (2 points for stroke + at least 1 other factor), making them ineligible by score. Also excluded explicitly because prior stroke is an absolute indication for OAC.
3. Prior systemic embolism (I74.x): Same reasoning — contributes 2 points
4. Active cancer (C00-C97): confounds mortality and treatment decisions
5. Mechanical heart valve (Z95.2): absolute indication for warfarin
6. Age ≥ 75: contributes 2 points → CHA₂DS₂-VASc ≥ 3 for men, ≥ 4 for women
7. Prior OAC use at any time before time zero (ensures new-user design)

**Note on score = 1 (men) / 2 (women):** Because the stroke/TIA component awards 2 points and age ≥ 75 awards 2 points, patients at the target score can only have ONE of: CHF, hypertension, diabetes, vascular disease, or age 65-74. The exclusion of prior stroke/TIA and age ≥ 75 is inherent in the score constraint.

### 2.2 Treatment Strategies

- **Intervention (OAC arm):** Initiation of any oral anticoagulant within ±7 days of time zero:
  - Apixaban: RXCUI 1364435, 1364445, 1364441, 1364447
  - Rivaroxaban: RXCUI 1114198, 1232082, 1232086, 2059015, 1114202, 1232084, 1232088, 2059017
  - Dabigatran: RXCUI 1037179, 1723476, 1037045, 1037181, 1723478, 1037049
  - Edoxaban: RXCUI 1599543, 1599551, 1599555, 1599549, 1599553, 1599557
  - Warfarin: RXCUI 855350, 855288, 855302, 855312, 855318, 855324, 855332, 855338, 855344, 855296, 855290, 855304, 855314, 855320, 855326, 855334, 855340, 855346, 855298, 855292, 855306, 855316, 855322, 855328, 855336, 855342, 855348, 855300

- **Comparator (No OAC arm):** Absence of any OAC prescription within ±7 days of time zero.

This is a **treated vs untreated** design, unlike the active-comparator designs in Protocols 01 and 02. The comparator is the absence of treatment, which introduces stronger confounding by indication — clinicians who prescribe OAC at this threshold may do so because the patient has additional unmeasured risk factors (e.g., prior transient symptoms, echocardiographic findings). IPW must adjust aggressively for all measured confounders.

### 2.3 Assignment Procedure

At time zero (the date a patient first meets all eligibility criteria), patients are classified as:
- **OAC (treatment = 1):** An OAC prescription appears in PRESCRIBING within ±7 days of time zero
- **No OAC (treatment = 0):** No OAC prescription within ±7 days of time zero

The ±7-day grace period accounts for the fact that the clinical decision and the prescription may not occur on the exact same date. This emulates the "intent to treat at the point of clinical decision."

Assignment is non-randomized. Confounding by indication is the primary threat — sicker patients or those with additional subclinical risk factors may be more likely to receive OAC. Confounding is addressed through IPW with a propensity score model incorporating demographics, comorbidities, laboratory values, and concomitant medications.

### 2.4 Outcome Definition and Measurement Window

**Primary outcome:** Ischemic stroke or systemic embolism — first occurrence of I63.x (ischemic stroke) or I74.x (arterial embolism/thrombosis) after time zero, identified in DIAGNOSIS linked to an inpatient or ED encounter (ENC_TYPE IN ('IP', 'EI', 'ED')).

**Secondary outcomes:**
1. **Major bleeding:** First occurrence of intracranial hemorrhage (I60.x, I61.x, I62.x), GI bleeding (K92.0, K92.1, K92.2, K62.5), or ulcer/gastritis with hemorrhage (K25.0, K25.4, K26.0, K26.4, K27.0, K27.4, K29.01)
2. **Intracranial hemorrhage (ICH):** Subset of major bleeding — I60.x, I61.x, I62.x only
3. **All-cause mortality:** Death from CDW.dbo.DEATH
4. **Net clinical benefit (NCB):** Computed in R as:
   NCB = (stroke rate without OAC − stroke rate with OAC) − 1.5 × (ICH rate with OAC − ICH rate without OAC)

   The weight of 1.5 for ICH reflects the greater severity of hemorrhagic stroke relative to ischemic stroke (Singer et al., PMID: 19188512).

**Follow-up:** 365 days (1 year) from time zero. Patients are censored at death, end of follow-up, or end of study period, whichever occurs first.

### 2.5 Time Zero

Time zero = the date of the **first AF diagnosis encounter** (earliest I48.x code) where the patient also meets the following criteria at that date:
1. CHA₂DS₂-VASc = 1 (men) or 2 (women) based on all diagnoses on or before that date
2. No prior OAC prescription before the grace period window
3. No exclusion criteria met

The CHA₂DS₂-VASc score is evaluated at the first AF encounter only. Patients who are first diagnosed with AF at score 0 and later develop a risk factor (e.g., new HTN diagnosis bringing score to 1) are not captured. This is a deliberate simplification: the first AF encounter is the natural clinical decision point for OAC initiation, and evaluating the score at subsequent encounters would add complexity without clear benefit for the primary analysis. The proportion of patients excluded by this approach is estimated to be modest, as most CHA₂DS₂-VASc components (hypertension, diabetes, age) are chronic conditions likely present at AF diagnosis. This is documented as a limitation in Section 6.

This definition avoids immortal time bias — the patient enters the study at the first AF encounter, and treatment assignment is determined within the ±7-day grace period around that date.

### 2.6 Causal Contrast and Estimand

**Estimand:** Average Treatment Effect (ATE) — the effect of initiating OAC vs not initiating OAC in the population of AF patients at CHA₂DS₂-VASc = 1 (men) / 2 (women).

**Causal contrast:** "What would happen if all eligible patients initiated OAC at time zero, versus if none of them did?"

The ATE is the appropriate estimand because the clinical question is about a population-level recommendation — should guidelines recommend OAC at this threshold? The ATE answers this by estimating the average effect across all patients at this score, not just those who chose to be treated (ATT).

---

## 3. Emulation Using Observational Data

### 3.1 Target Dataset

**PCORnet CDW** — institutional Clinical Data Warehouse on MS SQL Server, containing ~10M patients with comprehensive EHR data including diagnoses, medications, labs, vitals, procedures, and death records.

**Study period:** 2016-01-01 to 2025-12-31

Justification:
- ICD-10 fully in effect from 2016 (essential for precise AF subtyping and comorbidity coding)
- DOAC adoption well-established by 2016
- Spans AllScripts (pre-2020) and Epic (post-2020) EHR eras
- Legacy encounter filtering (`RAW_ENC_TYPE <> 'Legacy Encounter'`) applied throughout
- Sensitivity analysis restricted to 2021+ (post-Epic only) recommended

### 3.2 Variable Mapping

| Protocol Element | CDW Table | Column(s) | Codes / Logic |
|-----------------|-----------|-----------|---------------|
| AF diagnosis | CDW.dbo.DIAGNOSIS | DX, DX_TYPE | DX LIKE 'I48%' AND DX_TYPE = '10', excluding I48.3, I48.4, I48.92 (flutter) |
| Valvular exclusion | CDW.dbo.DIAGNOSIS | DX | I05.x, I06.x, I07.x, I08.x, Z95.2, Z95.3, Z95.4 |
| Demographics | CDW.dbo.DEMOGRAPHIC | PATID, BIRTH_DATE, SEX, RACE, HISPANIC | Age, sex for score computation |
| CHA₂DS₂-VASc | DIAGNOSIS + DEMOGRAPHIC | Multiple | See Section 3.3 |
| OAC exposure | CDW.dbo.PRESCRIBING | RXNORM_CUI, RX_ORDER_DATE | 53 SCD+SBD RXCUIs (see Section 2.2) |
| Ischemic stroke/SE | CDW.dbo.DIAGNOSIS | DX | I63.x, I74.x on IP/EI/ED encounter |
| Major bleeding | CDW.dbo.DIAGNOSIS | DX | I60-I62, K92.0-K92.2, K62.5, K25.0/4, K26.0/4, K27.0/4, K29.01 |
| ICH | CDW.dbo.DIAGNOSIS | DX | I60.x, I61.x, I62.x on IP/EI/ED |
| All-cause mortality | CDW.dbo.DEATH | DEATH_DATE | Deduplicated via ROW_NUMBER |
| Comorbidities | CDW.dbo.DIAGNOSIS | DX | CHF (I50.x), HTN (I10-I16), DM (E10-E13), CKD (N18.x), prior bleed, liver disease, anemia |
| Vitals | CDW.dbo.VITAL | ORIGINAL_BMI, SYSTOLIC, DIASTOLIC | Most recent within 365 days |
| Labs | CDW.dbo.LAB_RESULT_CM | LAB_LOINC, RESULT_NUM | eGFR (48642-3, 62238-1), creatinine (2160-0), hemoglobin (718-7), HbA1c (4548-4) |
| Medications | CDW.dbo.PRESCRIBING | RXNORM_CUI | Antiplatelet, statin, ACEi/ARB, beta-blocker, PPI, NSAID |

### 3.3 CHA₂DS₂-VASc Computation in SQL

The score is computed from its components using a GROUP BY query over DIAGNOSIS with CASE/WHEN aggregation, plus age and sex from DEMOGRAPHIC:

```sql
SELECT
  d.PATID,
  d.SEX,
  -- Component flags
  MAX(CASE WHEN dx.DX LIKE 'I50%' THEN 1 ELSE 0 END) AS chf_flag,
  MAX(CASE WHEN dx.DX LIKE 'I10%' OR dx.DX LIKE 'I11%' OR dx.DX LIKE 'I12%'
             OR dx.DX LIKE 'I13%' OR dx.DX LIKE 'I15%' OR dx.DX LIKE 'I16%'
       THEN 1 ELSE 0 END) AS htn_flag,
  MAX(CASE WHEN dx.DX LIKE 'E10%' OR dx.DX LIKE 'E11%' OR dx.DX LIKE 'E13%'
       THEN 1 ELSE 0 END) AS dm_flag,
  MAX(CASE WHEN dx.DX LIKE 'I21%' OR dx.DX LIKE 'I25%' OR dx.DX LIKE 'I70%'
             OR dx.DX LIKE 'I71%' OR dx.DX = 'I73.9'
       THEN 1 ELSE 0 END) AS vasc_flag,
  -- Age components computed separately from DEMOGRAPHIC
  CASE WHEN DATEDIFF(year, d.BIRTH_DATE, af.index_date) >= 75 THEN 2
       WHEN DATEDIFF(year, d.BIRTH_DATE, af.index_date) BETWEEN 65 AND 74 THEN 1
       ELSE 0 END AS age_score,
  CASE WHEN d.SEX = 'F' THEN 1 ELSE 0 END AS sex_score

-- Total score = chf + htn + age_score + dm + stroke_tia (excluded → 0) + vasc + sex_score
-- Filter: total = 1 (men) or 2 (women)
```

Patients with stroke/TIA/TE are excluded from eligibility (these contribute 2 points, making the minimum score 3). Therefore the stroke/TIA component is always 0 in the eligible population.

### 3.4 Data Gaps and Limitations

1. **Smoking:** Unusable in CDW (99.8% unknown/NI per data profile §6). Cannot adjust for smoking as a confounder.
2. **Aspirin/antiplatelet (OTC):** Aspirin purchased OTC is not captured in PRESCRIBING. Cannot identify the "aspirin-only" alternative strategy. This is a known limitation.
3. **Payer/insurance type:** PAYER_TYPE_PRIMARY is 0% populated — cannot adjust for insurance.
4. **Echocardiographic data:** Left atrial size, LVEF not available as structured data.
5. **Treatment persistence:** RX_DAYS_SUPPLY only 42.8% complete — cannot reliably assess whether OAC was continued.
6. **Unmeasured confounders:** Symptoms (palpitations, near-syncope), patient preference, and shared decision-making context are not captured.

---

## 4. Statistical Analysis Plan

### 4.1 Primary Analysis Method: IPW with Weighted Cox PH

**Propensity score model:** Logistic regression predicting OAC initiation (treatment = 1) using all measured confounders:
- Demographics: age (continuous), sex, race, Hispanic ethnicity
- CHA₂DS₂-VASc driving component (which single risk factor)
- Vital signs: BMI, systolic and diastolic BP
- Labs: eGFR, serum creatinine, hemoglobin, HbA1c
- Comorbidities: CHF, hypertension, diabetes, vascular disease, CKD, prior bleeding, liver disease, anemia, obesity, cancer
- Concomitant medications: antiplatelet, statin, ACEi/ARB, beta-blocker, PPI, NSAID
- Index year (calendar time)

**Weights:** Inverse probability weights for ATE estimation. Extreme weights are diagnosed by effective sample size (ESS) and PS distribution plots.

**Outcome model:** Weighted Cox proportional hazards model: `Surv(time, event) ~ treatment`, with robust (sandwich) variance estimation.

### 4.2 Confounder Identification

The confounder set is motivated by the DAG:

- **Common causes of treatment and outcome:** Age, sex, comorbidities (CHF, HTN, DM, vascular disease), renal function, bleeding history — all influence both the clinician's decision to prescribe OAC and the patient's risk of stroke and bleeding.
- **Confounding by indication:** The strongest threat. Clinicians who choose to prescribe OAC at this threshold may do so because of unmeasured factors (e.g., echocardiographic findings, prior TIA-like symptoms). The PS model includes all available measured proxies.
- **Calendar year:** Practice patterns have shifted toward OAC at lower thresholds over time; year adjusts for secular trends.

### 4.3 Balance Diagnostics

- Absolute standardized mean differences (ASMD) before and after weighting
- Threshold: ASMD < 0.1 for adequate balance
- Love plot visualization
- PS distribution overlap assessment

### 4.4 Sensitivity Analyses

1. **E-value analysis:** Quantifies unmeasured confounding strength needed to explain away the observed effect. Critical for the treated-vs-untreated design.
2. **PS trimming (5th-95th percentile):** Restricts to the region of PS overlap, improving positivity.
3. **Post-Epic era only (2021+):** Sensitivity to EHR era and data quality differences.
4. **DOAC-only subgroup:** Restricts OAC arm to DOAC users only (excludes warfarin), testing whether the effect is driven by DOAC-specific benefits.

### 4.5 Subgroup Analyses

By CHA₂DS₂-VASc driving component:
- CHF (the single risk factor is heart failure)
- Hypertension (the single risk factor is HTN)
- Diabetes (the single risk factor is DM)
- Vascular disease (the single risk factor is vascular disease)
- Age 65-74 (the single risk factor is age)

By demographics:
- Male vs Female
- Age < 70 vs ≥ 70

### 4.6 Net Clinical Benefit Calculation

NCB = (stroke rate in no-OAC − stroke rate in OAC) − 1.5 × (ICH rate in OAC − ICH rate in no-OAC)

Rates are computed as weighted event rates per 100 person-years using IPW weights. A positive NCB indicates that the stroke reduction outweighs the excess ICH risk.

---

## 5. R Analysis Script

See `protocol_03_analysis.qmd` for the complete Quarto analysis script implementing this protocol. The script:

1. Connects to the CDW via `DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")`
2. Builds the analytic cohort through sequential temp tables: `#af_patients` → `#chadsvasc_scores` → `#eligible` → `#treatment` → `#outcomes` → `#analytic_cohort`
3. Computes CHA₂DS₂-VASc from its components in SQL
4. Assigns treatment based on OAC prescription within ±7 days
5. Ascertains stroke/SE, major bleeding, ICH, and death outcomes at 365 days
6. Extracts confounders (vitals, labs, comorbidities, medications) with ROW_NUMBER deduplication
7. Runs IPW with dynamic PS formula construction
8. Fits weighted Cox PH models for all outcomes
9. Computes net clinical benefit
10. Performs subgroup and sensitivity analyses
11. Renders CONSORT diagram, love plots, KM curves, and forest plots inline

---

## 6. Limitations and Threats to Validity

### 6.1 Confounding by Indication

This is the primary threat. The treated-vs-untreated design means that factors driving OAC initiation (some unmeasured) also predict outcomes. Unlike active-comparator designs (P01, P02), there is no guarantee that the treatment groups are comparable even after adjustment. The E-value analysis quantifies the residual bias needed to explain away the observed effect.

### 6.2 Unmeasured Confounders

- **Echocardiographic data:** Left atrial size and LVEF may influence OAC decisions but are not available as structured data.
- **Symptom severity:** Patients with symptomatic AF (palpitations, near-syncope) may be more likely to receive OAC.
- **Patient preference:** Shared decision-making context is not captured.
- **OTC aspirin use:** Cannot identify patients self-treating with aspirin.

### 6.3 Positivity Violations

At CHA₂DS₂-VASc = 1 (men) / 2 (women), positivity may be violated in subgroups where nearly no patients receive OAC (e.g., very young men with lone AF and score = 1 from age alone). PS trimming addresses this partially.

### 6.4 Small Treated Arm

The treated (OAC) arm is estimated at ~2,000-4,000 patients, which is adequate for the primary analysis but may limit power for subgroup analyses and rare outcomes (ICH).

### 6.5 Treatment Persistence

The analysis uses an intent-to-treat approach at time zero. Patients in the OAC arm may discontinue; patients in the no-OAC arm may later initiate OAC. This dilutes the treatment effect toward the null but is the appropriate estimand for the clinical question ("what is the effect of the initial decision to prescribe?").

### 6.6 EHR Era Transition

The study spans AllScripts (pre-2020) and Epic (post-2020) EHR eras. Legacy encounter filtering is applied, and a sensitivity analysis restricted to post-Epic data (2021+) is included.

### 6.7 Score Evaluation at First AF Encounter Only

The CHA₂DS₂-VASc score is evaluated at the first AF diagnosis encounter. Patients who initially present with AF at score 0 and later develop a risk factor (e.g., new hypertension or diabetes diagnosis) bringing their score to the target threshold are not captured. This may exclude a clinically relevant subgroup — particularly younger patients whose score rises over time. The impact is expected to be modest because most score components (hypertension, diabetes, HF, vascular disease) are chronic conditions typically diagnosed before or concurrent with AF. A future extension could evaluate the score at each encounter to capture these late-qualifying patients.
