# Review: Literature Discovery — Atrial Fibrillation

## Summary Verdict: REVISE

The literature scan and evidence gaps documents demonstrate thorough three-pass
searching with strong coverage of the AF landscape. However, two critical errors
require revision before approval: (1) the direction of effect for Liu 2025
(PMID 41121356) is reversed — the worker wrote "digoxin associated with lower
mortality" when the study found digoxin associated with **higher** mortality;
(2) a TTE study directly comparing apixaban vs rivaroxaban (PMID 36252244,
Annals of Internal Medicine 2022) was missed entirely, invalidating the
Section 8 claim that TTE has "NOT been applied to head-to-head DOAC comparisons
(apixaban vs rivaroxaban) in any population." Additionally, CLOSURE-AF results
are mischaracterized. These errors affect gap scoring for Q1 and the
characterization of Q7.

---

## 1. PMID Verification

Verified 10 key PMIDs via fetch_abstracts. Results:

| PMID | Worker's Claim | Abstract Says | Verdict |
|------|---------------|---------------|---------|
| 34271110 (Mei 2021) | TTE, Medicare, dabigatran superior for composite | Confirmed: emulated target trial, dabigatran superior (HR 1.232 for rivaroxaban) | **PASS** |
| 41121356 (Liu 2025) | TTE, digoxin vs BB: digoxin associated with **lower** mortality | Digoxin associated with **higher** all-cause mortality (RR 1.21, 95% CI 1.17–1.26), **higher** CV mortality, **higher** HF hospitalization | **FAIL — direction reversed** |
| 37839687 (Fu 2024) | Advanced CKD: apixaban lower bleeding than rivaroxaban/warfarin | Confirmed: rivaroxaban HR 1.69, warfarin HR 1.85 for major bleeding vs apixaban | **PASS** |
| 38976880 (Simon 2024) | Cirrhosis: apixaban lowest bleeding | Confirmed: rivaroxaban HR 1.47, warfarin HR 1.38 for hemorrhage vs apixaban | **PASS** |
| 40243977 (Martens 2025) | CABANA post-hoc: ablation beneficial in HFpEF | Confirmed: HR 0.82 for CV hospitalization/death in high HFpEF likelihood | **PASS** |
| 39447815 (DeLuca 2025) | Ablation superior in HFpEF | Confirmed: CA associated with decreased mortality (HR 0.431) | **PASS** |
| 40231086 (Lu 2025) | TTE, LAAC vs DOACs: LAAC lower dementia risk (HR 0.57) | Confirmed: HR 0.57 (95% CI 0.38–0.85) | **PASS** |
| 36315950 (Lau 2022) | Multinational: apixaban lower bleeding, similar stroke | Confirmed: apixaban lower GIB risk vs all DOACs, similar ischemic stroke | **PASS** |
| 39442621 (Dawwas & Cuker 2025) | Rivaroxaban vs apixaban: higher stroke (HR 1.23) and bleeding (HR 1.60) | Confirmed: stroke/SE HR 1.23, bleeding HR 1.60 | **PASS** |
| 32865375 (EAST-AFNET 4) | RCT: early rhythm control reduced CV death/stroke/HF | Confirmed: HR 0.79 (96% CI 0.66–0.94) | **PASS** |

Additionally verified:
| PMID | Verification | Verdict |
|------|-------------|---------|
| 41849741 (CLOSURE-AF) | Worker said "results pending/recent" — actual result: LAAC was **NOT noninferior** to medical therapy (p=0.44 for noninferiority) | **FAIL — mischaracterized** |
| 35968706 (Rillig 2022) | EAST-AFNET4 high comorbidity subanalysis | **PASS** |
| 39191612, 38112741 | LAAC meta-analyses in CKD — confirmed real | **PASS** |

**PMID verification score: 12/14 pass (2 failures)**

---

## 2. Critical Error: Missed TTE Study (PMID 36252244)

**This is the most important finding of this review.**

PMID 36252244 (Annals of Internal Medicine, 2022) is titled: "Apixaban Versus
Rivaroxaban in Patients With Atrial Fibrillation and Valvular Heart Disease:
A Population-Based Study."

The abstract explicitly states: **"To emulate a target trial of effectiveness
and safety of apixaban and rivaroxaban in patients with AF and VHD."**

This study used a new-user, active comparator design with PS-matched cohorts
(N=19,894) and found apixaban was associated with lower stroke/SE (HR 0.57)
and lower bleeding (HR 0.51) compared with rivaroxaban.

**Impact on worker's claims:**

1. **Section 8 claim FALSIFIED:** "TTE methodology has NOT been applied to:
   Head-to-head DOAC comparisons (apixaban vs rivaroxaban) in any population."
   This is wrong — PMID 36252244 applied TTE to exactly this comparison.

2. **Q1 TTE novelty score overestimated:** The worker scored TTE novelty = 2
   ("No TTE in this domain"), but TTE has been applied to apixaban vs rivaroxaban
   in a related population (VHD). TTE novelty should be 1 ("TTE applied to related
   question"), reducing Q1's gap score from 9 to **8**.

3. **Section 1 claim partially wrong:** "No TTE study has directly compared
   apixaban vs rivaroxaban" is false in the general case. The narrower claim —
   no TTE has compared them **in CKD** — is correct and should be the stated gap.

**Action required:** Add PMID 36252244 to Section 1, add to Section 8 TTE
inventory, correct Section 8 claims, and revise Q1 gap score to 8.

---

## 3. Critical Error: Liu 2025 Direction of Effect

In Sections 2 and 7 of the literature scan, the worker wrote:

> "Liu et al. 2025 | **TTE** | Digoxin vs beta-blocker in AF+HF: digoxin
> associated with lower mortality"

The abstract states the exact opposite: **"digoxin was associated with
significantly higher risks of all-cause mortality (AR: 51.2% vs 42.2%;
RR: 1.21), cardiovascular mortality (AR: 25.1% vs 21.0%; RR: 1.20), and
heart failure hospitalization."**

This error appears in two tables (Sections 2 and 7) and could mislead
downstream protocol design.

**Action required:** Correct the finding description in both sections to:
"digoxin associated with **higher** mortality and HF hospitalization vs
beta-blocker."

---

## 4. CLOSURE-AF Mischaracterization

The worker listed CLOSURE-AF (PMID 41849741) as "LAAC vs medical therapy:
results pending/recent." The trial has been published (NEJM) and showed
**LAAC was NOT noninferior** to physician-directed best medical care
(difference in RMST: −0.36 years; p=0.44 for noninferiority).

This is significant context for Q5 (LAAC in dialysis), as it undermines
the case for LAAC over medical therapy in high-risk patients.

**Action required:** Update Section 6 to reflect the actual CLOSURE-AF
result.

---

## 5. Search Completeness Verification

### Pass 2 (Targeted per-question PICO searches)

**Q1 (Apixaban vs rivaroxaban in CKD):** I ran `"apixaban" AND "rivaroxaban"
AND ("chronic kidney disease" OR "CKD" OR "renal insufficiency" OR "dialysis")
AND "atrial fibrillation"` — 191 results. Worker captured the key primary
studies (Fu 2024, Siontis 2018, Lau 2022). Additional meta-analyses found
(Kao 2024 PMID 38606775, Hashimoto 2025 PMID 40468697, de Lucena 2024
PMID 38281231) are secondary sources. No major primary studies missed in CKD.
**However**, the broader apixaban vs rivaroxaban TTE (PMID 36252244) was missed.

**Q2 (Catheter ablation in HFpEF):** I ran `"catheter ablation" AND ("heart
failure with preserved ejection fraction" OR "HFpEF") AND "atrial fibrillation"`
— 134 results. Worker captured the most important papers (CABANA subanalysis,
DeLuca 2025, Oraii 2024 meta-analysis, CABA-HFPEF protocol). Additional
meta-analyses found (Bulhões 2024 PMID 38621498, Mahalleh 2025 PMID 39278992,
Wani 2025 PMID 41426236, Gu 2022 PMID 35544952) and an observational study
(Zylla 2022 PMID 36126143). These are secondary/confirmatory — no TTE studies
found. Search completeness adequate.

**Q3 (DOACs in cirrhosis):** I ran `("direct oral anticoagulant" OR "DOAC" OR
"apixaban" OR "rivaroxaban") AND ("cirrhosis" OR "liver disease") AND "atrial
fibrillation"` — 87 results. Worker captured key papers (Simon 2024, Lawal 2023,
Song 2024). Additional studies found include Chou 2025 (PMID 39495818), network
meta-analysis (Shaikh 2024 PMID 39583376), and multinational cohort study. No
TTE studies found. Search completeness adequate.

### Pass 3 (Citation chaining and TTE verification)

**TTE inventory verification:** I searched PubMed for `"target trial emulation"
AND ("DOAC" OR "apixaban" OR "rivaroxaban") AND "atrial fibrillation"` — 6
results. Worker's inventory of 10 TTE studies is largely accurate, but:
- **Missing:** PMID 36252244 (apixaban vs rivaroxaban in VHD — explicit TTE)
- **Potentially missing:** PMID 39992678 (Quinlan 2025, comparative bleeding
  in HIV+AF — appeared in TTE search; may use TTE methodology)

**No TTE for rhythm control confirmed:** PubMed search for TTE + rhythm/rate
control + AF returned 0 results. WebSearch found only RCTs (EAST-AFNET4,
AF-CHF, RAFT-AF). Worker's claim verified.

**No TTE for ablation in HF confirmed:** WebSearch found no TTE studies.
Only RCTs (CASTLE-AF, CASTLE-HTx, CAMTAF). Worker's claim verified.

**No TTE for cirrhosis confirmed:** WebSearch found no TTE studies in
anticoagulation + cirrhosis + AF. Worker's claim verified.

### Stress-testing "no study" claims

| Claim | Search Method | Verdict |
|-------|--------------|---------|
| "No TTE comparing apixaban vs rivaroxaban" (Section 1) | PubMed + WebSearch | **FALSE** — PMID 36252244 is an explicit TTE of this comparison |
| "No TTE in CKD" (Q1) | PubMed + WebSearch | Correct — no TTE in CKD specifically |
| "No TTE for ablation in HFpEF" (Q2) | PubMed + WebSearch | Correct |
| "No TTE for anticoag in cirrhosis" (Q3) | PubMed + WebSearch | Correct |
| "No TTE for rhythm vs rate in HF" (Q4) | PubMed + WebSearch | Correct |
| "Mei 2021 is the only DOAC-vs-DOAC TTE" (Section 1) | PubMed TTE+DOAC search | **FALSE** — PMID 36252244 is also a DOAC-vs-DOAC TTE |

---

## 6. Per-Question Verdicts

### Q1: Apixaban vs Rivaroxaban in AF + Advanced CKD — **REVISED**

- **PMIDs:** All verified correctly
- **Gap characterization:** Sound for CKD specifically, but the broader "no TTE"
  framing is wrong (PMID 36252244 exists)
- **Gap score:** Revise from 9 → **8** (TTE novelty = 1, not 2)
- **Required changes:**
  1. Add PMID 36252244 to Section 1 and Section 8
  2. Narrow TTE novelty claim to CKD specifically
  3. Correct Section 8 broad claims about DOAC TTE

### Q2: Catheter Ablation vs AADs in AF + HFpEF — **VERIFIED**

- **PMIDs:** All verified correctly
- **Gap characterization:** Accurate — no TTE confirmed
- **Gap score:** 8 is justified
- **Notes:** Rich meta-analysis literature confirms the gap. Worker's coverage
  of primary studies is adequate.

### Q3: DOACs vs Warfarin in AF + Liver Cirrhosis — **VERIFIED**

- **PMIDs:** All verified correctly
- **Gap characterization:** Accurate — no TTE, all patients excluded from RCTs
- **Gap score:** 8 is justified
- **Notes:** Additional studies found (Chou 2025, network meta-analyses) are
  confirmatory.

### Q4: Early Rhythm Control vs Usual Care in AF + HF — **VERIFIED**

- **PMIDs:** All verified correctly (including Rillig 2022 = EAST subanalysis)
- **Gap characterization:** Accurate — no TTE for rhythm vs rate in HF subgroups
- **Gap score:** 7 is justified
- **Notes:** Worker appropriately distinguished Liu 2025 TTE (rate-control drug
  choice) from the rhythm-vs-rate strategy question.

### Q5: LAAC vs Continued Anticoagulation in AF + Dialysis — **REVISED**

- **PMIDs:** Verified (including meta-analyses)
- **Gap characterization:** Mostly accurate, but CLOSURE-AF result must be updated
- **Gap score:** 6 remains reasonable, possibly should be lower given CLOSURE-AF failure
- **Required changes:**
  1. Update CLOSURE-AF characterization to reflect that LAAC was NOT noninferior
  2. Note that this negative result may dampen enthusiasm for LAAC-focused TTE

### Q6: DOAC Dose Reduction in Elderly — **VERIFIED**

- **Gap score:** 6 is reasonable
- **No issues identified**

### Q7: Digoxin vs BB for Rate Control in AF + HF — **REVISED**

- **Direction of effect error is critical** — must be corrected
- **Gap score:** 5 is appropriate (TTE already applied, as correctly noted)
- **Required changes:**
  1. Fix Liu 2025 finding in Sections 2 and 7: "higher mortality" not "lower"

---

## 7. What Was Done Well

1. **Three-pass strategy executed thoroughly.** The worker documented 8 broad
   searches, 5 targeted PICO searches, and citation chaining — a systematic
   approach that covered the landscape effectively.

2. **TTE inventory is valuable.** Compiling 10 TTE studies in AF is genuinely
   useful for identifying methodological gaps. The inventory is mostly accurate
   (9/10 correctly characterized).

3. **Gap scoring methodology is transparent.** The 5-dimension scoring framework
   is well-defined and applied consistently.

4. **Q7 correctly flagged as having an existing TTE.** Identifying Liu 2025 as
   prior art for digoxin vs BB shows appropriate methodological awareness (despite
   the direction-of-effect error).

5. **Self-consistency checks were attempted.** The stress-testing documentation in
   Q1–Q3 shows the worker tried to verify their own claims, though the verification
   was incomplete (missed PMID 36252244).

6. **Strong clinical framing.** The PICO specifications are well-constructed and
   the clinical rationale for each gap is sound.

---

## 8. Summary of Required Revisions

| Priority | Issue | Affected Sections | Action |
|----------|-------|-------------------|--------|
| **Critical** | Liu 2025 direction of effect reversed | Sections 2, 7 | Change "lower mortality" → "higher mortality" |
| **Critical** | Missed PMID 36252244 (TTE of apixaban vs rivaroxaban) | Sections 1, 8; Q1 gap score | Add paper, revise TTE novelty claims, lower Q1 gap score to 8 |
| **Major** | CLOSURE-AF mischaracterized as "pending/recent" | Section 6 | Update to reflect negative result (not noninferior) |
| **Minor** | Section 8 TTE inventory incomplete | Section 8 | Add PMID 36252244 to inventory |
| **Minor** | Simon 2024 characterized as "rivaroxaban comparable to warfarin" | Section 5 | More accurate: both rivaroxaban and warfarin had higher bleeding vs apixaban |

---

## 9. Approved Questions (Pending Revision)

After the required revisions are made, the following questions are approved
for protocol development:

1. **Apixaban vs rivaroxaban in AF + advanced CKD** — Approved at revised gap
   score 8. Narrow the TTE novelty claim to CKD-specific gap.
2. **Catheter ablation vs AADs in AF + HFpEF** — Approved at gap score 8.
3. **DOACs vs warfarin in AF + liver cirrhosis** — Approved at gap score 8.
4. **Early rhythm control vs usual care in AF + HF** — Approved at gap score 7.
5. **LAAC vs anticoag in AF + dialysis** — Conditionally approved at gap score 6,
   pending CLOSURE-AF characterization update.
6. **DOAC dose reduction in elderly** — Approved at gap score 6.
7. **Digoxin vs BB in AF + HF** — **Not approved** for protocol development
   (TTE already exists; Liu 2025). Approved as correctly identified prior art
   once the direction of effect is corrected.

**Recommended top 3 for protocol development (unchanged):**
1. Apixaban vs rivaroxaban in AF + advanced CKD (revised score: 8)
2. Catheter ablation vs AADs in AF + HFpEF (score: 8)
3. DOACs vs warfarin in AF + liver cirrhosis (score: 8)
