# Next Steps: Type 2 Diabetes — SGLT2i vs DPP-4i for 3P-MACE

**Date:** 2026-04-15
**Mode:** OFFLINE — the analysis scripts were generated without live database access.

---

## What Was Generated

| File | Description |
|------|-------------|
| `01_literature_scan.md` | Comprehensive literature scan (32 PMIDs, 3 search passes) |
| `02_evidence_gaps.md` | 7 ranked PICO questions with evidence gap scores |
| `03_feasibility.md` | Database feasibility assessment with code mappings |
| `review_discovery.md` | Peer review of literature discovery |
| `protocols/protocol_01.md` | Full TTE protocol (SGLT2i class vs DPP-4i for 3P-MACE) |
| `protocols/protocol_01_analysis.R` | Complete R analysis script (1,380+ lines) |
| `protocols/review_protocol_01.md` | Peer review of protocol (2 bugs found and fixed) |
| `coordinator_log.md` | Full decision log |
| `agent_state.json` | Pipeline state |

## What You Need to Do

### Step 1: Review the Protocol
Read `protocols/protocol_01.md` to verify the study design matches your intent. Key design decisions:

- **Primary exposure:** SGLT2i class (canagliflozin + empagliflozin + dapagliflozin) — expanded from canagliflozin-only because this CDW has only 142 canagliflozin patients
- **Primary comparator:** DPP-4 inhibitors (sitagliptin, linagliptin, saxagliptin, alogliptin)
- **Secondary comparator:** 2nd-generation sulfonylureas (glipizide, glimepiride, glyburide)
- **Primary outcome:** 3-point MACE (CV death, nonfatal MI, nonfatal stroke)
- **Estimand:** ATO (overlap weights)
- **Pre-specified sensitivity:** Canagliflozin-only subgroup (descriptive, underpowered)

### Step 2: Run the Analysis Script
The R script requires an active ODBC connection to the CDW:

```bash
cd results/type_2_diabetes/protocols
Rscript protocol_01_analysis.R
```

**Prerequisites:**
- R ≥ 4.1 with packages: tidyverse, DBI, odbc, WeightIt, cobalt, survival, survminer, sandwich, lmtest, EValue, jsonlite, gtsummary, gt, MatchIt
- ODBC DSN `SQLODBCD17CDM` configured and accessible
- Sufficient permissions to create temp tables (#) in CDW

**Expected runtime:** 15–45 minutes depending on database load.

### Step 3: Check Results
The script saves results to `protocols/protocol_01_results.json`. It also generates:

| Output File | Description |
|-------------|-------------|
| `protocol_01_results.json` | Structured results (HRs, CIs, p-values, CONSORT, subgroups) |
| `protocol_01_table1.html` | Baseline characteristics table (gtsummary) |
| `protocol_01_loveplot.pdf` | Covariate balance love plot |
| `protocol_01_ps_distribution.pdf` | Propensity score overlap plot |
| `protocol_01_km.pdf` | Kaplan-Meier survival curves |
| `protocol_01_forest.pdf` | Subgroup forest plot |
| `protocol_01_consort.pdf` | CONSORT flow diagram |

### Step 4: Generate Reports
Once `protocol_01_results.json` exists, re-run the pipeline with `--resume-reports` to generate the narrative report:

```bash
./run.sh --therapeutic-area "type 2 diabetes" \
  --database databases/secure_pcornet_cdw.yaml \
  --resume-reports
```

This will launch a report-writing agent that reads the results JSON and writes `protocols/protocol_01_report.md`.

---

## Important Notes

1. **Canagliflozin limitation:** This CDW has only 142 canagliflozin patients. The primary analysis uses SGLT2i class-level comparison. The canagliflozin subgroup analysis will be descriptive with wide confidence intervals (~5-6 expected MACE events).

2. **Unvalidated combo RxCUIs:** Synjardy (empagliflozin/metformin) and Xigduo XR (dapagliflozin/metformin) combination product RxCUIs were included but not validated via MCP tools. Verify these codes produce expected patient counts.

3. **DEATH_CAUSE completeness:** CV death ascertainment depends on DEATH_CAUSE table completeness, which is unknown. The all-cause mortality sensitivity analysis addresses this.

4. **Smoking proxy:** VITAL.SMOKING is 99.8% unknown. The script uses tobacco use disorder ICD-10 codes (F17.x, Z72.0, Z87.891) as a proxy.

5. **Two SQL bugs were fixed** after peer review:
   - MI/stroke outcome subqueries restructured to filter post-index dates before aggregating
   - I22.x (subsequent MI) codes added to MI definition
