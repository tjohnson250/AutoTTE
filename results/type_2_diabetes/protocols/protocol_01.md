# Protocol 01: SGLT2 Inhibitor Class vs DPP-4 Inhibitors for 3-Point MACE in Type 2 Diabetes

**Protocol ID:** protocol_01
**Version:** 1.0
**Date:** 2026-04-15
**Design:** Target Trial Emulation — Active Comparator New-User Cohort
**Database:** PCORnet CDW v6.1 (MS SQL Server), schema `CDW.dbo`
**Mode:** OFFLINE (code written for future execution)

---

## 1. Clinical Context

Type 2 diabetes mellitus (T2D) affects over 37 million Americans and is a major independent risk factor for cardiovascular (CV) disease. Sodium-glucose cotransporter 2 (SGLT2) inhibitors have demonstrated CV benefit in landmark cardiovascular outcome trials (CVOTs): the CANVAS Program showed canagliflozin reduced 3-point MACE versus placebo (HR 0.86, 95% CI 0.75-0.97; PMID 28605608), EMPA-REG OUTCOME showed similar benefit for empagliflozin (HR 0.86, 0.74-0.99; PMID 26378978), and DECLARE-TIMI 58 demonstrated noninferiority for dapagliflozin (HR 0.93, 0.84-1.03; PMID 30415602).

DPP-4 inhibitors are established as cardiovascularly neutral by three CVOTs — SAVOR-TIMI 53 (saxagliptin), TECOS (sitagliptin), and CAROLINA (linagliptin) — with pooled MACE HR approximately 0.99 (PMID 41246652, 34364771). This CV neutrality makes DPP-4 inhibitors an ideal active comparator (pharmacoepidemiologic placebo) for observational studies of SGLT2i CV effects, avoiding confounding by indication inherent in untreated comparator groups.

Several observational studies have compared SGLT2i as a class to DPP-4i for CV outcomes: D'Andrea et al. 2023 (modified MACE HR 0.85, 0.75-0.95; PMID 36745425), EMPRISE (empagliflozin-specific MACE HR 0.73, 0.62-0.86; PMID 38509341), and Xie et al. 2023 using target trial emulation (MACE HR 0.86, 0.82-0.89; PMID 37499675). However, no published study has emulated a CANVAS-like trial comparing canagliflozin specifically to DPP-4i for 3P-MACE as the primary question.

**Feasibility modification:** This CDW contains only 142 canagliflozin patients — far too few for MACE analysis. Following the feasibility assessment (03_feasibility.md, Alternative D), the primary analysis expands the exposure to the SGLT2i class (canagliflozin + empagliflozin + dapagliflozin, ~9,833 patients total). A canagliflozin-only subgroup analysis is pre-specified as a descriptive sensitivity analysis.

---

## 2. Target Trial Specification

### 2.1 Eligibility Criteria

**Inclusion:**

1. Adults aged ≥18 years at time zero
2. Type 2 diabetes diagnosis: at least one ICD-10 E11.x code (DX_TYPE = '10') on or before the index date
3. New initiation of an SGLT2 inhibitor, DPP-4 inhibitor, or 2nd-generation sulfonylurea during the study period (2016-01-01 to 2025-12-31)
4. No prior prescription of the same drug class during a 180-day washout period before the index prescription
5. Continuous enrollment for ≥180 days before time zero (ENR_START_DATE ≤ index_date − 180 days)

**Exclusion:**

| Criterion | Data Source | Codes |
|-----------|-----------|-------|
| Type 1 diabetes | CDW.dbo.DIAGNOSIS | E10.x (DX_TYPE = '10') any time ≤ index |
| Gestational diabetes | CDW.dbo.DIAGNOSIS | O24.x any time |
| ESRD or dialysis | CDW.dbo.DIAGNOSIS + PROCEDURES | N18.6, Z99.2; CPT 90935–90940 before index |
| Active malignancy (past 12 months) | CDW.dbo.DIAGNOSIS | C00–C97 within 365 days before index |
| Concurrent initiation of both SGLT2i and DPP-4i on the same day | CDW.dbo.PRESCRIBING | Same-day prescriptions for both classes |
| Age < 18 at index date | CDW.dbo.DEMOGRAPHIC | DATEDIFF(year, BIRTH_DATE, index_date) < 18 |

### 2.2 Treatment Strategies

**Strategy A (Treatment) — SGLT2 Inhibitor Class:**
- Canagliflozin (Invokana, Invokamet, Invokamet XR)
- Empagliflozin (Jardiance, Synjardy, Synjardy XR)
- Dapagliflozin (Farxiga, Xigduo XR)

Identified via RXNORM_CUI in CDW.dbo.PRESCRIBING. See Appendix A of 03_feasibility.md for validated RxCUI code lists.

**Strategy B (Primary Comparator) — DPP-4 Inhibitor Class:**
- Sitagliptin (Januvia, Zituvio)
- Linagliptin (Tradjenta)
- Saxagliptin (Onglyza)
- Alogliptin (Nesina)

**Strategy C (Secondary Comparator) — 2nd-Generation Sulfonylureas:**
- Glipizide (Glucotrol)
- Glimepiride (Amaryl)
- Glyburide (Glynase)

**New-user design:** Patients must have no prescription for the same drug class during the 180-day washout period before their qualifying index prescription. Patients are permitted to take other antidiabetic medications during the study, consistent with the CANVAS trial design. Each patient enters the cohort at the date of their first initiation across all three study drug classes; assignment is to the class initiated at that date.

### 2.3 Treatment Assignment Procedure

Assignment is determined by the drug class initiated at time zero (active comparator new-user design). Randomization is emulated via propensity score overlap weighting. The propensity score model includes all measured confounders listed in Section 4.2. A separate PS model is fitted for each pairwise comparison (SGLT2i vs DPP-4i; SGLT2i vs SU).

### 2.4 Outcome

**Primary outcome — 3-Point MACE (composite, first occurrence):**

| Component | Data Source | ICD-10 Codes | Encounter Restriction |
|-----------|-----------|-------------|----------------------|
| Nonfatal myocardial infarction | DIAGNOSIS + ENCOUNTER | I21.x (excl I21.A1 type 2 MI, I21.A9, I21.B); I22.x (subsequent MI) | ENC_TYPE IN ('IP','EI','ED'); RAW_ENC_TYPE ≠ 'Legacy Encounter' |
| Nonfatal ischemic stroke | DIAGNOSIS + ENCOUNTER | I63.x | ENC_TYPE IN ('IP','EI','ED'); RAW_ENC_TYPE ≠ 'Legacy Encounter' |
| Cardiovascular death | DEATH + DEATH_CAUSE | DEATH_CAUSE: I20–I25, I46, I50, I60–I69, I71 (DEATH_CAUSE_CODE = '10') | DEATH table deduplicated via ROW_NUMBER() |

The first occurrence of any component after time zero defines the event. Type 2 MI (I21.A1, demand ischemia) is excluded from the primary definition for consistency with the CANVAS trial methodology; included in sensitivity analysis.

**Secondary outcomes:**
- Individual MACE components (CV death, MI, stroke analyzed separately)
- Hospitalization for heart failure (I50.x on IP/EI encounter)
- All-cause mortality

**Safety outcomes:**
- Lower-extremity amputation (CPT 27590–27598, 27880–27889, 28800, 28805, 28810, 28820, 28825)
- Diabetic ketoacidosis (E11.10, E11.11, E13.10, E13.11)
- Genital mycotic infections (B37.31, B37.32, B37.42, B37.49, N76.0, N77.1, N48.1)
- Acute kidney injury (N17.x)

### 2.5 Time Zero

**Time zero = date of the first qualifying prescription** (RX_ORDER_DATE) for the study drug in a patient meeting all eligibility criteria.

**Justification:** The prescribing decision point represents the moment of treatment assignment in the active comparator new-user design. Eligibility, treatment assignment, and time zero coincide — eliminating immortal time bias. Follow-up begins the day after time zero (index_date + 1 day), consistent with the CANVAS trial design and the study description specification.

### 2.6 Causal Contrast and Estimand

**Estimand:** Average Treatment Effect in the Overlap population (ATO), implemented via overlap weights. Overlap weights assign each patient a weight proportional to the probability of being assigned to the opposite treatment group (w = 1 − PS for treated, w = PS for control), naturally downweighting patients at the extremes of the PS distribution. This provides robustness against extreme propensity scores and positivity violations near the tails, which is particularly important given the expected imbalance in arm sizes.

**Causal contrast:** The causal effect of initiating an SGLT2 inhibitor versus initiating a DPP-4 inhibitor on the hazard of 3-point MACE, in the population of adults with T2D who are clinically eligible for either drug class.

**Primary analysis (ITT):** Patients are followed from time zero regardless of subsequent treatment changes (discontinuation, switching, augmentation), reflecting the effect of a treatment initiation policy.

### 2.7 Follow-up Period

Follow-up begins the day after time zero (index_date + 1) and continues until the earliest of:

1. 3P-MACE event
2. Death from non-cardiovascular cause (censoring event)
3. End of continuous enrollment (ENR_END_DATE)
4. End of study period (2025-12-31)
5. 5 years (1,825 days) from time zero

**As-treated sensitivity analysis:** Additionally censors at treatment discontinuation + 30-day grace period. Treatment duration estimated from RX_END_DATE (47.6% populated), else RX_DAYS_SUPPLY (42.8%), else 90-day default assumption.

---

## 3. Emulation Using Observational Data

### 3.1 Target Dataset

| Parameter | Value |
|-----------|-------|
| Database | PCORnet Clinical Data Warehouse v6.1 |
| Engine | Microsoft SQL Server |
| Schema | CDW.dbo |
| Study period | 2016-01-01 to 2025-12-31 |
| T2D patients | ~242,522 (E11.x) |
| SGLT2i patients | ~9,833 (canagliflozin 142 + empagliflozin 6,526 + dapagliflozin 3,165) |
| DPP-4i patients | Estimated 8,000–20,000 |
| SU patients | Estimated 15,000–35,000 |

**Justification for class-level analysis:** The CDW contains only 142 canagliflozin patients. With an expected ~5–6 MACE events, canagliflozin-specific analysis is not feasible. Expanding to the SGLT2i class yields ~9,833 patients with an estimated 4,000–7,000 new users after eligibility criteria, providing adequate power for MACE analysis. This approach is consistent with published class-level analyses (CVD-REAL, EASEL, Xie et al. 2023 TTE).

### 3.2 Variable Mapping

| Protocol Concept | PCORnet Table | Column(s) | Codes / Values |
|---|---|---|---|
| **Population** | | | |
| T2D diagnosis | DIAGNOSIS | DX, DX_TYPE | E11.x (DX_TYPE = '10') |
| Age | DEMOGRAPHIC | BIRTH_DATE | DATEDIFF(year, BIRTH_DATE, index_date) |
| Sex | DEMOGRAPHIC | SEX | F, M |
| Race | DEMOGRAPHIC | RACE | PCORnet coded (01–07, NI, UN, OT) |
| Hispanic ethnicity | DEMOGRAPHIC | HISPANIC | Y, N, NI, UN, OT, R |
| Enrollment | ENROLLMENT | ENR_START_DATE, ENR_END_DATE | ≥180 days before index |
| **Exposure** | | | |
| SGLT2i initiation | PRESCRIBING | RXNORM_CUI | See 03_feasibility.md Appendix A.1–A.4 |
| DPP-4i initiation | PRESCRIBING | RXNORM_CUI | See 03_feasibility.md Appendix A.5 |
| SU initiation | PRESCRIBING | RXNORM_CUI | See 03_feasibility.md Appendix A.6 |
| Time zero | PRESCRIBING | RX_ORDER_DATE | First qualifying Rx date |
| **Outcomes** | | | |
| Nonfatal MI | DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I21.x (excl I21.A1,A9,B) on IP/EI/ED |
| Nonfatal stroke | DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I63.x on IP/EI/ED |
| CV death | DEATH + DEATH_CAUSE | DEATH_DATE, DEATH_CAUSE | CV cause codes (I20–I25, I46, I50, I60–I69, I71) |
| All-cause death | DEATH | DEATH_DATE | Deduplicated with ROW_NUMBER() |
| HHF | DIAGNOSIS + ENCOUNTER | DX, ENC_TYPE | I50.x on IP/EI |
| **Confounders — Vitals** | | | |
| BMI | VITAL | ORIGINAL_BMI | Most recent in 365-day lookback |
| Systolic BP | VITAL | SYSTOLIC | Most recent in 365-day lookback |
| Diastolic BP | VITAL | DIASTOLIC | Most recent in 365-day lookback |
| **Confounders — Labs** | | | |
| HbA1c | LAB_RESULT_CM | LAB_LOINC | 4548-4 |
| Serum creatinine | LAB_RESULT_CM | LAB_LOINC | 2160-0 |
| eGFR | LAB_RESULT_CM | LAB_LOINC | 48642-3 (primary), 33914-3 (fallback) |
| Total cholesterol | LAB_RESULT_CM | LAB_LOINC | 2093-3 |
| LDL cholesterol | LAB_RESULT_CM | LAB_LOINC | 13457-7 |
| HDL cholesterol | LAB_RESULT_CM | LAB_LOINC | 2085-9 |
| Triglycerides | LAB_RESULT_CM | LAB_LOINC | 2571-8 |
| Hemoglobin | LAB_RESULT_CM | LAB_LOINC | 718-7 |
| Potassium | LAB_RESULT_CM | LAB_LOINC | 2823-3 |
| ALT | LAB_RESULT_CM | LAB_LOINC | 1742-6 |
| **Confounders — Comorbidities** | | | |
| Hypertension | DIAGNOSIS | DX | I10, I11.x–I16.x |
| Heart failure | DIAGNOSIS | DX | I50.x |
| Atrial fibrillation | DIAGNOSIS | DX | I48.x |
| CKD (non-ESRD) | DIAGNOSIS | DX | N18.1–N18.5, N18.9 |
| Prior MI | DIAGNOSIS | DX | I21.x, I25.2 |
| Prior stroke | DIAGNOSIS | DX | I63.x, Z86.73, I69.3x |
| COPD | DIAGNOSIS | DX | J44.x |
| Obesity | DIAGNOSIS | DX | E66.x |
| Dyslipidemia | DIAGNOSIS | DX | E78.x |
| PAD / PVD | DIAGNOSIS | DX | I70.x, I73.9 |
| VTE / PE | DIAGNOSIS | DX | I26.x, I82.x |
| Tobacco use disorder | DIAGNOSIS | DX | F17.x, Z72.0, Z87.891 (proxy for smoking) |
| **Confounders — Concomitant Medications** (180-day lookback) | | | |
| Metformin | PRESCRIBING | RAW_RX_MED_NAME | LIKE '%metformin%' |
| Insulin | PRESCRIBING | RAW_RX_MED_NAME | LIKE '%insulin%' |
| Statin | PRESCRIBING | RAW_RX_MED_NAME | Individual statin generic names |
| ACE inhibitor / ARB | PRESCRIBING | RAW_RX_MED_NAME | Individual ACEi/ARB generic names |
| Beta-blocker | PRESCRIBING | RAW_RX_MED_NAME | Individual beta-blocker generic names |
| Antiplatelet | PRESCRIBING | RAW_RX_MED_NAME | clopidogrel, ticagrelor, prasugrel |

### 3.3 Database-Specific Conventions Applied

All conventions from `secure_pcornet_cdw_conventions.md` are applied:

1. **Legacy encounter filtering:** All encounter-linked queries exclude `RAW_ENC_TYPE = 'Legacy Encounter'` (duplicate AllScripts records from EHR migration)
2. **Date quality guards:** All date columns bounded to realistic range (≥2005-01-01, ≤GETDATE()) to exclude junk dates (1820–3019 range in CDW)
3. **DEATH table deduplication:** `ROW_NUMBER() OVER (PARTITION BY PATID ORDER BY DEATH_DATE)` with `rn = 1`
4. **ROW_NUMBER on all LEFT JOINs:** Vitals, labs, enrollment use ROW_NUMBER to guarantee one row per patient
5. **Column name normalization:** `names(df) <- tolower(names(df))` after every `dbGetQuery()`
6. **ODBC batch bug mitigation:** Separate `dbExecute()` for DDL and `dbGetQuery()` for SELECT
7. **COUNT(DISTINCT PATID):** Used instead of `COUNT(*)` for temp table counts to detect row duplication from JOINs
8. **ICD-10 only:** Study period starts 2016-01-01; `DX_TYPE = '10'` only
9. **Table qualification:** All tables fully qualified as `CDW.dbo.TABLE_NAME`
10. **Dynamic PS formula:** Single-level factors and zero-variance columns dropped before model fitting

### 3.4 CONSORT Flow Diagram

The analysis script produces both text and visual CONSORT flow diagrams. Expected flow:

1. Patients with T2D diagnosis (E11.x) in CDW: ~242,522
2. Prescriptions for SGLT2i, DPP-4i, or SU in study period (2016–2025): [computed at execution]
3. New users (180-day washout, first class initiated): [computed]
4. Meet enrollment criterion (≥180 days continuous): [computed]
5. Meet age criterion (≥18): [computed]
6. Exclude T1D, GDM, ESRD, active cancer, same-day ties: [computed]
7. Final eligible cohort: [computed]
   - SGLT2i arm: [N]
   - DPP-4i arm: [N]
   - SU arm: [N]

---

## 4. Statistical Analysis Plan

### 4.1 Primary Analysis: IPTW with Overlap Weights

**Method:** Inverse probability of treatment weighting using propensity score overlap weights, implemented via `WeightIt::weightit()` with `method = "glm"` and `estimand = "ATO"`.

**Outcome model:** Weighted Cox proportional hazards regression with robust (sandwich) standard errors:
```
coxph(Surv(time_to_event, event) ~ treatment, data = cohort, weights = ipw, robust = TRUE)
```

**Effect measure:** Hazard ratio (HR) with 95% confidence interval.

### 4.2 Confounder Set and DAG Justification

Each confounder is justified as a common cause of treatment choice and MACE risk, or as a proxy for unmeasured confounders that satisfy this criterion.

| Confounder | DAG Role | Justification |
|---|---|---|
| Age | Common cause | Older age increases MACE risk; prescribing patterns vary by age |
| Sex | Common cause | CV risk profiles differ by sex; may influence drug choice |
| Race | Common cause | CV risk varies by race; healthcare access affects prescribing |
| Hispanic ethnicity | Common cause | Correlated with CV risk factors and healthcare access |
| BMI | Common cause | Obesity increases CV risk; SGLT2i preferred for weight benefit |
| Systolic BP | Common cause | Hypertension is a major MACE risk factor; BP level may influence drug choice |
| Diastolic BP | Common cause | Complementary CV risk indicator |
| HbA1c | Common cause | Glycemic control influences both drug selection and CV risk |
| Serum creatinine / eGFR | Common cause | Renal function determines SGLT2i eligibility and affects CV risk |
| Lipid panel (TC, LDL, HDL, TG) | Outcome risk factor | Lipid levels are independent CV risk factors; may reflect CV risk awareness affecting prescribing |
| Hemoglobin | Proxy | Anemia associated with CKD severity and CV risk burden |
| Potassium | Proxy | Electrolyte abnormalities reflect renal/cardiac comorbidity |
| ALT | Proxy | Liver disease affects drug metabolism and overall comorbidity burden |
| Hypertension | Common cause | Major MACE risk factor; well-known confounder in CV pharmacoepi |
| Heart failure | Common cause | HF strongly predicts MACE; SGLT2i specifically indicated for HF per guidelines |
| Atrial fibrillation | Common cause | AF increases stroke risk (MACE component); may influence drug choice |
| CKD | Common cause | Renal function determines SGLT2i eligibility and is a strong CV risk factor |
| Prior MI | Common cause | Prior MI is the strongest predictor of recurrent MACE; likely drives SGLT2i preference |
| Prior stroke | Common cause | Prior cerebrovascular events predict recurrent stroke |
| COPD | Common cause | Respiratory comorbidity increases CV risk and affects treatment decisions |
| Obesity | Common cause | Captures coded diagnosis; SGLT2i preferred for weight reduction |
| Dyslipidemia | Common cause | Lipid disorder diagnosis signals recognized CV risk |
| PAD | Common cause | ASCVD marker; canagliflozin amputation signal may deter SGLT2i in PAD patients |
| VTE/PE | Common cause | Thromboembolic risk increases CV event likelihood |
| Tobacco use | Common cause | Strongest modifiable CV risk factor; coded diagnoses proxy for active smoking |
| Concomitant metformin | Treatment intensity marker | Background therapy level |
| Concomitant insulin | Disease severity marker | Insulin use signals advanced T2D with higher CV risk |
| Concomitant statin | CV risk management marker | Statin use proxies recognized and treated CV risk |
| Concomitant ACEi/ARB | CV risk management marker | RAAS inhibitor use signals recognized CV/renal risk |
| Concomitant beta-blocker | CV comorbidity marker | Beta-blocker use suggests HF, CAD, or arrhythmia |
| Concomitant antiplatelet | ASCVD marker | Antiplatelet therapy proxies recognized atherosclerotic disease |

**Variables not included (with justification):**

| Variable | Reason for Exclusion |
|----------|---------------------|
| Smoking (VITAL.SMOKING) | 99.8% unknown/missing; tobacco use disorder codes from DIAGNOSIS used as proxy |
| LVEF | Not available as structured data; HF ICD-10 subtypes (I50.2x vs I50.3x) serve as partial proxy |
| Insurance/payer | PAYER_TYPE_PRIMARY is 0% populated in this CDW |
| NT-proBNP | Only 4,714 patients with values; too sparse for routine PS adjustment |
| OTC aspirin | Not captured in PRESCRIBING; antiplatelet variable underestimates true use |
| Duration of diabetes | Derivable from first E11.x but imprecise; measurement error risk outweighs benefit |
| Albuminuria/UACR | Not available in top LOINCs; CKD characterization limited to eGFR staging |

### 4.3 Propensity Score Model

Logistic regression predicting probability of SGLT2i initiation versus comparator:

```
P(SGLT2i = 1 | X) = logit⁻¹(β₀ + β₁·age + β₂·sex + ... + βₖ·Xₖ)
```

The formula is constructed dynamically in R: single-level factors and zero-variance columns are identified and dropped before fitting to prevent model convergence failures (per CDW conventions). Continuous confounders with missing values are imputed with the median.

### 4.4 Balance Diagnostics

- **Pre-weighting SMDs:** Computed for all covariates via `bal.tab(weights, un = TRUE)`
- **Post-weighting SMDs:** Target < 0.10 (threshold of adequate balance)
- **Love plot:** `love.plot(weights, threshold = 0.1, abs = TRUE, un = TRUE)` displays pre- vs post-weighting balance
- **PS distribution:** Density plots of propensity scores by treatment group to assess overlap

If any post-weighting SMD exceeds 0.10, the PS model is revised (e.g., adding quadratic terms or interactions).

### 4.5 Secondary Analysis: SGLT2i Class vs 2nd-Generation Sulfonylureas

The same analysis framework is applied with sulfonylureas as the comparator. A separate PS model is fitted. The SGLT2i arm is the same patients as in the primary comparison (patients whose first initiation across all three classes was SGLT2i).

**Rationale:** SU are a widely used second-line T2D therapy. The study description specifies SU as the secondary comparator. Xie et al. 2023 found SGLT2i vs SU MACE HR 0.77 (0.74–0.80). SU may carry independent CV risk (hypoglycemia, weight gain).

### 4.6 Sensitivity Analyses

| Analysis | Modification | Rationale |
|---|---|---|
| Canagliflozin-only subgroup | Restrict SGLT2i arm to canagliflozin initiators (N ~80–120) | Addresses the original study question; expected to be descriptive and underpowered |
| As-treated analysis | Censor at treatment discontinuation + 30-day grace period | Per-protocol effect; addresses treatment switching |
| All-cause mortality in MACE | Replace CV death with all-cause death in composite | Addresses potentially incomplete DEATH_CAUSE data |
| Include type 2 MI | Add I21.A1 to MI definition | Sensitivity to MI coding variations |
| Exclude saxagliptin | Remove saxagliptin users from DPP-4i arm | Saxagliptin's unique HHF signal (SAVOR-TIMI 53 HR 1.27) may bias the DPP-4i arm toward worse CV outcomes |
| E-value | Compute E-value for the primary HR | Quantifies minimum unmeasured confounding strength needed to explain the observed association |
| PS matching | 1:1 nearest-neighbor PS matching via MatchIt | Alternative estimation approach for robustness check |

### 4.7 Pre-Specified Subgroup Analyses

| Subgroup | Definition | Clinical Rationale |
|---|---|---|
| Age ≥65 vs <65 | age_at_index dichotomized | CANVAS enrolled patients aged 30+; elderly are at higher CV risk |
| Sex (male vs female) | DEMOGRAPHIC.SEX | CV risk profiles and treatment responses differ by sex |
| Prior ASCVD (yes vs no) | I25.x, I21.x history, I70.x, I73.9, Z86.73 before index | CANVAS enrolled 65.6% with CVD history; benefit may be larger in secondary prevention |
| CKD (yes vs no) | N18.x (excl N18.6) or eGFR < 60 before index | CREDENCE showed canagliflozin renal/CV benefit in CKD; eGFR may modify SGLT2i effect |

Each subgroup analysis re-estimates the IPTW Cox model within the subgroup. Results are displayed in a forest plot. Treatment-by-subgroup interaction p-values are computed from the full cohort model.

### 4.8 Grace Period and Treatment Duration

**Treatment duration estimation (hierarchical):**
1. RX_END_DATE when populated (47.6% of records)
2. RX_ORDER_DATE + RX_DAYS_SUPPLY when populated (42.8%)
3. RX_ORDER_DATE + 90 days (default outpatient prescription duration)

**Grace period:** 30 days added to the estimated end of the last prescription to account for gaps between refills.

**Persistent treatment:** A patient is considered on-treatment as long as consecutive prescriptions overlap or gaps between prescriptions are ≤30 days (grace period).

---

## 5. Limitations and Threats to Validity

### 5.1 Confounding

- **Unmeasured confounders:** Smoking status (VITAL.SMOKING 99.8% missing), left ventricular ejection fraction, socioeconomic status, insurance type (0% populated), OTC aspirin use, physical activity, diet, and frailty. Tobacco use disorder codes are an imperfect proxy for active smoking status.
- **Channeling bias:** SGLT2i may be preferentially prescribed to patients with established CVD or HF (guideline-concordant prescribing), creating confounding by indication. The PS model includes CV comorbidities and CV medications to address this, but residual confounding is possible.
- **Time-varying confounding:** The ITT analysis does not account for post-baseline changes in concomitant medications or clinical status. The as-treated sensitivity analysis partially addresses this.
- **E-value sensitivity analysis** quantifies the minimum strength of an unmeasured confounder (in terms of its associations with treatment and outcome) needed to explain away the observed association.

### 5.2 Exposure Measurement

- **Class-level analysis:** The primary analysis combines three SGLT2i molecules with different selectivity profiles, trial evidence, and safety signals. Within-class heterogeneity may exist (e.g., canagliflozin's unique amputation signal). The canagliflozin subgroup analysis is pre-specified but expected to be underpowered (~80–120 patients, ~5–6 MACE events).
- **Treatment duration uncertainty:** RX_END_DATE and RX_DAYS_SUPPLY are each populated in fewer than 50% of records. The 90-day default assumption may misclassify treatment duration for both arms.
- **Combination products:** Empagliflozin/metformin (Synjardy) and dapagliflozin/metformin (Xigduo XR) combination RxCUIs are included but were not validated via MCP tools during the feasibility phase. Canagliflozin combination codes (Invokamet) were validated.
- **Cross-class combinations excluded:** Glyxambi (empagliflozin/linagliptin) and Qtern (dapagliflozin/saxagliptin) contain both SGLT2i and DPP-4i components. Patients on these products are not captured in either arm.

### 5.3 Outcome Measurement

- **CV death ascertainment:** DEATH_CAUSE completeness is unknown. If sparsely populated, the CV death component of MACE will be systematically undercounted. The all-cause mortality sensitivity analysis addresses this limitation.
- **MI/stroke coding accuracy:** ICD-10 codes in EHR data have imperfect sensitivity and specificity for acute MI and ischemic stroke. No chart review validation is available for this CDW. The positive predictive value of I21.x for acute MI in administrative data is estimated at 85–95%.
- **Type 2 MI exclusion:** I21.A1 (demand ischemia) is excluded from the primary MACE definition. This code was introduced in ICD-10-CM 2018 and may be inconsistently applied, potentially affecting sensitivity analysis results.

### 5.4 Selection and Information Bias

- **Single-institution CDW:** Results reflect prescribing patterns and patient populations at one institution and may not generalize to other settings.
- **Healthy user bias:** Patients initiating newer drug classes (SGLT2i) may be systematically different from those prescribed older agents (DPP-4i, SU), despite PS adjustment.
- **Temporal prescribing trends:** SGLT2i prescribing increased dramatically after CVOT publications (2015–2019). Early SGLT2i adopters may differ from later adopters. Calendar year is implicitly captured through baseline covariate patterns.

### 5.5 Statistical Considerations

- **Multiple comparisons:** Primary comparison (vs DPP-4i) and secondary comparison (vs SU) increase false discovery risk. The secondary comparison should be interpreted as supportive evidence, not a confirmatory analysis.
- **Positivity violations:** Despite overlap weights mitigating extreme PS values, some covariate strata may have near-zero probability of receiving SGLT2i, particularly in the early study period or among patients with advanced CKD.
- **Proportional hazards assumption:** The Cox model assumes a constant HR over follow-up time. If the treatment effect varies over time (e.g., delayed benefit), this assumption may be violated. Schoenfeld residuals should be examined.

---

## 6. References

1. Neal B et al. Canagliflozin and cardiovascular and renal events in type 2 diabetes. NEJM 2017;377:644-657. PMID 28605608.
2. Zinman B et al. Empagliflozin, cardiovascular outcomes, and mortality in type 2 diabetes. NEJM 2015;373:2117-2128. PMID 26378978.
3. Wiviott SD et al. Dapagliflozin and cardiovascular outcomes in type 2 diabetes. NEJM 2019;380:347-357. PMID 30415602.
4. Perkovic V et al. Canagliflozin and renal outcomes in type 2 diabetes and nephropathy. NEJM 2019;380:2295-2306. PMID 30990260.
5. Scirica BM et al. Saxagliptin and cardiovascular outcomes in patients with type 2 diabetes mellitus. NEJM 2013;369:1317-1326. PMID 23992601.
6. Green JB et al. Effect of sitagliptin on cardiovascular outcomes in type 2 diabetes. NEJM 2015;373:232-242. PMID 27437883.
7. Rosenstock J et al. Effect of linagliptin vs glimepiride on major adverse cardiovascular outcomes in patients with type 2 diabetes. JAMA 2019;322:1155-1166. PMID 31536101.
8. D'Andrea E et al. Cardiovascular outcomes of SGLT2 inhibitors vs DPP-4 inhibitors by baseline HbA1c. JAMA Intern Med 2023;183:1050-1060. PMID 36745425.
9. Htoo PT et al. Cardiovascular effects of empagliflozin in type 2 diabetes: final results of EMPRISE. Diabetologia 2024;67:495-509. PMID 38509341.
10. Xie Y et al. Comparative effectiveness of SGLT2 inhibitors, GLP-1 receptor agonists, DPP-4 inhibitors, and sulfonylureas on risk of major adverse cardiovascular events: emulation of a randomised target trial using electronic health records. Lancet Diabetes Endocrinol 2023;11:644-656. PMID 37499675.
11. Kosjerina V et al. Comparative cardiovascular effectiveness of GLP-1 receptor agonists, SGLT-2 inhibitors, and DPP-4 inhibitors in older adults with type 2 diabetes. eClinicalMedicine 2025;79:103029. PMID 40201798.
12. Hernan MA, Robins JM. Using big data to emulate a target trial when a randomized trial is not available. Am J Epidemiol 2016;183:758-764.
