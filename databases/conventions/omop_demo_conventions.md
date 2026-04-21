# Conventions: OMOP CDM Demo (synthea-heart-10k)

Synthetic OMOP CDM v5.3 dataset distributed via CDMConnector's example
datasets, materialized locally via the `OMOPSynth` package. Used for
AutoTTE end-to-end demos in cardiovascular therapeutic areas.

## Source

- Dataset: `synthea-heart-10k` — 10,000 Synthea-generated patients with
  cardiac-disease prevalence weighting
- ~800 MB zipped, ~1.5 GB on disk after unzip
- Materialized by `setup_omop_demo()` in `databases/data/setup_omop.R`

## Engine

- DuckDB (single `.duckdb` file at `databases/data/omop_demo.duckdb`)
- All OMOP tables live in the `main` schema

## SQL dialect notes for agents

- Use `LIMIT N`, not `TOP N`.
- Use `strftime(date, '%Y-%m')`, not `to_char(date, 'YYYY-MM')`.
- Use `EXTRACT(year FROM x)` (DuckDB returns BIGINT; cast to INT if needed).
- Date subtraction `(end_date - start_date)` returns days as an integer
  directly — no `EXTRACT(day FROM …)` wrapper needed.

## Notable quirks

- All data is **synthetic** Synthea output. Calendar dates are real-time
  (not shifted), but patients/conditions/drugs are generated from
  population-level statistics, not real patients.
- Cardiac conditions are over-represented relative to a general
  population, which is the point of the dataset.
- Vocabulary tables are included with broader coverage than GiBleed but
  are still a subset of the full OHDSI vocabulary.

## Refreshing the data

```r
file.remove("databases/data/omop_demo.duckdb")  # invalidate
source("databases/data/setup_omop.R")
setup_omop_demo()  # ~800 MB download — may take several minutes
```
