# Source registry

Official case data is compiled by Data Science for Social Impact (DSFSI), University of Pretoria, from NICD and the Department of Health. Licence for those CSVs: **CC BY-SA 4.0**. Always credit them.

Base URL:

`https://raw.githubusercontent.com/dsfsi/covid19za/master/data/`

| ID | Name | File | How it enters the database |
|---|---|---|---|
| SRC-001 | Provincial confirmed (cumulative) | `covid19za_provincial_cumulative_timeline_confirmed.csv` | Notebook download or CSV load into `raw` |
| SRC-002 | Provincial recoveries (cumulative) | `covid19za_provincial_cumulative_timeline_recoveries.csv` | Notebook download or CSV load into `raw` |
| SRC-003 | Provincial vaccination (cumulative) | `covid19za_provincial_cumulative_timeline_vaccination.csv` | Notebook download or CSV load into `raw` |
| SRC-004 | Provincial deaths (cumulative) | `covid19za_provincial_cumulative_timeline_deaths.csv` | Notebook download or CSV load into `raw` |
| SRC-005 | Province population | `data/manual/province_population.csv` | Local CSV you prepare |
| SRC-006 | Lockdown levels and waves | `core.dim_event` / manual CSV | Typed by hand or small CSV |
| SRC-007 | Analyst observations | `meta.manual_observation` | Typed INSERT in pgAdmin |

## Column shape of official provincial files

Typical headers:

`date, YYYYMMDD, EC, FS, GP, KZN, LP, MP, NC, NW, WC, [UNKNOWN], total, source`

- `date` is usually `DD-MM-YYYY`. Vaccination uses `YYYY-MM-DD`.
- Values are **cumulative**, not daily new cases.
- Province codes: EC, FS, GP, KZN, LP, MP, NC, NW, WC.

## What we will not treat as a source of truth

- Random web dashboards with no citation
- Edited Excel copies of the official files
- Totals typed into Power BI without landing in PostgreSQL first
