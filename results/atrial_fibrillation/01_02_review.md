# Literature Discovery Review — Atrial Fibrillation

**Reviewer verdict: REVISE (minor)**
**Date:** 2026-04-06

The worker produced a thorough, well-structured literature scan and evidence gap analysis covering >70 PMIDs across RCTs, observational studies, meta-analyses, and guidelines. The three-pass search strategy was executed and documented. However, I identified two factual discrepancies in PMID descriptions, one missed study with potential impact on Q2, and one missed RCT (BRAIN-AF) relevant to Q1. None of these are fatal, but the evidence gap file should be updated before advancing to feasibility.

---

## PMID Verification

I verified 11 PMIDs by fetching abstracts from PubMed and comparing them against the worker's descriptions. PMIDs were sampled across landmark RCTs, key observational studies, and newer papers to cover the full range of cited evidence.

| PMID | Paper | Worker's Claim | Abstract Finding | Verdict |
|------|-------|----------------|------------------|---------|
| 19717844 | RE-LY (Connolly 2009) | Dabigatran 150mg: lower stroke/SE, similar bleeding; 110mg: similar stroke/SE, lower bleeding | Dabigatran 150mg: 1.11%/yr stroke vs 1.69%/yr warfarin (superior); 110mg: 1.53%/yr (noninferior). Major bleeding: 110mg 2.71% (lower), 150mg 3.11% (similar). N=18,113. | MATCH |
| 32865375 | EAST-AFNET 4 (Kirchhof 2020) | Early rhythm control reduced composite CV outcome (HR 0.79); N=2,789 | HR 0.79 (3.9 vs 5.0 per 100 PY); N=2,789; stopped early for efficacy. | MATCH |
| 25770314 | Lip 2015 (Danish cohort) | No benefit from OAC or aspirin at CHA2DS2-VASc 0-1 | CHA2DS2-VASc 0: 0.49/100 PY stroke; with 1 additional risk factor: 1.55/100 PY. Truly low-risk had minimal stroke risk. | MATCH (minor oversimplification; study focused on truly low risk = score 0) |
| 39867851 | HERA-FIB (Yildirim 2025) | 20.7% under-dosed; underdosing: HR 1.98 for all-cause mortality | 20.7% under-dosed correct. BUT abstract reports HR 1.84 (95% CI 1.55-2.18) for **composite endpoint** (all-cause mortality + stroke + major bleeding + MI), NOT all-cause mortality alone. | **DISCREPANCY** — wrong endpoint and wrong HR magnitude |
| 37839687 | Fu 2024 (AJKD) | Rivaroxaban and warfarin: higher major bleeding vs apixaban in advanced CKD | Rivaroxaban HR 1.69 (1.33-2.15) and warfarin HR 1.85 (1.59-2.15) for major bleeding vs apixaban in CKD 4/5. N=5,720 (riva vs apix), 12,488 (warf vs apix). | MATCH |
| 35589174 | Kim 2022 (JACC:CEP) | Early rhythm control benefit ATTENUATES with increasing age | HR 0.80 for <75yr, HR 0.94 (0.87-1.03) for >=75yr. Linear decrease with advancing age. N=31,220. | MATCH (note: study uses >=75 cutoff, not >=80 as Q4 targets) |
| 37952132 | ARTESiA (Healey 2024) | Apixaban reduced stroke vs aspirin in subclinical AF | HR 0.63 (0.45-0.88) for stroke/SE; major bleeding HR 1.80 (1.26-2.57). N=4,012, mean CHA2DS2-VASc 3.9. | MATCH |
| 37712551 | Campbell 2024 (Ann Pharmacother) | 15% underdosed; higher mortality (10.9% vs 1.4%) | Abstract shows 17% underdosed (201/1172), not 15%. Mortality 10.9% vs 1.4% correct. Stroke/bleeding NOT significantly different. | **MINOR DISCREPANCY** — 17% not 15% |
| 37713139 | Burnham 2023 (J Pharm Pract) | No difference in stroke/TIA/MI; small study, baseline differences | N=303. Composite 3.8% vs 1.7% (P=0.28). Not significant. | MATCH |
| 26223245 | Lip 2015 (Thromb Haemost) | Positive NCB for warfarin vs no treatment at CHA2DS2-VASc = 1 | NCB positive for warfarin vs no treatment at 1-year and 5-year follow-up for patients with 1 risk factor. | MATCH |
| 41733864 | Gillis 2026 (Int J Clin Pharm) | Scoping review; gaps in dose-comparison and non-dialysis CKD data | 34 studies reviewed. Identifies "limited dose-comparison studies, heterogeneous outcomes and sparse data in non-dialysis patients." | MATCH |

**Summary:** 9/11 PMIDs match. Two discrepancies found:
1. **PMID 39867851:** HR 1.84 for composite, not HR 1.98 for all-cause mortality. This inflates the apparent harm of underdosing in the evidence gaps file.
2. **PMID 37712551:** 17% underdosed, not 15%. Minor.

---

## Independent Searches

### Q1: OAC vs No OAC at CHA2DS2-VASc = 1

**Search 1:** `"target trial emulation" oral anticoagulant atrial fibrillation "low risk" OR "score 1" OR threshold`
- Found TTE of OAC initiation strategies in AF+cancer (PMID: 38504063, Truong 2024). This uses TTE methodology with CHA2DS2-VASc thresholds but in cancer patients — different population, not directly applicable.

**Search 2:** `BRAIN-AF trial rivaroxaban placebo low risk atrial fibrillation CHA2DS2-VASc 0 1`
- **KEY FINDING — MISSED BY WORKER:** The BRAIN-AF trial (PMID: 41501492, published 2025 in Nature Medicine) is an RCT of rivaroxaban 15mg vs placebo in patients with AF and CHA2DS2-VASc 0-1 (excluding female sex). N=1,235, mean age 53, 53 centers in Canada. Primary endpoint: composite of cognitive decline + stroke/TIA. Result: NO benefit (HR 1.10, 95% CI 0.86-1.40, P=0.46). Stopped early for futility.
- **Relevance to Q1:** This is the only RCT in low-risk AF with a placebo arm. However, it differs from Q1 in critical ways: (a) used rivaroxaban 15mg (reduced dose), (b) primary endpoint was cognitive decline not stroke, (c) mean age 53 (much younger than typical CHA2DS2-VASc = 1 patients), (d) included score 0 and 1 combined. The trial was underpowered for stroke alone. Still, it provides important context that the worker should have cited.

**Search 3:** `apixaban "CHA2DS2-VASc 1" anticoagulation benefit stroke prevention observational 2024 2025`
- Confirmed ARTESiA subgroup analysis (PMID: 39019530) already cited by worker. Found 2024 ESC guidelines (PMC: 11865665) also cited. No additional uncited studies found.

**Verdict for Q1 searches:** Worker's core claim (no TTE exists for this question) is CONFIRMED. However, the BRAIN-AF trial (PMID: 41501492) should have been cited as the only RCT testing anticoagulation vs placebo in low-risk AF, even though it has a different primary endpoint and used reduced-dose rivaroxaban.

### Q2: DOAC Underdosing vs Guideline-Concordant Dosing

**Search 1:** `"target trial emulation" DOAC underdosing inappropriate dose anticoagulation outcomes`
- No TTE for underdosing found. Confirmed worker's claim.

**Search 2:** `DOAC "off-label" underdosing apixaban causal effect target trial emulation propensity score 2024 2025`
- **KEY FINDING — MISSED BY WORKER:** The ASPIRE study (PMID: 40113236, Cha 2025) is a prospective multicenter Korean cohort (N=1,944) of AF patients with a single dose-reduction criterion randomized between off-label reduced-dose and standard-dose apixaban. 1-year results showed NO significant differences in stroke/SE, major bleeding, or all-cause mortality between groups.
- This is important because it complicates the "underdosing = universally worse" narrative that the worker presents. While the ASPIRE population (single criterion, Asian) differs from Q2's target, it suggests the evidence is more nuanced than the worker indicates.
- Also found: a 2025 Swedish registry study using propensity score-weighted Cox regression (off-label underdosing associated with higher MI HR 1.47, ischemic stroke HR 1.25, major bleeding HR 1.16) — consistent with worker's cited evidence.

**Verdict for Q2 searches:** Worker's core claim (no TTE for underdosing) is CONFIRMED. The ASPIRE study should be cited as it provides conflicting evidence within the single-criterion subgroup.

### Q3: Apixaban vs Rivaroxaban in CKD 3b-5

**Search 1:** `apixaban vs rivaroxaban "chronic kidney disease" CKD stage 3b 4 head-to-head comparison 2024 2025 2026`
- Confirmed Fu et al. (PMID: 37839687) remains the primary head-to-head study.
- Confirmed 2026 scoping review (PMID: 41733864) identifies the gap.
- Found an editorial in AJKD ("Anticoagulation for Atrial Fibrillation in Advanced CKD: Can Observational Studies Provide the Answer?") accompanying Fu et al. that explicitly calls for further comparative effectiveness research. Worker did not cite this editorial.

**Verdict for Q3 searches:** Worker's assessment confirmed. Gap score of 7/10 is well-calibrated given emerging but limited evidence.

---

## Stress-Testing of Claims

### Claim: "No TTE exists for OAC at CHA2DS2-VASc = 1" (Q1)

**Tests performed:**
1. `"target trial emulation" oral anticoagulant atrial fibrillation "CHA2DS2-VASc" low risk` — No TTE found
2. `"target trial emulation" "atrial fibrillation" anticoagulation oral causal inference 2023 2024 2025` — Found TTE in AF+cancer (different population) and TTE methodology papers, but none addressing CHA2DS2-VASc = 1 specifically
3. Checked for any TTE in AF broadly — found TTE of OAC in AF+diabetes (Taiwan, propensity score weighting), TTE of LAAC vs DOAC (Medicare), and TTE of OAC initiation strategies in AF+cancer. None address the threshold question.

**Verdict: CONFIRMED.** No TTE exists for OAC benefit at CHA2DS2-VASc = 1. However, the BRAIN-AF trial (an RCT with placebo arm in CHA2DS2-VASc 0-1) was missed and should be noted.

### Claim: "No TTE exists for DOAC underdosing" (Q2)

**Tests performed:**
1. `"target trial emulation" DOAC underdosing inappropriate dose` — No results
2. `"target trial" OR "trial emulation" DOAC dose underdose inappropriate anticoagulation atrial fibrillation causal` — Found conventional observational studies only; no TTE
3. `DOAC "off-label" underdosing apixaban causal effect target trial emulation propensity score` — Found propensity-score-weighted studies but not formal TTE

**Verdict: CONFIRMED.** No TTE exists for the underdosing question. All existing evidence uses conventional epidemiologic methods. The worker correctly identified a sequential TTE for DOAC reinitiation after ICH (different question) as the closest methodological analog.

### Claim: "Limited head-to-head DOAC data in CKD" (Q3)

**Tests performed:**
1. `apixaban vs rivaroxaban "chronic kidney disease" CKD stage 3b 4 head-to-head comparison 2024 2025 2026` — Confirmed Fu et al. (2024) is the primary study
2. Checked 2026 scoping review (PMID: 41733864) — explicitly states "limited dose-comparison studies" and "sparse data in non-dialysis patients"

**Verdict: CONFIRMED.** One key head-to-head study (Fu 2024) exists for CKD 4/5. Non-dialysis CKD 3b-4 remains understudied. Worker correctly revised gap score from 8/10 to 7/10.

---

## Question-by-Question Assessment

### Q1: OAC vs No OAC at CHA2DS2-VASc = 1 — **REVISED**

**Gap Score: 9/10 (unchanged, but with caveats)**

**What the worker got right:**
- Correctly identified this as the highest-priority evidence gap
- Thorough citation of existing observational studies on both sides of the debate
- Correctly noted ethical barriers to randomization
- Good CDW feasibility assessment
- Appropriate acknowledgment of 2024 ESC guideline evolution (CHA2DS2-VA score)
- Citation chaining from Lip 2015 was productive

**What needs revision:**
- **BRAIN-AF trial (PMID: 41501492) must be cited.** This is the only RCT testing anticoagulation vs placebo in CHA2DS2-VASc 0-1 patients. Though it used reduced-dose rivaroxaban, targeted cognitive decline, enrolled younger patients (mean age 53), and was stopped for futility (no benefit), it is directly relevant to the evidence landscape. It should be added to Section 2.8 of the literature scan and noted in Q1's justification.
- The BRAIN-AF finding of NO benefit weakens the assumption of clinical equipoise slightly, though the population and intervention differences are substantial enough that Q1 remains a valid TTE target.
- Gap score remains 9/10 given the important differences between BRAIN-AF and Q1 (different dose, endpoint, and population).

**CDW note:** Time-zero definition will be critical. The worker correctly proposes "date of first AF diagnosis without prior anticoagulation" — this should be scrutinized for immortal time bias during protocol development.

### Q2: DOAC Underdosing vs Guideline-Concordant Dosing — **REVISED**

**Gap Score: 8/10 (unchanged, but corrections needed)**

**What the worker got right:**
- Correctly identified the absence of any TTE for this question
- Comprehensive citation of underdosing prevalence data
- Good identification of confounding by indication as the key analytic challenge
- Excellent CDW feasibility assessment with dose-reduction criteria operationalized
- Correctly distinguished the DOAC reinitiation TTE (PMC: 11934045) from the underdosing question

**What needs revision:**
1. **PMID 39867851 (HERA-FIB) correction required:** The worker reports "HR 1.98 for all-cause mortality" but the abstract reports HR 1.84 (95% CI 1.55-2.18) for a **composite endpoint** (all-cause mortality + stroke + major bleeding + MI). This is the wrong endpoint and wrong HR. Must be corrected in both the literature scan (Section 2.5) and the evidence gaps file (Q2 justification).
2. **PMID 37712551 correction:** 17% underdosed, not 15%.
3. **ASPIRE study (PMID: 40113236) should be cited.** This 2025 prospective Korean cohort (N=1,944) of AF patients with a single dose-reduction criterion found NO significant difference in stroke/SE, major bleeding, or mortality between off-label reduced dose and standard dose apixaban at 1 year. While the population is different (single criterion, Asian), it complicates the "underdosing = universally worse" narrative and should be noted as a counterpoint.
4. The evidence on underdosing harm is more heterogeneous than the worker presents. Large meta-analyses show consistent harm, but studies in specific subgroups (single criterion, elderly with matching) show weaker or null effects. This nuance should be reflected.

**Gap score remains 8/10** because the core question (causal effect via TTE) is unanswered, even with heterogeneous observational evidence.

### Q3: Apixaban vs Rivaroxaban in CKD 3b-5 — **VERIFIED**

**Gap Score: 7/10 (confirmed)**

**What the worker got right:**
- Correctly identified Fu et al. (PMID: 37839687) as the key study
- Appropriate downward revision from 8/10 to 7/10 after finding more evidence
- Good pharmacokinetic rationale (apixaban 27% vs rivaroxaban 36% renal clearance)
- Correctly identified non-dialysis CKD 3b-4 as the largest remaining gap
- 2026 scoping review (PMID: 41733864) appropriately cited as confirming the gap
- CDW feasibility is accurately assessed

**Minor note:** Could have cited the AJKD editorial accompanying Fu et al. that explicitly calls for further comparative effectiveness research, but this is not a required addition.

### Q4: Early Rhythm vs Rate Control in Age >= 80 — **VERIFIED**

**Gap Score: 7/10 (confirmed)**

**What the worker got right:**
- Critical finding from Kim 2022 (PMID: 35589174) that benefit attenuates with age
- Important note that Kim uses >=75 cutoff, supporting but not directly addressing the >=80 question
- Frailty attenuation finding (PMID: 36684588) adds depth
- 2019 systematic review (PMID: 31745834) showing insufficient evidence in >=65
- Appropriate CDW feasibility concerns about treatment crossover

**Note:** The CDW feasibility rating of MODERATE is accurate. Treatment strategy classification from EHR data is indeed challenging.

### Q5: Apixaban vs Rivaroxaban in Morbid Obesity — **VERIFIED**

**Gap Score: 5/10 (confirmed)**

Worker's downward revision from 7/10 was appropriate given the 2023 direct comparison study (PMID: 37713139). Small sample (N=303) limits conclusions, but the gap has meaningfully narrowed.

### Q6: Apixaban vs Rivaroxaban in Liver Disease — **VERIFIED**

**Gap Score: 6/10 (confirmed)**

Limited evidence cited (only 2 PMIDs), but this is appropriate given the sparse literature. CDW feasibility concern (cannot determine Child-Pugh score) is well-noted.

### Q7: LAAC vs DOAC — **REVISED**

**Gap Score: 6/10 -> 4/10**

**Issue:** A target trial emulation of LAAC vs DOAC has now been published (2026, Journal of Interventional Cardiac Electrophysiology) using Medicare data. N=3,692 pLAAO + 11,076 DOAC. Found no significant difference in stroke/TIA/SE. This substantially reduces the evidence gap. Combined with low CDW feasibility for single-site study, this question should be deprioritized.

---

## What Was Done Well

1. **Three-pass search strategy** was genuinely executed and documented. The targeted per-question searches in Pass 2 found meaningful new papers (e.g., the age-attenuation finding for Q4, the direct obesity comparison for Q5).
2. **Gap score self-revision** — the worker appropriately revised gap scores downward when Pass 2 found new evidence (Q3: 8->7, Q5: 7->5). This demonstrates honest assessment rather than confirmation bias.
3. **Diverse source coverage** — papers cited span cardiology, nephrology, geriatrics, pharmacy, and PK journals. Not just high-impact general medicine journals.
4. **CDW feasibility assessments** are specific and operationalizable, with correct PCORnet CDM table references (PRESCRIBING, DIAGNOSIS, LAB_RESULT_CM, VITAL, DEMOGRAPHIC, DEATH).
5. **Stress-testing documentation** — the worker documented their own stress-testing of key claims, which is commendable.

---

## Approved Questions for Feasibility

The following questions should advance to Phase 2 (feasibility assessment), pending the corrections noted above:

| Rank | Question | Gap Score | Verdict | Condition for Advancement |
|------|----------|-----------|---------|---------------------------|
| 1 | OAC vs no OAC at CHA2DS2-VASc = 1 | 9/10 | REVISED | Add BRAIN-AF trial citation; note it tested OAC vs placebo in this population with null result |
| 2 | DOAC underdosing vs correct dosing | 8/10 | REVISED | Correct HERA-FIB HR (1.84 composite, not 1.98 mortality); add ASPIRE study; correct Campbell underdosing prevalence |
| 3 | Apixaban vs rivaroxaban in CKD 3b-5 | 7/10 | VERIFIED | No changes needed |
| 4 | Early rhythm vs rate control in age >= 80 | 7/10 | VERIFIED | No changes needed |

**Questions NOT advancing:**

| Rank | Question | Gap Score | Reason |
|------|----------|-----------|--------|
| 5 | Apixaban vs rivaroxaban in obesity | 5/10 | Gap score below threshold; direct comparison exists |
| 6 | Apixaban vs rivaroxaban in liver disease | 6/10 | Smaller population, CDW feasibility concerns |
| 7 | LAAC vs DOAC | 4/10 (revised down) | TTE now exists (2026); low CDW feasibility |

---

## Required Corrections Before Advancing

These are specific, actionable changes the worker must make:

1. **01_literature_scan.md, Section 2.5 (DOAC Dosing):** Change HERA-FIB entry from "HR 1.98 for all-cause mortality" to "HR 1.84 for composite of all-cause mortality, stroke, major bleeding, and MI."
2. **01_literature_scan.md, Section 2.8:** Add BRAIN-AF trial (PMID: 41501492, Healey 2025, Nature Medicine): RCT of rivaroxaban 15mg vs placebo in CHA2DS2-VASc 0-1, N=1,235, stopped for futility, no benefit on cognitive decline + stroke composite.
3. **02_evidence_gaps.md, Q2 justification:** Correct HERA-FIB HR. Change PMID 37712551 prevalence from 15% to 17%. Add ASPIRE study (PMID: 40113236) as counterpoint showing null results in single-criterion patients.
4. **02_evidence_gaps.md, Q1 justification:** Note BRAIN-AF trial existence and explain why it does not close the gap (different dose, endpoint, population).
5. **02_evidence_gaps.md, Q7:** Update gap score to 4/10 and note 2026 LAAC vs DOAC TTE.
