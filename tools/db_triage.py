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

    Args:
        selection: either the literal "all" or a comma-separated list of DB ids.
        databases_dir: directory containing the DB YAML files (passed to discover_dbs).
        project_root: base path for resolving relative file paths inside each YAML.
        mode_override: "online" / "offline" to override every config's own setting,
            or "" to use each config's own `online` field.

    Returns:
        A list of dicts, one per selected DB, each with these keys:
            id, name, cdm, engine, yaml_path         (from discovery / config)
            disposition, effective_mode, reason, warnings   (from triage_one)

        The disposition values are the RUN / RUN_AUTO_ONBOARD / SKIP constants
        defined at module scope. This shape is the public contract consumed by
        the tools.db_triage CLI and by run.sh; adding keys is backward-compatible,
        renaming or removing them is a breaking change.

    Raises:
        ValueError: if selection is empty, if any id in the selection is not
            present in databases_dir, or if the selection contains duplicates.
    """
    known = discover_dbs(databases_dir)
    known_by_id = {db["id"]: db for db in known}

    if selection.strip() == "all":
        selected = known
    else:
        ids = [s.strip() for s in selection.split(",") if s.strip()]
        if not ids:
            raise ValueError(
                "Empty selection. Pass 'all' or a comma-separated list of DB ids."
            )
        # Check for duplicates.
        seen: set[str] = set()
        dups: list[str] = []
        for i in ids:
            if i in seen:
                dups.append(i)
            else:
                seen.add(i)
        if dups:
            raise ValueError(
                f"Duplicate DB id(s) in selection: {', '.join(sorted(set(dups)))}"
            )
        # Check for unknown IDs.
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


import argparse
import json
import sys


def format_list_table(dbs: list[dict[str, Any]], project_root: str) -> str:
    """Return a plain-text table of all known DBs with file-presence flags."""
    headers = ["ID", "NAME", "CDM", "ENGINE", "DEFAULT", "SCHEMA", "PROFILE", "CONVENTIONS"]
    rows: list[list[str]] = [headers]
    for db in dbs:
        cfg = db["config"]
        default_mode = "online" if cfg.get("online") else "offline"
        schema_present = Path(_resolve(project_root, cfg.get("schema_dump", ""))).exists()
        profile_present = Path(_resolve(project_root, cfg.get("data_profile", ""))).exists()
        conv_present = Path(_resolve(project_root, cfg.get("conventions", ""))).exists()
        rows.append([
            db["id"],
            cfg.get("name", db["id"]),
            cfg.get("cdm", ""),
            cfg.get("engine", ""),
            default_mode,
            "yes" if schema_present else "no",
            "yes" if profile_present else "no",
            "yes" if conv_present else "no",
        ])

    # Pad each column to its max width.
    widths = [max(len(row[i]) for row in rows) for i in range(len(headers))]
    lines = []
    for row in rows:
        lines.append("  ".join(cell.ljust(widths[i]) for i, cell in enumerate(row)))
    return "\n".join(lines)


def format_show_db(db: dict[str, Any], project_root: str) -> str:
    """Return a multi-line description of one DB + its file presence."""
    cfg = db["config"]
    lines = [
        f"ID:        {db['id']}",
        f"Name:      {cfg.get('name', db['id'])}",
        f"CDM:       {cfg.get('cdm', '')}",
        f"Engine:    {cfg.get('engine', '')}",
        f"Default:   {'online' if cfg.get('online') else 'offline'}",
        f"YAML:      {db['yaml_path']}",
        "",
        "Files:",
    ]
    for label, key in [
        ("  schema_dump  ", "schema_dump"),
        ("  data_profile ", "data_profile"),
        ("  conventions  ", "conventions"),
    ]:
        path = cfg.get(key, "")
        resolved = _resolve(project_root, path)
        present = "present" if (resolved and Path(resolved).exists()) else "MISSING"
        lines.append(f"{label}{path:<60} [{present}]")
    return "\n".join(lines)


def _cli_list(args: argparse.Namespace) -> int:
    dbs = discover_dbs(args.databases_dir)
    print(format_list_table(dbs, args.project_root))
    return 0


def _cli_show(args: argparse.Namespace) -> int:
    dbs = discover_dbs(args.databases_dir)
    match = next((db for db in dbs if db["id"] == args.id), None)
    if match is None:
        valid = ", ".join(sorted(db["id"] for db in dbs)) or "(none)"
        print(f"No DB with id {args.id!r}. Valid ids: {valid}", file=sys.stderr)
        return 1
    print(format_show_db(match, args.project_root))
    return 0


def _cli_triage(args: argparse.Namespace) -> int:
    try:
        results = triage_selection(
            selection=args.selection,
            databases_dir=args.databases_dir,
            project_root=args.project_root,
            mode_override=args.mode or "",
        )
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    print(json.dumps(results, indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="tools.db_triage")
    subparsers = parser.add_subparsers(dest="cmd", required=True)

    # Create a parent parser with shared arguments for all subcommands.
    parent_parser = argparse.ArgumentParser(add_help=False)
    parent_parser.add_argument("--databases-dir", default="databases")
    parent_parser.add_argument("--project-root", default=".")

    subparsers.add_parser("list", parents=[parent_parser])

    show = subparsers.add_parser("show", parents=[parent_parser])
    show.add_argument("id")

    triage = subparsers.add_parser("triage", parents=[parent_parser])
    triage.add_argument("--selection", required=True)
    triage.add_argument("--mode", choices=["online", "offline"], default="")

    args = parser.parse_args(argv)
    if args.cmd == "list":
        return _cli_list(args)
    if args.cmd == "show":
        return _cli_show(args)
    if args.cmd == "triage":
        return _cli_triage(args)
    return 2


if __name__ == "__main__":
    sys.exit(main())
