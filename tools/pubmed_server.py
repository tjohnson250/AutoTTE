"""
PubMed MCP Tool Server
======================
Lightweight MCP server that gives Claude Code access to PubMed search
and abstract retrieval via NCBI E-utilities.

Run with:
    python tools/pubmed_server.py

Requires:
    pip install mcp httpx lxml
"""

import json
import re
from typing import Any

import httpx
from lxml import etree
from mcp.server.fastmcp import FastMCP

PUBMED_BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"

mcp = FastMCP("pubmed")


# ---------------------------------------------------------------------------
# PubMed Search
# ---------------------------------------------------------------------------

@mcp.tool()
async def search_pubmed(
    query: str,
    max_results: int = 30,
    sort: str = "relevance",
) -> str:
    """Search PubMed and return a list of PMIDs with basic metadata.

    Args:
        query: PubMed search query. Supports MeSH terms, field tags, and
               boolean operators. Examples:
               - '"atrial fibrillation"[MeSH] AND "randomized controlled trial"[pt]'
               - '"metformin" AND "dementia" AND "cohort studies"[MeSH]'
        max_results: Maximum number of results to return (default 30, max 100).
        sort: Sort order — "relevance" or "date" (default "relevance").
    """
    max_results = min(max_results, 100)

    async with httpx.AsyncClient(timeout=30) as client:
        # Step 1: Search for PMIDs
        search_resp = await client.get(
            f"{PUBMED_BASE}/esearch.fcgi",
            params={
                "db": "pubmed",
                "term": query,
                "retmax": max_results,
                "retmode": "json",
                "sort": sort,
            },
        )
        search_resp.raise_for_status()
        search_data = search_resp.json()

        result = search_data.get("esearchresult", {})
        pmids = result.get("idlist", [])
        total_count = int(result.get("count", 0))

        if not pmids:
            return json.dumps({
                "total_found": total_count,
                "returned": 0,
                "articles": [],
                "note": "No results found. Try broadening your search terms.",
            })

        # Step 2: Fetch summaries for the PMIDs
        summary_resp = await client.get(
            f"{PUBMED_BASE}/esummary.fcgi",
            params={
                "db": "pubmed",
                "id": ",".join(pmids),
                "retmode": "json",
            },
        )
        summary_resp.raise_for_status()
        summary_data = summary_resp.json().get("result", {})

        articles = []
        for pmid in pmids:
            if pmid in summary_data:
                info = summary_data[pmid]
                articles.append({
                    "pmid": pmid,
                    "title": info.get("title", ""),
                    "authors": [a.get("name", "") for a in info.get("authors", [])[:3]],
                    "journal": info.get("fulljournalname", ""),
                    "year": info.get("pubdate", "")[:4],
                    "pub_type": info.get("pubtype", []),
                })

        return json.dumps({
            "total_found": total_count,
            "returned": len(articles),
            "articles": articles,
        }, indent=2)


# ---------------------------------------------------------------------------
# Abstract Retrieval
# ---------------------------------------------------------------------------

@mcp.tool()
async def fetch_abstracts(
    pmids: list[str],
) -> str:
    """Fetch full title, abstract text, and MeSH terms for a list of PMIDs.

    Args:
        pmids: List of PubMed IDs to fetch. Max 20 per call to keep
               context manageable.
    """
    if len(pmids) > 20:
        pmids = pmids[:20]

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.get(
            f"{PUBMED_BASE}/efetch.fcgi",
            params={
                "db": "pubmed",
                "id": ",".join(pmids),
                "retmode": "xml",
                "rettype": "abstract",
            },
        )
        resp.raise_for_status()

    # Parse XML and extract structured data
    articles = _parse_pubmed_xml(resp.text)

    return json.dumps(articles, indent=2)


def _parse_pubmed_xml(xml_text: str) -> list[dict]:
    """Parse PubMed XML into structured article dicts."""
    try:
        root = etree.fromstring(xml_text.encode("utf-8"))
    except etree.XMLSyntaxError:
        return [{"error": "Failed to parse PubMed XML", "raw_length": len(xml_text)}]

    articles = []
    for article_el in root.findall(".//PubmedArticle"):
        pmid_el = article_el.find(".//PMID")
        title_el = article_el.find(".//ArticleTitle")
        abstract_el = article_el.find(".//Abstract")

        # Extract abstract text (may have multiple sections)
        abstract_parts = []
        if abstract_el is not None:
            for text_el in abstract_el.findall("AbstractText"):
                label = text_el.get("Label", "")
                text = "".join(text_el.itertext()).strip()
                if label:
                    abstract_parts.append(f"{label}: {text}")
                else:
                    abstract_parts.append(text)

        # Extract MeSH terms
        mesh_terms = []
        for mesh_el in article_el.findall(".//MeshHeading/DescriptorName"):
            mesh_terms.append(mesh_el.text)

        # Extract publication types
        pub_types = []
        for pt_el in article_el.findall(".//PublicationType"):
            pub_types.append(pt_el.text)

        articles.append({
            "pmid": pmid_el.text if pmid_el is not None else "unknown",
            "title": "".join(title_el.itertext()).strip() if title_el is not None else "",
            "abstract": "\n\n".join(abstract_parts),
            "mesh_terms": mesh_terms,
            "publication_types": pub_types,
        })

    return articles


# ---------------------------------------------------------------------------
# Dataset Registry
# ---------------------------------------------------------------------------

DATASET_REGISTRY = [
    {
        "name": "MIMIC-IV",
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
        "name": "eICU-CRD",
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
        "name": "NHANES",
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
        "name": "MEPS",
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
        "name": "CMS_SynPUF",
        "description": "CMS Synthetic Medicare Claims Public Use Files. Synthetic but realistic claims for ~2M beneficiaries.",
        "domain": "claims",
        "access": "Public download, no restrictions",
        "variables": ["demographics", "diagnoses_icd", "procedures_cpt",
                      "prescriptions_ndc", "inpatient_stays", "outpatient_visits",
                      "carrier_claims", "expenditures", "death_date"],
        "strengths": ["Large sample", "Longitudinal claims", "No access restrictions"],
        "limitations": ["SYNTHETIC data — not real patients", "Relationships between variables may not be preserved", "Cannot make real clinical inferences"],
        "url": "https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files",
    },
    {
        "name": "Synthea",
        "description": "Synthetic patient generator. Can generate arbitrary-sized populations with configurable disease modules.",
        "domain": "synthetic_ehr",
        "access": "Open source, generate locally",
        "variables": ["demographics", "conditions", "medications", "procedures",
                      "encounters", "observations", "immunizations", "care_plans",
                      "allergies", "imaging"],
        "strengths": ["Any sample size", "No access restrictions", "FHIR/CSV output", "Good for methods development"],
        "limitations": ["SYNTHETIC — disease relationships are programmed, not observed", "Only useful for methods demonstrations, not real inference"],
        "url": "https://synthetichealth.github.io/synthea/",
    },
]


@mcp.tool()
async def query_dataset_registry(
    domain: str = "",
    required_variables: list[str] | None = None,
    keyword: str = "",
) -> str:
    """Search the registry of available public clinical datasets.

    Use this to find datasets that could support a target trial emulation.
    You can filter by domain, required variables, or keyword.

    Args:
        domain: Filter by domain — "inpatient_icu", "population_health",
                "claims", "expenditures_utilization", "synthetic_ehr", or "" for all.
        required_variables: List of variable categories that the dataset must have.
                           e.g., ["medications", "mortality", "labs"]
        keyword: Free-text keyword to search in name and description.
    """
    results = DATASET_REGISTRY

    if domain:
        results = [d for d in results if domain.lower() in d["domain"].lower()]

    if required_variables:
        required = {v.lower() for v in required_variables}
        results = [
            d for d in results
            if required.issubset({v.lower() for v in d["variables"]})
        ]

    if keyword:
        kw = keyword.lower()
        results = [
            d for d in results
            if kw in d["name"].lower() or kw in d["description"].lower()
        ]

    return json.dumps(results, indent=2)


@mcp.tool()
async def get_dataset_details(name: str) -> str:
    """Get full details for a specific dataset in the registry.

    Args:
        name: Dataset name, e.g. "MIMIC-IV", "NHANES", "MEPS"
    """
    for d in DATASET_REGISTRY:
        if d["name"].lower() == name.lower():
            return json.dumps(d, indent=2)
    return json.dumps({"error": f"Dataset '{name}' not found in registry."})


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
