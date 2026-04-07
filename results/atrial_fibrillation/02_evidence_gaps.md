# Evidence Gaps: Atrial Fibrillation — Ranked Causal Questions

**Therapeutic area:** Atrial fibrillation (AF)
**Protocol target:** CDW (PCORnet CDM)
**Date:** 2026-04-06
**Status:** FINAL — All three search passes complete.

---

## Ranking Criteria

Gap scores (1-10) consider:
- **Clinical importance** — Does the answer change practice?
- **Evidence gap size** — How much existing evidence addresses this question?
- **TTE suitability** — Is this question well-suited to target trial emulation?
- **CDW feasibility** — Can this be studied with PCORnet CDM EHR data?

---

## Ranked Causal Questions

### Question 1: Anticoagulation vs No Anticoagulation in AF with CHA2DS2-VASc = 1 (Men) / 2 (Women)

**Gap Score: 9/10**

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF and CHA2DS2-VASc = 1 (men) or 2 (women) |
| **Intervention** | Oral anticoagulation (any DOAC or warfarin) |
| **Comparator** | No anticoagulation |
| **Outcome** | Primary: Ischemic stroke or systemic embolism; Secondary: Major bleeding, all-cause mortality, net clinical benefit |
| **Causal contrast** | What is the causal effect of initiating anticoagulation vs. no anticoagulation on stroke/SE risk in AF patients at the threshold of guideline-recommended treatment? |

**Justification:**
- This is the single most debated clinical decision in AF management
- Guidelines give a weak/conditional recommendation for this group (Class IIb, 2023 ACC/AHA; PMID: 38033089)
- It is UNETHICAL to randomize patients to no anticoagulation when guidelines suggest potential benefit, making this a perfect TTE target
- Prior observational studies show conflicting results:
  - Lip et al. (PMID: 25770314): No benefit from OAC or aspirin at CHA2DS2-VASc 0-1
  - Friberg et al. (PMID: 26223245): Positive net clinical benefit for warfarin at score 1
  - Individual risk factor heterogeneity: hypertension alone may warrant OAC (PMC: 5919811), while young patients at score 1 have uncertain benefit (PMC: 5121486)
  - Risk refinement studies show different stroke rates depending on WHICH risk factor drives the score (PMID: 25039724)
- No net clinical benefit analysis has been done with DOACs (only warfarin)
- The ARTESiA trial (PMID: 37952132) showed apixaban reduces stroke vs aspirin in subclinical AF, but this is a different population
- The BRAIN-AF trial (PMID: 41501492, Nature Medicine 2025) is the only RCT testing anticoagulation vs placebo in CHA2DS2-VASc 0-1: rivaroxaban 15mg vs placebo in N=1,235, stopped for futility with no benefit (HR 1.10, P=0.46). However, it used reduced-dose rivaroxaban, targeted cognitive decline as primary endpoint, enrolled younger patients (mean age 53), and combined scores 0 and 1 — so it does not close the gap for DOAC benefit at CHA2DS2-VASc = 1 specifically
- Biomarkers (hs-cTnT) may improve risk prediction at intermediate scores (PMC: 12370022)
- 2024 ESC guidelines updated anticoagulation threshold recommendations (PMC: 11865665)
- **Stress-tested:** After 6 targeted searches and citation chaining from 3 key papers, NO target trial emulation and NO RCT exists for this specific question. Gap confirmed.

**CDW Feasibility:** HIGH
- CHA2DS2-VASc components: age (DEMOGRAPHIC), sex (DEMOGRAPHIC), HF/HTN/DM/stroke/vascular disease (DIAGNOSIS ICD codes), all available
- Anticoagulation exposure: PRESCRIBING (RXNORM_CUI for DOACs/warfarin)
- Stroke outcomes: DIAGNOSIS (ICD-10 I63.x), DEATH table
- Time zero: Date of first AF diagnosis without prior anticoagulation

**Supporting PMIDs:** 25770314, 26223245, 27520653, 38033089, 25039724, 22268375, 23018151, 22473219, 31349811, 37952132, 39019530, 37573616, 41501492, PMC:7270900, PMC:5121486, PMC:5919811, PMC:5778974, PMC:11865665, PMC:12370022

---

### Question 2: Causal Effect of Inappropriate DOAC Underdosing vs Guideline-Concordant Dosing on Clinical Outcomes

**Gap Score: 8/10**

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF newly initiated on a DOAC (apixaban or rivaroxaban) |
| **Intervention** | Inappropriately reduced DOAC dose (below label criteria for dose reduction) |
| **Comparator** | Guideline-concordant DOAC dosing |
| **Outcome** | Primary: Composite of stroke/SE and major bleeding; Secondary: Stroke/SE alone, major bleeding alone, all-cause mortality |
| **Causal contrast** | What is the causal effect of receiving an inappropriately low DOAC dose (vs. guideline-concordant dose) on stroke/bleeding outcomes? |

**Justification:**
- 15-21% of AF patients receive inappropriately low DOAC doses in clinical practice (PMID: 39867851, 39666256; PMC: 8188240 prevalence meta-analysis: 20%)
- Observational evidence consistently shows worse outcomes with underdosing:
  - Stroke/SE: HR 1.29 (PMC: 8027572, 11 studies); rivaroxaban underdosing: HR 1.31 for stroke/SE (PMID: 35643840)
  - Composite (mortality + stroke + major bleeding + MI): HR 1.84 in HERA-FIB (PMID: 39867851); all-cause mortality: HR 1.37 (PMC: 8027572); HR 1.25 (PMID: 32943160)
  - Apixaban underdosing: 5-fold increased stroke risk in some analyses; all-cause mortality HR 1.24 (PMID: 35643840)
  - Meta-analysis of 148,909 patients: higher mortality (RR 2.8) with underdosing (PMC: 8012667)
  - Off-label reduced apixaban in elderly: 17% underdosed (201/1172), 10.9% vs 1.4% mortality, though stroke rates similar (PMID: 37712551)
  - ASPIRE study (PMID: 40113236, 2025): Prospective Korean cohort (N=1,944) of AF patients with a single dose-reduction criterion — NO significant difference in stroke/SE, major bleeding, or mortality between off-label reduced-dose and standard-dose apixaban at 1 year. Suggests underdosing harm may be subgroup-dependent
- 41% of clinicians admit to empirically underdosing apixaban (PMC: 8483523)
- In AF+HF+CKD, 53.2% received off-label underdosed apixaban (PMC: 12099564)
- Evidence is heterogeneous: large meta-analyses consistently show harm, but the ASPIRE study (single-criterion subgroup, Asian population) shows null results, suggesting the effect may be subgroup-dependent
- NO target trial emulation has been performed. A sequential TTE was done for DOAC reinitiation after ICH (PMC: 11934045), confirming TTE methodology is applicable to DOAC questions, but the underdosing question remains unaddressed.
- Confounding by indication is the key concern: physicians may underdose sicker/frailer patients
- **Stress-tested:** After 4 targeted searches and citation chaining, confirmed no TTE exists. Multiple meta-analyses and >20 observational studies exist, but all use conventional epidemiologic methods without formal causal framework. Gap confirmed.

**CDW Feasibility:** HIGH
- DOAC prescriptions: PRESCRIBING (RXNORM_CUI includes dose-specific formulations — apixaban 2.5mg vs 5mg, rivaroxaban 15mg vs 20mg)
- Dose appropriateness assessment requires: weight (VITAL), serum creatinine/eGFR (LAB_RESULT_CM), age (DEMOGRAPHIC)
- FDA dose-reduction criteria for apixaban: any 2 of {age >= 80, weight <= 60kg, serum creatinine >= 1.5 mg/dL}
- Outcomes: stroke (DIAGNOSIS ICD-10 I63.x), bleeding (ICD-10 codes for GI/ICH bleeding)
- Can operationalize: Compare patients who received reduced dose WITHOUT meeting criteria vs patients on standard dose

**Supporting PMIDs:** 39867851, 39666256, 32943160, 33444586, 37712551, 35643840, 34932377, 35095525, PMC:8027572, PMC:8483523, PMC:11012240, PMC:10248740, PMC:8012667, PMC:8188240, PMC:10842588, PMC:12099564, PMC:11934045

---

### Question 3: Apixaban vs Rivaroxaban in AF Patients with CKD Stage 3b-5

**Gap Score: 7/10** *(revised down from 8 after Pass 2: more evidence exists than initially assessed)*

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF and CKD stage 3b-5 (eGFR < 45 mL/min/1.73m2) |
| **Intervention** | Apixaban |
| **Comparator** | Rivaroxaban |
| **Outcome** | Primary: Composite of stroke/SE and major bleeding; Secondary: Stroke/SE, major bleeding, GI bleeding, all-cause mortality |
| **Causal contrast** | Does apixaban cause different rates of stroke/SE or major bleeding compared to rivaroxaban in AF patients with moderate-to-severe CKD? |

**Justification:**
- Landmark DOAC RCTs excluded severe CKD (eGFR <25-30 in most trials)
- Apixaban has the lowest renal clearance (~27%) vs rivaroxaban (~36%) — pharmacokinetic rationale for preference (PMC: 11344734)
- Head-to-head data is EMERGING but limited:
  - Nationwide US cohort (PMID: 37839687, 2024): Rivaroxaban associated with higher major bleeding vs apixaban in CKD 4/5
  - Rivaroxaban vs apixaban in ESRD/dialysis (PMID: 31925840): Direct comparison but small sample
  - Rivaroxaban or apixaban in CKD 4-5/dialysis meta-analysis (PMID: 33538928): Both safe/effective vs warfarin but no DOAC-vs-DOAC analysis
  - Apixaban dose study in severe CKD (PMID: 37681341): 5mg vs 2.5mg dosing question in CKD
- Most evidence is DOAC-class vs warfarin, not DOAC-vs-DOAC (PMID: 38035566, 36579375, 38744617)
- 2026 scoping review (PMID: 41733864) explicitly identifies "limited dose-comparison studies, heterogeneous outcomes and sparse data in non-dialysis patients" as gaps
- Non-dialysis CKD stage 3b-4 is the biggest gap: too sick for RCT inclusion, not on dialysis where some data exists
- Clinical importance: nephrologists face this choice daily with limited comparative effectiveness data
- **Stress-tested:** After 4 targeted searches and citation chaining from PMID 37839687, confirmed that one key US nationwide cohort study and a scoping review exist, but the non-dialysis CKD 3b-4 population remains understudied.

**CDW Feasibility:** HIGH
- AF diagnosis: DIAGNOSIS (ICD-10 I48.x)
- CKD staging: LAB_RESULT_CM (eGFR by LOINC codes 48642-3, 62238-1), DIAGNOSIS (ICD-10 N18.3x, N18.4, N18.5)
- DOAC exposure: PRESCRIBING (RXNORM_CUI)
- eGFR trajectory available for defining CKD stage at baseline
- Potential limitation: eGFR lab completeness should be verified against CDW data profile

**Supporting PMIDs:** 37839687, 41733864, 33538928, 37681341, 32160801, 36381830, 31925840, 38230301, 40160594, 38035566, 36579375, 38744617, 34932078, 36252244, 39154873, 31648714, PMC:10545858, PMC:11344734

---

### Question 4: Early Rhythm Control vs Rate Control in Elderly AF Patients (Age >= 80)

**Gap Score: 7/10**

| Element | Specification |
|---------|--------------|
| **Population** | Adults >= 80 years with newly diagnosed AF (within 12 months) |
| **Intervention** | Early rhythm control strategy (antiarrhythmic drugs and/or cardioversion/ablation within 12 months of AF diagnosis) |
| **Comparator** | Rate control strategy (beta-blockers, calcium channel blockers, digoxin) |
| **Outcome** | Primary: Composite of CV death, stroke, HF hospitalization; Secondary: All-cause mortality, AF-related hospitalization |
| **Causal contrast** | Does initiating early rhythm control (vs rate control) cause different rates of the composite CV outcome in elderly AF patients >= 80 years? |

**Justification:**
- EAST-AFNET 4 (PMID: 32865375) showed early rhythm control benefit; median age 70, but elderly >= 80 underrepresented
- **Critical finding from Pass 2:** Early rhythm control benefit ATTENUATES with increasing age (PMID: 35589174, nationwide cohort)
- Frailty further attenuates the benefit (PMID: 36684588)
- A systematic review of rate vs rhythm in patients >=65 (PMID: 31745834) found INSUFFICIENT evidence to recommend either strategy
- AFFIRM elderly subgroup showed possible HARM from rhythm control in older patients
- High-comorbidity patients still benefit (PMID: 36942567), but these studies don't isolate the very elderly
- Multiple real-world cohort studies exist (PMID: 36942567, 34889116, 36224587) but none specifically target >=80
- AAD toxicity (amiodarone, flecainide) is more concerning in the elderly — side effect profile may offset rhythm control benefits
- This question directly impacts clinical decision-making for the fastest-growing AF demographic

**CDW Feasibility:** MODERATE
- Age from DEMOGRAPHIC (BIRTH_DATE)
- AF diagnosis: DIAGNOSIS (ICD-10 I48.x) with onset date
- Rhythm control: PRESCRIBING (AADs: amiodarone, flecainide, propafenone, sotalol, dofetilide RXNORMs) + PROCEDURES (cardioversion CPT, ablation CPT)
- Rate control: PRESCRIBING (beta-blockers, diltiazem, verapamil, digoxin RXNORMs)
- Outcomes: DIAGNOSIS, DEATH table
- Challenge: Defining treatment strategies requires careful classification (first prescription after AF diagnosis)
- Challenge: Treatment crossover and AAD switches are common

**Supporting PMIDs:** 32865375, 35589174, 36684588, 36942567, 34889116, 36224587, 38727662, 31745834, 34610350, 35621202, 34447995, PMC:10205477, PMC:9939510, 35255732, 12466506

---

### Question 5: Apixaban vs Rivaroxaban in AF Patients with Morbid Obesity (BMI >= 40)

**Gap Score: 5/10** *(revised down from 7 after Pass 2: a direct comparison study now exists)*

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF and BMI >= 40 kg/m2 |
| **Intervention** | Apixaban |
| **Comparator** | Rivaroxaban |
| **Outcome** | Primary: Stroke/SE; Secondary: Major bleeding, all-cause mortality |
| **Causal contrast** | Does apixaban cause different rates of thromboembolic or bleeding events compared to rivaroxaban in morbidly obese AF patients? |

**Justification:**
- ISTH 2016 guidance recommended avoiding DOACs in BMI >40 or weight >120kg due to limited data
- Post-hoc analyses of ARISTOTLE (PMID: 27071819) and ENGAGE AF showed apixaban and edoxaban effective in BMI >= 40 vs warfarin
- Real-world data suggests DOACs are safe in morbid obesity (PMID: 34825048)
- **Pass 2 finding:** A direct real-world comparison NOW EXISTS (PMID: 37713139, 2023): Apixaban vs rivaroxaban in obese/morbidly obese AF — no difference in stroke/TIA/MI, but small study with baseline differences
- Additional data: apixaban/rivaroxaban in BMI >= 50 (PMID: 34820876); DOACs in obese AF+HF (PMID: 36419246)
- PK reviews reassuring: modest body weight effect on apixaban PK (PMID: 35570249)
- The gap has narrowed substantially with the 2023 direct comparison study

**CDW Feasibility:** MODERATE-HIGH
- BMI: VITAL table (ORIGINAL_BMI or calculated from HT/WT)
- Same DOAC and outcome variables as Question 3

**Supporting PMIDs:** 37713139, 34820876, 34825048, 35501916, 36419246, 40002903, 35570249, 27071819, 38033089

---

### Question 6: Apixaban vs Rivaroxaban in AF Patients with Concomitant Liver Disease

**Gap Score: 6/10**

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF and chronic liver disease (excluding Child-Pugh C) |
| **Intervention** | Apixaban |
| **Comparator** | Rivaroxaban |
| **Outcome** | Primary: Major bleeding; Secondary: Stroke/SE, all-cause mortality, GI bleeding |
| **Causal contrast** | Does apixaban cause different rates of bleeding compared to rivaroxaban in AF patients with liver disease? |

**Justification:**
- All DOAC RCTs excluded significant liver disease
- Rivaroxaban has highest hepatic metabolism (~66%) vs apixaban (different metabolic pathways)
- Meta-analyses (PMID: 32880804, 32626835) show DOACs safe in Child-Pugh A, not recommended in B/C
- These compare DOACs as a CLASS to VKA, not head-to-head
- Clinically important but smaller population than CKD/underdosing questions

**CDW Feasibility:** MODERATE
- Liver disease: DIAGNOSIS (ICD-10 K70-K77 codes)
- Cannot reliably determine Child-Pugh score from EHR data
- Smaller sample size expected

**Supporting PMIDs:** 32880804, 32626835

---

### Question 7: Left Atrial Appendage Closure vs DOAC for Stroke Prevention in AF

**Gap Score: 4/10** *(revised down from 6 after review: a TTE of LAAC vs DOAC has been published in 2026)*

| Element | Specification |
|---------|--------------|
| **Population** | Adults with non-valvular AF and CHA2DS2-VASc >= 2 |
| **Intervention** | Left atrial appendage closure (WATCHMAN or similar device) |
| **Comparator** | DOAC therapy (apixaban or rivaroxaban) |
| **Outcome** | Primary: Composite of stroke/SE and major bleeding; Secondary: All-cause mortality, device complications |
| **Causal contrast** | Does LAAC cause different rates of stroke/SE and bleeding compared to DOAC therapy in AF patients? |

**Justification:**
- All LAAC RCTs (PROTECT AF, PREVAIL) compared to WARFARIN, not DOACs
- OPTION trial (PMID: 39555822) compared LAAC to OAC post-ablation — showed less bleeding, similar efficacy
- No RCT of LAAC vs DOAC in general AF population exists
- LAAC is increasingly performed in patients with high bleeding risk

**CDW Feasibility:** LOW-MODERATE
- LAAC is relatively uncommon — small sample size
- Strong confounding by indication (LAAC patients selected for high bleeding risk)
- Positivity concerns — very different patient profiles
- May require multi-site PCORnet data

**Supporting PMIDs:** 39555822, 29103847, 27343417, 23325525

---

## Final Summary Table

| Rank | Question | Gap Score | CDW Feasibility | Top TTE Candidate? |
|------|----------|-----------|-----------------|---------------------|
| 1 | OAC vs no OAC at CHA2DS2-VASc = 1 | **9/10** | HIGH | **YES** — highest gap, highest feasibility |
| 2 | DOAC underdosing vs correct dosing | **8/10** | HIGH | **YES** — no TTE exists, excellent CDW fit |
| 3 | Apixaban vs rivaroxaban in CKD 3b-5 | **7/10** | HIGH | **YES** — gap narrowing but non-dialysis CKD understudied |
| 4 | Early rhythm vs rate control in age >= 80 | **7/10** | MODERATE | **YES** — age-attenuation finding makes this critical |
| 5 | Apixaban vs rivaroxaban in BMI >= 40 | 5/10 | MODERATE-HIGH | Maybe — direct comparison study now exists |
| 6 | Apixaban vs rivaroxaban in liver disease | 6/10 | MODERATE | Maybe — smaller population, feasibility concerns |
| 7 | LAAC vs DOAC | 4/10 | LOW-MODERATE | No — TTE now exists (2026); CDW feasibility too low for single-site |

**Recommended for protocol development:** Questions 1-4 (all have gap scores >= 7 and moderate-to-high CDW feasibility)

---

## Search Completeness Checklist

### Pass 1: Broad Landscape Searches — COMPLETE
- [x] 12 thematic PubMed searches (DOAC comparisons, rate/rhythm, ablation, LAAC, CKD, HF, liver/obesity, dosing, low CHA2DS2-VASc, bleeding, landmark RCTs)
- [x] >70 unique PMIDs identified
- [x] Study types distinguished (RCT, observational, meta-analysis, guideline)

### Pass 2: Targeted Per-Question Searches — COMPLETE
- [x] Q1 (CHA2DS2-VASc = 1): 2 narrow PICO searches run → 8 new papers found
- [x] Q2 (DOAC underdosing): 2 narrow PICO searches run → 10 new papers found; confirmed no TTE
- [x] Q3 (Apixaban vs rivaroxaban in CKD): 2 narrow PICO searches → key US cohort study and scoping review found; gap score revised
- [x] Q4 (Obesity): 1 narrow search → direct comparison study found; gap score revised down
- [x] Q5 (Elderly rhythm control): 1 narrow search → age-attenuation finding and frailty data found

### Pass 3: Citation Chaining — COMPLETE
- [x] Q1: Forward/backward from PMID 25770314 (Lip 2015) and PMID 26223245 → 8 additional papers
- [x] Q2: Forward from PMID 37712551 (Campbell 2024) and PMC:8012667 → 5 additional papers; TTE gap confirmed
- [x] Q3: Forward from PMID 37839687 (2024 US cohort) → 4 additional papers; gap assessment updated

### Stress-Testing of Claims — COMPLETE
- [x] Q1 "No TTE exists for OAC at CHA2DS2-VASc = 1" — stress-tested with 6 searches: CONFIRMED
- [x] Q2 "No TTE for underdosing" — stress-tested with 4 searches including "target trial emulation" + "DOAC": CONFIRMED (TTE exists for DOAC reinitiation after ICH but NOT underdosing)
- [x] Q3 "Limited head-to-head DOAC in CKD" — stress-tested: PARTIALLY REVISED (one key study found, but gap remains for non-dialysis CKD)
- [x] Q4 "No comparison in obesity" — REVISED (2023 direct comparison found; gap score lowered)
- [x] All cited papers come from diverse sources including specialty journals (nephrology: PMID 37839687, 41733864; geriatrics: PMID 37712551; pharmacy: PMID 35643840)
