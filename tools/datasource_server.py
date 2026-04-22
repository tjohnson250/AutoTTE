"""Datasource registry MCP server.

Provides a unified view of all data sources available for target trial
emulation: public datasets (MIMIC-IV, NHANES, etc.) and locally-configured
database connections defined in databases/*.yaml.
"""

from __future__ import annotations

import glob
import os
from pathlib import Path
from typing import Any

import yaml
from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATABASES_DIR = PROJECT_ROOT / "databases"

# ---------------------------------------------------------------------------
# Public dataset registry
# ---------------------------------------------------------------------------

PUBLIC_DATASETS: list[dict[str, Any]] = [
    {
        "id": "mimic_iv",
        "type": "public",
        "name": "MIMIC-IV",
        "description": "Critical care EHR data from Beth Israel Deaconess Medical Center. ~70k ICU stays, ~400k hospital admissions.",
        "domain": "inpatient_icu",
        "access": "PhysioNet credentialed access (free, requires CITI training)",
        "variables": [
            "demographics", "vitals", "labs", "medications", "procedures",
            "diagnoses_icd", "ventilation", "vasopressors", "mortality",
            "length_of_stay", "readmission", "microbiology", "radiology_notes",
        ],
        "strengths": ["Granular temporal data", "Medication administration records", "Lab time series"],
        "limitations": ["Single center", "ICU patients only (sicker population)", "US academic hospital"],
        "url": "https://physionet.org/content/mimiciv/",
    },
    {
        "id": "eicu_crd",
        "type": "public",
        "name": "eICU-CRD",
        "description": "Multi-center ICU database from Philips eICU telehealth program. ~200k ICU stays across 208 hospitals.",
        "domain": "inpatient_icu",
        "access": "PhysioNet credentialed access (free)",
        "variables": [
            "demographics", "vitals", "labs", "medications", "diagnoses",
            "apache_scores", "ventilation", "mortality", "length_of_stay",
            "nurse_charting", "respiratory_charting",
        ],
        "strengths": ["Multi-center", "Large sample", "APACHE scores available"],
        "limitations": ["Less granular than MIMIC", "Telehealth ICUs may differ", "US only"],
        "url": "https://physionet.org/content/eicu-crd/",
    },
    {
        "id": "nhanes",
        "type": "public",
        "name": "NHANES",
        "description": "National Health and Nutrition Examination Survey. ~5k participants per 2-year cycle, nationally representative.",
        "domain": "population_health",
        "access": "Public download, no restrictions",
        "variables": [
            "demographics", "blood_pressure", "cholesterol", "hba1c",
            "bmi", "smoking", "medications_self_report", "diet",
            "physical_activity", "mortality_linked", "kidney_function",
            "liver_function", "mental_health",
        ],
        "strengths": ["Nationally representative", "Physical exam + lab data", "Mortality follow-up linkage"],
        "limitations": ["Cross-sectional (no longitudinal follow-up except mortality)", "Self-reported medications", "Small sample per cycle"],
        "url": "https://www.cdc.gov/nchs/nhanes/",
        "schema_dump": "databases/schemas/nhanes_schema.txt",
        "data_profile": "databases/profiles/nhanes_profile.md",
        "conventions": "databases/conventions/nhanes_conventions.md",
    },
    {
        "id": "meps",
        "type": "public",
        "name": "MEPS",
        "description": "Medical Expenditure Panel Survey. Longitudinal survey of ~15k households per panel (2-year follow-up).",
        "domain": "expenditures_utilization",
        "access": "Public download, no restrictions",
        "variables": [
            "demographics", "conditions_icd", "prescriptions",
            "utilization", "expenditures", "insurance", "income",
            "employment", "functional_status", "sf12_quality_of_life",
        ],
        "strengths": ["Longitudinal (2 years)", "Detailed cost data", "Nationally representative"],
        "limitations": ["Self-reported conditions", "Short follow-up", "No lab values"],
        "url": "https://meps.ahrq.gov/",
    },
    {
        "id": "cms_synpuf",
        "type": "public",
        "name": "CMS_SynPUF",
        "description": "CMS Synthetic Medicare Claims Public Use Files. Synthetic but realistic claims for ~2M beneficiaries.",
        "domain": "claims",
        "access": "Public download, no restrictions",
        "variables": [
            "demographics", "diagnoses_icd", "procedures_cpt",
            "prescriptions_ndc", "inpatient_stays", "outpatient_visits",
            "carrier_claims", "expenditures", "death_date",
        ],
        "strengths": ["Large sample", "Longitudinal claims", "No access restrictions"],
        "limitations": [
            "SYNTHETIC data — not real patients",
            "Relationships between variables may not be preserved",
            "Cannot make real clinical inferences",
        ],
        "url": "https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files",
    },
    {
        "id": "synthea",
        "type": "public",
        "name": "Synthea",
        "description": "Synthetic patient generator. Can generate arbitrary-sized populations with configurable disease modules.",
        "domain": "synthetic_ehr",
        "access": "Open source, generate locally",
        "variables": [
            "demographics", "conditions", "medications", "procedures",
            "encounters", "observations", "immunizations", "care_plans",
            "allergies", "imaging",
        ],
        "strengths": ["Any sample size", "No access restrictions", "FHIR/CSV output", "Good for methods development"],
        "limitations": [
            "SYNTHETIC — disease relationships are programmed, not observed",
            "Only useful for methods demonstrations, not real inference",
        ],
        "url": "https://synthetichealth.github.io/synthea/",
    },
]

# ---------------------------------------------------------------------------
# Pure helper functions (testable without MCP)
# ---------------------------------------------------------------------------


def load_db_configs(databases_dir: str) -> list[dict]:
    """Load all *.yaml database config files from *databases_dir* and
    *databases_dir*/local/.

    The `local/` subdir is a conventional mount point for a private git
    submodule holding institution-specific DB configs. Returns an empty
    list if neither directory exists. Each returned dict is the raw
    parsed YAML with ``type`` set to ``"database"``.
    """
    dir_path = Path(databases_dir)
    if not dir_path.is_dir():
        return []

    scan_dirs = [dir_path]
    local_dir = dir_path / "local"
    if local_dir.is_dir():
        scan_dirs.append(local_dir)

    configs: list[dict] = []
    for scan_dir in scan_dirs:
        for yaml_file in sorted(scan_dir.glob("*.yaml")):
            try:
                with open(yaml_file, "r", encoding="utf-8") as fh:
                    cfg = yaml.safe_load(fh)
                if isinstance(cfg, dict):
                    cfg.setdefault("type", "database")
                    configs.append(cfg)
            except Exception:
                # Skip malformed files rather than aborting.
                continue

    return configs


def filter_datasources(
    sources: list[dict],
    domain: str = "",
    cdm: str = "",
    online_only: bool = False,
) -> list[dict]:
    """Return sources that match all supplied filter criteria.

    Filters are ANDed together; an empty/falsy filter value means "no
    restriction on that field".
    """
    result = []
    for src in sources:
        if domain and src.get("domain", "") != domain:
            continue
        if cdm and src.get("cdm", "") != cdm:
            continue
        if online_only and not src.get("online", False):
            continue
        result.append(src)
    return result


def get_details_by_id(source_id: str, sources: list[dict]) -> dict | None:
    """Return the first source whose ``id`` or ``name`` matches *source_id*.

    Matching is case-insensitive.
    """
    needle = source_id.lower()
    for src in sources:
        if src.get("id", "").lower() == needle:
            return src
        if src.get("name", "").lower() == needle:
            return src
    return None


def read_file_content(file_path: str) -> str:
    """Return the text content of *file_path*, or an error message if missing."""
    path = Path(file_path)
    if not path.exists():
        return f"[File not found: {file_path}]"
    try:
        return path.read_text(encoding="utf-8")
    except Exception as exc:
        return f"[Error reading {file_path}: {exc}]"


# ---------------------------------------------------------------------------
# Internal source list (lazily populated)
# ---------------------------------------------------------------------------

_all_sources: list[dict] = []


def _load_all_sources() -> None:
    """Populate *_all_sources* with public datasets + DB configs (once)."""
    global _all_sources
    if _all_sources:
        return
    _all_sources = list(PUBLIC_DATASETS) + load_db_configs(str(DATABASES_DIR))


# ---------------------------------------------------------------------------
# MCP server
# ---------------------------------------------------------------------------

mcp = FastMCP("datasource")


@mcp.tool()
async def list_datasources(
    domain: str = "",
    cdm: str = "",
    online_only: bool = False,
) -> str:
    """List all available data sources with optional filtering.

    Args:
        domain: Filter by domain (e.g. "inpatient_icu", "claims", "pcornet").
        cdm: Filter by common data model (e.g. "pcornet", "omop").
        online_only: If true, only return sources that are online/accessible now.
    """
    _load_all_sources()
    sources = filter_datasources(_all_sources, domain=domain, cdm=cdm, online_only=online_only)

    if not sources:
        return "No data sources match the supplied filters."

    lines: list[str] = []
    for src in sources:
        src_id = src.get("id", src.get("name", "unknown"))
        src_name = src.get("name", src_id)
        src_type = src.get("type", "unknown")
        src_domain = src.get("domain", "")
        src_cdm = src.get("cdm", "")
        src_desc = src.get("description", "")
        online_flag = src.get("online", None)

        summary_parts = [f"**{src_name}** (id: `{src_id}`, type: {src_type})"]
        if src_domain:
            summary_parts.append(f"domain: {src_domain}")
        if src_cdm:
            summary_parts.append(f"CDM: {src_cdm}")
        if online_flag is not None:
            summary_parts.append(f"online: {online_flag}")
        if src_desc:
            summary_parts.append(src_desc)

        lines.append(" | ".join(summary_parts))

    return "\n".join(lines)


@mcp.tool()
async def get_datasource_details(id: str) -> str:  # noqa: A002
    """Return full details for a single data source.

    Args:
        id: The source id or name (case-insensitive).
    """
    _load_all_sources()
    src = get_details_by_id(id, _all_sources)
    if src is None:
        return f"No data source found with id or name: {id!r}"

    import json
    return json.dumps(src, indent=2, default=str)


@mcp.tool()
async def get_schema(id: str) -> str:  # noqa: A002
    """Return the schema dump for a database data source.

    Args:
        id: The source id or name (case-insensitive).
    """
    _load_all_sources()
    src = get_details_by_id(id, _all_sources)
    if src is None:
        return f"No data source found with id or name: {id!r}"

    schema_path = src.get("schema_dump")
    if not schema_path:
        return f"No schema_dump configured for {id!r}."

    # Resolve relative paths against PROJECT_ROOT
    resolved = Path(schema_path)
    if not resolved.is_absolute():
        resolved = PROJECT_ROOT / resolved

    content = read_file_content(str(resolved))

    # Also include MPI schema if available
    mpi_path = src.get("mpi_schema_dump")
    if mpi_path:
        mpi_resolved = Path(mpi_path)
        if not mpi_resolved.is_absolute():
            mpi_resolved = PROJECT_ROOT / mpi_resolved
        mpi_content = read_file_content(str(mpi_resolved))
        content = content + "\n\n--- MPI Schema ---\n\n" + mpi_content

    # Append any staging-database schema dumps (optional). These exist for
    # sites whose analyses need cross-database joins (e.g. the secure
    # PCORnet CDW's GECBI / Allscripts staging tables used by duplicate-
    # records studies). Missing files are skipped with a marker so the
    # worker can tell the dump was intended but isn't available yet.
    staging_list = src.get("staging_schema_dumps") or []
    for entry in staging_list:
        label = entry.get("label") or "(unlabeled staging)"
        schema_name = entry.get("schema_name") or "dbo"
        staging_path = entry.get("schema_dump")
        if not staging_path:
            continue
        staging_resolved = Path(staging_path)
        if not staging_resolved.is_absolute():
            staging_resolved = PROJECT_ROOT / staging_resolved
        header = f"\n\n--- Staging Schema: {label} (schema={schema_name}) ---\n\n"
        if staging_resolved.exists():
            content = content + header + read_file_content(str(staging_resolved))
        else:
            content = (
                content + header
                + f"[staging dump not yet generated: {staging_path}]\n"
                + "Run CDW_DB_Profiler.qmd on the secure host to produce it.\n"
            )

    return content


@mcp.tool()
async def get_profile(id: str) -> str:  # noqa: A002
    """Return the data profile for a database data source.

    Args:
        id: The source id or name (case-insensitive).
    """
    _load_all_sources()
    src = get_details_by_id(id, _all_sources)
    if src is None:
        return f"No data source found with id or name: {id!r}"

    profile_path = src.get("data_profile")
    if not profile_path:
        return f"No data_profile configured for {id!r}."

    resolved = Path(profile_path)
    if not resolved.is_absolute():
        resolved = PROJECT_ROOT / resolved

    return read_file_content(str(resolved))


@mcp.tool()
async def get_conventions(id: str) -> str:  # noqa: A002
    """Return the coding/naming conventions for a database data source.

    Args:
        id: The source id or name (case-insensitive).
    """
    _load_all_sources()
    src = get_details_by_id(id, _all_sources)
    if src is None:
        return f"No data source found with id or name: {id!r}"

    conventions_path = src.get("conventions")
    if not conventions_path:
        return ""  # Not configured — return empty string with note below

    resolved = Path(conventions_path)
    if not resolved.is_absolute():
        resolved = PROJECT_ROOT / resolved

    content = read_file_content(str(resolved))
    if not content.strip():
        return ""  # Conventions file exists but is empty

    return content


if __name__ == "__main__":
    mcp.run()
