# Evidence Gaps: Atrial Fibrillation

## Ranked Candidate Causal Questions

Based on the three-pass literature search (82 papers reviewed, 7 existing AF TTE
studies identified), the following 5 questions are ranked by evidence gap score.
Each is framed as a causal contrast suitable for target trial emulation.

---

### Q1: Early Rhythm Control vs Rate Control in Newly Diagnosed AF

**Gap Score: 8/10**

#### PICO Formulation

| Element | Specification |
|---------|--------------|
| **Population** | Adults with newly diagnosed AF (≤12 months), ≥1 stroke risk factor (CHA₂DS₂-VASc ≥2), no prior rhythm control |
| **Intervention** | Early rhythm control (AADs or catheter ablation) initiated within 12 months of diagnosis |
| **Comparator** | Usual care (rate control + anticoagulation only) |
| **Outcome** | Composite of CV death, stroke, HF hospitalization, ACS hospitalization (primary); all-cause mortality, stroke (secondary) |
| **Time zero** | Date of AF diagnosis (or index encounter) |
| **Follow-up** | 5 years |

#### Causal Contrast

*What is the effect of initiating early rhythm control (AADs or ablation) within 12 months of AF diagnosis, compared to usual care with rate control only, on the composite of CV death, stroke, and HF/ACS hospitalization?*

**Estimand:** ATE (intention to treat the strategy)

#### Evidence Gap Rationale

EAST-AFNET 4 (Kirchhof 2020, PMID 32865375) demonstrated HR 0.79 for the
composite with early rhythm control. Multiple real-world observational
validations exist (Dickow 2023, PMID 36942567; Chao 2022, PMID 35322396;
Gu 2024, PMID 38964555 meta-analysis: HR 0.86). However, **no study has applied
the formal target trial emulation framework** to this question. All existing
observational studies use propensity score weighting/matching without explicit
specification of the target trial protocol elements (eligibility, treatment
strategies, assignment, time zero, causal contrast).

A TTE would add value by:
1. Explicitly addressing immortal time bias (which some PS studies may not fully handle)
2. Enabling per-protocol analyses using clone-censor-weight approach
3. Exploring subgroups underpowered in EAST-AFNET 4 (e.g., age >80, HFpEF, CKD)
4. Using US claims/EHR data to replicate a European RCT

#### TTE Suitability: VERY HIGH

- Clear target trial to emulate (EAST-AFNET 4 protocol published)
- Time zero well-defined (AF diagnosis date)
- Treatment strategies identifiable in claims (AAD prescriptions, ablation procedures)
- Outcome definitions map cleanly to ICD/procedure codes
- Large eligible populations in US claims databases

#### Supporting PMIDs

32865375, 34447995, 38727662, 36942567, 35322396, 38964555, 40052479,
40551338, 41317034, 30874766

#### Search Completeness Checklist

- [x] At least one narrow PICO-specific search was run
- [x] Abstracts fetched for all targeted search results
- [x] Citation chaining done (Dickow → Gu meta-analysis → national cohorts)
- [x] "No TTE exists" claim stress-tested: searched PubMed for "rhythm control" + "target trial emulation" AND WebSearch; confirmed no TTE
- [x] Self-consistency check: none of the cited papers use TTE framework
- [x] Specialty journal coverage: searched electrophysiology and general cardiology literature

---

### Q2: Catheter Ablation vs Antiarrhythmic Drugs in AF + HFpEF

**Gap Score: 8/10**

#### PICO Formulation

| Element | Specification |
|---------|--------------|
| **Population** | Adults with AF and HFpEF (LVEF ≥50%), on stable HF medications |
| **Intervention** | Catheter ablation for AF |
| **Comparator** | Antiarrhythmic drug therapy (rhythm or rate control) |
| **Outcome** | Composite of all-cause death + HF hospitalization (primary); all-cause mortality, CV death, HF hospitalization, stroke (secondary) |
| **Time zero** | Date of ablation/AAD initiation |
| **Follow-up** | 3 years |

#### Causal Contrast

*What is the effect of catheter ablation, compared to antiarrhythmic drug therapy, on the composite of all-cause death and heart failure hospitalization in patients with AF and HFpEF?*

**Estimand:** ATE

#### Evidence Gap Rationale

No completed RCT addresses this question directly. CASTLE-AF (Marrouche 2018,
PMID 29385358) proved ablation's benefit in HFrEF; CABANA (Packer 2019) was
underpowered for HFpEF. The CABANA HFpEF subanalysis (Martens 2025,
PMID 40243977) showed trends toward benefit but wide CIs. CABA-HFPEF-DZHK27
(PMID 39023141) is an ongoing RCT but results are not expected until 2027–2028.

Observational studies show strong signals: DeLuca 2025 (PMID 39447815, mortality
HR 0.43), meta-analyses by Bulhões 2024 (HR 0.62) and Wani 2025 (HR 0.53).
**None of these use target trial emulation.** All rely on PS matching/weighting.

A TTE is particularly valuable here because:
1. RCT data won't be available for 2+ years
2. Observational studies haven't addressed immortal time bias or crossover systematically
3. The causal question has strong clinical equipoise
4. A well-designed TTE could help estimate treatment effect magnitude pending RCT

#### TTE Suitability: HIGH (with caveats)

- Time zero defined as ablation/AAD initiation date
- Treatment strategies identifiable via CPT codes (ablation) and Rx claims (AADs)
- Challenge: HFpEF diagnosis in claims requires validation (ICD + echo data); risk of misclassification
- Challenge: High crossover rate expected (patients failing AADs → ablation)
- Clone-censor-weight approach needed for sustained treatment strategy

#### Supporting PMIDs

29385358, 30874766, 33554614, 40243977, 39447815, 38621498, 41426236,
41606998, 41669949, 39023141

#### Search Completeness Checklist

- [x] At least one narrow PICO-specific search was run
- [x] Abstracts fetched for all targeted search results
- [x] Citation chaining done (CABANA → Martens → DeLuca → meta-analyses)
- [x] "No TTE exists" claim stress-tested: WebSearch confirmed no TTE for ablation in HFpEF
- [x] Self-consistency check: none of cited papers use TTE
- [x] Specialty journal coverage: searched EP journals (Heart Rhythm, JCE, Europace)

---

### Q3: Apixaban vs Rivaroxaban in AF + Advanced CKD (eGFR <30)

**Gap Score: 7/10**

#### PICO Formulation

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF and eGFR <30 mL/min/1.73m² (or on dialysis), new OAC users |
| **Intervention** | Apixaban initiation |
| **Comparator** | Rivaroxaban initiation |
| **Outcome** | Major bleeding (primary); stroke/SE, all-cause mortality, GI bleeding, intracranial hemorrhage (secondary) |
| **Time zero** | Date of first OAC dispensing |
| **Follow-up** | 2 years |

#### Causal Contrast

*What is the effect of initiating apixaban, compared to rivaroxaban, on major bleeding risk in patients with AF and advanced CKD (eGFR <30)?*

**Estimand:** ATE (intention-to-treat equivalent for new-user active-comparator)

#### Evidence Gap Rationale

Patients with eGFR <30 were excluded from ALL pivotal DOAC trials (RE-LY,
ROCKET-AF, ARISTOTLE, ENGAGE AF-TIMI 48). No head-to-head RCT comparing any
two DOACs exists in any population.

Multiple observational studies provide converging evidence:
- Fu 2024 (PMID 37839687): Rivaroxaban vs apixaban, bleeding HR 1.69 in advanced CKD
- Xu 2024 (PMID 39119973): Apixaban vs rivaroxaban, bleeding sub-HR 0.53 in eGFR <30
- Binding 2024 (PMID 38402466): Rivaroxaban vs apixaban, bleeding HR 1.78 in eGFR 30–49

**None of these use TTE.** All use PS-matched or IPW new-user active-comparator
designs. While the new-user design is a component of TTE, a formal TTE would:
1. Explicitly define the target trial being emulated (e.g., a hypothetical head-to-head RCT)
2. Handle treatment switching/discontinuation with sustained treatment strategies
3. Use clone-censor-weight or sequential nested trials for per-protocol effects
4. Provide estimands beyond ITT (e.g., per-protocol effect, effect modification by eGFR strata)

#### TTE Suitability: HIGH

- Time zero and new-user design are standard for this question
- Active comparator eliminates confounding by indication (both drugs treat the same condition)
- Outcome definitions are well-validated in claims data (ICD + hospitalization)
- eGFR available in EHR-linked databases (not always in pure claims)
- PCORnet CDM databases with lab results would be ideal

#### Supporting PMIDs

37839687, 39119973, 38230301, 38402466, 41438731, 41292445, 33538928,
36335914, 33753537, 41085503, 38606775

#### Search Completeness Checklist

- [x] At least one narrow PICO-specific search was run (two run)
- [x] Abstracts fetched for all targeted search results
- [x] Citation chaining done (Fu → Xu → Binding concurrent studies)
- [x] "No TTE exists" claim stress-tested: WebSearch confirmed Fu 2024 is PS-matched, not TTE
- [x] Self-consistency check: none of cited papers use TTE
- [x] Specialty journal coverage: searched nephrology journals (AJKD, JASN, CJASN)

---

### Q4: DOACs vs Warfarin in AF + Liver Cirrhosis

**Gap Score: 7/10**

#### PICO Formulation

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF and compensated or decompensated liver cirrhosis, new OAC users |
| **Intervention** | DOAC initiation (apixaban or rivaroxaban) |
| **Comparator** | Warfarin initiation |
| **Outcome** | Composite of ischemic stroke/SE + major bleeding (primary); individual components, all-cause mortality, GI bleeding, ICH (secondary) |
| **Time zero** | Date of first OAC dispensing |
| **Follow-up** | 2 years |

#### Causal Contrast

*What is the effect of initiating a DOAC (apixaban or rivaroxaban), compared to warfarin, on the composite of ischemic stroke/SE and major bleeding in patients with AF and liver cirrhosis?*

**Estimand:** ATE

#### Evidence Gap Rationale

Cirrhosis patients were excluded from ALL pivotal DOAC trials. The evidence base
is growing rapidly:
- Simon 2024 (PMID 38976880): Apixaban superior on bleeding, similar stroke/SE vs warfarin
- Lawal 2023 (PMID 36762560): Apixaban HR 0.40 for stroke/SE, HR 0.60 for bleeding
- Douros 2024 (PMID 38552497): Apixaban safer than rivaroxaban in liver disease but NOT in cirrhosis subgroup (HR 1.01)
- Zhou 2025 (PMID 40727096): Meta-analysis confirms DOAC safety advantage

**Critical uncertainty:** Apixaban vs rivaroxaban safety advantage observed in
"liver disease" populations DISAPPEARS in cirrhosis-specific subgroups (Douros
2024, Zhou 2025). This suggests cirrhosis-specific analyses are essential.

**No TTE has been applied to this question.** All studies use PS-weighted
observational designs. A TTE could clarify the cirrhosis-specific causal effect
and address confounding by disease severity (Child-Pugh class).

#### TTE Suitability: HIGH (with caveats)

- Time zero well-defined (OAC initiation)
- Cirrhosis identification in claims requires ICD + complications codes for staging
- Challenge: Child-Pugh score not available in claims; would need EHR with lab values
- Competing risk of liver-related mortality is important
- PCORnet CDM with lab data could provide bilirubin, albumin, INR for staging

#### Supporting PMIDs

38976880, 36762560, 38552497, 39583376, 40727096, 39027793, 39053441,
38699468, 35913111

#### Search Completeness Checklist

- [x] At least one narrow PICO-specific search was run (two run)
- [x] Abstracts fetched for all targeted search results
- [x] Citation chaining done (Simon → Lawal → Douros; cirrhosis subgroup discordance identified)
- [x] "No TTE exists" claim stress-tested: WebSearch confirmed Simon 2024 is PS-weighted, not TTE
- [x] Self-consistency check: none of cited papers use TTE
- [x] Specialty journal coverage: searched hepatology/GI journals

---

### Q5: DOACs (Apixaban vs Rivaroxaban) in AF + Active Cancer

**Gap Score: 5/10**

#### PICO Formulation

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF and active cancer (solid tumor, receiving treatment), new OAC users |
| **Intervention** | Apixaban initiation |
| **Comparator** | Rivaroxaban initiation |
| **Outcome** | Major bleeding (primary); stroke/SE, VTE, all-cause mortality (secondary) |
| **Time zero** | Date of first OAC dispensing after AF diagnosis |
| **Follow-up** | 1 year |

#### Causal Contrast

*What is the effect of initiating apixaban, compared to rivaroxaban, on major bleeding risk in patients with AF and active cancer?*

**Estimand:** ATE

#### Evidence Gap Rationale

This space already has TTE studies — but they address a DIFFERENT question.
Truong et al. published two TTE studies from SEER-Medicare:
- Truong 2024 (PMID 38504063): TTE of OAC initiation strategies (timing) in AF + cancer
- Truong 2025 (PMID 38847907): TTE of DOACs-as-class vs warfarin in AF + cancer

**The remaining gap is head-to-head DOAC comparison (apixaban vs rivaroxaban) in
cancer.** Non-TTE evidence:
- Deitelzweig 2021 (PMID 34604802): ARISTOPHANES subgroup (n=40,271), apixaban best
- Agrawal 2026 (PMID 41554390): TriNetX (n=41,764 pairs), apixaban vs warfarin
- Chan 2021 (PMID 34233467): Taiwan (n=7,955), NOACs vs warfarin

Gap score is lower (5/10) because:
1. Two TTE studies already exist in this space
2. The DOACs-vs-warfarin comparison is largely settled (DOACs favored)
3. Head-to-head DOAC comparison in cancer is narrower question with less clinical equipoise
4. Apixaban appears consistently safer — incremental TTE value is lower

#### TTE Suitability: MODERATE

- Active-comparator design feasible
- Cancer staging and treatment status hard to capture in claims
- SEER-Medicare is ideal (cancer registry + Medicare claims) but already used by Truong
- Incremental value over existing observational studies is modest

#### Supporting PMIDs

38504063, 38847907, 39973613, 33044735, 34604802, 41554390, 34233467,
36213361, 38088911

#### Search Completeness Checklist

- [x] At least one narrow PICO-specific search was run (two run)
- [x] Abstracts fetched for all targeted search results
- [x] Citation chaining done (Truong 2024 → Truong 2025 → Deitelzweig → Agrawal)
- [x] "Existing TTE" claim verified: WebSearch confirmed Truong 2024/2025 use TTE
- [x] Self-consistency check: correctly noted existing TTE studies; gap is in head-to-head DOAC comparison
- [x] Specialty journal coverage: searched cardio-oncology journals

---

## Summary Table

| Rank | Question | Gap Score | Existing TTE? | No. Supporting Papers | Key Uncertainty |
|------|----------|-----------|--------------|----------------------|-----------------|
| 1 | Early rhythm vs rate control (EAST-AFNET 4 emulation) | 8 | No | 10 | No formal TTE despite multiple RW validations |
| 2 | Catheter ablation vs AADs in AF + HFpEF | 8 | No | 10 | No RCT; only PS-matched observational data |
| 3 | Apixaban vs rivaroxaban in AF + advanced CKD | 7 | No | 11 | Converging observational evidence but no TTE or RCT |
| 4 | DOACs vs warfarin in AF + cirrhosis | 7 | No | 9 | Apixaban advantage disappears in cirrhosis subgroup |
| 5 | DOACs (apixaban vs rivaroxaban) in AF + cancer | 5 | Yes (DOACs vs warfarin only) | 9 | Head-to-head comparison not yet done via TTE |

## Existing TTE Literature in AF (Self-Consistency Check)

Seven TTE studies were identified in the Pass 1 search (PMID: 41121356,
41024059, 38504063, 38847907, 39394165, 39603638, 36852680). None of these
overlap with questions Q1–Q4. The two Truong studies (Q5 space) address
DOACs-vs-warfarin, not head-to-head DOACs. The remaining TTE studies cover:
digoxin vs beta-blocker (Liu 2025), multidisciplinary antithrombotic management
(Prunel 2025), suicide risk with OACs (Li 2024), OAC resumption after SDH (Anno
2024), and anticoagulation after sepsis-onset AF (Walkey 2023).

**No existing TTE study addresses any of the top 4 candidate questions.**
This was verified via PubMed targeted searches AND WebSearch cross-referencing.
