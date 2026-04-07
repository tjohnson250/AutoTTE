"""
Clinical Codes MCP Tool Server (LOINC + HCPCS)
===============================================
MCP server providing lookup and validation for LOINC lab codes and
HCPCS/CPT procedure codes. Complements the separate RxNorm and ICD-10
MCP servers to give AutoTTE agents full clinical code coverage.

LOINC lookups use the NLM Clinical Tables API (free, no auth).
HCPCS lookups use a bundled reference of common oncology/cardiology J-codes
plus the NLM Clinical Tables API for search.

Run with:
    python tools/clinical_codes_server.py

Requires:
    pip install mcp httpx
"""

import json
from typing import Any

import httpx
from mcp.server.fastmcp import FastMCP

CLINICAL_TABLES_BASE = "https://clinicaltables.nlm.nih.gov/api"

mcp = FastMCP("clinical_codes")


# ---------------------------------------------------------------------------
# Helper: HTTP GET
# ---------------------------------------------------------------------------

async def _api_get(url: str, params: dict | None = None) -> Any:
    """Make a GET request and return parsed JSON."""
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url, params=params or {})
        resp.raise_for_status()
        return resp.json()


# ===========================================================================
# LOINC Tools
# ===========================================================================

@mcp.tool()
async def search_loinc(
    query: str,
    max_results: int = 25,
) -> str:
    """Search for LOINC codes by keyword or lab test name.

    Use this to find the correct LOINC code(s) for a lab test when building
    LAB_RESULT_CM queries. Returns matching LOINC codes with their long names,
    components, and systems.

    Args:
        query: Search term (e.g., "creatinine", "eGFR", "hemoglobin A1c",
               "INR", "platelet count", "albumin serum").
        max_results: Maximum results to return (default 25, max 100).
    """
    max_results = min(max_results, 100)

    # NLM Clinical Tables API for LOINC
    data = await _api_get(
        f"{CLINICAL_TABLES_BASE}/loinc_items/v3/search",
        {
            "terms": query,
            "maxList": max_results,
            "df": "LOINC_NUM,LONG_COMMON_NAME,COMPONENT,SYSTEM,METHOD_TYP,PROPERTY,TIME_ASPCT,SCALE_TYP,CLASS",
        },
    )

    # Response format: [total_count, codes_list, extra_data, display_fields]
    total = data[0] if len(data) > 0 else 0
    codes = data[1] if len(data) > 1 else []
    fields = data[3] if len(data) > 3 else []

    results = []
    for i, code in enumerate(codes):
        row = fields[i] if i < len(fields) else []
        results.append({
            "loinc_code": row[0] if len(row) > 0 else code,
            "long_name": row[1] if len(row) > 1 else "",
            "component": row[2] if len(row) > 2 else "",
            "system": row[3] if len(row) > 3 else "",
            "method": row[4] if len(row) > 4 else "",
            "property": row[5] if len(row) > 5 else "",
            "time_aspect": row[6] if len(row) > 6 else "",
            "scale": row[7] if len(row) > 7 else "",
            "class": row[8] if len(row) > 8 else "",
        })

    return json.dumps({
        "query": query,
        "total_found": total,
        "returned": len(results),
        "results": results,
        "note": "For PCORnet LAB_RESULT_CM queries, use the loinc_code value in "
                "WHERE LAB_LOINC = '<code>'. Consider including multiple LOINCs "
                "for the same analyte (e.g., serum vs plasma creatinine).",
    }, indent=2)


@mcp.tool()
async def get_loinc_details(
    loinc_code: str,
) -> str:
    """Get detailed information about a specific LOINC code.

    Args:
        loinc_code: The LOINC code to look up (e.g., "2160-0", "48642-3").
    """
    # Search for the exact code
    data = await _api_get(
        f"{CLINICAL_TABLES_BASE}/loinc_items/v3/search",
        {
            "terms": loinc_code,
            "maxList": 5,
            "df": "LOINC_NUM,LONG_COMMON_NAME,SHORTNAME,COMPONENT,SYSTEM,"
                  "METHOD_TYP,PROPERTY,TIME_ASPCT,SCALE_TYP,CLASS,"
                  "STATUS,EXAMPLE_UCUM_UNITS,RELATEDNAMES2",
        },
    )

    fields = data[3] if len(data) > 3 else []

    # Find exact match
    for row in fields:
        if len(row) > 0 and row[0] == loinc_code:
            return json.dumps({
                "loinc_code": row[0],
                "long_name": row[1] if len(row) > 1 else "",
                "short_name": row[2] if len(row) > 2 else "",
                "component": row[3] if len(row) > 3 else "",
                "system": row[4] if len(row) > 4 else "",
                "method": row[5] if len(row) > 5 else "",
                "property": row[6] if len(row) > 6 else "",
                "time_aspect": row[7] if len(row) > 7 else "",
                "scale": row[8] if len(row) > 8 else "",
                "class": row[9] if len(row) > 9 else "",
                "status": row[10] if len(row) > 10 else "",
                "example_units": row[11] if len(row) > 11 else "",
                "related_names": row[12] if len(row) > 12 else "",
                "valid": True,
            }, indent=2)

    return json.dumps({
        "loinc_code": loinc_code,
        "valid": False,
        "error": f"LOINC code '{loinc_code}' not found.",
        "suggestion": "Search for the lab test name using search_loinc() to find the correct code.",
    })


@mcp.tool()
async def find_related_loincs(
    loinc_code: str,
) -> str:
    """Find related LOINC codes for the same analyte/test.

    Given a LOINC code, finds other LOINCs that measure the same thing but
    with different methods, specimens, or properties. Essential for ensuring
    complete lab capture — a CDW may store creatinine under multiple LOINCs
    depending on the method and specimen.

    Args:
        loinc_code: A starting LOINC code (e.g., "2160-0" for serum creatinine).
    """
    # First get the component of this LOINC
    detail_data = await _api_get(
        f"{CLINICAL_TABLES_BASE}/loinc_items/v3/search",
        {
            "terms": loinc_code,
            "maxList": 1,
            "df": "LOINC_NUM,LONG_COMMON_NAME,COMPONENT",
        },
    )

    fields = detail_data[3] if len(detail_data) > 3 else []
    if not fields:
        return json.dumps({"error": f"LOINC '{loinc_code}' not found."})

    component = fields[0][2] if len(fields[0]) > 2 else ""
    if not component:
        return json.dumps({"error": "Could not determine component for this LOINC."})

    # Search for all LOINCs with the same component
    related_data = await _api_get(
        f"{CLINICAL_TABLES_BASE}/loinc_items/v3/search",
        {
            "terms": component,
            "maxList": 50,
            "df": "LOINC_NUM,LONG_COMMON_NAME,COMPONENT,SYSTEM,METHOD_TYP,PROPERTY,SCALE_TYP",
        },
    )

    related_fields = related_data[3] if len(related_data) > 3 else []
    results = []
    for row in related_fields:
        if len(row) > 2 and component.lower() in row[2].lower():
            results.append({
                "loinc_code": row[0],
                "long_name": row[1] if len(row) > 1 else "",
                "component": row[2] if len(row) > 2 else "",
                "system": row[3] if len(row) > 3 else "",
                "method": row[4] if len(row) > 4 else "",
                "property": row[5] if len(row) > 5 else "",
                "scale": row[6] if len(row) > 6 else "",
                "is_source": row[0] == loinc_code,
            })

    return json.dumps({
        "source_loinc": loinc_code,
        "component": component,
        "related_count": len(results),
        "related": results,
        "note": "Consider including all LOINCs for the same component in your "
                "LAB_RESULT_CM query, especially those with system='Ser/Plas' or "
                "'Bld' for common serum/blood tests. Different EHR configurations "
                "may use different LOINCs for the same test.",
    }, indent=2)


# ===========================================================================
# ICD-10-CM Tools (using NLM Clinical Tables API)
# ===========================================================================

@mcp.tool()
async def search_icd10(
    query: str,
    max_results: int = 25,
) -> str:
    """Search for ICD-10-CM diagnosis codes by keyword or code prefix.

    Use this to find all relevant ICD-10-CM codes for a condition when
    building DIAGNOSIS queries. Catches subcodes that manual lookup might miss.

    Args:
        query: Search term — can be a condition name (e.g., "atrial fibrillation",
               "deep vein thrombosis", "multiple myeloma") or a code prefix
               (e.g., "I48", "C90.0").
        max_results: Maximum results to return (default 25, max 100).
    """
    max_results = min(max_results, 100)

    data = await _api_get(
        f"{CLINICAL_TABLES_BASE}/icd10cm/v3/search",
        {
            "sf": "code,name",
            "terms": query,
            "maxList": max_results,
        },
    )

    total = data[0] if len(data) > 0 else 0
    codes = data[1] if len(data) > 1 else []
    display = data[3] if len(data) > 3 else []

    results = []
    for i, code in enumerate(codes):
        row = display[i] if i < len(display) else []
        results.append({
            "code": row[0] if len(row) > 0 else code,
            "description": row[1] if len(row) > 1 else "",
        })

    return json.dumps({
        "query": query,
        "total_found": total,
        "returned": len(results),
        "results": results,
        "note": "For PCORnet DIAGNOSIS queries: WHERE DX LIKE '<code>%' AND DX_TYPE = '10'. "
                "Check whether you need parent codes, specific subcodes, or both. "
                "Parent codes (e.g., I48) may not be used in actual billing — "
                "specific subcodes (e.g., I48.0, I48.1, I48.91) are more reliable.",
    }, indent=2)


@mcp.tool()
async def get_icd10_hierarchy(
    code_prefix: str,
) -> str:
    """Get all ICD-10-CM codes under a parent code.

    Use this to ensure you're capturing all subcodes when using ICD-10 in
    SQL LIKE patterns. For example, 'I82.4' has subcodes I82.40x, I82.41x,
    I82.42x, I82.43x, I82.44x, I82.49x — each with laterality variants.

    Args:
        code_prefix: The parent code prefix (e.g., "I82.4", "C90.0", "I48").
    """
    # Search for all codes starting with this prefix
    data = await _api_get(
        f"{CLINICAL_TABLES_BASE}/icd10cm/v3/search",
        {
            "sf": "code,name",
            "terms": code_prefix,
            "maxList": 200,
        },
    )

    display = data[3] if len(data) > 3 else []

    # Filter to only those that actually start with the prefix
    results = []
    for row in display:
        if len(row) >= 2 and row[0].startswith(code_prefix):
            results.append({"code": row[0], "description": row[1]})

    # Sort by code
    results.sort(key=lambda x: x["code"])

    return json.dumps({
        "prefix": code_prefix,
        "total_subcodes": len(results),
        "codes": results,
        "note": f"These are all ICD-10-CM codes under '{code_prefix}'. "
                f"Use DX LIKE '{code_prefix}%' to capture all, or list specific "
                f"codes for precision. Verify against CDW_data_profile.md Section 13 "
                f"to confirm these codes appear in your data.",
    }, indent=2)


# ===========================================================================
# HCPCS Tools (bundled reference + API search)
# ===========================================================================

# Common HCPCS J-codes used in oncology and cardiology TTE protocols
HCPCS_REFERENCE = {
    # Oncology parenteral drugs
    "J9145": {"description": "Injection, daratumumab, 10 mg (IV)", "drug": "daratumumab", "route": "IV"},
    "J9144": {"description": "Injection, daratumumab and hyaluronidase-fihj, 10 mg (SC)", "drug": "daratumumab", "route": "SC"},
    "J9041": {"description": "Injection, bortezomib, 0.1 mg", "drug": "bortezomib", "route": "SC/IV"},
    "J9047": {"description": "Injection, carfilzomib, 1 mg", "drug": "carfilzomib", "route": "IV"},
    "J9245": {"description": "Injection, melphalan HCl, 50 mg", "drug": "melphalan", "route": "IV"},
    "J8610": {"description": "Methotrexate; oral, per 2.5 mg", "drug": "methotrexate", "route": "oral"},
    "J9035": {"description": "Injection, bevacizumab, 10 mg", "drug": "bevacizumab", "route": "IV"},
    "J9173": {"description": "Injection, durvalumab, 10 mg", "drug": "durvalumab", "route": "IV"},
    "J9271": {"description": "Injection, pembrolizumab, 1 mg", "drug": "pembrolizumab", "route": "IV"},
    "J9228": {"description": "Injection, ipilimumab, 1 mg", "drug": "ipilimumab", "route": "IV"},
    "J9299": {"description": "Injection, nivolumab, 1 mg", "drug": "nivolumab", "route": "IV"},
    "J9354": {"description": "Injection, ado-trastuzumab emtansine, 1 mg", "drug": "T-DM1", "route": "IV"},
    "J9355": {"description": "Injection, trastuzumab, 10 mg", "drug": "trastuzumab", "route": "IV"},
    "J9312": {"description": "Injection, rituximab, 10 mg", "drug": "rituximab", "route": "IV"},
    "J9311": {"description": "Injection, rituximab and hyaluronidase, 10 mg", "drug": "rituximab SC", "route": "SC"},
    "J9022": {"description": "Injection, atezolizumab, 10 mg", "drug": "atezolizumab", "route": "IV"},
    "J9023": {"description": "Injection, avelumab, 10 mg", "drug": "avelumab", "route": "IV"},
    "J9176": {"description": "Injection, elotuzumab, 1 mg", "drug": "elotuzumab", "route": "IV"},
    "J9227": {"description": "Injection, isatuximab-irfc, 10 mg", "drug": "isatuximab", "route": "IV"},
    # Supportive care
    "J0897": {"description": "Injection, denosumab, 1 mg", "drug": "denosumab", "route": "SC"},
    "J3489": {"description": "Injection, zoledronic acid, 1 mg", "drug": "zoledronic acid", "route": "IV"},
    "J0881": {"description": "Injection, darbepoetin alfa, 1 mcg", "drug": "darbepoetin", "route": "SC/IV"},
    "J0885": {"description": "Injection, epoetin alfa, 1000 units", "drug": "epoetin", "route": "SC/IV"},
    "J2505": {"description": "Injection, pegfilgrastim, 6 mg", "drug": "pegfilgrastim", "route": "SC"},
    "J1442": {"description": "Injection, filgrastim, 1 mcg", "drug": "filgrastim", "route": "SC/IV"},
    # Cardiology
    "J1170": {"description": "Injection, hydromorphone, up to 4 mg", "drug": "hydromorphone", "route": "injection"},
    "J1940": {"description": "Injection, furosemide, up to 20 mg", "drug": "furosemide", "route": "IV"},
}


@mcp.tool()
async def search_hcpcs(
    query: str,
    max_results: int = 25,
) -> str:
    """Search for HCPCS/CPT procedure codes by keyword or drug name.

    Use this to find the correct J-codes for parenteral drugs when building
    PROCEDURES queries. Critical for injectable drugs that may not appear
    in the PRESCRIBING table (e.g., daratumumab, bortezomib, carfilzomib).

    Args:
        query: Search term — drug name (e.g., "daratumumab", "bortezomib")
               or HCPCS code (e.g., "J9145").
        max_results: Maximum results to return (default 25).
    """
    # First search bundled reference
    query_lower = query.lower()
    bundled_results = []
    for code, info in HCPCS_REFERENCE.items():
        if (query_lower in code.lower()
            or query_lower in info["description"].lower()
            or query_lower in info["drug"].lower()):
            bundled_results.append({
                "code": code,
                "description": info["description"],
                "drug": info["drug"],
                "route": info["route"],
                "source": "bundled_reference",
            })

    # Also search NLM Clinical Tables API for HCPCS
    try:
        data = await _api_get(
            f"{CLINICAL_TABLES_BASE}/hcpcs/v3/search",
            {
                "terms": query,
                "maxList": max_results,
                "df": "HCPC,LONG_DESCRIPTION,SHORT_DESCRIPTION",
            },
        )
        api_fields = data[3] if len(data) > 3 else []
        api_results = []
        seen_codes = {r["code"] for r in bundled_results}
        for row in api_fields:
            code = row[0] if len(row) > 0 else ""
            if code and code not in seen_codes:
                api_results.append({
                    "code": code,
                    "description": row[1] if len(row) > 1 else row[2] if len(row) > 2 else "",
                    "source": "nlm_api",
                })
    except Exception:
        api_results = []

    all_results = bundled_results + api_results

    return json.dumps({
        "query": query,
        "count": len(all_results),
        "results": all_results[:max_results],
        "note": "For PCORnet PROCEDURES queries: WHERE PX = '<code>' AND PX_TYPE = 'CH'. "
                "J-codes are essential for parenteral drugs that may not appear in PRESCRIBING.",
    }, indent=2)


@mcp.tool()
async def lookup_hcpcs(
    code: str,
) -> str:
    """Look up a specific HCPCS/CPT code and return its details.

    Args:
        code: The HCPCS code to look up (e.g., "J9145", "J9041").
    """
    # Check bundled reference first
    if code in HCPCS_REFERENCE:
        info = HCPCS_REFERENCE[code]
        return json.dumps({
            "code": code,
            "valid": True,
            "description": info["description"],
            "drug": info["drug"],
            "route": info["route"],
            "source": "bundled_reference",
        }, indent=2)

    # Fall back to API
    try:
        data = await _api_get(
            f"{CLINICAL_TABLES_BASE}/hcpcs/v3/search",
            {
                "terms": code,
                "maxList": 5,
                "df": "HCPC,LONG_DESCRIPTION,SHORT_DESCRIPTION",
            },
        )
        fields = data[3] if len(data) > 3 else []
        for row in fields:
            if len(row) > 0 and row[0] == code:
                return json.dumps({
                    "code": code,
                    "valid": True,
                    "description": row[1] if len(row) > 1 else "",
                    "source": "nlm_api",
                }, indent=2)
    except Exception:
        pass

    return json.dumps({
        "code": code,
        "valid": False,
        "error": f"HCPCS code '{code}' not found.",
    })


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
