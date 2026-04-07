"""
RxNorm MCP Tool Server
======================
MCP server that gives Claude Code agents access to the NLM RxNorm REST API
for drug code lookup, validation, and completeness checking.

This prevents under-ascertainment of medications in target trial emulation
protocols by ensuring agents use ALL relevant RXNORM_CUI codes (SCD, SBD,
GPCK, BPCK) rather than a manually curated subset.

Run with:
    python tools/rxnorm_server.py

Requires:
    pip install mcp httpx
"""

import json
from typing import Any

import httpx
from mcp.server.fastmcp import FastMCP

RXNORM_BASE = "https://rxnav.nlm.nih.gov/REST"

mcp = FastMCP("rxnorm")


# ---------------------------------------------------------------------------
# Helper: HTTP GET with error handling
# ---------------------------------------------------------------------------

async def _rxnorm_get(path: str, params: dict | None = None) -> dict:
    """Make a GET request to the RxNorm REST API and return parsed JSON."""
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(f"{RXNORM_BASE}/{path}", params=params or {})
        resp.raise_for_status()
        return resp.json()


# ---------------------------------------------------------------------------
# Tool: Search for a drug by name
# ---------------------------------------------------------------------------

@mcp.tool()
async def search_drug(
    name: str,
    search_type: str = "contains",
) -> str:
    """Search RxNorm for a drug by name and return matching concepts.

    Use this as the FIRST step when building a medication code list.
    Returns ingredient-level and clinical drug concepts matching the name.

    Args:
        name: Drug name to search for. Can be a generic name (e.g., "aspirin"),
              brand name (e.g., "Eliquis"), or ingredient (e.g., "apixaban").
        search_type: How to match — "exact", "contains", or "approximate"
                     (default "contains").
    """
    # Strategy 1: getDrugs (returns organized by ingredient with SCD/SBD)
    data = await _rxnorm_get("drugs.json", {"name": name})

    drug_groups = data.get("drugGroup", {})
    concept_groups = drug_groups.get("conceptGroup", [])

    results = []
    for group in concept_groups:
        tty = group.get("tty", "")
        concepts = group.get("conceptProperties", [])
        for c in concepts:
            results.append({
                "rxcui": c.get("rxcui", ""),
                "name": c.get("name", ""),
                "tty": tty,
                "synonym": c.get("synonym", ""),
            })

    # Strategy 2: If getDrugs returned nothing, try approximate match
    if not results and search_type == "approximate":
        data2 = await _rxnorm_get("approximateTerm.json", {"term": name, "maxEntries": 20})
        candidates = data2.get("approximateGroup", {}).get("candidate", [])
        for c in candidates:
            results.append({
                "rxcui": c.get("rxcui", ""),
                "name": c.get("name", ""),  # name not in approx, will fill below
                "tty": "",
                "score": c.get("score", ""),
            })

    if not results:
        return json.dumps({
            "query": name,
            "count": 0,
            "results": [],
            "note": "No results. Try a different spelling or use search_type='approximate'.",
        })

    return json.dumps({
        "query": name,
        "count": len(results),
        "results": results,
    }, indent=2)


# ---------------------------------------------------------------------------
# Tool: Get ALL related concepts for an RXCUI (the core completeness tool)
# ---------------------------------------------------------------------------

@mcp.tool()
async def get_all_related(
    rxcui: str,
) -> str:
    """Get ALL related RxNorm concepts for a given RXCUI, organized by term type.

    This is the KEY TOOL for building complete medication code lists.
    Given any RXCUI (ingredient, clinical drug, branded drug, etc.), it returns
    every related concept across all term types: IN (ingredient), PIN (precise
    ingredient), SCDC, SCDF, SCD, SBD, SBDC, SBDF, GPCK, BPCK, etc.

    For PCORnet CDW queries, you primarily need SCD and SBD codes.

    Args:
        rxcui: Any valid RXCUI. Typically start with the ingredient RXCUI
               obtained from search_drug(), then get all SCD/SBD forms.
    """
    data = await _rxnorm_get(f"rxcui/{rxcui}/allrelated.json")

    all_groups = data.get("allRelatedGroup", {})
    concept_groups = all_groups.get("conceptGroup", [])

    organized = {}
    for group in concept_groups:
        tty = group.get("tty", "unknown")
        concepts = group.get("conceptProperties", [])
        if concepts:
            organized[tty] = [
                {"rxcui": c.get("rxcui", ""), "name": c.get("name", "")}
                for c in concepts
            ]

    # Summarize for the agent
    scd_count = len(organized.get("SCD", []))
    sbd_count = len(organized.get("SBD", []))

    return json.dumps({
        "source_rxcui": rxcui,
        "summary": f"Found {scd_count} SCD (generic) and {sbd_count} SBD (branded) concepts",
        "concepts_by_tty": organized,
        "note": "For PCORnet PRESCRIBING queries, use SCD + SBD RXCUIs. "
                "For MED_ADMIN, also consider SCD + SBD. "
                "GPCK/BPCK are pack-level codes (e.g., starter packs) — include if relevant.",
    }, indent=2)


# ---------------------------------------------------------------------------
# Tool: Get RXCUIs for a specific drug + strength + form combination
# ---------------------------------------------------------------------------

@mcp.tool()
async def get_rxcuis_for_drug(
    ingredient: str,
    strength: str = "",
    dose_form: str = "",
) -> str:
    """Get all RXCUI codes for a specific drug, optionally filtered by strength and form.

    This is a convenience wrapper that combines search + filtering to return
    exactly the codes you need for a SQL IN() clause.

    Args:
        ingredient: Drug ingredient name (e.g., "aspirin", "apixaban", "warfarin").
        strength: Optional strength filter (e.g., "2.5 MG", "81 MG"). If empty,
                  returns ALL strengths.
        dose_form: Optional dose form filter (e.g., "Oral Tablet", "Injection",
                   "Oral Capsule"). If empty, returns ALL forms.

    Returns:
        All matching SCD and SBD RXCUIs with their full names, formatted for
        easy copy-paste into SQL IN() clauses.
    """
    # Step 1: Find the ingredient RXCUI
    data = await _rxnorm_get("rxcui.json", {"name": ingredient, "search": 2})
    id_group = data.get("idGroup", {})
    rxcuis = id_group.get("rxnormId", [])

    if not rxcuis:
        # Try getDrugs as fallback
        data2 = await _rxnorm_get("drugs.json", {"name": ingredient})
        groups = data2.get("drugGroup", {}).get("conceptGroup", [])
        for g in groups:
            if g.get("tty") == "IN":
                for c in g.get("conceptProperties", []):
                    rxcuis.append(c.get("rxcui"))
                break

    if not rxcuis:
        return json.dumps({"error": f"Could not find ingredient '{ingredient}' in RxNorm."})

    # Step 2: Get all related concepts
    all_scd = []
    all_sbd = []

    for rxcui in rxcuis[:3]:  # limit to avoid excessive API calls
        related = await _rxnorm_get(f"rxcui/{rxcui}/allrelated.json")
        groups = related.get("allRelatedGroup", {}).get("conceptGroup", [])

        for group in groups:
            tty = group.get("tty", "")
            concepts = group.get("conceptProperties", [])
            if not concepts:
                continue

            for c in concepts:
                entry = {"rxcui": c.get("rxcui", ""), "name": c.get("name", "")}
                name_upper = entry["name"].upper()

                # Apply strength filter
                if strength and strength.upper() not in name_upper:
                    continue

                # Apply dose form filter
                if dose_form and dose_form.upper() not in name_upper:
                    continue

                if tty == "SCD":
                    all_scd.append(entry)
                elif tty == "SBD":
                    all_sbd.append(entry)

    # Deduplicate
    seen = set()
    scd_dedup = []
    for e in all_scd:
        if e["rxcui"] not in seen:
            seen.add(e["rxcui"])
            scd_dedup.append(e)
    sbd_dedup = []
    for e in all_sbd:
        if e["rxcui"] not in seen:
            seen.add(e["rxcui"])
            sbd_dedup.append(e)

    # Format SQL-ready list
    all_codes = scd_dedup + sbd_dedup
    sql_list = ",".join(f"'{e['rxcui']}'" for e in all_codes)

    return json.dumps({
        "ingredient": ingredient,
        "strength_filter": strength or "(all strengths)",
        "dose_form_filter": dose_form or "(all forms)",
        "scd_count": len(scd_dedup),
        "sbd_count": len(sbd_dedup),
        "total": len(all_codes),
        "scd": scd_dedup,
        "sbd": sbd_dedup,
        "sql_in_clause": sql_list,
        "note": "Use the sql_in_clause value directly in your RXNORM_CUI IN (...) queries.",
    }, indent=2)


# ---------------------------------------------------------------------------
# Tool: Validate a list of RXCUIs (completeness check)
# ---------------------------------------------------------------------------

@mcp.tool()
async def validate_rxcui_list(
    rxcuis: list[str],
    expected_drug: str = "",
) -> str:
    """Validate a list of RXCUIs and check for completeness.

    Use this to audit existing protocol code lists. For each RXCUI, it checks
    whether the code is valid and what drug/strength/form it represents. Then
    it identifies any MISSING codes by looking up what the complete set should be.

    Args:
        rxcuis: List of RXCUI strings to validate (e.g., ["1364435", "1364441"]).
        expected_drug: The drug these codes should represent (e.g., "apixaban 2.5 MG").
                       If provided, the tool will find the complete set and flag gaps.
    """
    # Validate each provided RXCUI
    validated = []
    ingredient_rxcuis = set()

    async with httpx.AsyncClient(timeout=30) as client:
        for rxcui in rxcuis:
            resp = await client.get(
                f"{RXNORM_BASE}/rxcui/{rxcui}/properties.json"
            )
            if resp.status_code == 200:
                data = resp.json()
                props = data.get("properties", {})
                if props:
                    validated.append({
                        "rxcui": rxcui,
                        "valid": True,
                        "name": props.get("name", ""),
                        "tty": props.get("tty", ""),
                        "synonym": props.get("synonym", ""),
                    })
                else:
                    validated.append({"rxcui": rxcui, "valid": False, "name": "", "tty": ""})
            else:
                validated.append({"rxcui": rxcui, "valid": False, "name": "", "tty": ""})

    # Check completeness if expected_drug is provided
    missing = []
    complete_set = []
    if expected_drug:
        # Parse ingredient and optional strength from expected_drug
        parts = expected_drug.strip().split()
        ingredient_name = parts[0]  # first word
        strength = ""
        if len(parts) >= 3 and parts[-1].upper() in ("MG", "ML", "MCG"):
            strength = " ".join(parts[1:])

        # Get the complete set
        search_data = await _rxnorm_get("rxcui.json", {"name": ingredient_name, "search": 2})
        ing_rxcuis = search_data.get("idGroup", {}).get("rxnormId", [])

        if ing_rxcuis:
            related = await _rxnorm_get(f"rxcui/{ing_rxcuis[0]}/allrelated.json")
            groups = related.get("allRelatedGroup", {}).get("conceptGroup", [])

            provided_set = set(rxcuis)
            for group in groups:
                tty = group.get("tty", "")
                if tty not in ("SCD", "SBD"):
                    continue
                for c in group.get("conceptProperties", []):
                    name = c.get("name", "")
                    cid = c.get("rxcui", "")
                    # Apply strength filter if given
                    if strength and strength.upper() not in name.upper():
                        continue
                    complete_set.append({"rxcui": cid, "name": name, "tty": tty})
                    if cid not in provided_set:
                        missing.append({"rxcui": cid, "name": name, "tty": tty})

    result = {
        "provided_count": len(rxcuis),
        "valid_count": sum(1 for v in validated if v["valid"]),
        "invalid_count": sum(1 for v in validated if not v["valid"]),
        "validated": validated,
    }

    if expected_drug:
        result["completeness_check"] = {
            "expected_drug": expected_drug,
            "complete_set_count": len(complete_set),
            "provided_count": len(rxcuis),
            "missing_count": len(missing),
            "missing": missing,
            "complete_set": complete_set,
        }
        if missing:
            result["WARNING"] = (
                f"INCOMPLETE CODE LIST: {len(missing)} SCD/SBD codes are missing "
                f"for '{expected_drug}'. Patients prescribed these formulations "
                f"will be MISSED in your cohort query."
            )

    return json.dumps(result, indent=2)


# ---------------------------------------------------------------------------
# Tool: Get drug class members (e.g., all DOACs, all IMiDs)
# ---------------------------------------------------------------------------

@mcp.tool()
async def get_drug_class_members(
    class_name: str,
    source: str = "ATC",
) -> str:
    """Get all drugs in a therapeutic class.

    Useful for building comprehensive drug lists for entire classes
    (e.g., "all DOACs", "all immunomodulatory agents", "all proteasome inhibitors").

    Args:
        class_name: Drug class name to search for (e.g., "direct oral anticoagulant",
                    "immunomodulatory agent", "proteasome inhibitor").
        source: Classification source — "ATC", "MESH", "FDASPL", "VA", or "DAILYMED".
                Default "ATC" (WHO Anatomical Therapeutic Chemical classification).
    """
    # Search for the class
    data = await _rxnorm_get("rxclass/search.json", {"name": class_name, "type": "all"})

    results = data.get("rxclassSearchResult", {}).get("rxclassMinConceptList", {})
    classes = results.get("rxclassMinConcept", []) if results else []

    if not classes:
        return json.dumps({
            "query": class_name,
            "count": 0,
            "classes": [],
            "note": "No matching drug class found. Try broader terms or different source.",
        })

    # For each matching class, get the member drugs
    class_results = []
    for cls in classes[:3]:  # limit to top 3 matches
        class_id = cls.get("classId", "")
        class_name_found = cls.get("className", "")
        class_type = cls.get("classType", "")

        # Get class members
        members_data = await _rxnorm_get("rxclass/classMembers.json", {
            "classId": class_id,
            "relaSource": class_type,
        })

        member_list = members_data.get("drugMemberGroup", {}).get("drugMember", [])
        members = []
        for m in member_list:
            node = m.get("minConcept", {})
            members.append({
                "rxcui": node.get("rxcui", ""),
                "name": node.get("name", ""),
                "tty": node.get("tty", ""),
            })

        class_results.append({
            "class_id": class_id,
            "class_name": class_name_found,
            "class_type": class_type,
            "member_count": len(members),
            "members": members,
        })

    return json.dumps({
        "query": class_name,
        "matching_classes": len(class_results),
        "classes": class_results,
    }, indent=2)


# ---------------------------------------------------------------------------
# Tool: Quick RXCUI lookup (single code)
# ---------------------------------------------------------------------------

@mcp.tool()
async def lookup_rxcui(
    rxcui: str,
) -> str:
    """Look up a single RXCUI and return its full properties.

    Use this to quickly check what a specific RXCUI code represents.

    Args:
        rxcui: The RXCUI to look up (e.g., "1364435").
    """
    data = await _rxnorm_get(f"rxcui/{rxcui}/properties.json")
    props = data.get("properties", {})

    if not props:
        return json.dumps({"rxcui": rxcui, "valid": False, "error": "RXCUI not found"})

    return json.dumps({
        "rxcui": rxcui,
        "valid": True,
        "name": props.get("name", ""),
        "tty": props.get("tty", ""),
        "language": props.get("language", ""),
        "suppress": props.get("suppress", ""),
        "umlscui": props.get("umlscui", ""),
    }, indent=2)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
