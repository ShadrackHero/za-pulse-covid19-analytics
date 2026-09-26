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
  core  dim_date, dim_province, fact_provincial_daily
  meta  source registry, load_log, manual_observation
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
| `core` | Analysis model: dimensions + `fact_provincial_daily`. |
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
