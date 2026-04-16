"""Tests for tools/db_triage.py."""
import json
import subprocess
import sys
from pathlib import Path

import pytest
import yaml

from tools.db_triage import discover_dbs


def _write_yaml(path, data):
    path.write_text(yaml.dump(data))


@pytest.fixture
def databases_dir(tmp_path):
    d = tmp_path / "databases"
    d.mkdir()
    (d / "schemas").mkdir()
    (d / "profiles").mkdir()
    (d / "conventions").mkdir()
    _write_yaml(d / "alpha.yaml", {
        "id": "alpha", "name": "Alpha DB", "cdm": "pcornet",
        "engine": "duckdb", "online": True,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": "databases/schemas/alpha_schema.txt",
        "data_profile": "databases/profiles/alpha_profile.md",
        "conventions": "databases/conventions/alpha_conventions.md",
    })
    _write_yaml(d / "beta.yaml", {
        "id": "beta", "name": "Beta DB", "cdm": "omop",
        "engine": "mssql", "online": False,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": "databases/schemas/beta_schema.txt",
        "data_profile": "databases/profiles/beta_profile.md",
        "conventions": "databases/conventions/beta_conventions.md",
    })
    return d


def test_discover_dbs_returns_all_yamls(databases_dir):
    dbs = discover_dbs(str(databases_dir))
    ids = sorted(db["id"] for db in dbs)
    assert ids == ["alpha", "beta"]


def test_discover_dbs_includes_config_and_yaml_path(databases_dir):
    dbs = discover_dbs(str(databases_dir))
    alpha = next(db for db in dbs if db["id"] == "alpha")
    assert alpha["config"]["name"] == "Alpha DB"
    assert alpha["yaml_path"].endswith("alpha.yaml")


def test_discover_dbs_empty_dir(tmp_path):
    empty = tmp_path / "empty"
    empty.mkdir()
    assert discover_dbs(str(empty)) == []


def test_discover_dbs_skips_non_yaml(databases_dir):
    (databases_dir / "README.md").write_text("ignore me")
    dbs = discover_dbs(str(databases_dir))
    assert len(dbs) == 2


def test_discover_dbs_skips_yaml_without_id(databases_dir):
    _write_yaml(databases_dir / "broken.yaml", {"name": "No ID"})
    dbs = discover_dbs(str(databases_dir))
    ids = sorted(db["id"] for db in dbs)
    assert ids == ["alpha", "beta"]


from tools.db_triage import triage_one


def _make_config(online=True, **overrides):
    base = {
        "id": "example",
        "name": "Example",
        "cdm": "pcornet",
        "engine": "duckdb",
        "online": online,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": "databases/schemas/example_schema.txt",
        "data_profile": "databases/profiles/example_profile.md",
        "conventions": "databases/conventions/example_conventions.md",
    }
    base.update(overrides)
    return base


def test_triage_online_profile_present(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN"
    assert result["effective_mode"] == "online"
    assert result["warnings"] == []


def test_triage_online_profile_missing_is_auto_onboard(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "missing_profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN_AUTO_ONBOARD"
    assert result["effective_mode"] == "online"
    assert any("profile missing" in w.lower() for w in result["warnings"])


def test_triage_offline_profile_present(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=False),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN"
    assert result["effective_mode"] == "offline"


def test_triage_offline_profile_missing_is_skip(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=False),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "missing_profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "SKIP"
    assert "offline" in result["reason"].lower()


def test_triage_schema_missing_offline_is_skip(tmp_path):
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=False),
        schema_path=str(tmp_path / "missing_schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "SKIP"


def test_triage_schema_missing_online_is_auto_onboard(tmp_path):
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "missing_schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN_AUTO_ONBOARD"


def test_triage_conventions_missing_warns_but_runs(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "missing_conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN"
    assert any("conventions" in w.lower() for w in result["warnings"])


def test_triage_mode_override_online_forces_online(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=False),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="online",
    )
    assert result["effective_mode"] == "online"


def test_triage_mode_override_offline_forces_offline(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="offline",
    )
    assert result["effective_mode"] == "offline"


from tools.db_triage import triage_selection


def test_triage_selection_all_keyword(databases_dir, tmp_path):
    # Touch the files each config references so both DBs come out RUN.
    (tmp_path / "alpha_schema.txt").write_text("x")
    (tmp_path / "alpha_profile.md").write_text("x")
    (tmp_path / "alpha_conv.md").write_text("x")
    (tmp_path / "beta_schema.txt").write_text("x")
    (tmp_path / "beta_profile.md").write_text("x")
    (tmp_path / "beta_conv.md").write_text("x")
    # Override the relative paths in the config files.
    for p in (databases_dir / "alpha.yaml", databases_dir / "beta.yaml"):
        data = yaml.safe_load(p.read_text())
        prefix = data["id"]
        data["schema_dump"] = str(tmp_path / f"{prefix}_schema.txt")
        data["data_profile"] = str(tmp_path / f"{prefix}_profile.md")
        data["conventions"] = str(tmp_path / f"{prefix}_conv.md")
        p.write_text(yaml.dump(data))
    results = triage_selection(
        selection="all",
        databases_dir=str(databases_dir),
        project_root=str(tmp_path),
        mode_override="",
    )
    ids = sorted(r["id"] for r in results)
    assert ids == ["alpha", "beta"]


def test_triage_selection_csv_ids(databases_dir, tmp_path):
    results = triage_selection(
        selection="alpha",
        databases_dir=str(databases_dir),
        project_root=str(tmp_path),
        mode_override="",
    )
    assert [r["id"] for r in results] == ["alpha"]


def test_triage_selection_unknown_id_raises(databases_dir, tmp_path):
    with pytest.raises(ValueError) as exc_info:
        triage_selection(
            selection="alpha,unknown_db",
            databases_dir=str(databases_dir),
            project_root=str(tmp_path),
            mode_override="",
        )
    assert "unknown_db" in str(exc_info.value)
    assert "alpha" in str(exc_info.value)  # valid IDs listed


def test_triage_selection_relative_paths_resolved(databases_dir, tmp_path):
    # Config has "databases/schemas/alpha_schema.txt" (relative).
    # Create the file relative to tmp_path acting as project root.
    (tmp_path / "databases" / "schemas").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "schemas" / "alpha_schema.txt").write_text("x")
    (tmp_path / "databases" / "profiles").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "profiles" / "alpha_profile.md").write_text("x")
    (tmp_path / "databases" / "conventions").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "conventions" / "alpha_conventions.md").write_text("x")
    results = triage_selection(
        selection="alpha",
        databases_dir=str(databases_dir),
        project_root=str(tmp_path),
        mode_override="",
    )
    assert results[0]["disposition"] == "RUN"


def test_triage_selection_empty_raises(databases_dir, tmp_path):
    with pytest.raises(ValueError) as exc:
        triage_selection(
            selection="",
            databases_dir=str(databases_dir),
            project_root=str(tmp_path),
            mode_override="",
        )
    assert "empty" in str(exc.value).lower()


def test_triage_selection_whitespace_only_raises(databases_dir, tmp_path):
    with pytest.raises(ValueError):
        triage_selection(
            selection="   ,  ,",
            databases_dir=str(databases_dir),
            project_root=str(tmp_path),
            mode_override="",
        )


def test_triage_selection_duplicate_ids_raises(databases_dir, tmp_path):
    with pytest.raises(ValueError) as exc:
        triage_selection(
            selection="alpha,alpha",
            databases_dir=str(databases_dir),
            project_root=str(tmp_path),
            mode_override="",
        )
    assert "duplicate" in str(exc.value).lower()
    assert "alpha" in str(exc.value).lower()


def _project_root() -> str:
    return str(Path(__file__).resolve().parent.parent)


def test_cli_list_dbs_prints_table(databases_dir, tmp_path):
    env = {"PYTHONPATH": str(tmp_path.parent.parent.parent)}
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "list",
         "--databases-dir", str(databases_dir)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode == 0
    assert "alpha" in result.stdout
    assert "beta" in result.stdout
    assert "ID" in result.stdout  # header row
    assert "DEFAULT" in result.stdout


def test_cli_show_db_prints_config(databases_dir, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "show", "alpha",
         "--databases-dir", str(databases_dir)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode == 0
    assert "alpha" in result.stdout
    assert "Alpha DB" in result.stdout


def test_cli_show_db_unknown_id_exits_nonzero(databases_dir, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "show", "missing_id",
         "--databases-dir", str(databases_dir)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode != 0
    assert "missing_id" in (result.stdout + result.stderr)
    # Lock in the clean-error UX: reject tracebacks that happen to mention the id.
    assert "Valid ids:" in result.stderr
    assert "Traceback" not in (result.stdout + result.stderr)


def test_cli_triage_emits_json(databases_dir, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "triage",
         "--selection", "alpha",
         "--databases-dir", str(databases_dir),
         "--project-root", str(tmp_path)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode == 0
    parsed = json.loads(result.stdout)
    assert isinstance(parsed, list)
    assert parsed[0]["id"] == "alpha"
    assert parsed[0]["disposition"] in ("RUN", "RUN_AUTO_ONBOARD", "SKIP")


def test_cli_triage_empty_mode_is_equivalent_to_omitted(databases_dir, tmp_path):
    """Passing --mode '' must not be rejected by argparse; it should behave like omitting --mode."""
    # Touch the files so alpha comes out RUN.
    (tmp_path / "databases" / "schemas").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "schemas" / "alpha_schema.txt").write_text("x")
    (tmp_path / "databases" / "profiles").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "profiles" / "alpha_profile.md").write_text("x")
    (tmp_path / "databases" / "conventions").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "conventions" / "alpha_conventions.md").write_text("x")
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "triage",
         "--selection", "alpha",
         "--databases-dir", str(databases_dir),
         "--project-root", str(tmp_path),
         "--mode", ""],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    parsed = json.loads(result.stdout)
    assert parsed[0]["id"] == "alpha"


def test_cli_triage_unknown_id_exits_nonzero(databases_dir, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "triage",
         "--selection", "no_such_db",
         "--databases-dir", str(databases_dir),
         "--project-root", str(tmp_path)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode != 0
    assert "no_such_db" in (result.stdout + result.stderr)
    assert "Traceback" not in (result.stdout + result.stderr)
