"""Tests for the multi-session registry in tools/r_executor_server.py."""
import yaml
import pytest

from tools.r_executor_server import SessionRegistry


def _write_yaml(path, data):
    path.write_text(yaml.dump(data))


@pytest.fixture
def two_configs(tmp_path):
    a = {
        "id": "alpha", "name": "Alpha", "cdm": "pcornet",
        "engine": "duckdb", "online": True,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": str(tmp_path / "a_schema.txt"),
        "data_profile": str(tmp_path / "a_profile.md"),
    }
    b = {
        "id": "beta", "name": "Beta", "cdm": "omop",
        "engine": "duckdb", "online": True,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": str(tmp_path / "b_schema.txt"),
        "data_profile": str(tmp_path / "b_profile.md"),
    }
    pa = tmp_path / "alpha.yaml"
    pb = tmp_path / "beta.yaml"
    _write_yaml(pa, a)
    _write_yaml(pb, b)
    return [str(pa), str(pb)]


def test_registry_loads_multiple_configs(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    assert sorted(reg.db_ids()) == ["alpha", "beta"]


def test_registry_get_config_by_id(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    cfg = reg.get_config("alpha")
    assert cfg["name"] == "Alpha"


def test_registry_get_config_unknown_id_raises(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    with pytest.raises(KeyError) as exc:
        reg.get_config("unknown")
    assert "unknown" in str(exc.value)


def test_registry_get_session_lazy_creates(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    # Before any call, no sessions exist.
    assert reg.has_session("alpha") is False
    s1 = reg.get_session("alpha")
    assert reg.has_session("alpha") is True
    # Calling again returns the same session, not a new one.
    s2 = reg.get_session("alpha")
    assert s1 is s2
    # Unrelated session still absent.
    assert reg.has_session("beta") is False


def test_registry_get_session_unknown_id_raises(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    with pytest.raises(KeyError):
        reg.get_session("unknown")


def test_registry_load_configs_rejects_duplicate_ids(tmp_path):
    cfg = {
        "id": "dup", "name": "Dup", "cdm": "x", "engine": "x",
        "online": True, "connection": {"r_code": ""},
    }
    pa = tmp_path / "one.yaml"
    pb = tmp_path / "two.yaml"
    _write_yaml(pa, cfg)
    _write_yaml(pb, cfg)
    reg = SessionRegistry()
    with pytest.raises(ValueError) as exc:
        reg.load_configs([str(pa), str(pb)])
    assert "dup" in str(exc.value).lower()
