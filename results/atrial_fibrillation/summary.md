# Executive Summary: Atrial Fibrillation Target Trial Emulation Protocols

## Overview

This project used a multi-agent autonomous pipeline to design target trial emulation (TTE) protocols for atrial fibrillation (AF) research, targeting an institutional PCORnet Clinical Data Warehouse (CDW) containing ~10 million patients. The pipeline executed four sequential phases -- literature discovery, evidence gap analysis with independent review, CDW feasibility assessment, and protocol generation with independent review -- producing three publication-ready TTE protocols with accompanying Quarto analysis scripts. The protocols address the three highest-priority evidence gaps in AF management where randomized trials are infeasible or have not been conducted, and where CDW data supports robust causal inference.

The CDW contains 86,308 AF patients, ~20,000 with oral anticoagulant prescriptions, and comprehensive comorbidity, laboratory, vital sign, and mortality data spanning 2016--2025 across two EHR eras (AllScripts and Epic).

## Evidence Landscape

The literature scan employed a three-pass search strategy (broad landscape, targeted per-question PICO searches, and citation chaining) identifying **>70 unique PMIDs** across 12+ landmark RCTs, 25+ observational cohorts, 15+ meta-analyses/systematic reviews, and 3 clinical guidelines. An independent reviewer verified 11 PMIDs against PubMed abstracts, finding 9 matches and 2 discrepancies (corrected). The reviewer also identified 2 studies missed by the primary search: the BRAIN-AF trial (PMID: 41501492, the only RCT of anticoagulation vs placebo in low-risk AF) and the ASPIRE study (PMID: 40113236, a prospective cohort complicating the underdosing narrative).

Seven candidate causal questions were identified and ranked by evidence gap size (1--10), clinical importance, TTE suitability, and CDW feasibility. Four questions scored >= 7/10 and advanced to feasibility assessment. Gap scores were revised iteratively as new evidence emerged (Q3: 8 to 7, Q5: 7 to 5, Q7: 6 to 4), demonstrating genuine rather than confirmatory assessment.

## Protocols Generated

### Protocol 1: Apixaban vs Rivaroxaban for Stroke Prevention in AF with CKD Stage 3b-5

- **Question:** Does apixaban cause different rates of stroke/SE or major bleeding compared to rivaroxaban in AF patients with moderate-to-severe CKD (eGFR < 45)?
- **Design:** Active-comparator, new-user TTE with inverse probability weighting (IPW)
- **Population:** Adults with NVAF and CKD 3b-5 (dual ascertainment: ICD-10 diagnosis or eGFR < 45), newly initiating apixaban or rivaroxaban
- **Estimated N:** 2,200--3,700 (apixaban ~1,500--2,500; rivaroxaban ~700--1,200)
- **Primary Outcome:** Composite of stroke/systemic embolism and major bleeding at 365 days
- **Key Strength:** Active-comparator design minimizes confounding by indication; dual CKD ascertainment (diagnosis + lab) maximizes capture; pharmacokinetic rationale (apixaban 27% vs rivaroxaban 36% renal clearance) grounds the hypothesis
- **Key Limitation:** Rivaroxaban arm is smaller (~2:1 ratio); unmeasured confounders include prescriber specialty, frailty, and LVEF
- **Review Verdict:** ACCEPT

### Protocol 2: Early Rhythm Control vs Rate Control in Elderly AF (Age >= 80)

- **Question:** Does initiating early rhythm control (vs rate control) cause different rates of a composite CV outcome in elderly AF patients >= 80 years?
- **Design:** Landmark TTE with 12-month treatment classification window and IPW
- **Population:** Adults >= 80 with newly diagnosed AF (first I48.x, no prior AF in 365 days) receiving rhythm or rate control within 12 months
- **Estimated N:** 9,000--15,000 (rhythm control ~3,000--5,000; rate control ~6,000--10,000)
- **Primary Outcome:** Composite of CV death, stroke, and HF hospitalization, assessed from the 12-month landmark for up to 3 additional years
- **Key Strength:** Landmark design correctly eliminates immortal time bias inherent in treatment classification windows; addresses the fastest-growing AF demographic systematically excluded from RCTs; DEATH_CAUSE completeness check with automatic fallback to all-cause mortality
- **Key Limitation:** Cannot adjust for LVEF or symptom severity (strong drivers of treatment selection); landmark excludes early treatment effects (both beneficial and harmful); treatment crossover dilutes ITT effect
- **Review Verdict:** ACCEPT

### Protocol 3: OAC vs No OAC at CHA2DS2-VASc = 1 (Men) / 2 (Women)

- **Question:** What is the causal effect of initiating oral anticoagulation vs no anticoagulation on stroke/SE risk in AF patients at the guideline treatment threshold?
- **Design:** Treated-vs-untreated, new-user TTE with IPW and net clinical benefit analysis
- **Population:** Adults with NVAF and CHA2DS2-VASc = 1 (men) or 2 (women), with no prior OAC use
- **Estimated N:** 12,000--16,000 eligible (~2,000--4,000 treated; ~8,000--12,000 untreated)
- **Primary Outcome:** Ischemic stroke or systemic embolism at 365 days; net clinical benefit (stroke reduction minus 1.5x ICH excess) as key secondary measure
- **Key Strength:** Addresses the single most debated clinical decision in AF management; natural comparator group exists (many clinicians defer OAC at this threshold); includes subgroup analysis by driving CHA2DS2-VASc component
- **Key Limitation:** Treated-vs-untreated design carries stronger confounding by indication than active-comparator designs; cannot capture OTC aspirin use; E-value analysis critical for interpreting results
- **Review Verdict:** REVISE (time-zero discrepancy between protocol document and SQL; corrected by coordinator)

## Feasibility Summary

| Rank | Question | Gap Score | CDW Feasibility | Estimated N | Advanced to Protocol? |
|------|----------|-----------|-----------------|-------------|----------------------|
| 1 | OAC vs no OAC at CHA2DS2-VASc = 1 | 9/10 | Partially feasible | 12,000--16,000 (2,000--4,000 treated) | Yes (Protocol 3) |
| 2 | DOAC underdosing vs correct dosing | 8/10 | Partially feasible | 600--1,500 underdosed | **No** -- sample too small |
| 3 | Apixaban vs rivaroxaban in CKD 3b-5 | 7/10 | Feasible | 2,200--3,700 | Yes (Protocol 1) |
| 4 | Early rhythm vs rate control in age >= 80 | 7/10 | Feasible | 9,000--15,000 | Yes (Protocol 2) |
| 5 | Apixaban vs rivaroxaban in obesity (BMI >= 40) | 5/10 | Moderate-high | -- | No -- gap score below threshold |
| 6 | Apixaban vs rivaroxaban in liver disease | 6/10 | Moderate | -- | No -- smaller population |
| 7 | LAAC vs DOAC | 4/10 | Low-moderate | -- | No -- TTE already published (2026) |

## Quality Assurance

**Literature review (Phase 1):** An independent reviewer verified 11 PMIDs against PubMed abstracts, identified 2 factual discrepancies (HERA-FIB: HR 1.84 for composite, not HR 1.98 for mortality; Campbell: 17% underdosed, not 15%), and found 2 missed studies (BRAIN-AF, ASPIRE). All corrections were applied to source files before advancing. The reviewer also stress-tested three "no TTE exists" claims with independent searches -- all confirmed.

**Protocol review (Phase 3):** An independent reviewer evaluated all three protocols against a TTE checklist (eligibility, treatment, assignment, time zero, outcome, estimand, causal contrast), verified code quality (CDW table references, legacy encounter filtering, ROW_NUMBER deduplication, T-SQL syntax, dynamic PS formula construction), and assessed immortal time bias. Protocols 1 and 2 were accepted without changes. Protocol 3 had a time-zero discrepancy (document said "first qualifying encounter" but SQL evaluated at "first AF encounter" only); the coordinator resolved this by updating the document to match the SQL and adding a limitations note.

**Cross-protocol quality:** All three protocols share consistent standards -- fully qualified CDW table names, legacy encounter filtering on all joins, RXNORM_CUI for medications, LOINC for labs, ROW_NUMBER deduplication, CONSORT flow diagrams, dynamic propensity score formula construction, E-value sensitivity analyses, and post-Epic era sensitivity analyses.

## Deferred Questions

| Question | Gap Score | Reason Deferred |
|----------|-----------|-----------------|
| DOAC underdosing vs guideline-concordant dosing | 8/10 | Inappropriately underdosed subgroup too small (~600--1,000 for apixaban) for robust causal inference. Recommended for multi-site PCORnet study. |
| Apixaban vs rivaroxaban in morbid obesity (BMI >= 40) | 5/10 | A direct real-world comparison now exists (PMID: 37713139, 2023); PK data reassuring. Gap has narrowed. |
| Apixaban vs rivaroxaban in liver disease | 6/10 | Smaller population in CDW; cannot reliably determine Child-Pugh score from EHR data. |
| LAAC vs DOAC | 4/10 | A TTE of LAAC vs DOAC was published in 2026 using Medicare data. Single-site CDW feasibility too low. |

## Recommendations for Next Steps

1. **Execution priority:** Protocol 1 (Apixaban vs Rivaroxaban in CKD) is the strongest candidate for immediate execution -- active-comparator design, clean time-zero definition, and adequate sample size. Protocol 2 (Rhythm vs Rate Control in Elderly) has the largest population and should follow. Protocol 3 (OAC at Threshold) is the most clinically impactful but carries the strongest confounding threat and should be executed with careful E-value interpretation.

2. **Data access:** All protocols require read access to CDW tables via ODBC connection (`SQLODBCD17CDM`). Each protocol includes a complete Quarto analysis script (`.qmd`) ready for execution. Verify that eGFR lab data (LOINC 48642-3) and DEATH_CAUSE completeness meet expected thresholds before running Protocols 1 and 2 respectively.

3. **Methodological considerations:**
   - All three protocols use IPW with logistic regression propensity scores. Consider augmented IPW (AIPW) or doubly robust estimation as a planned secondary analysis.
   - Protocol 3's treated-vs-untreated design is most vulnerable to unmeasured confounding. The E-value will be the primary tool for assessing robustness.
   - LVEF and symptom severity are unmeasured across all protocols. NLP extraction from echocardiography reports could strengthen confounding adjustment if resources permit.
   - Smoking data is unusable (99.8% unknown) across all protocols -- a known CDW limitation.

4. **Multi-site extension:** The DOAC underdosing question (Q2, gap score 8/10) has the highest evidence gap among deferred questions and is ideally suited for a multi-site PCORnet analysis where the underdosed subgroup would be large enough for robust inference.

5. **Publication strategy:** Each protocol is designed as a standalone study suitable for submission to clinical journals. Protocol 1 targets nephrology/cardiology journals (e.g., AJKD, JACC); Protocol 2 targets geriatrics/cardiology (e.g., JAMA Internal Medicine); Protocol 3 targets general medicine (e.g., NEJM, BMJ) given its broad clinical impact.

## Appendix: Pipeline Statistics

- **Total sub-agents launched:** 7 (3 worker agents, 2 reviewer agents, 1 feasibility agent, 1 summary agent)
- **Literature PMIDs cited:** >70 unique (across RCTs, cohorts, meta-analyses, guidelines)
- **Clinical codes validated:** ~160 RxNorm CUIs, ~60 ICD-10 codes, 8 LOINC codes, 4 CPT codes
- **Revision cycles:** 2 (literature corrections after discovery review; Protocol 3 time-zero fix after protocol review)
- **Backtracks:** 1 (Q2 DOAC underdosing deferred from protocol generation due to insufficient sample size)
- **Total output:** 3 protocol documents (~400 lines each), 3 Quarto analysis scripts (~1,900 lines each), 1 literature scan, 1 evidence gaps analysis, 1 feasibility assessment, 2 review reports, 1 coordinator log
