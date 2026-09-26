# Day 2 build log — structure before data

**Date:** 26 September 2026  
**Repo:** https://github.com/ShadrackHero/za-pulse-covid19-analytics  
**Local folder:** `Desktop\za-pulse-covid19-analytics`  
**Tools used:** PostgreSQL, pgAdmin 4, GitHub Desktop  
**Not used today:** Jupyter plots, Power BI, CSV loads

---

## Purpose of Day 2

Day 1 made empty rooms (`raw`, `stg`, `core`, `meta`). Day 2 puts labelled shelves in those rooms. No COVID numbers are loaded yet.

| Part | Question it answers | Output |
|---|---|---|
| 2A Raw tables | What does an official file look like before we clean it? | `raw.confirmed`, `raw.recoveries`, `raw.deaths`, `raw.vaccination` |
| 2B Dimensions | What is a province and what is a day? | `core.dim_province`, `core.dim_date`, `core.dim_event` |
| 2C Lineage | Where did a dataset come from, and when did we load it? | `meta.source`, `meta.load_log`, `meta.manual_observation` |
| 2D Seed | Can we look up GP or 2020-07-01 without a CSV? | 10 provinces, 1036 dates, 7 sources, lockdown + wave events |

---

## Why empty tables first

If you load a CSV before the shelves exist, cleaning happens in the landing zone and you cannot tell original values from fixed values. Raw stays a photocopy. Dimensions stay the dictionary Power BI will filter on.

---

## Files added to the repo

| File | Run order in pgAdmin |
|---|---|
| `sql/02_raw_tables.sql` | 1 |
| `sql/03_create_dims_and_meta.sql` | 2 |
| `sql/04_seed_dims_and_meta.sql` | 3 |
| `sql/05_day2_checks.sql` | 4 — read results, do not expect writes |

---

## How to run in pgAdmin

1. Open pgAdmin 4.
2. Connect to server → database **za_pulse**.
3. Query Tool.
4. Open `02_raw_tables.sql` from `Desktop\za-pulse-covid19-analytics\sql`.
5. Execute (F5). Repeat for 03, then 04, then 05.
6. If a script was already run, `IF NOT EXISTS` / `ON CONFLICT` keeps it safe.

Schemas `raw`, `stg`, `core`, `meta` must already exist from Day 1 (`sql/01_create_schemas.sql`).

---

## What each new object means

### Raw landing tables

Wide tables. One column per province, matching the official files.

| Official CSV header | Column in PostgreSQL |
|---|---|
| date | `date_text` (kept as text) |
| YYYYMMDD | `yyyymmdd` (kept as text) |
| EC … WC | `ec` … `wc` (BIGINT) |
| UNKNOWN | `unknown_count` (missing on vaccination) |
| total | `total` |
| source | `source_text` |

Values in these files are **cumulative**, not daily new cases. Date text is `DD-MM-YYYY` for cases / recoveries / deaths and `YYYY-MM-DD` for vaccination. We do not fix that in `raw`.

### `core.dim_province` — 10 rows

EC, FS, GP, KZN, LP, MP, NC, NW, WC, UNKNOWN.

- `population` is NULL until the local Stats SA file (SRC-005) is loaded.
- `region_group` is a simple coastal / inland split for later slicers.
- There is no `ZA` row. National totals live in the CSV `total` column and will be rebuilt in facts if needed.

### `core.dim_date` — 1036 rows

1 March 2020 through 31 December 2022. Built with `generate_series`, not typed by hand.

| Column | Meaning |
|---|---|
| date_key | The day. Primary key. |
| year_num, quarter_num, month_num | Calendar parts |
| month_name | January, February, … |
| week_iso | ISO week number |
| weekday_num | Monday = 1 … Sunday = 7 |
| is_weekend | Saturday or Sunday |
| year_month | `YYYY-MM` |
| wave_name | Copied from `dim_event` where the day falls inside a wave band |

### `core.dim_event`

Two kinds of period, plus one milestone:

- **lockdown** — official alert levels from gov.za. Inclusive start and end dates.
- **wave** — approximate national bands for dashboard shading. Labelled `date_precision = approximate` on purpose.
- **milestone** — national state of disaster lifted on 5 April 2022.

A wave and a lockdown can overlap. That is expected. They are not the same thing.

### Meta

| Table | Role today |
|---|---|
| `meta.source` | SRC-001 to SRC-007 seeded |
| `meta.load_log` | Empty. First row is written when a CSV lands (Day 3) |
| `meta.manual_observation` | Empty. Notes and late corrections come later |

---

## Checks that close Day 2

```sql
SELECT COUNT(*) FROM core.dim_province;          -- 10
SELECT COUNT(*) FROM core.dim_date;              -- 1036
SELECT COUNT(*) FROM meta.source;                -- 7
SELECT COUNT(*) FROM raw.confirmed;              -- 0
```

If province is 10 and raw is 0, Day 2 is complete.

---

## What we did not do on Day 2

- No official CSV downloaded or copied
- No staging unpivot
- No fact table
- No population numbers
- No Jupyter
- No Power BI

---

## Commit

Suggested message after the SQL and this log are in the working folder:

`Day 2: schemas and conformed dimensions`

Then push origin from GitHub Desktop.

---

## Interview version of Day 2

“Before I loaded a single COVID row I created landing tables that match the official headers, a 10-row province dimension, a generated date dimension for the full study window, a source register, and a lockdown / wave calendar. Raw stays a photocopy. Dimensions are the keys Power BI will filter on.”

---

## Next

Day 3 is the first ingest: confirmed + recoveries into `raw`, then an unpivot into `stg`. Still no Power BI.
