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
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
