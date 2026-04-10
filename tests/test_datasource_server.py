"""Tests for datasource_server pure logic functions."""

import pytest

from tools.datasource_server import (
    PUBLIC_DATASETS,
    filter_datasources,
    get_details_by_id,
    load_db_configs,
    read_file_content,
)


# ---------------------------------------------------------------------------
# Fixture: sample databases directory
# ---------------------------------------------------------------------------


@pytest.fixture()
def sample_db_dir(tmp_path):
    """Create a temporary databases directory with sample configs and files."""
    db_dir = tmp_path / "databases"
    db_dir.mkdir()

    # Subdirectories
    schemas_dir = db_dir / "schemas"
    profiles_dir = db_dir / "profiles"
    conventions_dir = db_dir / "conventions"
    schemas_dir.mkdir()
    profiles_dir.mkdir()
    conventions_dir.mkdir()

    # Sample content files
    (schemas_dir / "test_db_schema.txt").write_text("TABLE patients (id INT, age INT);")
    (profiles_dir / "test_db_profile.md").write_text("# Test DB Profile\n\n100 patients.")
    (conventions_dir / "test_db_conventions.md").write_text("# Conventions\n\nUse snake_case.")

    # YAML config 1: PCORnet / DuckDB / online
    (db_dir / "test_db.yaml").write_text(
        "id: test_db\n"
        "name: Test DB\n"
        "cdm: pcornet\n"
        "cdm_version: '6.0'\n"
        "engine: duckdb\n"
        "online: true\n"
        "schema_dump: databases/schemas/test_db_schema.txt\n"
        "data_profile: databases/profiles/test_db_profile.md\n"
        "conventions: databases/conventions/test_db_conventions.md\n"
    )

    # YAML config 2: OMOP / Postgres / offline
    (db_dir / "test_omop.yaml").write_text(
        "id: test_omop\n"
        "name: Test OMOP DB\n"
        "cdm: omop\n"
        "cdm_version: '5.4'\n"
        "engine: postgres\n"
        "online: false\n"
    )

    return db_dir


# ---------------------------------------------------------------------------
# load_db_configs
# ---------------------------------------------------------------------------


def test_load_db_configs(sample_db_dir):
    configs = load_db_configs(str(sample_db_dir))
    assert len(configs) == 2
    ids = {c["id"] for c in configs}
    assert ids == {"test_db", "test_omop"}


def test_load_db_configs_empty_dir(tmp_path):
    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    configs = load_db_configs(str(empty_dir))
    assert configs == []


def test_load_db_configs_missing_dir(tmp_path):
    missing = tmp_path / "nonexistent"
    configs = load_db_configs(str(missing))
    assert configs == []


# ---------------------------------------------------------------------------
# filter_datasources
# ---------------------------------------------------------------------------


def test_filter_datasources_by_cdm(sample_db_dir):
    sources = load_db_configs(str(sample_db_dir))
    result = filter_datasources(sources, cdm="pcornet")
    assert len(result) == 1
    assert result[0]["id"] == "test_db"


def test_filter_datasources_online_only(sample_db_dir):
    sources = load_db_configs(str(sample_db_dir))
    result = filter_datasources(sources, online_only=True)
    assert len(result) == 1
    assert result[0]["id"] == "test_db"


def test_filter_datasources_by_domain():
    result = filter_datasources(PUBLIC_DATASETS, domain="inpatient_icu")
    assert len(result) >= 2
    for src in result:
        assert src["domain"] == "inpatient_icu"


# ---------------------------------------------------------------------------
# get_details_by_id
# ---------------------------------------------------------------------------


def test_get_details_by_id(sample_db_dir):
    sources = load_db_configs(str(sample_db_dir))
    result = get_details_by_id("test_omop", sources)
    assert result is not None
    assert result["id"] == "test_omop"


def test_get_details_by_id_not_found(sample_db_dir):
    sources = load_db_configs(str(sample_db_dir))
    result = get_details_by_id("does_not_exist", sources)
    assert result is None


# ---------------------------------------------------------------------------
# read_file_content
# ---------------------------------------------------------------------------


def test_read_file_content(tmp_path):
    target = tmp_path / "sample.txt"
    target.write_text("hello world")
    content = read_file_content(str(target))
    assert content == "hello world"


def test_read_file_content_missing(tmp_path):
    missing = tmp_path / "missing.txt"
    content = read_file_content(str(missing))
    assert content.startswith("[File not found:")


# ---------------------------------------------------------------------------
# PUBLIC_DATASETS sanity check
# ---------------------------------------------------------------------------


def test_public_datasets_present():
    names = {ds["name"] for ds in PUBLIC_DATASETS}
    assert "MIMIC-IV" in names
    assert "NHANES" in names
    assert "MEPS" in names
    assert "Synthea" in names
