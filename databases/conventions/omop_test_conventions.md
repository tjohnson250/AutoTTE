# Conventions: OMOP CDM Test (GiBleed)

Synthetic OMOP CDM v5.3 dataset distributed by the OHDSI Eunomia project,
materialized locally via the `OMOPSynth` package. Used for AutoTTE's OMOP
profiler tests and quick local development.

## Source

- Dataset: `GiBleed` (gastrointestinal bleeding cohort)
- ~6 MB zipped, ~15-25 MB on disk after unzip
- Materialized by `setup_omop_test()` in `databases/data/setup_omop.R`

## Engine

- DuckDB (single `.duckdb` file at `databases/data/omop_test.duckdb`)
- All OMOP tables live in the `main` schema

## SQL dialect notes for agents

- Use `LIMIT N`, not `TOP N`.
- Use `strftime(date, '%Y-%m')`, not `to_char(date, 'YYYY-MM')`.
- Use `EXTRACT(year FROM x)` (DuckDB returns BIGINT; cast to INT if needed).
- Date subtraction `(end_date - start_date)` returns days as an integer
  directly — no `EXTRACT(day FROM …)` wrapper needed.

## Notable quirks

- All data is **synthetic**. Do not interpret prevalence figures as
  representative of any real population.
- Vocabulary tables (`concept`, `vocabulary`, `concept_relationship`) are
  included but minimal compared to a full OHDSI vocabulary download.
- Patient counts are small (~2,700) — many cohorts will have suppressed
  cells if you apply the standard `<11` rule. That is expected for a
  test fixture.

## Refreshing the data

```r
file.remove("databases/data/omop_test.duckdb")  # invalidate
source("databases/data/setup_omop.R")
setup_omop_test()
```
