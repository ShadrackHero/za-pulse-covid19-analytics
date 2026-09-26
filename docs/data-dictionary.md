# Data dictionary (Day 1 draft)

This is the planned model. Tables are created from Day 2 onward. Schemas exist after Day 1B.

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

## Planned core tables

### `core.dim_province`

| Column | Meaning |
|---|---|
| province_code | Primary key. See table above. |
| province_name | Full name |
| population | Used for per-100k measures. Source SRC-005. |
| region_group | Optional grouping (e.g. coastal / inland) |

### `core.dim_date`

| Column | Meaning |
|---|---|
| date_key | Date, one row per day |
| year, quarter, month, week | Calendar parts |
| weekday | Day name |
| is_weekend | Saturday or Sunday |
| wave_name | Filled later from events |

### `core.dim_event`

| Column | Meaning |
|---|---|
| event_id | Surrogate key |
| event_name | Lockdown level or wave label |
| start_date | Inclusive |
| end_date | Inclusive or null |
| event_type | `lockdown` or `wave` |

### `core.fact_provincial_daily`

Grain: one row per province per date.

| Column | Meaning |
|---|---|
| report_date | Reporting date |
| province_code | FK to dim_province |
| cum_confirmed | Cumulative confirmed cases |
| cum_recovered | Cumulative recoveries |
| cum_deaths | Cumulative deaths |
| cum_vaccinated | Cumulative vaccine doses (not necessarily unique people) |
| new_confirmed | Today minus yesterday |
| new_recovered | Today minus yesterday |
| new_deaths | Today minus yesterday |
| new_vaccinated | Today minus yesterday |
| active_cases | cum_confirmed − cum_recovered − cum_deaths |
| dq_flag | Set when a value goes backwards or turns negative |
| source_id | Which official file fed the row |

## Planned meta tables

### `meta.source`

Registry of SRC-001 … SRC-007.

### `meta.load_log`

One row per ingest run: when, which source, how many rows, success or fail.

### `meta.manual_observation`

Notes typed by hand (reporting lag, holidays, corrections).

## Important definitions

- **Cumulative** means “total so far”, not “new today”.
- **Active cases** is an estimate: confirmed minus recovered minus deaths. Revisions in the source can make it dip.
- **Vaccination coverage** must be labelled as doses per population until we prove the file is unique people.
