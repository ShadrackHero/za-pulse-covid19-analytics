# Day 10 — validation and screenshots

Date: 10 October 2026. Report is the Day 6–9 Import model plus the cover. No refresh for this pass. No new measure except the Report Context and Flag Row Count fixes already applied.

## Pages

Cover, Pulse, Provinces, Vaccination, Quality. Cover button navigates to Pulse.

## Filters for the golden check

Date both ends **1 July 2021**. Province cleared. Wave on Select all. Report Context must read `South Africa · as of 01 Jul 2021`. Pick Gauteng and it must read `Gauteng · as of 01 Jul 2021`.

## Pulse and Provinces — 1 July 2021

| Check | National | Gauteng |
|---|---:|---:|
| Confirmed (Cumulative) | 1,995,556 | 662,300 |
| Confirmed (New) | 21,583 | 12,806 |
| Confirmed (7-day avg) | 16,916.1 | 10,613.0 |
| Deaths (Cumulative) | 61,029 | 13,094 |
| Recovered (Cumulative) | 1,754,793 | 554,529 |
| Active Cases | 179,734 | 94,677 |
| Cases per 100k | 3,318.0 | 4,189.0 |
| New Cases per 100k | 35.9 | 81.0 |

Provinces bar is New Cases per 100k. Nine provinces. Gauteng 81.0 that day.

## Vaccination — 1 July 2021

Doses, not people.

| Check | National | Gauteng |
|---|---:|---:|
| Vaccinated (Cumulative) | 3,289,900 | 789,010 |
| Dose Coverage % | 5.47% | 4.99% |
| Doses per 100k | 5,470.1 | 4,990.5 |

## Quality — full series

Date 1 Mar 2020 – 31 Dec 2022. Province cleared. Wave Select all.

| Check | Expect |
|---|---:|
| Fact rows | 9,909 |
| Flagged rows | 61 |
| Flagged share | 0.6% |
| REV_CONF | 48 |
| REV_REC | 9 |
| REV_DEATH | 3 |
| REV_VAX | 0 |
| NEG_ACTIVE | 1 |
| REC_GT_CONF | 0 |
| DEATH_GT_CONF | 0 |

Source catalogue stays at SRC-001 to SRC-007. Flagged table filter is `DqFlag` is not blank. A `REV_CONF` row has a negative Confirmed (New).

Warehouse query that produced the 61:

```sql
SELECT
    COUNT(*) AS "FactRows",
    COUNT(*) FILTER (WHERE "DqFlag" IS NOT NULL) AS "FlaggedRows",
    COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REV_CONF%')      AS "RevConf",
    COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REV_REC%')       AS "RevRec",
    COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REV_DEATH%')     AS "RevDeath",
    COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REV_VAX%')       AS "RevVax",
    COUNT(*) FILTER (WHERE "DqFlag" LIKE '%NEG_ACTIVE%')    AS "NegActive",
    COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REC_GT_CONF%')   AS "RecGtConf",
    COUNT(*) FILTER (WHERE "DqFlag" LIKE '%DEATH_GT_CONF%') AS "DeathGtConf"
FROM core."FactProvincialDaily";
```

## Rules confirmed on the report

- Report Context dates ignore `WaveName` (`REMOVEFILTERS`). Province half uses `FILTER` over `VALUES`, not `CALCULATE` on `ProvinceName`.
- Wave slicer filters trend lines only. None on context cards and stock cards.
- Snapshot cards use the Cumulative measures, not a sum of the running total.
- Daily numbers come from warehouse `New*`. Do not diff a sliced cumulative.
- Vaccination captions say doses, not people. Stats SA is population only.
- Cover map is an unbound locator.
- `DqFlag Catalogue` has no relationship to the fact. `Flag Row Count` uses `CONTAINSSTRING`.

## Screenshots

Saved under `docs/screenshots/`. Panes hidden. No visual selected. Fit to page.

| File | Page | Filter |
|---|---|---|
| `cover.png` | Cover | none |
| `pulse.png` | Pulse | full series, province cleared |
| `pulse-2021-07-01.png` | Pulse | both ends 1 July 2021 |
| `provinces.png` | Provinces | full series, province cleared |
| `vaccination.png` | Vaccination | full series, province cleared |
| `vaccination-2021-07-01.png` | Vaccination | both ends 1 July 2021 |
| `quality.png` | Quality | full series, flagged table filtered |

Do not commit the `.pbix` unless the file stays small enough for GitHub.
