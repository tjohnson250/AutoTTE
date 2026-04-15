# Evidence Gaps: Atrial Fibrillation

## Scoring Methodology

Each candidate question is scored on five dimensions (0–2 each, max 10):

| Dimension | 0 | 1 | 2 |
|-----------|---|---|---|
| **Clinical importance** | Low-impact question | Moderate clinical relevance | High-impact, guideline-changing potential |
| **Evidence gap** | Well-studied by RCTs and observational | Some evidence but key gaps | No RCT; sparse/conflicting observational data |
| **TTE novelty** | TTE already applied to this exact question | TTE applied to related question | No TTE in this domain |
| **Data feasibility** | Rare exposures/outcomes; hard to define | Feasible but needs creative design | Common exposures/outcomes; clean operationalization |
| **Methodological value** | Standard design | Moderate causal inference interest | Addresses key TTE challenge (time zero, positivity) |

---

## Ranked Candidate Questions

### 1. Apixaban vs Rivaroxaban in AF with Advanced CKD (Stages 4–5)

**Gap Score: 8/10** (Clinical: 2, Gap: 2, Novelty: 1, Feasibility: 2, Methods: 1)

**PICO:**
- **P:** Adults with non-valvular AF and advanced CKD (eGFR <30 or dialysis)
- **I:** Apixaban (standard or reduced dose per label)
- **C:** Rivaroxaban (standard or reduced dose per label)
- **O:** Composite of stroke/SE and major bleeding; individual components; all-cause mortality

**Supporting Evidence:**
- Fu et al. 2024 (PMID 37839687): US nationwide cohort showing apixaban associated with lower bleeding than rivaroxaban in advanced CKD, using PS matching but not TTE
- Yao et al. 2020 (PMID 33012172): OAC effectiveness varies by kidney function strata
- Siontis et al. 2018 (PMID 29954737): Apixaban in ESKD — lower bleeding than warfarin
- Ray et al. 2021 (PMID 34932078): Apixaban vs rivaroxaban in general AF population (JAMA)
- Lau et al. 2022 (PMID 36315950): Multinational DOAC comparison
- Dawwas & Cuker 2025 (PMID 39442621): Rivaroxaban inferior to apixaban in elderly
- RENAL-AF (PMID 36335914): Only RCT in hemodialysis (apixaban vs warfarin, N=154, underpowered)
- De Vriese et al. 2021 (PMID 33753537): Only RCT of rivaroxaban in hemodialysis (vs VKA)

**Why this is a gap:**
No RCT or TTE study directly compares apixaban to rivaroxaban **in advanced CKD**.
One TTE (PMID 36252244, Annals of Internal Medicine 2022) compared apixaban vs
rivaroxaban in AF patients with valvular heart disease (N=19,894; apixaban: lower
stroke HR 0.57, lower bleeding HR 0.51), and Mei 2021 compared dabigatran vs
rivaroxaban in a general Medicare population. However, neither addressed the CKD
population, where altered pharmacokinetics, high bleeding risk, and underpowered
RCTs (RENAL-AF N=154, De Vriese N=132) leave the clinical question unanswered.
Fu 2024 is the closest CKD-specific study but used standard PS matching without
formal TTE framework.

**Stress test of "no TTE in CKD" claim:** Verified via (1) PubMed search for
"target trial emulation" AND "anticoagulant" AND "atrial fibrillation" — 7 results,
one comparing apixaban vs rivaroxaban in VHD (PMID 36252244) but none in CKD;
(2) WebSearch for "target trial emulation atrial fibrillation CKD" — confirmed no
CKD-specific TTE. Note: TTE novelty scored as 1 (not 2) because PMID 36252244
applied TTE to the same drug comparison in a different population.

**TTE design opportunity:** Emulate a pragmatic trial of new-user apixaban vs
rivaroxaban initiators with eGFR <30. Time zero = date of first DOAC fill.
Active-comparator, new-user design addresses confounding by indication. CKD stage
captured via lab-based eGFR or ICD codes. PCORnet CDM has PRESCRIBING (RXNORM_CUI)
and LAB_RESULT_CM (creatinine/eGFR LOINC codes) tables ideal for this design.

---

### 2. Catheter Ablation vs Antiarrhythmic Drugs in AF with HFpEF

**Gap Score: 8/10** (Clinical: 2, Gap: 2, Novelty: 2, Feasibility: 1, Methods: 1)

**PICO:**
- **P:** Adults with AF and HFpEF (EF ≥50%)
- **I:** Catheter ablation (any energy source)
- **C:** Antiarrhythmic drug therapy
- **O:** Composite of all-cause death and HF hospitalization; AF recurrence

**Supporting Evidence:**
- CASTLE-AF 2018 (PMID 29385358): RCT in HFrEF only (EF ≤35%)
- CABANA 2019 (PMID 30874766): Mixed population; ITT non-significant
- Martens et al. 2025 (PMID 40243977): CABANA post-hoc HFpEF subanalysis — ablation beneficial
- Oraii et al. 2024 (PMID 38656292): Meta-analysis showing ablation benefits in HFrEF > HFpEF
- DeLuca et al. 2025 (PMID 39447815): Multicenter comparative — ablation superior in HFpEF
- CABA-HFPEF-DZHK27 (PMID 39023141): Ongoing dedicated RCT (not yet reported)

**Why this is a gap:**
CASTLE-AF excluded HFpEF patients entirely. CABANA was not designed to test HF
subgroups, and the HFpEF subanalysis was post-hoc and likely underpowered. DeLuca 2025
is a multicenter observational comparison but did not use TTE. The dedicated CABA-HFPEF
RCT is ongoing but years from reporting. No TTE study has attempted to emulate
CASTLE-AF or CABANA in the HFpEF population.

**Stress test:** Verified via PubMed search for ablation + HFpEF + AF (68 results):
multiple meta-analyses and observational studies, zero TTE studies. WebSearch confirmed
no TTE application to this question.

**TTE design opportunity:** Emulate CASTLE-AF in HFpEF patients using PCORnet data.
Identify ablation recipients via procedure codes (CPT 93656) and AAD initiators via
prescribing data. Key challenge: defining HFpEF reliably (requires EF measurement from
echocardiography, which may not be in structured CDM fields). Time zero = date of
ablation or first AAD fill.

---

### 3. DOACs vs Warfarin in AF with Liver Cirrhosis

**Gap Score: 8/10** (Clinical: 2, Gap: 2, Novelty: 2, Feasibility: 1, Methods: 1)

**PICO:**
- **P:** Adults with non-valvular AF and liver cirrhosis (any Child-Pugh class)
- **I:** Any DOAC (apixaban, rivaroxaban, or edoxaban)
- **C:** Warfarin
- **O:** Stroke/SE; major bleeding; all-cause mortality

**Supporting Evidence:**
- Simon et al. 2024 (PMID 38976880): US nationwide cohort — apixaban lowest bleeding, rivaroxaban comparable to warfarin
- Lawal et al. 2023 (PMID 36762560): Nationwide cohort — DOACs safer than warfarin in chronic liver disease
- Song et al. 2024 (PMID 39053441): Real-world outcomes of anticoag in cirrhosis+AF

**Why this is a gap:**
All pivotal DOAC RCTs (RE-LY, ROCKET-AF, ARISTOTLE, ENGAGE) excluded patients with
significant liver disease (Child-Pugh B or C). The FDA labels carry warnings about
use in moderate-severe hepatic impairment. Observational evidence (Simon 2024, Lawal
2023) suggests DOACs are safe, but no study has used formal TTE methodology, and
Child-Pugh severity strata are poorly characterized in claims data.

**Stress test:** PubMed search for DOACs + cirrhosis + AF returned multiple
observational studies and meta-analyses but zero TTE studies. WebSearch confirmed
no TTE application.

**TTE design opportunity:** Emulate ARISTOTLE or ROCKET-AF in cirrhosis patients.
Active-comparator (DOAC vs warfarin) new-user design. Cirrhosis identified via
ICD-10 codes (K70.3x, K74.x) + lab markers (FIB-4, MELD). PCORnet's DIAGNOSIS
and LAB_RESULT_CM tables support this, though Child-Pugh classification requires
albumin, bilirubin, INR, ascites, and encephalopathy — partially available.

---

### 4. Early Rhythm Control vs Usual Care in AF with Heart Failure

**Gap Score: 7/10** (Clinical: 2, Gap: 1, Novelty: 2, Feasibility: 1, Methods: 1)

**PICO:**
- **P:** Adults with newly diagnosed AF (<1 year) and concomitant heart failure (HFrEF or HFpEF)
- **I:** Early rhythm control (AAD initiation or ablation within 1 year of AF diagnosis)
- **C:** Rate control only (usual care)
- **O:** Composite of CV death, stroke, and HF hospitalization

**Supporting Evidence:**
- EAST-AFNET 4 (PMID 32865375): Early rhythm control beneficial in general AF population
- Willems et al. 2022 (PMID 34447995): EAST substudy — benefit in symptomatic and asymptomatic patients
- Kim et al. 2022 (PMID 36063552): Korean nationwide — early rhythm control in low-risk patients
- Kriz et al. 2025 (PMID 41342526): CYCLE cohort — early rhythm control in acute decompensated HF
- Rillig et al. 2022 (PMID 35968706): EAST — benefit persists in high comorbidity patients
- Dickow et al. 2022 (PMID 35621202): EAST generalizability to US population

**Why this is a gap:**
EAST-AFNET 4 included HF patients but was not designed or powered for HF subgroup
analysis. The HF subgroup has not been separately analyzed. Korean cohort studies
(Kim 2022) replicated EAST in general populations but did not isolate the HF
subgroup. No TTE has emulated EAST-AFNET 4 in a HF-specific population. Liu 2025
(PMID 41121356) used TTE for rate-control drug choice in AF+HF, but not for rhythm
vs rate control strategy.

**Stress test:** Confirmed via targeted PubMed search for "early rhythm control" +
AF + HF + observational: 29 results, including cohort studies but no TTE studies
specifically in HF subgroups.

**TTE design opportunity:** Emulate EAST-AFNET 4 in HF patients. Identify newly
diagnosed AF patients with HF (ICD codes + encounters). Classify early rhythm
control vs rate control based on first treatment received within 1 year. Challenge:
defining "early" diagnosis requires lookback period; potential for time-zero bias.

---

### 5. LAAC vs Continued Anticoagulation in AF with Dialysis

**Gap Score: 6/10** (Clinical: 2, Gap: 1, Novelty: 1, Feasibility: 1, Methods: 1)

**PICO:**
- **P:** Adults with AF on chronic hemodialysis
- **I:** Percutaneous LAAC (Watchman or Amulet device)
- **C:** Continued oral anticoagulation (DOAC or warfarin)
- **O:** Stroke/SE; major bleeding; all-cause mortality

**Supporting Evidence:**
- Dhar et al. 2025 (PMID 40924421): LAAC vs anticoagulants in dialysis
- OPTION trial (PMID 39555822): LAAC after ablation (not dialysis-specific)
- PRAGUE-17 (PMID 32586585): LAAC vs DOACs in high-risk (not CKD-specific)
- CLOSURE-AF (PMID 41849741): LAAC vs medical therapy (general population)
- Lu et al. 2025 (PMID 40231086): TTE of LAAC vs DOACs for dementia risk
- Multiple meta-analyses of LAAC in CKD (PMIDs 39191612, 38112741, 39029071)

**Why gap score is lower:**
Dhar 2025 directly addresses this population, and the CLOSURE-AF results provide
new RCT data. However, Dhar 2025 was observational without formal TTE, and no
study has emulated PROTECT-AF or PREVAIL in dialysis patients. Lu 2025 used TTE
for LAAC but focused on dementia, not stroke/bleeding in CKD.

---

### 6. Appropriate vs Inappropriate DOAC Dose Reduction in Elderly AF

**Gap Score: 6/10** (Clinical: 2, Gap: 1, Novelty: 1, Feasibility: 2, Methods: 0)

**PICO:**
- **P:** Adults ≥75 with AF prescribed a DOAC
- **I:** Guideline-concordant DOAC dosing (standard or reduced per label criteria)
- **C:** Off-label dose reduction (reduced dose without meeting label criteria)
- **O:** Stroke/SE; major bleeding; all-cause mortality

**Supporting Evidence:**
- Ciou et al. 2024 (PMID 38266751): Different DOAC regimens in high-bleeding-risk AF
- Chan et al. 2023 (PMID 37580139): Very low dose vs regular dose NOAC
- Shurrab et al. 2024 (PMID 38878942): Apixaban vs rivaroxaban in older patients

**Why this is a gap:**
Inappropriate dose reduction is a known clinical problem (up to 25–30% of DOAC
prescriptions in elderly), and observational data suggest it increases stroke risk
without reducing bleeding. However, the question has been studied by multiple cohort
studies and is not a high-novelty TTE opportunity.

---

### 7. Digoxin vs Beta-Blocker for Rate Control in AF with HF

**Gap Score: 5/10** (Clinical: 1, Gap: 0, Novelty: 0, Feasibility: 2, Methods: 2)

**PICO:**
- **P:** Adults with AF and heart failure
- **I:** Digoxin for rate control
- **C:** Beta-blocker for rate control
- **O:** All-cause mortality; HF hospitalization

**Supporting Evidence:**
- RATE-AF (PMID 33351042): RCT, digoxin vs bisoprolol
- Liu et al. 2025 (PMID 41121356): **TTE already applied** — digoxin vs BB in AF+HF; digoxin associated with **higher** mortality (RR 1.21) and higher HF hospitalization

**Why gap score is lower:**
Liu 2025 has already applied TTE to this exact question. RATE-AF provides RCT
evidence. This is not a gap requiring new TTE work.

---

## Search Completeness Checklist

| Check | Q1 (CKD) | Q2 (HFpEF) | Q3 (Cirrhosis) | Q4 (HF) | Q5 (LAAC) |
|-------|-----------|------------|-----------------|---------|-----------|
| Narrow PICO search run | Yes | Yes | Yes* | Yes | Yes |
| Abstracts fetched for targeted results | Yes | Yes | Partial* | Yes | Yes |
| Citation chaining (top 3) | Yes | Yes | Yes | N/A | N/A |
| "No studies" claim stress-tested | Yes | Yes | Yes | Yes | Yes |
| WebSearch verification | Yes | Yes | Yes | Yes | Yes |
| Self-consistency check | Pass | Pass | Pass | Pass | Pass |

*Cirrhosis search was rate-limited by PubMed API; supplemented by Pass 1 results.

---

## Summary Table

| Rank | Question | Gap Score | Key Missing Evidence | TTE Applied? |
|------|----------|-----------|---------------------|--------------|
| 1 | Apixaban vs rivaroxaban in AF + advanced CKD | 8 | No RCT in CKD; TTE exists for VHD (PMID 36252244) but not CKD | No (in CKD) |
| 2 | Catheter ablation vs AADs in AF + HFpEF | 8 | No completed RCT in HFpEF; no TTE | No |
| 3 | DOACs vs warfarin in AF + liver cirrhosis | 8 | No RCT (excluded from pivotal trials); no TTE | No |
| 4 | Early rhythm control vs usual care in AF + HF | 7 | EAST not powered for HF; no TTE in HF subgroup | No |
| 5 | LAAC vs anticoagulation in AF + dialysis | 6 | One observational study (Dhar 2025); no TTE | No |
| 6 | Appropriate vs inappropriate DOAC dose reduction | 6 | Multiple cohort studies exist; low novelty for TTE | No |
| 7 | Digoxin vs BB for rate control in AF + HF | 5 | TTE already applied (Liu 2025) | **Yes** |

---

## Recommended Top 3 for Protocol Development

1. **Apixaban vs rivaroxaban in AF + advanced CKD** — Highest clinical impact, clean
   active-comparator design, ideal for PCORnet CDM (prescribing + labs + outcomes).

2. **Catheter ablation vs AADs in AF + HFpEF** — Addresses the most important gap
   in AF ablation evidence. Requires procedure codes + echo data.

3. **DOACs vs warfarin in AF + liver cirrhosis** — Addresses population explicitly
   excluded from all RCTs. Requires diagnosis codes + lab data for severity staging.
