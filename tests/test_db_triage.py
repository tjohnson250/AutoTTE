"""Tests for tools/db_triage.py."""
import yaml
import pytest

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
