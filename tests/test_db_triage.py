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
