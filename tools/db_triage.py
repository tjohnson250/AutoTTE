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


# Disposition constants — these appear in db_triage.json and are checked
# by run.sh and the coordinator prompt. Do not rename without updating
# both consumers.
RUN = "RUN"
RUN_AUTO_ONBOARD = "RUN_AUTO_ONBOARD"
SKIP = "SKIP"


def _effective_mode(config: dict, mode_override: str) -> str:
    if mode_override in ("online", "offline"):
        return mode_override
    return "online" if config.get("online") else "offline"


def triage_one(
    config: dict,
    schema_path: str,
    profile_path: str,
    conventions_path: str,
    mode_override: str,
) -> dict[str, Any]:
    """Triage one DB. Return {disposition, effective_mode, reason, warnings}.

    disposition is one of RUN, RUN_AUTO_ONBOARD, SKIP.
    reason is a human-readable string explaining a SKIP or auto-onboard.
    warnings is a list of non-fatal issues (e.g. missing conventions).
    """
    effective_mode = _effective_mode(config, mode_override)
    schema_present = Path(schema_path).exists() if schema_path else False
    profile_present = Path(profile_path).exists() if profile_path else False
    conventions_present = Path(conventions_path).exists() if conventions_path else False

    warnings: list[str] = []
    if not conventions_present:
        warnings.append("Conventions file missing; protocols may miss DB-specific rules.")

    missing_parts: list[str] = []
    if not schema_present:
        missing_parts.append("schema dump")
    if not profile_present:
        missing_parts.append("data profile")

    if not missing_parts:
        return {
            "disposition": RUN,
            "effective_mode": effective_mode,
            "reason": "",
            "warnings": warnings,
        }

    missing_str = " and ".join(missing_parts)
    if effective_mode == "online":
        warnings.append(f"{missing_str} missing; Phase 0 will generate via r_executor.")
        return {
            "disposition": RUN_AUTO_ONBOARD,
            "effective_mode": effective_mode,
            "reason": f"{missing_str} missing (will be auto-generated).",
            "warnings": warnings,
        }

    return {
        "disposition": SKIP,
        "effective_mode": effective_mode,
        "reason": (
            f"Offline with no {missing_str}. Run in online mode once or "
            "generate the files manually."
        ),
        "warnings": warnings,
    }


def _resolve(project_root: str, p: str) -> str:
    """Resolve *p* against *project_root* if it is relative."""
    if not p:
        return p
    path = Path(p)
    if path.is_absolute():
        return str(path)
    return str(Path(project_root) / path)


def triage_selection(
    selection: str,
    databases_dir: str,
    project_root: str,
    mode_override: str,
) -> list[dict[str, Any]]:
    """Resolve *selection* into a list of per-DB triage results.

    selection is either "all" or a comma-separated list of DB IDs.
    Raises ValueError if any requested ID is not present in *databases_dir*.
    """
    known = discover_dbs(databases_dir)
    known_by_id = {db["id"]: db for db in known}

    if selection.strip() == "all":
        selected = known
    else:
        ids = [s.strip() for s in selection.split(",") if s.strip()]
        unknown = [i for i in ids if i not in known_by_id]
        if unknown:
            valid = ", ".join(sorted(known_by_id)) or "(none)"
            raise ValueError(
                f"Unknown DB id(s): {', '.join(unknown)}. Valid ids: {valid}"
            )
        selected = [known_by_id[i] for i in ids]

    results: list[dict[str, Any]] = []
    for db in selected:
        cfg = db["config"]
        triage = triage_one(
            cfg,
            schema_path=_resolve(project_root, cfg.get("schema_dump", "")),
            profile_path=_resolve(project_root, cfg.get("data_profile", "")),
            conventions_path=_resolve(project_root, cfg.get("conventions", "")),
            mode_override=mode_override,
        )
        results.append({
            "id": db["id"],
            "name": cfg.get("name", db["id"]),
            "cdm": cfg.get("cdm", ""),
            "engine": cfg.get("engine", ""),
            "yaml_path": db["yaml_path"],
            **triage,
        })
    return results
