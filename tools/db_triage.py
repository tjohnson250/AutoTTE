"""Database discovery and triage for AutoTTE multi-DB runs.

This module is the single source of truth for:
  - Which DB YAMLs exist under databases/
  - Whether a selected DB can be run (triage disposition)
  - CLI-facing output for --list-dbs and --show-db
  - The JSON triage output consumed by run.sh

It is a pure Python module with no MCP or R dependencies, so it can be
tested thoroughly without needing mcp or a live R installation.
"""
from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml


def discover_dbs(databases_dir: str) -> list[dict[str, Any]]:
    """Return a list of {id, yaml_path, config} for every valid YAML
    under *databases_dir*.

    Entries missing an `id` key are silently skipped. Nested subdirectories
    (schemas/, profiles/, conventions/) are not traversed.
    """
    root = Path(databases_dir)
    if not root.is_dir():
        return []
    results: list[dict[str, Any]] = []
    for yaml_path in sorted(root.glob("*.yaml")):
        try:
            with open(yaml_path, "r", encoding="utf-8") as fh:
                config = yaml.safe_load(fh) or {}
        except Exception:
            continue
        db_id = config.get("id")
        if not db_id:
            continue
        results.append({
            "id": db_id,
            "yaml_path": str(yaml_path),
            "config": config,
        })
    return results
