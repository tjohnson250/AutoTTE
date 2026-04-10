# Database Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add config-driven database abstraction with online/offline modes, an R execution MCP server, and a unified datasource registry, replacing hardcoded CDW references.

**Architecture:** Database configs live in `databases/*.yaml`. A new datasource MCP server unifies public datasets and configured DBs. A new R executor MCP server provides persistent R sessions with live DB connections for online mode. Pipeline scripts and agent instructions are updated to use these abstractions instead of hardcoded file paths.

**Tech Stack:** Python 3.12 (FastMCP, PyYAML, subprocess), R (DBI, duckdb/odbc), Bash

**Spec:** `docs/superpowers/specs/2026-04-09-database-integration-design.md`

---

## File Structure

### New Files

| File | Responsibility |
|------|---------------|
| `databases/secure_pcornet_cdw.yaml` | Config for existing secure CDW (offline) |
| `databases/synthetic_pcornet.yaml` | Config for synthetic PCORnet DuckDB (online) |
| `databases/schemas/` | Directory for auto-generated schema dumps |
| `databases/profiles/` | Directory for auto-generated data profiles |
| `databases/conventions/secure_pcornet_cdw_conventions.md` | CDW-specific institutional knowledge extracted from WORKER.md/REVIEW.md |
| `tools/datasource_server.py` | Unified datasource registry MCP server |
| `tools/r_executor_server.py` | Persistent R session MCP server with DB connection |
| `tests/conftest.py` | Mock mcp module so server code can be imported in tests |
| `tests/test_datasource_server.py` | Unit tests for datasource registry logic |
| `tests/test_r_executor.py` | Unit tests for R executor config parsing and subprocess logic |

### Modified Files

| File | What Changes |
|------|-------------|
| `tools/pubmed_server.py` | Remove `DATASET_REGISTRY`, `query_dataset_registry()`, `get_dataset_details()` |
| `.mcp.json` | Add `datasource` server entry |
| `.gitignore` | Add `databases/schemas/`, `databases/profiles/`, `databases/conventions/`, `.mcp-session.json` |
| `run.sh` | Replace `--cdw/--both/--db-connect` with `--db-config/--db-mode`, generate session MCP config |
| `COORDINATOR.md` | Add Phase 0 onboarding, update sub-agent prompt templates, remove hardcoded CDW paths |
| `WORKER.md` | Extract CDW conventions, add datasource/conventions/dialect sections, update tool references |
| `REVIEW.md` | Extract CDW-specific checks, add conventions-based review section, update tool references |

### Moved Files

| Old Location | New Location |
|-------------|-------------|
| `CDW_DBO_database_schema.txt` | `databases/schemas/secure_pcornet_cdw_schema.txt` |
| `MasterPatientIndex_DBO_database_schema.txt` | `databases/schemas/secure_pcornet_cdw_mpi_schema.txt` |
| `CDW_data_profile.md` | `databases/profiles/secure_pcornet_cdw_profile.md` |

---

## Task 1: Directory Structure and File Migration

**Files:**
- Create: `databases/schemas/` (directory)
- Create: `databases/profiles/` (directory)
- Create: `databases/conventions/` (directory)
- Move: `CDW_DBO_database_schema.txt` -> `databases/schemas/secure_pcornet_cdw_schema.txt`
- Move: `MasterPatientIndex_DBO_database_schema.txt` -> `databases/schemas/secure_pcornet_cdw_mpi_schema.txt`
- Move: `CDW_data_profile.md` -> `databases/profiles/secure_pcornet_cdw_profile.md`
- Modify: `.gitignore`

- [ ] **Step 1: Create the databases directory structure**

```bash
mkdir -p databases/schemas databases/profiles databases/conventions
```

- [ ] **Step 2: Move existing CDW files using git mv**

```bash
git mv CDW_DBO_database_schema.txt databases/schemas/secure_pcornet_cdw_schema.txt
git mv MasterPatientIndex_DBO_database_schema.txt databases/schemas/secure_pcornet_cdw_mpi_schema.txt
git mv CDW_data_profile.md databases/profiles/secure_pcornet_cdw_profile.md
```

- [ ] **Step 3: Update .gitignore**

Add these lines to `.gitignore`:

```
databases/schemas/
databases/profiles/
databases/conventions/
.mcp-session.json
```

Then un-ignore the secure CDW files that were just moved (since they're already committed and we want to keep them tracked):

```
!databases/schemas/secure_pcornet_cdw_schema.txt
!databases/schemas/secure_pcornet_cdw_mpi_schema.txt
!databases/profiles/secure_pcornet_cdw_profile.md
```

- [ ] **Step 4: Verify files are in the right place**

```bash
ls -la databases/schemas/
ls -la databases/profiles/
ls -la databases/conventions/
```

Expected: schema files and profile in their new locations, conventions/ empty.

- [ ] **Step 5: Commit**

```bash
git add databases/ .gitignore
git commit -m "Migrate CDW schema/profile files to databases/ directory structure"
```

---

## Task 2: Database Configuration Files

**Files:**
- Create: `databases/secure_pcornet_cdw.yaml`
- Create: `databases/synthetic_pcornet.yaml`

- [ ] **Step 1: Create the secure CDW config**

Create `databases/secure_pcornet_cdw.yaml`:

```yaml
id: "secure_pcornet_cdw"
name: "Secure PCORnet CDW"
cdm: "pcornet"
cdm_version: "6.1"
engine: "mssql"
online: false

connection:
  r_code: |
    con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")

schema_prefix: "CDW.dbo"
schema_dump: "databases/schemas/secure_pcornet_cdw_schema.txt"
mpi_schema_dump: "databases/schemas/secure_pcornet_cdw_mpi_schema.txt"
data_profile: "databases/profiles/secure_pcornet_cdw_profile.md"
conventions: "databases/conventions/secure_pcornet_cdw_conventions.md"
```

- [ ] **Step 2: Create the synthetic PCORnet config**

Create `databases/synthetic_pcornet.yaml`:

```yaml
id: "synthetic_pcornet"
name: "PCORnet Synthetic CDW"
cdm: "pcornet"
cdm_version: "6.0"
engine: "duckdb"
online: true

connection:
  r_code: |
    library(pcornet.synthetic)
    dbs <- load_pcornet_database()
    con <- dbs$cdw

schema_prefix: "main"
schema_dump: "databases/schemas/synthetic_pcornet_schema.txt"
data_profile: "databases/profiles/synthetic_pcornet_profile.md"
conventions: "databases/conventions/synthetic_pcornet_conventions.md"
```

- [ ] **Step 3: Commit**

```bash
git add databases/secure_pcornet_cdw.yaml databases/synthetic_pcornet.yaml
git commit -m "Add database config YAML files for secure CDW and synthetic PCORnet"
```

---

## Task 3: Extract CDW Conventions

**Files:**
- Create: `databases/conventions/secure_pcornet_cdw_conventions.md`

This task extracts CDW-specific institutional knowledge from WORKER.md and REVIEW.md into a standalone conventions file. The content comes from:
- `WORKER.md` lines 228-428 (SQL conventions, legacy encounters, date bounds, ODBC bug, ROW_NUMBER, etc.)
- `REVIEW.md` lines 169-248 (CDW-specific code review checklist)

- [ ] **Step 1: Create the conventions file**

Create `databases/conventions/secure_pcornet_cdw_conventions.md` with this content:

```markdown
# Secure PCORnet CDW — Database Conventions

These conventions are specific to this CDW instance. Agents MUST read and apply
every convention when writing SQL or R code targeting this database. Reviewers
MUST check every convention as a review item.

## Required Filters

### Legacy Encounter Filtering (CRITICAL — duplicate records)

The CDW contains data from two EHR eras (AllScripts and Epic). When the
institution transitioned from AllScripts to Epic, some AllScripts records were
re-imported into Epic and re-fed into the CDW, creating **duplicates**.
These duplicates are flagged as `RAW_ENC_TYPE = 'Legacy Encounter'`.

**Rule:** Every query that joins ENCOUNTER must include:
```sql
AND e.RAW_ENC_TYPE <> 'Legacy Encounter'
```

**Exception:** You may keep legacy encounters when building a binary "any prior
diagnosis" indicator where double-counting is harmless (e.g.,
`EXISTS (SELECT 1 FROM DIAGNOSIS WHERE DX LIKE 'I48%')`). Even then, prefer
filtering them out for consistency. Always document your choice.

The `CDW_Source` column on many tables indicates which feed produced the record
(e.g., 'GECBI' for Epic). Use this for additional verification when needed,
but `RAW_ENC_TYPE` on ENCOUNTER is the primary filter.

### Date Bounds (CRITICAL — junk dates)

The CDW contains junk dates ranging from 1820 to 3019 due to EHR default
values, data entry errors, and placeholder dates.

**Rule:** Every query that uses a date column (ADMIT_DATE, PX_DATE,
RX_ORDER_DATE, RESULT_DATE, etc.) MUST include an explicit date range filter:
```sql
WHERE e.ADMIT_DATE BETWEEN '2005-01-01' AND GETDATE()
```

Key data eras:
- Year 1900 has ~40K patients — this is a default/unknown date, not real data
- Pre-2000 data is sparse and unreliable
- Realistic clinical data begins around **2000** and reaches full volume ~**2005**
- **AllScripts era:** through ~2019-2020 (all data before Epic go-live)
- **Epic go-live:** ~2019-2020 (legacy encounter volume drops sharply after 2021)
- **Post-ICD-10 only:** 2016+ (ICD-10 transition was Oct 2015, separate from Epic)
- **Post-Epic + post-ICD-10:** ~2020+
- Future dates (2027+) include some scheduled appointments but mostly errors

Choose the study start date based on data volume and document the choice.

## Coding System Requirements

### ICD-9/10 Transition

The ICD-10 transition date is October 1, 2015. If the study period extends
before this date, queries must include both `DX_TYPE = '09'` and
`DX_TYPE = '10'` with appropriate code mappings. If the study starts after
Oct 2015, `DX_TYPE = '10'` alone is sufficient.

Check the data profile Section 4 to see which years have ICD-9 vs ICD-10 data.

### Clinical Code Validation (MANDATORY)

Every medication, diagnosis, lab, and procedure code list MUST be validated
using the MCP tools before the protocol is finalized.

**RxNorm (medications):**
- For EVERY drug, call `get_rxcuis_for_drug()` to get the COMPLETE set of
  SCD + SBD RXCUIs. Never manually curate a partial list.
- Include both SCD (generic) and SBD (branded) forms. EHRs record branded
  entries (e.g., "Ecotrin" for aspirin, "Hemady" for dexamethasone 20mg).
- Before finalizing, call `validate_rxcui_list()` on every RXCUI list.
- Common pitfall: using ingredient-level CUIs (e.g., '11289' for warfarin).
  PCORnet PRESCRIBING stores SCD/SBD-level CUIs — ingredient CUIs match NOTHING.

**ICD-10-CM (diagnoses):**
- For EVERY diagnosis, call `get_icd10_hierarchy()` to see all subcodes.
- Call `search_icd10()` to catch codes you might not know about.

**LOINC (labs):**
- For EVERY lab test, call `search_loinc()` and `find_related_loincs()` to
  find all related codes for the same analyte.

**HCPCS (procedures):**
- For parenteral drugs (IV/SC), look up corresponding J-codes using
  `search_hcpcs()`. Multi-source detection (PRESCRIBING + PROCEDURES +
  MED_ADMIN) is required for any parenteral agent.

## SQL Patterns

### Table Qualification

All tables must be fully qualified as `CDW.dbo.TABLE_NAME`, not bare
`dbo.TABLE_NAME`.

### DEATH Table Deduplication

Always use `ROW_NUMBER() OVER (PARTITION BY PATID ORDER BY DEATH_DATE) AS rn`
and filter to `rn = 1` when joining DEATH. Some patients have duplicate death
records:
```sql
LEFT JOIN (
  SELECT d.PATID, d.DEATH_DATE,
         ROW_NUMBER() OVER (PARTITION BY d.PATID ORDER BY d.DEATH_DATE) AS rn
  FROM CDW.dbo.DEATH d
) death ON t.PATID = death.PATID AND death.rn = 1
```

### ROW_NUMBER on ALL LEFT JOINs

Every LEFT JOIN to vitals, labs, enrollment, or DEATH must use
`ROW_NUMBER() OVER (PARTITION BY PATID ...) ... WHERE rn = 1` to guarantee
exactly 1 row per patient. Do NOT use `MAX(date)` + self-join — that pattern
returns duplicates when multiple records share the same max date.

If the CONSORT shows MORE patients after any step than before, row duplication
from JOINs is the cause.

### ODBC Batch Bug

Do not combine `SELECT INTO #temp` and `SELECT * FROM #temp` in the same
`dbExecute()` / `dbGetQuery()` call. The ODBC driver fails silently. Use
separate calls:
```r
dbExecute(con, sql_that_creates_temp_table)
cohort <- dbGetQuery(con, "SELECT * FROM #analytic_cohort")
```

### count_temp() Helper

Must use `COUNT(DISTINCT PATID)`, not `COUNT(*)`. Using `COUNT(*)` hides
row duplication from JOINs.

## Column Handling

### Case Normalization

SQL Server returns column names in unpredictable case. After `dbGetQuery()`,
always call:
```r
names(df) <- tolower(names(df))
```
Then use lowercase column names everywhere in R code.

### Factor Naming

Create derived factor columns with distinct names (`sex_cat`, `race_cat`,
`hispanic_cat`), not by overwriting the raw column in `mutate()`.

## R Code Patterns

### E-value Sensitivity Analysis

When using `evalues.HR()`, you MUST specify the `rare` argument:
```r
evalues.HR(hr, lo = ci_lo, hi = ci_hi, rare = TRUE)
```
Set `rare = TRUE` when outcome incidence < ~15%. Omitting `rare` causes a
runtime error.

### Empty Cohort Guard

After pulling the analytic cohort, check for 0 rows before proceeding:
```r
if (nrow(cohort) == 0) {
  message("*** STOPPING: Analytic cohort has 0 patients. ***")
  knitr::knit_exit()
}
```

### Treatment Arms Guard

Before calling `weightit()`, verify the treatment variable has >= 2 values:
```r
n_arms <- length(unique(cohort$treatment))
if (n_arms < 2) {
  stop(sprintf("Cannot run IPW: treatment has only %d unique value(s).", n_arms))
}
```

### Dynamic PS Formula

Build the propensity score formula dynamically, dropping single-level factors
and zero-variance columns. Small or specific cohorts often have single-level
factors that crash `weightit()`.

### Quarto Layout

The `.qmd` file must use a two-part layout:
- **Part 1 (function definitions):** No visible output.
- **Part 2 (execution sections):** Each section calls its function and displays
  results inline.

No monolithic `main()`. No `eval: false` chunks. No `png()`/`dev.off()` — all
plots render inline via Quarto figure chunks.
```

- [ ] **Step 2: Verify the conventions file covers all CDW-specific items from WORKER.md and REVIEW.md**

Read through `WORKER.md` lines 188-595 and `REVIEW.md` lines 169-248.
Confirm every CDW-specific convention is captured in the conventions file.
The conventions file should NOT include generic guidance that applies to all
databases (e.g., "always specify the estimand").

- [ ] **Step 3: Commit**

```bash
git add databases/conventions/secure_pcornet_cdw_conventions.md
git commit -m "Extract CDW-specific conventions from agent instructions into conventions file"
```

---

## Task 4: Datasource Registry MCP Server

**Files:**
- Create: `tests/conftest.py`
- Create: `tools/datasource_server.py`
- Create: `tests/test_datasource_server.py`

**Important:** The MCP servers import `from mcp.server.fastmcp import FastMCP`,
but `mcp` is provided by Claude Code's runtime and is not installed in the
user's Python environment. Tests need a conftest.py that mocks the mcp module
so the pure logic functions can be imported and tested.

- [ ] **Step 0: Create tests/conftest.py to mock the mcp module**

Create `tests/conftest.py`:

```python
"""Test configuration — mock the mcp module so server code can be imported."""
import sys
from unittest.mock import MagicMock

# Mock the mcp module before any server imports.
# The mcp package is provided by Claude Code's runtime and isn't installed
# in the user's Python environment. We only test pure logic functions, not
# the MCP tool wrappers themselves.
if "mcp" not in sys.modules:
    mcp_mock = MagicMock()
    sys.modules["mcp"] = mcp_mock
    sys.modules["mcp.server"] = mcp_mock.server
    sys.modules["mcp.server.fastmcp"] = mcp_mock.server.fastmcp
```

- [ ] **Step 1: Write failing tests for config loading and filtering**

Create `tests/test_datasource_server.py`:

```python
"""Tests for datasource_server config loading and filtering logic."""

import json
import os
import tempfile
from pathlib import Path

import pytest
import yaml


# We test the pure logic functions, not the MCP tool wrappers.
# Import after creating the module.


@pytest.fixture
def sample_db_dir(tmp_path):
    """Create a temporary databases/ directory with sample configs."""
    db_dir = tmp_path / "databases"
    db_dir.mkdir()
    (db_dir / "schemas").mkdir()
    (db_dir / "profiles").mkdir()
    (db_dir / "conventions").mkdir()

    # Create a schema dump file
    schema_file = db_dir / "schemas" / "test_db_schema.txt"
    schema_file.write_text("CREATE TABLE DEMOGRAPHIC (PATID VARCHAR(50));\n")

    # Create a profile file
    profile_file = db_dir / "profiles" / "test_db_profile.md"
    profile_file.write_text("# Test DB Profile\n\n1000 patients total.\n")

    # Create a conventions file
    conventions_file = db_dir / "conventions" / "test_db_conventions.md"
    conventions_file.write_text("# Test DB Conventions\n\n- Always filter X.\n")

    # Write a YAML config
    config = {
        "id": "test_db",
        "name": "Test Database",
        "cdm": "pcornet",
        "cdm_version": "6.0",
        "engine": "duckdb",
        "online": True,
        "connection": {"r_code": "con <- DBI::dbConnect(duckdb::duckdb())\n"},
        "schema_prefix": "main",
        "schema_dump": str(schema_file),
        "data_profile": str(profile_file),
        "conventions": str(conventions_file),
    }
    config_path = db_dir / "test_db.yaml"
    config_path.write_text(yaml.dump(config))

    # Write a second config (offline, omop)
    config2 = {
        "id": "test_omop",
        "name": "Test OMOP DB",
        "cdm": "omop",
        "engine": "postgres",
        "online": False,
        "connection": {"r_code": "con <- DBI::dbConnect(RPostgres::Postgres())\n"},
        "schema_prefix": "public",
        "schema_dump": str(db_dir / "schemas" / "test_omop_schema.txt"),
        "data_profile": str(db_dir / "profiles" / "test_omop_profile.md"),
    }
    (db_dir / "test_omop.yaml").write_text(yaml.dump(config2))

    return db_dir


def test_load_db_configs(sample_db_dir):
    from tools.datasource_server import load_db_configs

    configs = load_db_configs(str(sample_db_dir))
    assert len(configs) == 2
    ids = {c["id"] for c in configs}
    assert ids == {"test_db", "test_omop"}


def test_load_db_configs_empty_dir(tmp_path):
    from tools.datasource_server import load_db_configs

    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    configs = load_db_configs(str(empty_dir))
    assert configs == []


def test_load_db_configs_missing_dir():
    from tools.datasource_server import load_db_configs

    configs = load_db_configs("/nonexistent/path")
    assert configs == []


def test_filter_datasources_by_cdm(sample_db_dir):
    from tools.datasource_server import load_db_configs, filter_datasources

    all_sources = load_db_configs(str(sample_db_dir))
    filtered = filter_datasources(all_sources, cdm="pcornet")
    assert len(filtered) == 1
    assert filtered[0]["id"] == "test_db"


def test_filter_datasources_online_only(sample_db_dir):
    from tools.datasource_server import load_db_configs, filter_datasources

    all_sources = load_db_configs(str(sample_db_dir))
    filtered = filter_datasources(all_sources, online_only=True)
    assert len(filtered) == 1
    assert filtered[0]["id"] == "test_db"


def test_filter_datasources_by_domain():
    """Public datasets have domains; DB configs do not."""
    from tools.datasource_server import PUBLIC_DATASETS, filter_datasources

    filtered = filter_datasources(PUBLIC_DATASETS, domain="inpatient_icu")
    assert all(d.get("domain") == "inpatient_icu" for d in filtered)
    assert len(filtered) >= 1  # At least MIMIC-IV


def test_get_details_by_id(sample_db_dir):
    from tools.datasource_server import load_db_configs, get_details_by_id

    all_sources = load_db_configs(str(sample_db_dir))
    detail = get_details_by_id("test_db", all_sources)
    assert detail is not None
    assert detail["name"] == "Test Database"


def test_get_details_by_id_not_found(sample_db_dir):
    from tools.datasource_server import load_db_configs, get_details_by_id

    all_sources = load_db_configs(str(sample_db_dir))
    detail = get_details_by_id("nonexistent", all_sources)
    assert detail is None


def test_read_file_content(sample_db_dir):
    from tools.datasource_server import read_file_content

    schema_path = str(sample_db_dir / "schemas" / "test_db_schema.txt")
    content = read_file_content(schema_path)
    assert "CREATE TABLE DEMOGRAPHIC" in content


def test_read_file_content_missing():
    from tools.datasource_server import read_file_content

    content = read_file_content("/nonexistent/file.txt")
    assert "not found" in content.lower() or "error" in content.lower()


def test_public_datasets_present():
    from tools.datasource_server import PUBLIC_DATASETS

    names = {d["name"] for d in PUBLIC_DATASETS}
    assert "MIMIC-IV" in names
    assert "NHANES" in names
    assert "MEPS" in names
    assert "Synthea" in names
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
python -m pytest tests/test_datasource_server.py -v 2>&1 | head -30
```

Expected: ImportError — `tools.datasource_server` does not exist yet.

- [ ] **Step 3: Create the datasource server**

Create `tools/datasource_server.py`:

```python
"""
Datasource Registry MCP Server
===============================
Unified registry of all available data sources — both public datasets
(MIMIC-IV, NHANES, etc.) and configured databases (PCORnet CDW, OMOP, etc.).

Replaces the dataset registry previously embedded in pubmed_server.py.

Run with:
    python tools/datasource_server.py

Requires:
    pip install mcp pyyaml
"""

import json
import os
from pathlib import Path

import yaml
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("datasource")

# Resolve project root relative to this file
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATABASES_DIR = PROJECT_ROOT / "databases"


# ---------------------------------------------------------------------------
# Public Dataset Registry (moved from pubmed_server.py)
# ---------------------------------------------------------------------------

PUBLIC_DATASETS = [
    {
        "id": "mimic_iv",
        "name": "MIMIC-IV",
        "type": "public",
        "description": "Critical care EHR data from Beth Israel Deaconess Medical Center. ~70k ICU stays, ~400k hospital admissions.",
        "domain": "inpatient_icu",
        "access": "PhysioNet credentialed access (free, requires CITI training)",
        "variables": ["demographics", "vitals", "labs", "medications", "procedures",
                      "diagnoses_icd", "ventilation", "vasopressors", "mortality",
                      "length_of_stay", "readmission", "microbiology", "radiology_notes"],
        "strengths": ["Granular temporal data", "Medication administration records", "Lab time series"],
        "limitations": ["Single center", "ICU patients only (sicker population)", "US academic hospital"],
        "url": "https://physionet.org/content/mimiciv/",
    },
    {
        "id": "eicu_crd",
        "name": "eICU-CRD",
        "type": "public",
        "description": "Multi-center ICU database from Philips eICU telehealth program. ~200k ICU stays across 208 hospitals.",
        "domain": "inpatient_icu",
        "access": "PhysioNet credentialed access (free)",
        "variables": ["demographics", "vitals", "labs", "medications", "diagnoses",
                      "apache_scores", "ventilation", "mortality", "length_of_stay",
                      "nurse_charting", "respiratory_charting"],
        "strengths": ["Multi-center", "Large sample", "APACHE scores available"],
        "limitations": ["Less granular than MIMIC", "Telehealth ICUs may differ", "US only"],
        "url": "https://physionet.org/content/eicu-crd/",
    },
    {
        "id": "nhanes",
        "name": "NHANES",
        "type": "public",
        "description": "National Health and Nutrition Examination Survey. ~5k participants per 2-year cycle, nationally representative.",
        "domain": "population_health",
        "access": "Public download, no restrictions",
        "variables": ["demographics", "blood_pressure", "cholesterol", "hba1c",
                      "bmi", "smoking", "medications_self_report", "diet",
                      "physical_activity", "mortality_linked", "kidney_function",
                      "liver_function", "mental_health"],
        "strengths": ["Nationally representative", "Physical exam + lab data", "Mortality follow-up linkage"],
        "limitations": ["Cross-sectional (no longitudinal follow-up except mortality)", "Self-reported medications", "Small sample per cycle"],
        "url": "https://www.cdc.gov/nchs/nhanes/",
    },
    {
        "id": "meps",
        "name": "MEPS",
        "type": "public",
        "description": "Medical Expenditure Panel Survey. Longitudinal survey of ~15k households per panel (2-year follow-up).",
        "domain": "expenditures_utilization",
        "access": "Public download, no restrictions",
        "variables": ["demographics", "conditions_icd", "prescriptions",
                      "utilization", "expenditures", "insurance", "income",
                      "employment", "functional_status", "sf12_quality_of_life"],
        "strengths": ["Longitudinal (2 years)", "Detailed cost data", "Nationally representative"],
        "limitations": ["Self-reported conditions", "Short follow-up", "No lab values"],
        "url": "https://meps.ahrq.gov/",
    },
    {
        "id": "cms_synpuf",
        "name": "CMS_SynPUF",
        "type": "public",
        "description": "CMS Synthetic Medicare Claims Public Use Files. Synthetic but realistic claims for ~2M beneficiaries.",
        "domain": "claims",
        "access": "Public download, no restrictions",
        "variables": ["demographics", "diagnoses_icd", "procedures_cpt",
                      "prescriptions_ndc", "inpatient_stays", "outpatient_visits",
                      "carrier_claims", "expenditures", "death_date"],
        "strengths": ["Large sample", "Longitudinal claims", "No access restrictions"],
        "limitations": ["SYNTHETIC data -- not real patients", "Relationships between variables may not be preserved", "Cannot make real clinical inferences"],
        "url": "https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files",
    },
    {
        "id": "synthea",
        "name": "Synthea",
        "type": "public",
        "description": "Synthetic patient generator. Can generate arbitrary-sized populations with configurable disease modules.",
        "domain": "synthetic_ehr",
        "access": "Open source, generate locally",
        "variables": ["demographics", "conditions", "medications", "procedures",
                      "encounters", "observations", "immunizations", "care_plans",
                      "allergies", "imaging"],
        "strengths": ["Any sample size", "No access restrictions", "FHIR/CSV output", "Good for methods development"],
        "limitations": ["SYNTHETIC -- disease relationships are programmed, not observed", "Only useful for methods demonstrations, not real inference"],
        "url": "https://synthetichealth.github.io/synthea/",
    },
]


# ---------------------------------------------------------------------------
# Config Loading (pure functions, testable without MCP)
# ---------------------------------------------------------------------------

def load_db_configs(databases_dir: str) -> list[dict]:
    """Load all database config YAML files from the given directory."""
    db_path = Path(databases_dir)
    if not db_path.exists():
        return []

    configs = []
    for yaml_file in sorted(db_path.glob("*.yaml")):
        try:
            with open(yaml_file) as f:
                config = yaml.safe_load(f)
            if config and isinstance(config, dict) and "id" in config:
                config["type"] = "database"
                config["_config_path"] = str(yaml_file)
                configs.append(config)
        except (yaml.YAMLError, OSError):
            continue
    return configs


def filter_datasources(
    sources: list[dict],
    domain: str = "",
    cdm: str = "",
    online_only: bool = False,
) -> list[dict]:
    """Filter a list of datasources by domain, CDM type, or online status."""
    results = sources

    if domain:
        results = [s for s in results if domain.lower() in s.get("domain", "").lower()]

    if cdm:
        results = [s for s in results if cdm.lower() == s.get("cdm", "").lower()]

    if online_only:
        results = [s for s in results if s.get("online", False)]

    return results


def get_details_by_id(source_id: str, sources: list[dict]) -> dict | None:
    """Find a datasource by its id."""
    for s in sources:
        if s.get("id", "").lower() == source_id.lower():
            return s
        # Also match by name for public datasets
        if s.get("name", "").lower() == source_id.lower():
            return s
    return None


def read_file_content(file_path: str) -> str:
    """Read and return the content of a file, or an error message if not found."""
    try:
        with open(file_path) as f:
            return f.read()
    except FileNotFoundError:
        return f"Error: File not found at '{file_path}'."
    except OSError as e:
        return f"Error reading file '{file_path}': {e}"


# ---------------------------------------------------------------------------
# State: loaded at startup
# ---------------------------------------------------------------------------

_all_sources: list[dict] = []


def _load_all_sources() -> list[dict]:
    """Load public datasets + database configs."""
    db_configs = load_db_configs(str(DATABASES_DIR))
    return PUBLIC_DATASETS + db_configs


# ---------------------------------------------------------------------------
# MCP Tools
# ---------------------------------------------------------------------------

@mcp.tool()
async def list_datasources(
    domain: str = "",
    cdm: str = "",
    online_only: bool = False,
) -> str:
    """List all available data sources, optionally filtered.

    Returns both public datasets (MIMIC-IV, NHANES, etc.) and configured
    databases from the databases/ directory.

    Args:
        domain: Filter by domain (e.g., "inpatient_icu", "population_health",
                "claims", "synthetic_ehr"). Only applies to public datasets.
        cdm: Filter by CDM type (e.g., "pcornet", "omop"). Only applies to
             configured databases.
        online_only: If True, only return databases that can be queried live.
    """
    global _all_sources
    if not _all_sources:
        _all_sources = _load_all_sources()

    filtered = filter_datasources(_all_sources, domain=domain, cdm=cdm, online_only=online_only)

    # Return a summary view (not full details)
    summary = []
    for s in filtered:
        entry = {
            "id": s.get("id", ""),
            "name": s.get("name", ""),
            "type": s.get("type", ""),
        }
        if s.get("type") == "database":
            entry["cdm"] = s.get("cdm", "")
            entry["engine"] = s.get("engine", "")
            entry["online"] = s.get("online", False)
        else:
            entry["domain"] = s.get("domain", "")
            entry["access"] = s.get("access", "")
        summary.append(entry)

    return json.dumps({"count": len(summary), "datasources": summary}, indent=2)


@mcp.tool()
async def get_datasource_details(id: str) -> str:
    """Get full details for a specific data source.

    Args:
        id: Data source id (e.g., "mimic_iv", "secure_pcornet_cdw") or name
            (e.g., "MIMIC-IV", "Secure PCORnet CDW").
    """
    global _all_sources
    if not _all_sources:
        _all_sources = _load_all_sources()

    source = get_details_by_id(id, _all_sources)
    if source is None:
        return json.dumps({"error": f"Data source '{id}' not found."})

    # Return full details, excluding internal fields
    result = {k: v for k, v in source.items() if not k.startswith("_")}
    return json.dumps(result, indent=2)


@mcp.tool()
async def get_schema(id: str) -> str:
    """Get the database schema dump for a configured data source.

    Args:
        id: Data source id (e.g., "secure_pcornet_cdw", "synthetic_pcornet").
    """
    global _all_sources
    if not _all_sources:
        _all_sources = _load_all_sources()

    source = get_details_by_id(id, _all_sources)
    if source is None:
        return json.dumps({"error": f"Data source '{id}' not found."})

    schema_path = source.get("schema_dump", "")
    if not schema_path:
        return json.dumps({"error": f"No schema dump configured for '{id}'."})

    # Resolve relative paths against project root
    if not os.path.isabs(schema_path):
        schema_path = str(PROJECT_ROOT / schema_path)

    content = read_file_content(schema_path)

    # Also include MPI schema if present
    mpi_path = source.get("mpi_schema_dump", "")
    mpi_content = ""
    if mpi_path:
        if not os.path.isabs(mpi_path):
            mpi_path = str(PROJECT_ROOT / mpi_path)
        mpi_content = read_file_content(mpi_path)

    result = {"id": id, "schema": content}
    if mpi_content and "error" not in mpi_content.lower():
        result["mpi_schema"] = mpi_content

    return json.dumps(result, indent=2)


@mcp.tool()
async def get_profile(id: str) -> str:
    """Get the data profile for a configured data source.

    Args:
        id: Data source id (e.g., "secure_pcornet_cdw", "synthetic_pcornet").
    """
    global _all_sources
    if not _all_sources:
        _all_sources = _load_all_sources()

    source = get_details_by_id(id, _all_sources)
    if source is None:
        return json.dumps({"error": f"Data source '{id}' not found."})

    profile_path = source.get("data_profile", "")
    if not profile_path:
        return json.dumps({"error": f"No data profile configured for '{id}'."})

    if not os.path.isabs(profile_path):
        profile_path = str(PROJECT_ROOT / profile_path)

    content = read_file_content(profile_path)
    return json.dumps({"id": id, "profile": content}, indent=2)


@mcp.tool()
async def get_conventions(id: str) -> str:
    """Get the database conventions for a configured data source.

    Conventions document database-specific quirks, required filters, and coding
    requirements. Agents MUST read and apply these before writing SQL or R code.

    Args:
        id: Data source id (e.g., "secure_pcornet_cdw", "synthetic_pcornet").
    """
    global _all_sources
    if not _all_sources:
        _all_sources = _load_all_sources()

    source = get_details_by_id(id, _all_sources)
    if source is None:
        return json.dumps({"error": f"Data source '{id}' not found."})

    conventions_path = source.get("conventions", "")
    if not conventions_path:
        return json.dumps({
            "id": id,
            "conventions": "",
            "note": "No conventions file configured for this data source.",
        })

    if not os.path.isabs(conventions_path):
        conventions_path = str(PROJECT_ROOT / conventions_path)

    content = read_file_content(conventions_path)
    return json.dumps({"id": id, "conventions": content}, indent=2)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
PYTHONPATH=. python -m pytest tests/test_datasource_server.py -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/conftest.py tools/datasource_server.py tests/test_datasource_server.py
git commit -m "Add datasource registry MCP server with unified public + DB config access"
```

---

## Task 5: Remove Dataset Registry from pubmed_server.py

**Files:**
- Modify: `tools/pubmed_server.py`

- [ ] **Step 1: Remove DATASET_REGISTRY and its tools from pubmed_server.py**

Delete the following from `tools/pubmed_server.py`:
- Lines 192-266: The `DATASET_REGISTRY` list
- Lines 269-306: The `query_dataset_registry()` tool function
- Lines 309-319: The `get_dataset_details()` tool function
- The trailing blank lines and the `# Dataset Registry` section header comment (line 190-191)

Keep everything else: imports, `search_pubmed()`, `fetch_abstracts()`,
`_parse_pubmed_xml()`, and the entry point.

- [ ] **Step 2: Verify pubmed_server.py still parses correctly**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
python -c "
import ast
with open('tools/pubmed_server.py') as f:
    ast.parse(f.read())
print('pubmed_server.py parses OK')
"
```

Expected: "pubmed_server.py parses OK"

- [ ] **Step 3: Commit**

```bash
git add tools/pubmed_server.py
git commit -m "Remove dataset registry from pubmed_server.py (moved to datasource_server.py)"
```

---

## Task 6: R Executor MCP Server

**Files:**
- Create: `tools/r_executor_server.py`
- Create: `tests/test_r_executor.py`

- [ ] **Step 1: Write failing tests for config loading and offline mode logic**

Create `tests/test_r_executor.py`:

```python
"""Tests for r_executor_server config loading and mode logic."""

import tempfile
from pathlib import Path

import pytest
import yaml


@pytest.fixture
def online_config(tmp_path):
    """Create an online database config YAML."""
    config = {
        "id": "test_db",
        "name": "Test DB",
        "cdm": "pcornet",
        "engine": "duckdb",
        "online": True,
        "connection": {"r_code": "con <- DBI::dbConnect(duckdb::duckdb())\n"},
        "schema_prefix": "main",
        "schema_dump": str(tmp_path / "schema.txt"),
        "data_profile": str(tmp_path / "profile.md"),
    }
    config_path = tmp_path / "test_db.yaml"
    config_path.write_text(yaml.dump(config))
    return str(config_path)


@pytest.fixture
def offline_config(tmp_path):
    """Create an offline database config YAML."""
    config = {
        "id": "test_offline",
        "name": "Test Offline DB",
        "cdm": "pcornet",
        "engine": "mssql",
        "online": False,
        "connection": {"r_code": 'con <- DBI::dbConnect(odbc::odbc(), "DSN")\n'},
        "schema_prefix": "CDW.dbo",
        "schema_dump": str(tmp_path / "schema.txt"),
        "data_profile": str(tmp_path / "profile.md"),
    }
    config_path = tmp_path / "test_offline.yaml"
    config_path.write_text(yaml.dump(config))
    return str(config_path)


def test_load_config(online_config):
    from tools.r_executor_server import load_config

    config = load_config(online_config)
    assert config["id"] == "test_db"
    assert config["online"] is True
    assert "r_code" in config["connection"]


def test_load_config_missing_file():
    from tools.r_executor_server import load_config

    with pytest.raises(FileNotFoundError):
        load_config("/nonexistent/config.yaml")


def test_is_online_mode(online_config, offline_config):
    from tools.r_executor_server import load_config, is_online

    assert is_online(load_config(online_config)) is True
    assert is_online(load_config(offline_config)) is False


def test_is_online_mode_override(online_config):
    from tools.r_executor_server import load_config, is_online

    config = load_config(online_config)
    # Override online to False
    assert is_online(config, mode_override="offline") is False


def test_get_connection_code(online_config):
    from tools.r_executor_server import load_config, get_connection_code

    config = load_config(online_config)
    code = get_connection_code(config)
    assert "DBI::dbConnect" in code
    assert "duckdb" in code


def test_build_sentinel():
    from tools.r_executor_server import build_sentinel

    sentinel = build_sentinel()
    assert sentinel.startswith("__SENTINEL_")
    assert sentinel.endswith("__")
    assert len(sentinel) > 20  # includes UUID


def test_wrap_r_code_with_sentinel():
    from tools.r_executor_server import wrap_r_code

    code = "print('hello')"
    wrapped, sentinel = wrap_r_code(code)
    assert code in wrapped
    assert f'cat("{sentinel}\\n")' in wrapped


def test_truncate_output():
    from tools.r_executor_server import truncate_output

    short = "line\n" * 10
    assert truncate_output(short, max_lines=200) == short

    long = "line\n" * 300
    truncated = truncate_output(long, max_lines=200)
    lines = truncated.strip().split("\n")
    assert len(lines) <= 202  # 200 + truncation notice
    assert "truncated" in truncated.lower()
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
PYTHONPATH=. python -m pytest tests/test_r_executor.py -v 2>&1 | head -20
```

Expected: ImportError — `tools.r_executor_server` does not exist yet.

- [ ] **Step 3: Create the R executor server**

Create `tools/r_executor_server.py`:

```python
"""
R Executor MCP Server
=====================
MCP server that manages a persistent R subprocess with an active database
connection. Provides tools for executing R code, running SQL queries, and
introspecting database schemas.

Run with:
    python tools/r_executor_server.py --config databases/synthetic_pcornet.yaml

Requires:
    pip install mcp pyyaml
    R installed and on PATH with DBI package
"""

import argparse
import json
import os
import subprocess
import sys
import threading
import uuid
from pathlib import Path

import yaml
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("r_executor")

PROJECT_ROOT = Path(__file__).resolve().parent.parent


# ---------------------------------------------------------------------------
# Config loading (pure functions, testable)
# ---------------------------------------------------------------------------

def load_config(config_path: str) -> dict:
    """Load and validate a database config YAML file."""
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {config_path}")
    with open(path) as f:
        config = yaml.safe_load(f)
    if not config or not isinstance(config, dict):
        raise ValueError(f"Invalid config file: {config_path}")
    return config


def is_online(config: dict, mode_override: str = "") -> bool:
    """Determine if online mode is active."""
    if mode_override == "offline":
        return False
    if mode_override == "online":
        return True
    return config.get("online", False)


def get_connection_code(config: dict) -> str:
    """Extract the R connection code from config."""
    return config.get("connection", {}).get("r_code", "").strip()


def build_sentinel() -> str:
    """Generate a unique sentinel string for R subprocess communication."""
    return f"__SENTINEL_{uuid.uuid4().hex[:12]}__"


def wrap_r_code(code: str, max_output_lines: int = 200) -> tuple[str, str]:
    """Wrap R code with error handling and a sentinel marker.

    Returns (wrapped_code, sentinel).
    """
    sentinel = build_sentinel()
    wrapped = f"""
tryCatch({{
{code}
}}, error = function(e) {{
  cat("R_ERROR:", conditionMessage(e), "\\n", file = stderr())
}}, warning = function(w) {{
  cat("R_WARNING:", conditionMessage(w), "\\n", file = stderr())
  invokeRestart("muffleWarning")
}})
cat("{sentinel}\\n")
"""
    return wrapped, sentinel


def truncate_output(output: str, max_lines: int = 200) -> str:
    """Truncate output to max_lines, adding a notice if truncated."""
    lines = output.split("\n")
    if len(lines) <= max_lines:
        return output
    kept = lines[:max_lines]
    kept.append(f"\n... [Output truncated: {len(lines)} lines total, showing first {max_lines}]")
    return "\n".join(kept)


# ---------------------------------------------------------------------------
# R Subprocess Manager
# ---------------------------------------------------------------------------

class RSession:
    """Manages a persistent R subprocess."""

    def __init__(self):
        self._process: subprocess.Popen | None = None
        self._lock = threading.Lock()
        self._connected = False

    def start(self):
        """Spawn the R subprocess."""
        if self._process is not None:
            return
        self._process = subprocess.Popen(
            ["R", "--vanilla", "--quiet", "--no-save"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )

    def execute(self, code: str, timeout: int = 120) -> dict:
        """Send R code to the subprocess and collect output until sentinel."""
        with self._lock:
            if self._process is None:
                self.start()

            wrapped, sentinel = wrap_r_code(code)
            self._process.stdin.write(wrapped + "\n")
            self._process.stdin.flush()

            stdout_lines = []
            try:
                while True:
                    line = self._process.stdout.readline()
                    if not line:
                        break
                    if sentinel in line:
                        break
                    stdout_lines.append(line.rstrip("\n"))
            except Exception as e:
                return {"stdout": "", "stderr": f"Error reading R output: {e}", "success": False}

            # Read any available stderr (non-blocking)
            stderr_text = ""
            try:
                import select
                while select.select([self._process.stderr], [], [], 0.1)[0]:
                    line = self._process.stderr.readline()
                    if not line:
                        break
                    stderr_text += line
            except Exception:
                pass

            stdout_text = "\n".join(stdout_lines)
            success = "R_ERROR:" not in stderr_text

            return {
                "stdout": stdout_text,
                "stderr": stderr_text,
                "success": success,
            }

    def connect_db(self, r_code: str) -> dict:
        """Run the connection code from the config."""
        result = self.execute(r_code)
        if result["success"]:
            # Verify connection by listing tables
            verify = self.execute("cat(paste(DBI::dbListTables(con), collapse='\\n'), '\\n')")
            if verify["success"]:
                self._connected = True
                result["tables"] = verify["stdout"].strip().split("\n")
        return result

    @property
    def connected(self) -> bool:
        return self._connected

    def stop(self):
        """Kill the R subprocess."""
        if self._process:
            self._process.terminate()
            self._process.wait(timeout=5)
            self._process = None
            self._connected = False


# ---------------------------------------------------------------------------
# Global state
# ---------------------------------------------------------------------------

_config: dict = {}
_mode_override: str = ""
_session = RSession()


def _ensure_connected() -> dict | None:
    """Start R and connect to DB if not already done. Returns error dict or None."""
    global _config, _session

    if not _config:
        return {"error": "No database config loaded. Server was started without --config."}

    if not is_online(_config, _mode_override):
        return {
            "error": f"Database '{_config.get('name', '')}' is configured for offline mode. "
                     "Use get_schema() and get_profile() from the datasource server instead.",
        }

    if not _session.connected:
        conn_code = get_connection_code(_config)
        if not conn_code:
            return {"error": "No connection R code found in config."}

        result = _session.connect_db(conn_code)
        if not result["success"]:
            return {"error": f"Failed to connect to database: {result['stderr']}"}

    return None


# ---------------------------------------------------------------------------
# MCP Tools
# ---------------------------------------------------------------------------

@mcp.tool()
async def execute_r(code: str) -> str:
    """Execute arbitrary R code in the persistent R session.

    The R session has an active database connection object named `con`.
    Use standard DBI functions: dbGetQuery(), dbExecute(), dbListTables(), etc.

    Args:
        code: R code to execute. Can be multi-line.

    Returns:
        stdout and stderr from the R session, truncated to 200 lines.
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    result = _session.execute(code)
    result["stdout"] = truncate_output(result["stdout"], max_lines=200)
    return json.dumps(result, indent=2)


@mcp.tool()
async def query_db(sql: str) -> str:
    """Run a SQL query via the active DBI connection and return results.

    Returns the first 50 rows, total row count, and column types.

    Args:
        sql: SQL query string. Use the dialect appropriate for the database
             engine (T-SQL for mssql, standard SQL for duckdb/postgres).
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    # Use R to run the query and format the result
    r_code = f"""
.q_result <- DBI::dbGetQuery(con, {json.dumps(sql)})
cat("ROWS:", nrow(.q_result), "\\n")
cat("COLS:", paste(names(.q_result), collapse=","), "\\n")
cat("TYPES:", paste(sapply(.q_result, class), collapse=","), "\\n")
if (nrow(.q_result) > 0) {{
  .show <- head(.q_result, 50)
  cat("DATA_START\\n")
  write.csv(.show, row.names = FALSE, quote = TRUE)
  cat("DATA_END\\n")
}}
"""
    result = _session.execute(r_code)
    if not result["success"]:
        return json.dumps({"error": result["stderr"], "sql": sql})

    # Parse the structured output
    stdout = result["stdout"]
    parsed = {"sql": sql, "success": True}

    for line in stdout.split("\n"):
        if line.startswith("ROWS:"):
            parsed["total_rows"] = int(line.split(":")[1].strip())
        elif line.startswith("COLS:"):
            parsed["columns"] = line.split(":")[1].strip().split(",")
        elif line.startswith("TYPES:"):
            parsed["column_types"] = line.split(":")[1].strip().split(",")

    # Extract CSV data between markers
    if "DATA_START" in stdout and "DATA_END" in stdout:
        data_section = stdout.split("DATA_START\n")[1].split("\nDATA_END")[0]
        parsed["data_csv"] = data_section
        parsed["rows_shown"] = min(parsed.get("total_rows", 0), 50)
    else:
        parsed["data_csv"] = ""
        parsed["rows_shown"] = 0

    return json.dumps(parsed, indent=2)


@mcp.tool()
async def list_tables() -> str:
    """List all tables in the connected database with row counts."""
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    r_code = """
.tables <- DBI::dbListTables(con)
.counts <- sapply(.tables, function(t) {
  tryCatch(
    nrow(DBI::dbGetQuery(con, paste("SELECT COUNT(*) AS n FROM", t))),
    error = function(e) NA
  )
})
cat(paste(.tables, .counts, sep="\\t"), sep="\\n")
cat("\\n")
"""
    result = _session.execute(r_code, timeout=300)
    if not result["success"]:
        return json.dumps({"error": result["stderr"]})

    tables = []
    for line in result["stdout"].strip().split("\n"):
        parts = line.split("\t")
        if len(parts) == 2:
            tables.append({"table": parts[0], "row_count": parts[1]})

    return json.dumps({"tables": tables, "count": len(tables)}, indent=2)


@mcp.tool()
async def describe_table(table: str) -> str:
    """Get column names, types, NULL rates, and sample values for a table.

    Args:
        table: Table name (use schema_prefix if needed, e.g., "CDW.dbo.DEMOGRAPHIC").
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    r_code = f"""
.sample <- DBI::dbGetQuery(con, paste("SELECT * FROM {table} LIMIT 5"))
.info <- data.frame(
  column = names(.sample),
  type = sapply(.sample, class),
  sample_value = sapply(.sample, function(x) paste(head(x, 1), collapse=",")),
  stringsAsFactors = FALSE
)
cat("NROW:", nrow(DBI::dbGetQuery(con, paste("SELECT COUNT(*) AS n FROM {table}"))), "\\n")
write.csv(.info, row.names = FALSE)
"""
    result = _session.execute(r_code)
    if not result["success"]:
        return json.dumps({"error": result["stderr"], "table": table})

    return json.dumps({"table": table, "output": truncate_output(result["stdout"], 100)}, indent=2)


@mcp.tool()
async def dump_schema() -> str:
    """Introspect the connected database and write a schema dump.

    Writes the schema to the path specified in the database config's
    schema_dump field. Returns the path to the generated file.
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    schema_path = _config.get("schema_dump", "")
    if not schema_path:
        return json.dumps({"error": "No schema_dump path in config."})

    if not os.path.isabs(schema_path):
        schema_path = str(PROJECT_ROOT / schema_path)

    # Ensure parent directory exists
    os.makedirs(os.path.dirname(schema_path), exist_ok=True)

    engine = _config.get("engine", "")
    prefix = _config.get("schema_prefix", "")

    # Engine-specific schema introspection
    if engine == "duckdb":
        r_code = f"""
.tables <- DBI::dbListTables(con)
.schema_lines <- character()
for (.t in .tables) {{
  .cols <- DBI::dbGetQuery(con, paste("PRAGMA table_info('", .t, "')", sep=""))
  .header <- paste("CREATE TABLE", .t, "(")
  .col_defs <- paste("  ", .cols$name, .cols$type, sep=" ")
  .schema_lines <- c(.schema_lines, .header, .col_defs, ");", "")
}}
writeLines(.schema_lines, {json.dumps(schema_path)})
cat("Schema written to:", {json.dumps(schema_path)}, "\\n")
"""
    elif engine == "mssql":
        r_code = f"""
.schema <- DBI::dbGetQuery(con, "
  SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE,
         CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
  FROM INFORMATION_SCHEMA.COLUMNS
  ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION
")
.lines <- character()
.prev_table <- ""
for (.i in seq_len(nrow(.schema))) {{
  .row <- .schema[.i, ]
  .full_name <- paste(.row$TABLE_SCHEMA, .row$TABLE_NAME, sep=".")
  if (.full_name != .prev_table) {{
    if (.prev_table != "") .lines <- c(.lines, ");", "")
    .lines <- c(.lines, paste("CREATE TABLE", .full_name, "("))
    .prev_table <- .full_name
  }}
  .type_str <- .row$DATA_TYPE
  if (!is.na(.row$CHARACTER_MAXIMUM_LENGTH))
    .type_str <- paste0(.type_str, "(", .row$CHARACTER_MAXIMUM_LENGTH, ")")
  .nullable <- ifelse(.row$IS_NULLABLE == "YES", "NULL", "NOT NULL")
  .lines <- c(.lines, paste("  ", .row$COLUMN_NAME, .type_str, .nullable))
}}
if (length(.lines) > 0) .lines <- c(.lines, ");")
writeLines(.lines, {json.dumps(schema_path)})
cat("Schema written to:", {json.dumps(schema_path)}, "\\n")
"""
    else:
        # Generic fallback using DBI
        r_code = f"""
.tables <- DBI::dbListTables(con)
.lines <- character()
for (.t in .tables) {{
  .fields <- DBI::dbListFields(con, .t)
  .lines <- c(.lines, paste("TABLE:", .t), paste("  ", .fields), "")
}}
writeLines(.lines, {json.dumps(schema_path)})
cat("Schema written to:", {json.dumps(schema_path)}, "\\n")
"""

    result = _session.execute(r_code, timeout=300)
    if not result["success"]:
        return json.dumps({"error": result["stderr"]})

    return json.dumps({"schema_path": schema_path, "output": result["stdout"]}, indent=2)


@mcp.tool()
async def run_profiler(code: str) -> str:
    """Execute R profiling code and save the output to the data profile path.

    The agent writes the profiling code based on the CDM type and schema.
    This tool executes it and saves the output to the config's data_profile path.

    Args:
        code: R code that generates profiling output. The code should write
              its output using cat() or writeLines(). The tool captures stdout
              and writes it to the profile file.
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    profile_path = _config.get("data_profile", "")
    if not profile_path:
        return json.dumps({"error": "No data_profile path in config."})

    if not os.path.isabs(profile_path):
        profile_path = str(PROJECT_ROOT / profile_path)

    os.makedirs(os.path.dirname(profile_path), exist_ok=True)

    # Wrap the profiling code to write output to the profile path
    wrapped_code = f"""
.profile_con <- file({json.dumps(profile_path)}, open = "wt")
sink(.profile_con)
{code}
sink()
close(.profile_con)
cat("Profile written to:", {json.dumps(profile_path)}, "\\n")
"""
    result = _session.execute(wrapped_code, timeout=600)
    if not result["success"]:
        return json.dumps({"error": result["stderr"]})

    return json.dumps({"profile_path": profile_path, "output": result["stdout"]}, indent=2)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    global _config, _mode_override

    parser = argparse.ArgumentParser(description="R Executor MCP Server")
    parser.add_argument("--config", required=True, help="Path to database config YAML")
    parser.add_argument("--mode", choices=["online", "offline"], default="",
                        help="Override online/offline mode from config")
    args = parser.parse_args()

    _config = load_config(args.config)
    _mode_override = args.mode

    mcp.run()


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
PYTHONPATH=. python -m pytest tests/test_r_executor.py -v
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/r_executor_server.py tests/test_r_executor.py
git commit -m "Add R executor MCP server with persistent R session and DB connection"
```

---

## Task 7: Update .mcp.json

**Files:**
- Modify: `.mcp.json`

- [ ] **Step 1: Add datasource server to .mcp.json**

Update `.mcp.json` to add the `datasource` server. Do NOT add `r_executor` —
that is added dynamically by `run.sh` via `.mcp-session.json`.

```json
{
  "mcpServers": {
    "pubmed": {
      "command": "python",
      "args": ["tools/pubmed_server.py"],
      "env": {}
    },
    "rxnorm": {
      "command": "python",
      "args": ["tools/rxnorm_server.py"],
      "env": {}
    },
    "clinical_codes": {
      "command": "python",
      "args": ["tools/clinical_codes_server.py"],
      "env": {}
    },
    "datasource": {
      "command": "python",
      "args": ["tools/datasource_server.py"],
      "env": {}
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add .mcp.json
git commit -m "Add datasource MCP server to .mcp.json"
```

---

## Task 8: Update run.sh

**Files:**
- Modify: `run.sh`

- [ ] **Step 1: Rewrite run.sh with new CLI flags**

Replace the entire content of `run.sh` with the new version that supports
`--db-config` and `--db-mode`, generates `.mcp-session.json` for online mode,
and builds the updated coordinator prompt.

The new `run.sh` must:
1. Parse `--db-config <path>` and `--db-mode online|offline` flags
2. Remove `--cdw`, `--both`, `--db-connect` flag handling
3. When `--db-config` is provided:
   - Read the YAML to extract `id`, `name`, `cdm`, `engine`, `schema_prefix`, `online`
   - If online mode: generate `.mcp-session.json` merging base `.mcp.json` with `r_executor`
   - Build a DB context block for the coordinator prompt with all DB details
4. Update the `--allowedTools` list to replace `mcp__pubmed__query_dataset_registry`
   and `mcp__pubmed__get_dataset_details` with `mcp__datasource__list_datasources`,
   `mcp__datasource__get_datasource_details`, `mcp__datasource__get_schema`,
   `mcp__datasource__get_profile`, `mcp__datasource__get_conventions`
5. In online mode, also add `mcp__r_executor__execute_r`, `mcp__r_executor__query_db`,
   `mcp__r_executor__list_tables`, `mcp__r_executor__describe_table`,
   `mcp__r_executor__dump_schema`, `mcp__r_executor__run_profiler` to the allowedTools
6. Clean up `.mcp-session.json` on exit with a trap

Key implementation: use `python3 -c "import yaml; ..."` to parse the YAML config
in bash, since `yq` may not be installed but Python + PyYAML are available.

The full run.sh content:

```bash
#!/usr/bin/env bash
# =============================================================================
# Auto-Protocol Designer — Launch Script
# =============================================================================
# Launches the coordinator agent, which autonomously orchestrates sub-agents
# through iterative review loops.
#
# Usage:
#   ./run.sh "atrial fibrillation"
#   ./run.sh "atrial fibrillation" --db-config databases/synthetic_pcornet.yaml
#   ./run.sh "atrial fibrillation" --db-config databases/secure_pcornet_cdw.yaml --db-mode offline
#   ./run.sh "type 2 diabetes" --db-config databases/my_cdw.yaml 75
#
# Prerequisites:
#   - Claude Code CLI installed (npm install -g @anthropic-ai/claude-code)
#   - Python 3.11+ with: pip install mcp httpx lxml pyyaml
#   - ANTHROPIC_API_KEY set in environment
#   - For online DB mode: R installed with DBI + engine-specific driver
# =============================================================================

set -euo pipefail

THERAPEUTIC_AREA="${1:?Usage: ./run.sh \"therapeutic area\" [--db-config <path>] [--db-mode online|offline] [max_turns]}"

# Parse optional flags
DB_CONFIG=""
DB_MODE=""
MAX_TURNS="50"
SKIP_NEXT=false
for i in $(seq 2 $#); do
  if $SKIP_NEXT; then
    SKIP_NEXT=false
    continue
  fi
  arg="${!i}"
  case "$arg" in
    --db-config)
      next_i=$((i + 1))
      DB_CONFIG="${!next_i}"
      SKIP_NEXT=true
      ;;
    --db-mode)
      next_i=$((i + 1))
      DB_MODE="${!next_i}"
      SKIP_NEXT=true
      ;;
    *)
      if [[ "$arg" =~ ^[0-9]+$ ]]; then
        MAX_TURNS="$arg"
      fi
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RESULTS_DIR="results/$(echo "$THERAPEUTIC_AREA" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
mkdir -p "$RESULTS_DIR/protocols"

# ---------------------------------------------------------------------------
# Parse DB config if provided
# ---------------------------------------------------------------------------
DB_ID=""
DB_NAME=""
DB_CDM=""
DB_ENGINE=""
DB_SCHEMA_PREFIX=""
DB_ONLINE="false"

if [[ -n "$DB_CONFIG" ]]; then
  if [[ ! -f "$DB_CONFIG" ]]; then
    echo "ERROR: DB config file not found: $DB_CONFIG" >&2
    exit 1
  fi

  # Parse YAML using Python (pyyaml is a dependency)
  eval "$(python3 -c "
import yaml, sys
with open('$DB_CONFIG') as f:
    c = yaml.safe_load(f)
print(f'DB_ID={c.get(\"id\", \"\")}')
print(f'DB_NAME=\"{c.get(\"name\", \"\")}\"')
print(f'DB_CDM={c.get(\"cdm\", \"\")}')
print(f'DB_ENGINE={c.get(\"engine\", \"\")}')
print(f'DB_SCHEMA_PREFIX=\"{c.get(\"schema_prefix\", \"\")}\"')
print(f'DB_ONLINE={str(c.get(\"online\", False)).lower()}')
")"

  # Apply mode override
  if [[ -n "$DB_MODE" ]]; then
    if [[ "$DB_MODE" == "offline" ]]; then
      DB_ONLINE="false"
    elif [[ "$DB_MODE" == "online" ]]; then
      DB_ONLINE="true"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Display banner
# ---------------------------------------------------------------------------
echo "============================================="
echo " Auto-Protocol Designer"
echo " Therapeutic area: $THERAPEUTIC_AREA"
if [[ -n "$DB_CONFIG" ]]; then
echo " Database:         $DB_NAME ($DB_ID)"
echo " CDM:              $DB_CDM"
echo " Engine:           $DB_ENGINE"
echo " Mode:             $([ "$DB_ONLINE" = "true" ] && echo "ONLINE" || echo "OFFLINE")"
else
echo " Data sources:     Public datasets only"
fi
echo " Max turns/sub-agent: $MAX_TURNS"
echo " Results: $RESULTS_DIR/"
echo "============================================="
echo ""

# ---------------------------------------------------------------------------
# Build MCP session config for online mode
# ---------------------------------------------------------------------------
MCP_CONFIG_FLAG=""
cleanup_session_config() {
  rm -f "$SCRIPT_DIR/.mcp-session.json"
}

if [[ "$DB_ONLINE" == "true" && -n "$DB_CONFIG" ]]; then
  # Generate session-specific MCP config with r_executor
  python3 -c "
import json
with open('.mcp.json') as f:
    config = json.load(f)
config['mcpServers']['r_executor'] = {
    'command': 'python',
    'args': ['tools/r_executor_server.py', '--config', '$DB_CONFIG'],
    'env': {}
}
with open('.mcp-session.json', 'w') as f:
    json.dump(config, f, indent=2)
"
  trap cleanup_session_config EXIT
  echo "Generated .mcp-session.json with r_executor for online mode."
  echo ""
fi

# ---------------------------------------------------------------------------
# Build tool allowlists
# ---------------------------------------------------------------------------
BASE_TOOLS="mcp__pubmed__search_pubmed,mcp__pubmed__fetch_abstracts"
DATASOURCE_TOOLS="mcp__datasource__list_datasources,mcp__datasource__get_datasource_details,mcp__datasource__get_schema,mcp__datasource__get_profile,mcp__datasource__get_conventions"
CODE_TOOLS="mcp__rxnorm__search_drug,mcp__rxnorm__get_all_related,mcp__rxnorm__get_rxcuis_for_drug,mcp__rxnorm__validate_rxcui_list,mcp__rxnorm__get_drug_class_members,mcp__rxnorm__lookup_rxcui,mcp__clinical_codes__search_loinc,mcp__clinical_codes__get_loinc_details,mcp__clinical_codes__find_related_loincs,mcp__clinical_codes__search_icd10,mcp__clinical_codes__get_icd10_hierarchy,mcp__clinical_codes__search_hcpcs,mcp__clinical_codes__lookup_hcpcs"
FILE_TOOLS="Bash,Read,Write,Edit,WebSearch,WebFetch"

R_EXECUTOR_TOOLS=""
if [[ "$DB_ONLINE" == "true" ]]; then
  R_EXECUTOR_TOOLS=",mcp__r_executor__execute_r,mcp__r_executor__query_db,mcp__r_executor__list_tables,mcp__r_executor__describe_table,mcp__r_executor__dump_schema,mcp__r_executor__run_profiler"
fi

WORKER_TOOLS="${BASE_TOOLS},${DATASOURCE_TOOLS},${CODE_TOOLS},${FILE_TOOLS}${R_EXECUTOR_TOOLS}"
REVIEWER_TOOLS="${BASE_TOOLS},${DATASOURCE_TOOLS},${CODE_TOOLS},${FILE_TOOLS}${R_EXECUTOR_TOOLS}"
COORDINATOR_TOOLS="Bash,Read,Write,Edit"

# ---------------------------------------------------------------------------
# Build coordinator prompt
# ---------------------------------------------------------------------------
DB_CONTEXT=""
if [[ -n "$DB_CONFIG" ]]; then
  DB_CONTEXT="
Database configuration:
- Config file: $DB_CONFIG
- Database ID: $DB_ID
- Database name: $DB_NAME
- CDM type: $DB_CDM
- Engine: $DB_ENGINE
- Schema prefix: $DB_SCHEMA_PREFIX
- Mode: $([ "$DB_ONLINE" = "true" ] && echo "ONLINE (agents can query the database)" || echo "OFFLINE (agents work from schema dump and data profile)")

When launching sub-agents for this database:
- Tell workers the database ID ('$DB_ID'), CDM type, engine, and schema prefix.
- Tell workers to call get_schema('$DB_ID'), get_profile('$DB_ID'), and
  get_conventions('$DB_ID') from the datasource MCP server to get database
  details. Do NOT reference hardcoded file paths.
- Tell workers to read and apply ALL database conventions before writing any
  SQL or R code. Conventions are hard requirements, not suggestions.
$([ "$DB_ONLINE" = "true" ] && echo "- Tell workers they have online access and can use execute_r() and query_db()
  to validate their work against the live database.
- During Phase 0 (Data Source Onboarding), check if schema dump and data profile
  exist. If not, use dump_schema() and run_profiler() to generate them." || echo "- Workers do NOT have online database access. They must work from the schema
  dump and data profile files.")"
fi

cat <<PROMPT | claude -p \
  --verbose \
  --max-turns 200 \
  --output-format stream-json \
  --allowedTools "$COORDINATOR_TOOLS" \
  2>&1 | python3 tools/stream_viewer.py --label "Coordinator"
You are the coordinator agent for the Auto-Protocol Designer.

Read COORDINATOR.md now for your full instructions.

Your configuration:
- Therapeutic area: "$THERAPEUTIC_AREA"
- Results directory: $RESULTS_DIR
- Max turns per sub-agent: $MAX_TURNS (pass this as --max-turns to sub-agents)
$DB_CONTEXT

When launching sub-agents, always pipe through stream_viewer.py with a label:
cat <<'SUBPROMPT' | claude -p --verbose --max-turns \$MAX_TURNS \\
  --output-format stream-json \\
  --allowedTools "$WORKER_TOOLS" \\
  2>&1 | python3 tools/stream_viewer.py --label "Worker"
[prompt for sub-agent]
SUBPROMPT

Use --label "Worker" for work agents, --label "Reviewer" for review agents.
Use --allowedTools "$REVIEWER_TOOLS" for reviewers.

Note: Sub-agents have access to PubMed, datasource registry, RxNorm, clinical
codes, and ICD-10 MCP tools. You (the coordinator) do not need those tools —
you work through sub-agents.

Begin by reading COORDINATOR.md, then initialize your state files and start
the pipeline.
PROMPT
```

- [ ] **Step 2: Make run.sh executable**

```bash
chmod +x run.sh
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n run.sh
```

Expected: No output (valid syntax).

- [ ] **Step 4: Commit**

```bash
git add run.sh
git commit -m "Rewrite run.sh with --db-config/--db-mode flags and session MCP config"
```

---

## Task 9: Update COORDINATOR.md

**Files:**
- Modify: `COORDINATOR.md`

- [ ] **Step 1: Update COORDINATOR.md**

Make the following changes to `COORDINATOR.md`:

**a) Replace the "Protocol Targets" section (lines 56-73)** with a new section
that describes database-driven targeting:

```markdown
## Data Sources

Your initial prompt will specify the data source configuration:

- **No database configured:** Protocols target public datasets only.
  Workers use the datasource MCP tools to find suitable public datasets.
- **Database configured (offline):** Protocols target the configured database.
  Workers use `get_schema(id)`, `get_profile(id)`, and `get_conventions(id)`
  from the datasource MCP server. They cannot query the database directly.
- **Database configured (online):** Same as offline, plus workers can query
  the live database via `execute_r()` and `query_db()` to validate feasibility
  and test generated R code.

Public datasets are always available via the datasource registry regardless
of whether a database is configured.

When a database is configured, tell workers:
1. The database ID, CDM type, engine, and schema prefix
2. To call `get_schema(id)`, `get_profile(id)`, and `get_conventions(id)`
3. To read and apply ALL conventions before writing SQL or R code
4. Whether they have online access (can use `execute_r()` / `query_db()`)
```

**b) Add Phase 0 before Phase 1 (insert after "## The Research Phases" header):**

```markdown
### Phase 0: Data Source Onboarding (if database configured)

If a database was configured in your initial prompt:

1. **Online mode:**
   a. Read the DB config YAML to understand the database.
   b. Check if the schema dump file exists. If not, call `dump_schema()` via
      the R executor MCP to generate it.
   c. Check if the data profile file exists. If not:
      - Read the generated schema dump.
      - Determine appropriate profiling queries based on the CDM type.
      - Write R profiling code.
      - Call `run_profiler(code)` to execute it and save the output.
   d. Log onboarding results to `{results_dir}/coordinator_log.md`.

2. **Offline mode:**
   a. Verify that schema dump and data profile files exist by checking
      the paths in the config.
   b. If missing, log a warning and proceed with whatever is available.

3. **Both modes:**
   a. Check that the conventions file exists. Log its path for sub-agents.
   b. Record the database details in `agent_state.json`.
```

**c) Update the worker/reviewer launch templates** in "How to Launch Sub-Agents"
(lines 21-45) to use the new `--allowedTools` list. Replace the hardcoded
`mcp__pubmed__query_dataset_registry,mcp__pubmed__get_dataset_details` with
the datasource tools. The exact allowedTools will come from the coordinator
prompt — the template in COORDINATOR.md should reference the tools listed in
the coordinator's initial prompt.

**d) Update Feasibility Acceptance Criteria** (lines 183-206):
- Replace "dataset registry AND/OR against the PCORnet CDW schema" with
  "datasource registry AND/OR against the configured database schema"
- Replace "Worker consulted `CDW_data_profile.md`" with
  "Worker consulted the database data profile via `get_profile(id)`"
- Remove hardcoded references to CDW-specific file paths

**e) Update Protocol Acceptance Criteria CDW section** (lines 215-265):
- Replace the CDW-specific SQL checklist with a generic reference:
  "Worker applied all conventions from `get_conventions(id)`. Reviewer verified
  compliance with each convention."
- Keep the generic protocol criteria (time zero, estimand, etc.)

**f) Update the sub-agent launch templates** to reference the allowedTools
variable from the coordinator prompt rather than hardcoding tool lists.

- [ ] **Step 2: Verify COORDINATOR.md is consistent**

Read through the updated file. Check that:
- No references to `CDW_DBO_database_schema.txt` or `CDW_data_profile.md` remain
- No references to `mcp__pubmed__query_dataset_registry` remain
- Phase 0 is clearly positioned before Phase 1
- The allowedTools guidance points workers at datasource + r_executor tools

- [ ] **Step 3: Commit**

```bash
git add COORDINATOR.md
git commit -m "Update COORDINATOR.md with Phase 0 onboarding and datasource MCP references"
```

---

## Task 10: Update WORKER.md

**Files:**
- Modify: `WORKER.md`

- [ ] **Step 1: Update WORKER.md**

Make the following changes:

**a) Update "Your Tools" section (lines 9-16):**

Replace:
```markdown
- **query_dataset_registry** — Search a registry of public clinical datasets.
- **get_dataset_details** — Get full details on a specific dataset.
```

With:
```markdown
- **list_datasources** — List all available data sources (public datasets + configured databases).
- **get_datasource_details** — Get full details for a specific data source.
- **get_schema** — Get the database schema dump for a configured data source.
- **get_profile** — Get the data profile for a configured data source.
- **get_conventions** — Get database-specific conventions (required filters, SQL patterns, etc.).
- **execute_r** — (Online mode only) Execute R code in a persistent session with DB connection.
- **query_db** — (Online mode only) Run SQL queries against the connected database.
```

**b) Replace the "Protocol Targets: Public Data vs CDW" section (lines 188-595)**
with a new, shorter, generic section. This is the big change — all
CDW-specific conventions move to the conventions file (Task 3).

The new section should cover:
1. **Data Source Access** — how to use datasource MCP tools
2. **Database Conventions** — always call `get_conventions(id)` before writing code
3. **SQL Dialect Awareness** — engine-specific patterns (mssql, duckdb, postgres)
4. **Online Mode Validation** — how to use `execute_r()` / `query_db()` to test code
5. **Key PCORnet CDM Tables** — the table reference (lines 209-225) stays as
   generic CDM guidance, but framed as "when targeting a PCORnet CDM database"
6. **Generic R Code Patterns** — keep the sections on CONSORT flow, propensity
   score formula building, Quarto layout, empty cohort guard, treatment arms
   guard, E-value, column naming. These are methodology patterns, not
   database-specific conventions. Remove CDW-specific SQL details from them.

The existing CDW-specific content that moves to conventions:
- Legacy encounter filtering (lines 262-284)
- Date bounds / junk dates (lines 233-256)
- ICD-9/10 transition (lines 257-261)
- Table qualification `CDW.dbo.TABLE_NAME` (lines 229-230)
- ODBC batch bug (lines 356-375)
- DEATH table deduplication (lines 418-429)
- ROW_NUMBER on all LEFT JOINs (lines 387-415)
- count_temp() using COUNT(DISTINCT PATID) (lines 429-430)
- Column case normalization (lines 324-328)
- Factor naming (lines 431-447)

These are all already captured in the conventions file from Task 3.

- [ ] **Step 2: Verify WORKER.md is consistent**

Read through the updated file. Check that:
- No references to `CDW_DBO_database_schema.txt`, `CDW_data_profile.md`, or
  `MasterPatientIndex_DBO_database_schema.txt` remain
- No references to `query_dataset_registry` or `get_dataset_details` from pubmed
- CDW-specific SQL conventions are NOT in WORKER.md (they're in conventions)
- Generic methodology guidance (CONSORT, PS formula, Quarto layout) is retained
- The file clearly directs workers to call `get_conventions(id)`

- [ ] **Step 3: Commit**

```bash
git add WORKER.md
git commit -m "Update WORKER.md with datasource MCP tools and extract CDW conventions"
```

---

## Task 11: Update REVIEW.md

**Files:**
- Modify: `REVIEW.md`

- [ ] **Step 1: Update REVIEW.md**

Make the following changes:

**a) Update "For Feasibility Reviews" section (lines 124-136):**

Replace `get_dataset_details` references with `get_datasource_details`.

**b) Replace "CDW-Specific Code Review" section (lines 169-248)** with a
generic conventions-based review section:

```markdown
### Database-Specific Code Review (required for all database-targeted protocols)

When reviewing protocols that target a configured database:

1. Call `get_conventions(id)` to load the database's conventions.
2. Use each convention as a checklist item — verify the worker's SQL and R code
   complies with every applicable convention.
3. Flag any violation as a REVISE item with a specific reference to the
   convention that was violated.

If the worker did NOT call `get_conventions(id)` or did not demonstrate
awareness of the conventions in their code, this is an automatic REVISE.

**Online mode additional checks:**
- If the run had online access, verify the worker actually executed the code
  against the database (look for execution output in the protocol or logs).
- Use `query_db()` to independently spot-check claims about patient counts
  or code coverage.
```

**c) Keep the generic protocol review checklist** (target trial specification,
common fatal flaws, R code review) — these are methodology checks, not
database-specific.

- [ ] **Step 2: Verify REVIEW.md is consistent**

Read through the updated file. Check that:
- No references to `CDW_data_profile.md` or `CDW_DBO_database_schema.txt` remain
- No references to `mcp__pubmed__query_dataset_registry` remain
- CDW-specific code review items are NOT in REVIEW.md
- The file clearly directs reviewers to use conventions

- [ ] **Step 3: Commit**

```bash
git add REVIEW.md
git commit -m "Update REVIEW.md with conventions-based review and datasource MCP references"
```

---

## Task 12: Update .gitignore with session config

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add .mcp-session.json to .gitignore (if not already done in Task 1)**

Verify `.mcp-session.json` is in `.gitignore`. If Task 1 already added it, skip.

- [ ] **Step 2: Commit if needed**

```bash
git add .gitignore
git commit -m "Add .mcp-session.json to .gitignore"
```

---

## Task 13: Integration Smoke Test

This task verifies the pieces work together. It does NOT require a running R
session or database — it tests the Python servers and config loading.

**Files:** None created. Uses existing test files.

- [ ] **Step 1: Run all unit tests**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
PYTHONPATH=. python -m pytest tests/ -v
```

Expected: All tests PASS.

- [ ] **Step 2: Verify datasource_server.py can load the real configs**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
python3 -c "
import sys
sys.path.insert(0, '.')
from tools.datasource_server import load_db_configs, filter_datasources, PUBLIC_DATASETS

configs = load_db_configs('databases')
print(f'Loaded {len(configs)} database configs:')
for c in configs:
    print(f'  - {c[\"id\"]}: {c[\"name\"]} ({c[\"cdm\"]}/{c[\"engine\"]}, online={c.get(\"online\", False)})')

print(f'\nPublic datasets: {len(PUBLIC_DATASETS)}')
for d in PUBLIC_DATASETS:
    print(f'  - {d[\"id\"]}: {d[\"name\"]}')

all_sources = PUBLIC_DATASETS + configs
pcornet = filter_datasources(all_sources, cdm='pcornet')
print(f'\nPCORnet sources: {len(pcornet)}')
for s in pcornet:
    print(f'  - {s[\"id\"]}: {s[\"name\"]}')
"
```

Expected: Lists both database configs and all public datasets. PCORnet filter
shows the two configured databases.

- [ ] **Step 3: Verify r_executor_server.py config loading works**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
python3 -c "
import sys
sys.path.insert(0, '.')
from tools.r_executor_server import load_config, is_online, get_connection_code

config = load_config('databases/synthetic_pcornet.yaml')
print(f'Config: {config[\"id\"]} - {config[\"name\"]}')
print(f'Online: {is_online(config)}')
print(f'Online (override offline): {is_online(config, mode_override=\"offline\")}')
print(f'Connection code: {get_connection_code(config)[:50]}...')

config2 = load_config('databases/secure_pcornet_cdw.yaml')
print(f'\nConfig: {config2[\"id\"]} - {config2[\"name\"]}')
print(f'Online: {is_online(config2)}')
"
```

Expected: Correctly loads both configs, shows online/offline status, prints
connection code preview.

- [ ] **Step 4: Verify run.sh parses flags correctly (dry run)**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
# Test flag parsing by running just the parsing section (the script will fail
# at the claude command since we're not running the full pipeline)
bash -c '
source <(head -90 run.sh | tail -60)
echo "DB_CONFIG=$DB_CONFIG"
echo "DB_MODE=$DB_MODE"
echo "MAX_TURNS=$MAX_TURNS"
' -- "test topic" --db-config databases/synthetic_pcornet.yaml --db-mode offline 75
```

Expected: Shows the parsed flag values.

- [ ] **Step 5: Verify no broken references in COORDINATOR.md, WORKER.md, REVIEW.md**

```bash
cd /Users/toddjohnson/Documents/GitHub/AutoTTE
# Check that old hardcoded references are gone
for f in COORDINATOR.md WORKER.md REVIEW.md; do
  echo "=== $f ==="
  grep -n "CDW_DBO_database_schema\|CDW_data_profile\|MasterPatientIndex_DBO\|query_dataset_registry\|get_dataset_details.*pubmed" "$f" || echo "  (no old references found - GOOD)"
done
```

Expected: No old references found in any of the three files.

- [ ] **Step 6: Commit any fixes discovered during smoke testing**

If any issues were found and fixed in previous steps:

```bash
git add -A
git commit -m "Fix integration issues discovered during smoke testing"
```

---

## Dependency Graph

```
Task 1 (directory + migration)
  └─> Task 2 (config YAMLs)
  └─> Task 3 (conventions file)
        └─> Task 10 (WORKER.md) ─────> Task 13 (smoke test)
        └─> Task 11 (REVIEW.md) ────>
  └─> Task 4 (datasource server) ──>
        └─> Task 5 (pubmed cleanup) >
  └─> Task 6 (R executor server) ──>
  └─> Task 7 (.mcp.json) ──────────>
  └─> Task 8 (run.sh) ─────────────>
  └─> Task 9 (COORDINATOR.md) ─────>
  └─> Task 12 (.gitignore check) ──>
```

Tasks 2-7 can be parallelized after Task 1. Tasks 8-11 depend on the MCP
servers and conventions file existing. Task 12 is a quick check. Task 13
verifies everything together.
