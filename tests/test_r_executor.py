"""Tests for r_executor_server config loading and mode logic."""
import pytest
import yaml

from tools.r_executor_server import (
    build_sentinel,
    get_connection_code,
    is_online,
    load_config,
    truncate_output,
    wrap_r_code,
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def online_config(tmp_path):
    config = {
        "id": "test_db",
        "name": "Test DB",
        "cdm": "pcornet",
        "engine": "duckdb",
        "online": True,
        "connection": {"r_code": "con <- DBI::dbConnect(duckdb::duckdb())\n"},
        "schema_prefix": "main",
        "schema_dump": str(tmp_path / "schema.txt"),
        "data_profile": str(tmp_path / "profile.md"),
    }
    path = tmp_path / "test_db.yaml"
    path.write_text(yaml.dump(config))
    return str(path)


@pytest.fixture
def offline_config(tmp_path):
    config = {
        "id": "test_offline",
        "name": "Test Offline DB",
        "cdm": "pcornet",
        "engine": "mssql",
        "online": False,
        "connection": {"r_code": 'con <- DBI::dbConnect(odbc::odbc(), "DSN")\n'},
        "schema_prefix": "CDW.dbo",
        "schema_dump": str(tmp_path / "schema.txt"),
        "data_profile": str(tmp_path / "profile.md"),
    }
    path = tmp_path / "test_offline.yaml"
    path.write_text(yaml.dump(config))
    return str(path)


# ---------------------------------------------------------------------------
# load_config
# ---------------------------------------------------------------------------


def test_load_config(online_config):
    """Loads a valid YAML config and returns a dict with expected keys."""
    cfg = load_config(online_config)
    assert isinstance(cfg, dict)
    assert cfg["id"] == "test_db"
    assert cfg["online"] is True


def test_load_config_missing_file(tmp_path):
    """Raises FileNotFoundError for a non-existent config path."""
    missing = str(tmp_path / "does_not_exist.yaml")
    with pytest.raises(FileNotFoundError):
        load_config(missing)


# ---------------------------------------------------------------------------
# is_online
# ---------------------------------------------------------------------------


def test_is_online_mode(online_config, offline_config):
    """Returns True for an online config and False for an offline config."""
    online_cfg = load_config(online_config)
    offline_cfg = load_config(offline_config)
    assert is_online(online_cfg) is True
    assert is_online(offline_cfg) is False


def test_is_online_mode_override(online_config, offline_config):
    """Mode override takes precedence over config's online flag."""
    online_cfg = load_config(online_config)
    offline_cfg = load_config(offline_config)

    # Override online → offline
    assert is_online(online_cfg, mode_override="offline") is False
    # Override offline → online
    assert is_online(offline_cfg, mode_override="online") is True


# ---------------------------------------------------------------------------
# get_connection_code
# ---------------------------------------------------------------------------


def test_get_connection_code(online_config):
    """Extracts the R connection code containing DBI::dbConnect."""
    cfg = load_config(online_config)
    r_code = get_connection_code(cfg)
    assert "DBI::dbConnect" in r_code


# ---------------------------------------------------------------------------
# build_sentinel
# ---------------------------------------------------------------------------


def test_build_sentinel():
    """Sentinel starts with __SENTINEL_, ends with __, and is longer than 20 chars."""
    sentinel = build_sentinel()
    assert sentinel.startswith("__SENTINEL_")
    assert sentinel.endswith("__")
    assert len(sentinel) > 20


# ---------------------------------------------------------------------------
# wrap_r_code
# ---------------------------------------------------------------------------


def test_wrap_r_code():
    """Wrapped code contains the original code and a sentinel cat() call."""
    code = 'cat("hello world\\n")'
    wrapped, sentinel = wrap_r_code(code)

    assert code in wrapped
    assert sentinel in wrapped
    # The sentinel should be emitted via cat()
    assert f'cat("{sentinel}' in wrapped


# ---------------------------------------------------------------------------
# truncate_output
# ---------------------------------------------------------------------------


def test_truncate_output_short():
    """Short output (under max_lines) is returned unchanged."""
    output = "\n".join(f"line {i}" for i in range(10))
    result = truncate_output(output, max_lines=200)
    assert result == output


def test_truncate_output_long():
    """Output exceeding max_lines is truncated with a notice appended."""
    lines = [f"line {i}" for i in range(300)]
    output = "\n".join(lines)
    result = truncate_output(output, max_lines=200)

    result_lines = result.splitlines()
    # First 200 lines preserved
    assert result_lines[:200] == lines[:200]
    # Truncation notice present
    assert "truncated" in result_lines[-1].lower()
    # Should be 201 lines total (200 kept + 1 notice)
    assert len(result_lines) == 201
