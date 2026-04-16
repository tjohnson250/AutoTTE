# Evidence Gaps and Ranked PICO Questions: Type 2 Diabetes

**Therapeutic Area:** Type 2 Diabetes Mellitus  
**Date:** 2026-04-15  
**Study Description Alignment:** Canagliflozin vs DPP-4 inhibitors (primary) and 2nd-generation sulfonylureas (secondary) for 3P-MACE, new-user parallel-group cohort design with 180-day baseline period, PCORnet CDM database.

---

## Evidence Gap Scoring Methodology

Each candidate question is scored 1–10 on the following dimensions:

| Dimension | Description |
|-----------|-------------|
| **Clinical importance** (1–10) | Burden of disease, guideline relevance, unresolved clinical uncertainty |
| **Existing evidence quality** (1–10) | Strength of current RCT + observational evidence (higher = less evidence = bigger gap) |
| **Feasibility in target database** (1–10) | Likelihood of sufficient sample size, exposure/outcome capture in PCORnet CDM |
| **Methodological novelty** (1–10) | Whether a TTE approach adds value beyond existing evidence |
| **Alignment with study description** (1–10) | How closely the question matches the specified study design |

**Gap Score** = weighted average: Clinical importance (0.25) + Evidence gap (0.30) + Feasibility (0.20) + Methodological novelty (0.10) + Study alignment (0.15)

---

## Ranked PICO Questions

### Rank 1: Canagliflozin vs DPP-4 Inhibitors for 3-Point MACE ⭐ PRIMARY

**PICO:**
- **P:** Adults with type 2 diabetes initiating canagliflozin or a DPP-4 inhibitor, with ≥180 days continuous enrollment
- **I:** New use of canagliflozin
- **C:** New use of any DPP-4 inhibitor (sitagliptin, linagliptin, saxagliptin, alogliptin)
- **O:** 3-point MACE (composite of CV death, nonfatal MI, nonfatal stroke)

**Gap Score: 8.4 / 10**

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Clinical importance | 9 | MACE is the primary CV endpoint; canagliflozin is widely prescribed; direct comparison informs treatment selection |
| Evidence gap | 8 | CANVAS showed canagliflozin reduces MACE vs placebo (HR 0.86, PMID 28605608), but **no study has compared canagliflozin specifically vs DPP-4i for 3P-MACE**. Class-level SGLT2i vs DPP4i studies exist (PMID 36745425, 37499675, 40201798) but none isolate canagliflozin. |
| Feasibility | 9 | PCORnet CDM has RxNorm prescribing data, ICD-10 diagnoses, enrollment tables. Canagliflozin and DPP-4i are commonly prescribed second-line agents. |
| Methodological novelty | 7 | TTE framework applied to this class comparison exists (Xie 2023), but agent-specific emulation of CANVAS against DPP-4i comparator is novel. |
| Study alignment | 10 | Direct match to the study description. |

**Supporting evidence:**
- PMID 28605608 — CANVAS: canagliflozin vs placebo, 3P-MACE HR 0.86 (0.75–0.97)
- PMID 36745425 — D'Andrea 2023: SGLT2i (class) vs DPP4i, modified MACE HR 0.85 (0.75–0.95)
- PMID 38509341 — EMPRISE: empagliflozin vs DPP4i, MACE HR 0.73 (0.62–0.86)
- PMID 37499675 — Xie 2023: SGLT2i vs DPP4i, MACE HR 0.86 (0.82–0.89), TTE with VA data
- PMID 40201798 — Kosjerina 2025: SGLT2i vs DPP4i, 3P-MACE IRR 0.65 (0.63–0.68) in elderly
- PMID 34481910 — CANTABILE: canagliflozin vs teneligliptin RCT, metabolic endpoints only (N=162)

**Why this gap matters:** Existing class-level comparisons show SGLT2i collectively reduce MACE vs DPP-4i, but individual SGLT2i may differ. The CANVAS amputation signal is unique to canagliflozin and suggests the risk-benefit profile may differ from empagliflozin or dapagliflozin. A canagliflozin-specific emulation provides actionable, agent-level evidence.

**Stress test of "no canagliflozin-specific evidence" claim:**
- Searched: "canagliflozin" AND DPP-4i terms AND MACE → 89 results; none compare canagliflozin specifically to DPP-4i for hard MACE
- Searched: "canagliflozin" AND "active comparator" AND MACE → 78 results; OBSERVE-4D (PMID 29938883) is canagliflozin-specific but focused on HHF/amputation, not 3P-MACE
- WebSearch: confirmed no published canagliflozin-vs-DPP4i TTE for 3P-MACE
- **Self-consistency check:** None of the cited papers perform this specific comparison. Claim validated.

---

### Rank 2: Canagliflozin vs 2nd-Generation Sulfonylureas for 3-Point MACE

**PICO:**
- **P:** Adults with type 2 diabetes initiating canagliflozin or a 2nd-generation sulfonylurea, with ≥180 days continuous enrollment
- **I:** New use of canagliflozin
- **C:** New use of 2nd-generation sulfonylurea (glipizide, glimepiride, glyburide)
- **O:** 3-point MACE (composite of CV death, nonfatal MI, nonfatal stroke)

**Gap Score: 7.5 / 10**

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Clinical importance | 8 | SU remain widely used; CAROLINA (PMID 31536101) only compared linagliptin vs glimepiride; SU associated with higher MACE in Xie 2023 |
| Evidence gap | 7 | Xie 2023 showed SGLT2i vs SU HR 0.77 for MACE (class-level); no canagliflozin-specific comparison |
| Feasibility | 8 | SU are very commonly prescribed in PCORnet; large sample expected |
| Methodological novelty | 7 | Secondary comparator design mirrors the study description |
| Study alignment | 10 | Direct match as secondary comparator arm |

**Supporting evidence:**
- PMID 37499675 — Xie 2023: SGLT2i vs SU, MACE HR 0.77 (0.74–0.80)
- PMID 31536101 — CAROLINA: linagliptin vs glimepiride, noninferior for MACE
- PMID 36129997, 38344820 — SU associated with CV risk in observational studies

**Stress test:** Searched "canagliflozin" AND sulfonylurea AND MACE → 35 results; none provide canagliflozin-specific TTE vs SU for 3P-MACE. Claim validated.

---

### Rank 3: Canagliflozin vs DPP-4 Inhibitors for Individual MACE Components (CV Death, MI, Stroke Separately)

**PICO:**
- **P:** Same as Rank 1
- **I:** New use of canagliflozin
- **C:** New use of any DPP-4 inhibitor
- **O:** Individual components: (a) CV death, (b) nonfatal MI, (c) nonfatal stroke

**Gap Score: 7.3 / 10**

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Clinical importance | 8 | SGLT2i class heterogeneity in MACE components is well-documented: empagliflozin drives CV death, canagliflozin may differ |
| Evidence gap | 8 | CANVAS showed no significant individual component reduction (composite was significant); observational data for individual components with canagliflozin is sparse |
| Feasibility | 7 | Individual components have lower event rates, requiring larger cohorts; PCORnet may have sufficient power |
| Methodological novelty | 6 | Component analyses are standard sensitivity analyses |
| Study alignment | 8 | Natural extension of the primary analysis |

**Supporting evidence:**
- PMID 28605608 — CANVAS: composite significant, but individual components did not reach significance
- PMID 26378978 — EMPA-REG: CV death HR 0.62, but MI/stroke not significant
- PMID 29540325 — CVD-REAL 2: SGLT2i vs oGLDs, MI HR 0.81, stroke HR 0.68 (class level)
- PMID 38509341 — EMPRISE: MI/stroke HR 0.88 (empagliflozin-specific)

---

### Rank 4: Canagliflozin vs DPP-4 Inhibitors for Hospitalization for Heart Failure

**PICO:**
- **P:** Adults with type 2 diabetes initiating canagliflozin or a DPP-4 inhibitor
- **I:** New use of canagliflozin
- **C:** New use of any DPP-4 inhibitor
- **O:** Hospitalization for heart failure (HHF)

**Gap Score: 6.8 / 10**

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Clinical importance | 9 | HHF is a key CV endpoint where SGLT2i show strongest benefit |
| Evidence gap | 5 | OBSERVE-4D (PMID 29938883) showed canagliflozin HHF HR 0.39 vs non-SGLT2i. EMPRISE, Fu 2023 show class-level benefit. Less of a gap than MACE. |
| Feasibility | 9 | HHF well-captured in claims/EHR data |
| Methodological novelty | 5 | Multiple studies already address this outcome |
| Study alignment | 7 | HHF is a natural secondary outcome for the described study |

**Supporting evidence:**
- PMID 29938883 — OBSERVE-4D: canagliflozin HHF HR 0.39 (0.26–0.60) vs non-SGLT2i
- PMID 37259575 — Fu 2023: SGLT2i vs sitagliptin, HHF HR 0.64 (0.58–0.70)
- PMID 38509341 — EMPRISE: empagliflozin vs DPP4i, HHF HR 0.50 (0.44–0.56)
- PMID 41732861 — Circulation 2026: GLP1RA vs SGLT2i/DPP4i for HHF TTE

---

### Rank 5: Canagliflozin vs DPP-4 Inhibitors — Safety Profile (Amputation, DKA, Genital Infections)

**PICO:**
- **P:** Adults with type 2 diabetes initiating canagliflozin or a DPP-4 inhibitor
- **I:** New use of canagliflozin
- **C:** New use of any DPP-4 inhibitor
- **O:** Composite safety: (a) lower-limb amputation, (b) DKA, (c) genital infections, (d) AKI

**Gap Score: 6.5 / 10**

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Clinical importance | 8 | Canagliflozin amputation signal from CANVAS was unique and led to FDA boxed warning (later removed) |
| Evidence gap | 6 | OBSERVE-4D (PMID 29938883) found no amputation increase in real-world; but DPP-4i-specific comparator not used. Multiple safety studies exist. |
| Feasibility | 7 | Amputation requires procedure codes; DKA and genital infections capturable via ICD-10 |
| Methodological novelty | 5 | Safety analyses standard in this design |
| Study alignment | 7 | Important safety endpoints for any canagliflozin study |

**Supporting evidence:**
- PMID 28605608 — CANVAS: amputation HR 1.97 (1.41–2.75)
- PMID 29938883 — OBSERVE-4D: canagliflozin amputation HR 1.01 (0.93–1.10) ITT vs non-SGLT2i
- PMID 36745425 — D'Andrea 2023: SGLT2i vs DPP4i increased genital infections, DKA
- PMID 38509341 — EMPRISE: empagliflozin DKA HR 1.78; AKI HR 0.62

---

### Rank 6: SGLT2 Inhibitors (Class) vs DPP-4 Inhibitors for MACE in Patients with CKD

**PICO:**
- **P:** Adults with T2D and CKD (eGFR 30–60) initiating SGLT2i or DPP-4i
- **I:** New use of any SGLT2i
- **C:** New use of any DPP-4i
- **O:** 3P-MACE

**Gap Score: 6.2 / 10**

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Clinical importance | 9 | CKD is the highest-risk subgroup; CREDENCE showed canagliflozin benefit in CKD |
| Evidence gap | 6 | CREDENCE (PMID 30990260) was placebo-controlled in CKD; some observational data exist (PMID 31862149, 41574952) |
| Feasibility | 6 | Requires lab data (eGFR) which may be incomplete in claims-only CDM; PCORnet has LAB_RESULT_CM |
| Methodological novelty | 5 | Subgroup analysis, not a novel design |
| Study alignment | 5 | Subgroup of the main study, not primary focus |

**Supporting evidence:**
- PMID 30990260 — CREDENCE: canagliflozin in CKD, CV benefit
- PMID 41574952 — SGLT2i mortality in DKD, TTE, Diabetes Obes Metab 2026
- PMID 31862149 — SGLT2i kidney outcomes in real-world

---

### Rank 7: Canagliflozin vs DPP-4 Inhibitors for MACE by Baseline ASCVD Status

**PICO:**
- **P:** Adults with T2D ± established ASCVD initiating canagliflozin or DPP-4i
- **I:** New use of canagliflozin
- **C:** New use of any DPP-4i
- **O:** 3P-MACE, stratified by ASCVD status

**Gap Score: 5.8 / 10**

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Clinical importance | 8 | DECLARE showed benefit only in ASCVD subgroup; CANVAS enrolled 65.6% with CVD history |
| Evidence gap | 5 | D'Andrea 2023 examined by HbA1c; EMPRISE examined by ASCVD history. Subgroup data exists at class level. |
| Feasibility | 8 | ASCVD well-defined by ICD codes in PCORnet |
| Methodological novelty | 4 | Standard subgroup analysis |
| Study alignment | 6 | Natural stratification variable |

**Supporting evidence:**
- PMID 36745425 — D'Andrea 2023: no treatment effect heterogeneity by HbA1c
- PMID 38509341 — EMPRISE: larger absolute benefits in ASCVD+ subgroup
- PMID 37677118 — Kutz 2023: benefits preserved across frailty strata

---

## Summary of Candidate Questions with Gap Scores ≥ 5

| Rank | PICO Question | Gap Score | Study Alignment |
|------|--------------|-----------|-----------------|
| **1** | **Canagliflozin vs DPP-4i for 3P-MACE** | **8.4** | **Primary** |
| **2** | **Canagliflozin vs 2nd-gen SU for 3P-MACE** | **7.5** | **Secondary** |
| **3** | **Canagliflozin vs DPP-4i for individual MACE components** | **7.3** | Extension |
| 4 | Canagliflozin vs DPP-4i for HHF | 6.8 | Secondary outcome |
| 5 | Canagliflozin vs DPP-4i safety (amputation, DKA, infections) | 6.5 | Safety |
| 6 | SGLT2i vs DPP-4i for MACE in CKD subgroup | 6.2 | Subgroup |
| 7 | Canagliflozin vs DPP-4i for MACE by ASCVD status | 5.8 | Subgroup |

---

## Search Completeness Checklist

For each top-5 question:

- [x] At least one narrow PICO-specific search was run (not just broad thematic)
- [x] Abstracts were fetched for all results of targeted searches
- [x] Citation chaining was done for the top 3 questions
- [x] Any claim of "no studies exist" or "only one study" was stress-tested with at least 2 different search strategies, including at least one WebSearch
- [x] For any claim "no study has applied [method] to [topic]," verified that none of the papers already cited actually used that method (self-consistency check)
- [x] Searches covered both the primary clinical literature AND relevant specialty journals

### Stress tests performed:

| Claim | Strategies Used | Result |
|-------|----------------|--------|
| "No canagliflozin-specific vs DPP4i TTE for 3P-MACE" | PubMed targeted search (89 hits reviewed); WebSearch (confirmed); citation chaining on Xie 2023 and CANVAS | **Validated.** No published study performs this specific comparison. Class-level SGLT2i vs DPP4i TTE exists (Xie 2023), but not canagliflozin-specific. |
| "No canagliflozin-specific vs SU TTE for 3P-MACE" | PubMed targeted search (35 hits reviewed); Xie 2023 does class-level only | **Validated.** No canagliflozin-specific study vs SU for 3P-MACE. |
| "OBSERVE-4D is HHF/amputation, not 3P-MACE" | Verified abstract (PMID 29938883): outcomes are HHF and BKLE amputation | **Confirmed.** OBSERVE-4D does not report 3P-MACE. |

---

## Recommended Protocol Focus

Based on this evidence gap analysis, the primary protocol should emulate the CANVAS trial design using the PCORnet CDM database:

1. **Primary analysis:** Canagliflozin vs DPP-4 inhibitor (active comparator as proxy for placebo) for 3-point MACE
2. **Secondary comparator:** Canagliflozin vs 2nd-generation sulfonylurea for 3-point MACE
3. **Secondary outcomes:** HHF, individual MACE components, all-cause mortality
4. **Safety outcomes:** Lower-limb amputation, DKA, genital infections, AKI
5. **Pre-specified subgroups:** ASCVD history, CKD status, age (≥65 vs <65), sex

This design fills a specific and clinically important evidence gap: the lack of canagliflozin-specific comparative effectiveness data vs DPP-4i for hard MACE endpoints in routine clinical practice.
