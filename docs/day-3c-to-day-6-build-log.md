# Days 3C to 6 build log — unpivot to Power BI model

**Dates:** 26–28 September 2026  
**Repo:** https://github.com/ShadrackHero/za-pulse-covid19-analytics  
**Local folder:** `Desktop\za-pulse-covid19-analytics`  
**Database:** `za_pulse` on PostgreSQL 18  
**SQL tool:** pgAdmin 4 Query Tool (user `postgres`)  
**Inspection:** Google Colab notebooks (VS Code blocked; Colab cannot see localhost Postgres)  
**Report tool:** Power BI Desktop, Import mode, file `powerbi.pbix`  
**How we worked:** one section at a time. Paste, F5, check, then the next section.

This log starts at Day 3C. Days 3A and 3B already landed the official confirmed and recoveries files in `raw`. Days 1–2 created schemas, dimensions, and empty landing tables.

---

## What was already true before 3C

| Piece | State |
|---|---|
| Schemas | `raw`, `stg`, `core`, `meta` |
| Dimensions | `DimProvince` 10 rows, `DimDate` 1,036 days (2020-03-01 to 2022-12-31), `DimEvent` seeded |
| Raw confirmed | 864 rows, still wide |
| Raw recoveries | 805 rows, still wide |
| Golden cell | 1 July 2021 Gauteng confirmed **662300**, recoveries **554529** |
| Date text in raw | `DD-MM-YYYY`, sometimes with slashes (`01/07/2021`) |
| Deaths and vaccines | Not loaded yet |
| Fact table | Not created yet |
| Power BI | Not connected yet |

Naming rule stayed locked: schemas lowercase; tables and columns PascalCase and quoted (`core."DimProvince"`, `"ProvinceCode"`).

---

## Map of this stretch

| Section | Question it answers | Result in `za_pulse` / Power BI |
|---|---|---|
| 3C | How do wide province columns become one row per province per date? | `stg."ConfirmedLong"`, `stg."RecoveriesLong"` |
| 4A–4C | How do deaths and vaccination enter the same long shape? | `raw` + `stg` for Deaths and Vaccination |
| 4D | What population do we use for later per-100k measures? | Stats SA P0302 2021 on `DimProvince` |
| 4E | Which analyst notes are part of the model? | 5 rows in `meta."ManualObservation"` |
| 5A–5B | What is the one table Power BI should trust? | `core."FactProvincialDaily"` |
| 5C | Can we prove the fact against the official file? | Validation queries |
| 6 | Can Power BI read that fact without exploding cumulative totals? | Import model + 1 July 2021 matrix |

---

## Day 3C — Unpivot confirmed and recoveries

**Meaning.** `raw` is a photocopy of the official DSFSI file: one row per date, provinces as columns (`EC`, `FS`, `GP`, …). Analysis needs the opposite: one row per date per province. That long table lives in `stg`. Values stay **cumulative**. Daily new cases are not computed on Day 3C.

**SQL file:** `sql/07_stg_unpivot_confirmed_recoveries.sql`

**What we created**

- `stg."ConfirmedLong"`
- `stg."RecoveriesLong"`

Grain of both: (`ReportDate`, `ProvinceCode`).  
Province list: EC, FS, GP, KZN, LP, MP, NC, NW, WC, UNKNOWN.  
`Total` from the official file is a source roll-up. It is **not** unpivoted.  
Empty province cells stay NULL. They are not turned into 0.

**Date parse.** `TO_DATE("DateText", 'DD-MM-YYYY')`. That format also accepts slashes, so `01/07/2021` and `01-07-2021` both become 1 July 2021.

**Expected counts after 3C**

| Table | Expected rows | Why |
|---|---|---|
| `stg."ConfirmedLong"` | 8,640 | 864 dates × 10 province codes |
| `stg."RecoveriesLong"` | 8,050 | 805 dates × 10 province codes |

**Golden check**

```sql
SELECT "DateText", "ProvinceCode", "CumulativeValue"
FROM stg."ConfirmedLong"
WHERE "DateText" IN ('01-07-2021', '01/07/2021')
  AND "ProvinceCode" = 'GP';
-- 662300
```

Same date in recoveries: Gauteng **554529**.

Lineage: each unpivot writes a `success` row to `meta."LoadLog"` (SRC-001, SRC-002).

---

## Day 4 — Deaths, vaccination, population, notes

### 4A Inspection (Colab)

Notebook: `notebooks/04a_inspect_deaths_vaccination.ipynb`

Deaths dates are `DD-MM-YYYY` like confirmed.  
Vaccination dates are `YYYY-MM-DD`.  
Vaccination has **no UNKNOWN column**.  
Pandas can show vaccination numbers as `5.0` (float). Landing uses a text pass-through so COPY does not invent precision.

### 4B Raw load

**SQL file:** `sql/08_load_raw_deaths_vaccination.sql`

| Table | Rows landed |
|---|---|
| `raw."Deaths"` | 828 |
| `raw."Vaccination"` | 657 |

pgAdmin Import/Export is not used. On this PC it prefixes a OneDrive Documents path onto `C:\Temp`. Query Tool `COPY` is the working method.

### 4C Unpivot

**SQL file:** `sql/09_stg_unpivot_deaths_vaccination.sql`

| Table | Expected rows | Notes |
|---|---|---|
| `stg."DeathsLong"` | 8,280 | 828 dates × 10 codes including UNKNOWN |
| `stg."VaccinationLong"` | 5,913 | 657 dates × 9 official provinces. No UNKNOWN |

Vaccination values are **cumulative doses**, not proven unique people. Coverage measures later must say “doses”, not “people vaccinated”.

### 4D Population

**SQL file:** `sql/10_load_province_population.sql`  
**Manual file:** `data/manual/province_population.csv`  
**Source:** Stats SA mid-year estimates 2021 (P0302), SRC-005.

| Code | Population |
|---|---|
| EC | 6,676,590 |
| FS | 2,932,441 |
| GP | 15,810,388 |
| KZN | 11,513,575 |
| LP | 5,926,724 |
| MP | 4,743,584 |
| NC | 1,303,047 |
| NW | 4,122,854 |
| WC | 7,113,776 |
| UNKNOWN | NULL |

UNKNOWN is not a province. It gets no population and must not go into a per-100k measure. No `ZA` row is added. Power BI will sum the nine official provinces when a national total is needed.

### 4E Manual observations

**SQL file:** `sql/11_manual_observations.sql`  
Five notes in `meta."ManualObservation"` (SRC-007), including the 1 July 2021 golden-row note, holiday reporting lag, vaccination start on 17 Feb 2021, UNKNOWN as unallocated, and the rule that a one-day fall in a cumulative series is a revision.

---

## Day 5 — Star-schema fact

**SQL files:**

- `sql/12_fact_provincial_daily.sql` (5A create + 5B load)
- `sql/13_day5_validation.sql` (5C checks)

Download copies also sit next to the Day 1 / Day 2 Word logs:

- `ZA_Pulse_Day5_Fact_Build.sql`
- `ZA_Pulse_Day5_Validation.sql`

### 5A Empty table

`core."FactProvincialDaily"`

Grain: one row per province per date that appears in **any** of the four staging tables.

| Column group | Columns |
|---|---|
| Keys | `ReportDate`, `ProvinceCode` |
| Cumulative | `CumConfirmed`, `CumRecovered`, `CumDeaths`, `CumVaccinated` |
| Daily (Frequency) | `NewConfirmed`, `NewRecovered`, `NewDeaths`, `NewVaccinated` |
| Derived | `ActiveCases`, `DqFlag` |
| Presence | `HasConfirmed`, `HasRecovered`, `HasDeaths`, `HasVaccinated` |

No `ZA` row. No single `SourceId` on the fact — one row can come from four files. Lineage stays in `LoadLog`.

### 5B Load rule

1. Build a spine with `UNION` of the four long tables.
2. Keep only dates that exist in `DimDate` and codes that exist in `DimProvince`.
3. Left join each measure. Missing measures stay NULL. They are not filled with 0.
4. `New*` = this report minus the previous report for that province (`LAG` partitioned by `ProvinceCode`, ordered by `ReportDate`).
5. First report for a province uses the cumulative itself (there is no previous report).
6. `ActiveCases` = `CumConfirmed − CumRecovered − CumDeaths`. NULL if any of the three is missing.
7. `DqFlag` is a pipe-separated list: `REV_CONF`, `REV_REC`, `REV_DEATH`, `REV_VAX`, `NEG_ACTIVE`, `REC_GT_CONF`, `DEATH_GT_CONF`. NULL means clean. Revisions are flagged, not deleted.

`New*` is “new since the previous published report”, not “new on this calendar day”. If NICD skipped a day, the jump sits on the next published date.

### Frequency is not a Power Query `diff()`

A sliced cumulative window in pandas / R / Power Query does this:

| Date | Wrong Frequency | Real daily GP | Cum GP |
|---|---:|---:|---:|
| 2021-04-01 | 0 | **362** | 414,623 |
| 2021-04-02 | 415 | 415 | 415,038 |
| 2021-04-03 | 228 | 228 | 415,266 |
| 2021-04-04 | 154 | 154 | 415,420 |
| 2021-04-05 | 120 | 120 | 415,540 |

The 0 on 1 April is the first row of the slice, not the first day of the pandemic. Official GP on 31 March 2021 was 414,261. 414,623 − 414,261 = 362.

In Power BI, Frequency is already on the fact:

```dax
Confirmed (New) :=
SUM ( 'FactProvincialDaily'[NewConfirmed] )
```

Do not rebuild it with Power Query `diff` or with `DATEADD` on `CumConfirmed`. `DATEADD` looks at the calendar yesterday, not the previous NICD report.

### Official daily check for 1 July 2021 Gauteng

| Date | Cum GP | Daily GP |
|---|---:|---:|
| 30 Jun 2021 | 649,494 | — |
| 1 Jul 2021 | 662,300 | **12,806** |
| 2 Jul 2021 | 676,524 | — |

### 5C Validation intent

| Check | Pass look |
|---|---|
| Duplicate (`ReportDate`, `ProvinceCode`) | 0 rows |
| Golden row | GP 1 Jul 2021 confirmed 662,300 / recovered 554,529 |
| Sum of provinces vs `raw."Confirmed"."Total"` on 1 Jul 2021 | Gap 0 (later confirmed in Power BI as 1,995,556) |
| `ZA` rows | 0 |
| Flagged rows | Some revisions are expected in real NICD data |

pgAdmin later showed 1,005 Gauteng dates in the fact. That is larger than the 864 confirmed dates because the spine is a union of all four sources.

---

## Day 6 — Power BI model

**Guide:** `docs/day-6-power-bi-model.md`  
**First measure note:** `docs/dax-measures.md`  
**File on the PC:** `powerbi.pbix` (blank report, then loaded)

### Connection

| Field | Value |
|---|---|
| Get data | PostgreSQL database |
| Server | `localhost` |
| Database | `za_pulse` |
| Mode | **Import** (not DirectQuery) |
| User name | `postgres` (from pgAdmin tab `za_pulse/postgres@PostgreSQL 18`) |
| Password | same as pgAdmin |
| Encrypt | off for local |

Tables imported:

- `core.DimDate`
- `core.DimProvince`
- `core.DimEvent`
- `core.FactProvincialDaily`
- `meta.Source`

`raw` and `stg` stay in PostgreSQL. They are not part of the semantic model.

### Relationships

| From | To | Cardinality | Direction |
|---|---|---|---|
| FactProvincialDaily[ReportDate] | DimDate[DateKey] | Many to one | Single |
| FactProvincialDaily[ProvinceCode] | DimProvince[ProvinceCode] | Many to one | Single |

`DimEvent` and `Source` stay **disconnected**. A lockdown row covers many dates. Joining it to the fact would duplicate rows.

### Model hygiene completed

- `DimDate` marked as date table on `DateKey`
- `MonthName` sorted by `MonthNum`
- Four `Has*` columns hidden from report view
- `DqFlag` left visible for Day 9

### Test visual (passed 28 September 2026)

Slicer on `DimDate[DateKey]` = **1 July 2021** only.  
Matrix: `ProvinceName` × Sum of `CumConfirmed`.

| Province | CumConfirmed |
|---|---|
| Eastern Cape | 207,610 |
| Free State | 115,215 |
| Gauteng | **662,300** |
| KwaZulu-Natal | 355,847 |
| Limpopo | 77,457 |
| Mpumalanga | 95,752 |
| North West | 97,154 |
| Northern Cape | 59,330 |
| Not allocated | 0 |
| Western Cape | 324,891 |
| **Total** | **1,995,556** |

That total matches the official `total` column on 1 July 2021. The model does not double-count.

**Trap recorded on the first bar chart.** A visual titled “Daily Confirmed Cases” was still bound to `CumConfirmed`, so Gauteng showed 0.66M. Daily on that day is `NewConfirmed` = **12,806**. Cumulative on a single-day slicer is a snapshot. Daily is the Frequency column.

Do not drop `CumConfirmed` on a Year matrix with no date filter. Power BI will SUM every daily running total and the number explodes.

---

## Decisions locked in this stretch

1. National totals are a Power BI SUM. There is no `ZA` fact row and no `ZA` province row.
2. UNKNOWN stays in the fact as unallocated cases. No population. No rates.
3. Vaccination is doses until proven otherwise.
4. Daily cases are computed once, in PostgreSQL, with `LAG`. Power BI sums `NewConfirmed`. It does not re-diff a sliced cumulative window.
5. Negative daily values are revisions. They are flagged in `DqFlag`. They are not deleted.
6. `DimEvent` is a disconnected reference table.
7. Import mode is enough. This volume does not need DirectQuery.

---

## Repo files added or updated in this stretch

| File | Role |
|---|---|
| `sql/07_stg_unpivot_confirmed_recoveries.sql` | Day 3C |
| `sql/08_load_raw_deaths_vaccination.sql` | Day 4B |
| `sql/09_stg_unpivot_deaths_vaccination.sql` | Day 4C |
| `sql/10_load_province_population.sql` | Day 4D |
| `sql/11_manual_observations.sql` | Day 4E |
| `sql/12_fact_provincial_daily.sql` | Day 5A–5B |
| `sql/13_day5_validation.sql` | Day 5C |
| `notebooks/04a_inspect_deaths_vaccination.ipynb` | Day 4A |
| `data/manual/province_population.csv` | SRC-005 |
| `docs/day-6-power-bi-model.md` | Day 6 guide |
| `docs/dax-measures.md` | First measure |
| `docs/architecture.md` | Status after Day 5 |
| `docs/data-dictionary.md` | Fact columns |

Suggested commits if they are not on `origin` yet:

- `Day 3: first ingest confirmed and recoveries`
- `Day 4: multi-source ingest complete`
- `Day 5: fact_provincial_daily and data-quality flags`
- `Day 6: Power BI model relationships`

Day 6 also wants a Model-view screenshot at `docs/screenshots/day-6-model-view.png`. Do not commit a huge `.pbix` if it embeds the whole imported fact unless you choose to.

---

## What Day 7 still owes

DAX library in `docs/dax-measures.md`: 7-day average, active cases, CFR, recovery rate, cases per 100k, dose coverage labelled as doses, share of national, week-on-week. Measures, not calculated columns. `DIVIDE`, not `/`.
