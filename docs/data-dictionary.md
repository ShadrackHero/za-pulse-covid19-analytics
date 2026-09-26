# Data dictionary

Schemas exist after Day 1. Dimension and landing tables exist after Day 2. Fact tables are still planned (Day 5).

## Province codes

| Code | Province |
|---|---|
| EC | Eastern Cape |
| FS | Free State |
| GP | Gauteng |
| KZN | KwaZulu-Natal |
| LP | Limpopo |
| MP | Mpumalanga |
| NC | Northern Cape |
| NW | North West |
| WC | Western Cape |
| UNKNOWN | Not allocated to a province |
| ZA | National total (only if we store a roll-up row) |

## Naming

Schemas stay lowercase: `raw`, `stg`, `core`, `meta`.  
Tables and columns are PascalCase and quoted in SQL: `core."DimProvince"`, `"ProvinceCode"`.

## Core tables created on Day 2

### `core."DimProvince"` — 10 rows

| Column | Meaning |
|---|---|
| ProvinceCode | Primary key. See table above. |
| ProvinceName | Full name |
| Population | NULL until SRC-005 is loaded. Used for per-100k measures. |
| RegionGroup | `coastal`, `inland`, or `unallocated` |
| IsNational | Always FALSE in this seed. No ZA roll-up row. |

### `core."DimDate"` — 1036 rows (2020-03-01 to 2022-12-31)

| Column | Meaning |
|---|---|
| DateKey | Date, primary key, one row per day |
| YearNum, QuarterNum, MonthNum | Calendar parts |
| MonthName | Full month name |
| WeekIso | ISO week number |
| WeekdayNum | Monday = 1 … Sunday = 7 |
| WeekdayName | Full weekday name |
| IsWeekend | Saturday or Sunday |
| YearMonth | `YYYY-MM` |
| WaveName | Filled from DimEvent wave bands after seed |

### `core."DimEvent"`

| Column | Meaning |
|---|---|
| EventId | Surrogate key |
| EventName | Lockdown level, wave label, or milestone |
| EventType | `lockdown`, `wave`, or `milestone` |
| StartDate | Inclusive |
| EndDate | Inclusive (milestone is a single day) |
| DatePrecision | `official` (gov.za) or `approximate` (wave bands) |
| Notes | Short context |
| SourceNote | Where the dates came from |

## Raw tables created on Day 2 (empty)

`raw."Confirmed"`, `raw."Recoveries"`, `raw."Deaths"`, `raw."Vaccination"`.

Wide landing copies of the official files. Dates stay TEXT. Province codes are columns, not rows. Vaccination has no `UnknownCount` column because the source file has no UNKNOWN header.

## Meta tables created on Day 2

### `meta."Source"`

Registry of SRC-001 … SRC-007. Seeded on Day 2.

### `meta."LoadLog"`

One row per ingest run: when, which source, how many rows, success or fail. Empty until Day 3.

### `meta."ManualObservation"`

Notes typed by hand (reporting lag, holidays, corrections). Empty until a later day.

## Planned later

### `core."FactProvincialDaily"` (Day 5)

Grain: one row per province per date.

| Column | Meaning |
|---|---|
| ReportDate | Reporting date |
| ProvinceCode | FK to DimProvince |
| CumConfirmed | Cumulative confirmed cases |
| CumRecovered | Cumulative recoveries |
| CumDeaths | Cumulative deaths |
| CumVaccinated | Cumulative vaccine doses (not necessarily unique people) |
| NewConfirmed | Today minus yesterday |
| NewRecovered | Today minus yesterday |
| NewDeaths | Today minus yesterday |
| NewVaccinated | Today minus yesterday |
| ActiveCases | CumConfirmed − CumRecovered − CumDeaths |
| DqFlag | Set when a value goes backwards or turns negative |
| SourceId | Which official file fed the row |

## Important definitions

- **Cumulative** means “total so far”, not “new today”.
- **Active cases** is an estimate: confirmed minus recovered minus deaths. Revisions in the source can make it dip.
- **Vaccination coverage** must be labelled as doses per population until we prove the file is unique people.
