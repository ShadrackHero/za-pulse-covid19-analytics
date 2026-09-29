# ZA Pulse — project architecture

```
Sources
  A. dsfsi/covid19za official CSVs (HTTP)
  B. Local population CSV
  C. Manual lockdown / wave / analyst notes
        ↓
PostgreSQL
  raw   exact file copies
  stg   long, typed, deduplicated
  core  DimDate, DimProvince, FactProvincialDaily
  meta  Source, LoadLog, ManualObservation
        ↓
Python notebooks
  ingest, checks, transforms
        ↓
Power BI + DAX
  report pages
        ↓
GitHub
  code, docs, screenshots (not full data dumps)
```

## Schemas

| Schema | Role |
|---|---|
| `raw` | Untouched landing tables. One table per official file. |
| `stg` | Unpivoted province columns. Dates typed. Duplicates removed. |
| `core` | Analysis model: dimensions + `FactProvincialDaily`. |
| `meta` | Where data came from, when it loaded, notes typed by hand. |

## Tools

| Layer | Tool |
|---|---|
| Database | PostgreSQL |
| Admin | pgAdmin 4 (not MySQL Workbench) |
| Analysis | Jupyter notebooks in `/notebooks` |
| Report | Power BI Desktop + DAX |
| Version control | GitHub + GitHub Desktop |

## Rule

Every number on the dashboard must trace back to a row in `raw` or a documented manual insert in `meta`.

## Status after Day 7

Power BI Import model + measure pack v1. Snapshot cumulatives, New*, 7-day avg, Active, CFR, Recovery, per 100k, dose coverage as doses, share of national, WoW.

Day 8 complete 29 Sep 2026: Pulse and Provinces pages. Extra measures: New Cases per 100k, Confirmed (7-day avg) per 100k, Report Context (single day = as of; Between slicer = start – end). Wave slicer uses DimDate[WaveName]. DimEvent stays disconnected. Vaccination and quality pages are Day 9.

## Status after Day 5

Naming: schemas stay lowercase (`raw`, `stg`, `core`, `meta`). Tables and columns are PascalCase and quoted in PostgreSQL (`core."DimProvince"`, `"ProvinceCode"`).

`core."FactProvincialDaily"` exists. Grain is province × report date. No ZA roll-up row. National totals are a Power BI SUM.

Day 6 imports DimDate, DimProvince, DimEvent, FactProvincialDaily, and meta.Source. DimEvent and Source stay disconnected.
