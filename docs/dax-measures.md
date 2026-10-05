# DAX measures

Write measures here as they are created. Prefer measures over calculated columns.

Home table in the model: `Measures` (Day 7A). Hide the dummy column.

PostgreSQL Import named the tables with the schema in front. Use these names in every formula:

| In the model | In DAX |
|---|---|
| `core FactProvincialDaily` | `'core FactProvincialDaily'` |
| `core DimDate` | `'core DimDate'` |
| `core DimProvince` | `'core DimProvince'` |

Rules that do not change:

- `DIVIDE`, not `/`
- Variables (`VAR`) on anything with more than one step
- Snapshot cumulatives use the last **report** date in context. Do not `SUM` a running total across a date range
- Daily cases come from warehouse `New*` columns. Do not `diff` a sliced cumulative window
- UNKNOWN has no population. Rates stay blank for that row
- Vaccination is doses until proven otherwise

Anchor checks below use **1 July 2021** unless a row says otherwise.

---

## Confirmed (New)

Folder: Confirmed. Format: Whole number `#,0`.

This is Frequency. Do not take `diff()` of a filtered window of `CumConfirmed` in Power Query or pandas. The first row of a slice becomes 0 even when that day had cases.

Use the warehouse column Day 5 already built:

```dax
Confirmed (New) :=
SUM ( 'core FactProvincialDaily'[NewConfirmed] )
```

Gauteng check, 1–5 April 2021:

| Date | Frequency | Cum GP |
|---|---:|---:|
| 2021-04-01 | 362 | 414623 |
| 2021-04-02 | 415 | 415038 |
| 2021-04-03 | 228 | 415266 |
| 2021-04-04 | 154 | 415420 |
| 2021-04-05 | 120 | 415540 |

1 April is 362, not 0. Official previous day (31 Mar 2021) was 414261.

Gauteng 1 July 2021: **12,806**. National that day: **21,583**.

Do not rebuild Frequency with DATEADD on CumConfirmed unless NewConfirmed is missing. DATEADD looks at the calendar day, not the previous published report, so a skipped NICD day goes blank.

---

## Recovered (New) / Deaths (New) / Vaccinated (New)

Folder: Confirmed (or Outcomes if you prefer the deaths/doses with the stock measures). Format: Whole number.

```dax
Recovered (New) :=
SUM ( 'core FactProvincialDaily'[NewRecovered] )
```

```dax
Deaths (New) :=
SUM ( 'core FactProvincialDaily'[NewDeaths] )
```

```dax
Vaccinated (New) :=
SUM ( 'core FactProvincialDaily'[NewVaccinated] )
```

Negative values are source revisions. They stay. `DqFlag` on the fact explains them.

---

## Confirmed (Cumulative)

Folder: Confirmed. Format: Whole number `#,0`.

Last published cumulative inside the current filter. Safe on a card, a matrix of provinces for one day, or a date range (it takes the end of the range).

```dax
Confirmed (Cumulative) :=
VAR AsOfDate =
    MAX ( 'core FactProvincialDaily'[ReportDate] )
RETURN
CALCULATE (
    SUM ( 'core FactProvincialDaily'[CumConfirmed] ),
    'core FactProvincialDaily'[ReportDate] = AsOfDate
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| All provinces | 1,995,556 |
| Gauteng | 662,300 |

If this card shows hundreds of millions, the measure is summing every daily running total. Fix this before building rates.

---

## Recovered (Cumulative)

Folder: Outcomes. Format: Whole number.

```dax
Recovered (Cumulative) :=
VAR AsOfDate =
    MAX ( 'core FactProvincialDaily'[ReportDate] )
RETURN
CALCULATE (
    SUM ( 'core FactProvincialDaily'[CumRecovered] ),
    'core FactProvincialDaily'[ReportDate] = AsOfDate
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| All provinces | 1,754,793 |
| Gauteng | 554,529 |

---

## Deaths (Cumulative)

Folder: Outcomes. Format: Whole number.

```dax
Deaths (Cumulative) :=
VAR AsOfDate =
    MAX ( 'core FactProvincialDaily'[ReportDate] )
RETURN
CALCULATE (
    SUM ( 'core FactProvincialDaily'[CumDeaths] ),
    'core FactProvincialDaily'[ReportDate] = AsOfDate
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| All provinces | 61,029 |
| Gauteng | 13,094 |

---

## Vaccinated (Cumulative)

Folder: Outcomes. Format: Whole number.

This is cumulative **doses**, not unique people.

```dax
Vaccinated (Cumulative) :=
VAR AsOfDate =
    MAX ( 'core FactProvincialDaily'[ReportDate] )
RETURN
CALCULATE (
    SUM ( 'core FactProvincialDaily'[CumVaccinated] ),
    'core FactProvincialDaily'[ReportDate] = AsOfDate
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| All provinces | 3,289,900 |
| Gauteng | 789,010 |

---

## Confirmed (7-day avg)

Folder: Confirmed. Format: Decimal number `#,0.0`.

Average of `Confirmed (New)` over the last 7 calendar days ending on the last visible date. Days with no NICD report stay blank and `AVERAGEX` skips them.

```dax
Confirmed (7-day avg) :=
VAR AnchorDate =
    MAX ( 'core DimDate'[DateKey] )
VAR LastSeven =
    DATESINPERIOD ( 'core DimDate'[DateKey], AnchorDate, -7, DAY )
RETURN
AVERAGEX (
    LastSeven,
    [Confirmed (New)]
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 10,613.0 |
| All provinces | 16,916.1 |

Gauteng daily confirmed 25 Jun–1 Jul 2021: 11782, 11304, 9861, 8443, 8927, 11168, 12806.

---

## Active Cases

Folder: Outcomes. Format: Whole number.

Estimate: confirmed still not recovered and not deceased, as of the last report date. Do not sum the warehouse `ActiveCases` column across a date range.

```dax
Active Cases :=
VAR ConfirmedStock = [Confirmed (Cumulative)]
VAR RecoveredStock = [Recovered (Cumulative)]
VAR DeathStock = [Deaths (Cumulative)]
RETURN
IF (
    OR ( ISBLANK ( ConfirmedStock ), OR ( ISBLANK ( RecoveredStock ), ISBLANK ( DeathStock ) ) ),
    BLANK (),
    ConfirmedStock - RecoveredStock - DeathStock
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 94,677 |
| All provinces | 179,734 |

Gauteng: 662300 − 554529 − 13094 = 94677. Source revisions can make this dip or go negative. That is a quality flag, not a reason to delete the row.

---

## CFR %

Folder: Rates. Format: Percentage, 2 decimals.

Case fatality ratio on the published cumulative counts. Descriptive. Not a risk of dying if infected today.

```dax
CFR % :=
DIVIDE (
    [Deaths (Cumulative)],
    [Confirmed (Cumulative)]
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 1.98% |
| All provinces | 3.06% |

---

## Recovery Rate %

Folder: Rates. Format: Percentage, 2 decimals.

```dax
Recovery Rate % :=
DIVIDE (
    [Recovered (Cumulative)],
    [Confirmed (Cumulative)]
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 83.73% |
| All provinces | 87.94% |

---

## Population

Folder: Rates. Format: Whole number.

Stats SA P0302 2021 mid-year estimates loaded on Day 4D. UNKNOWN is NULL, so it does not add.

```dax
Population :=
SUM ( 'core DimProvince'[Population] )
```

| Filter | Expect |
|---|---:|
| Gauteng | 15,810,388 |
| Nine official provinces | 60,142,979 |
| UNKNOWN only | (blank) |

---

## Cases per 100k

Folder: Rates. Format: Decimal number `#,0.0`.

Uses the snapshot confirmed count and the 2021 population. Do not put UNKNOWN on this visual.

```dax
Cases per 100k :=
DIVIDE (
    [Confirmed (Cumulative)],
    [Population]
) * 100000
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 4,189.0 |
| Nine official provinces | 3,318.0 |

---

## Dose Coverage %

Folder: Rates. Format: Percentage, 2 decimals.

Doses ÷ 2021 population. Not unique people. Can exceed 100% later in the series.

```dax
Dose Coverage % :=
DIVIDE (
    [Vaccinated (Cumulative)],
    [Population]
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 4.99% |
| Nine official provinces | 5.47% |

Caption on any report visual that uses this measure: “Cumulative doses divided by 2021 population. Not people fully vaccinated.”

---

## Share of National %

Folder: Change. Format: Percentage, 2 decimals.

Province’s snapshot confirmed as a share of the published national total. UNKNOWN stays in the denominator.

```dax
Share of National % :=
DIVIDE (
    [Confirmed (Cumulative)],
    CALCULATE (
        [Confirmed (Cumulative)],
        ALL ( 'core DimProvince' )
    )
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 33.19% |
| No province selected | 100.00% |

662300 ÷ 1995556 = 0.331887.

---

## WoW Change %

Folder: Change. Format: Percentage, 1 decimal.

This week versus the prior week of `Confirmed (New)`. Both windows are 7 calendar days.

```dax
WoW Change % :=
VAR AnchorDate =
    MAX ( 'core DimDate'[DateKey] )
VAR ThisWeek =
    CALCULATE (
        [Confirmed (New)],
        DATESINPERIOD ( 'core DimDate'[DateKey], AnchorDate, -7, DAY )
    )
VAR PriorWeek =
    CALCULATE (
        [Confirmed (New)],
        DATESINPERIOD ( 'core DimDate'[DateKey], AnchorDate - 7, -7, DAY )
    )
RETURN
DIVIDE ( ThisWeek - PriorWeek, PriorWeek )
```

| Filter on 1 July 2021 | This week | Prior week | WoW |
|---|---:|---:|---:|
| Gauteng | 74,291 | 58,136 | 27.8% |
| All provinces | 118,413 | 91,064 | 30.0% |

This week is 25 Jun–1 Jul 2021. Prior week is 18–24 Jun 2021.

---

## New Cases per 100k

Folder: Rates. Format: Decimal number `#,0.0`. Day 8.

On one day this is that day’s incidence. On a date range it is period incidence (sum of new cases in the window).

```dax
New Cases per 100k :=
DIVIDE (
    [Confirmed (New)],
    [Population]
) * 100000
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 81.0 |
| Nine official provinces | 35.9 |

12,806 ÷ 15,810,388 × 100,000 = 81.0.  
21,583 ÷ 60,142,979 × 100,000 = 35.9.

UNKNOWN stays blank.

---

## Confirmed (7-day avg) per 100k

Folder: Rates. Format: Decimal number `#,0.0`. Day 8.

```dax
Confirmed (7-day avg) per 100k :=
DIVIDE (
    [Confirmed (7-day avg)],
    [Population]
) * 100000
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 67.1 |
| Nine official provinces | 28.1 |

---

## Report Context

Folder: Change. Format: Text. Day 8 page title card.

`ISFILTERED` only sees a direct filter on `ProvinceName`. A slicer on `ProvinceCode`, a visual-level filter on other cards, or Edit interactions set to None all leave this card saying South Africa.

A Between date slicer is a range. Only print “as of” when the window is a single day. KPI cards still use the last report date inside that window.

```dax
Report Context :=
VAR ProvList =
    CALCULATETABLE (
        VALUES ( 'core DimProvince'[ProvinceName] ),
        'core DimProvince'[ProvinceName] <> "Not allocated"
    )
VAR ProvCount =
    COUNTROWS ( ProvList )
VAR Prov =
    SWITCH (
        TRUE (),
        ProvCount = 1,
            MINX ( ProvList, 'core DimProvince'[ProvinceName] ),
        ProvCount >= 9,
            "South Africa",
        CONCATENATEX (
            ProvList,
            'core DimProvince'[ProvinceName],
            ", ",
            'core DimProvince'[ProvinceName],
            ASC
        )
    )
VAR DateStart =
    MIN ( 'core DimDate'[DateKey] )
VAR DateEnd =
    MAX ( 'core DimDate'[DateKey] )
VAR DateText =
    IF (
        DateStart = DateEnd,
        "as of " & FORMAT ( DateStart, "dd mmm yyyy" ),
        FORMAT ( DateStart, "dd mmm yyyy" )
            & " – "
            & FORMAT ( DateEnd, "dd mmm yyyy" )
    )
RETURN
Prov & "  ·  " & DateText
```

| Filter | Expect |
|---|---|
| Date both ends 1 July 2021, no province | South Africa  ·  as of 01 Jul 2021 |
| Date both ends 1 July 2021, Gauteng | Gauteng  ·  as of 01 Jul 2021 |
| Date 26 Dec 2021 to 9 May 2022, no province | South Africa  ·  26 Dec 2021 – 09 May 2022 |
| Two provinces, same range | Eastern Cape, Gauteng  ·  26 Dec 2021 – 09 May 2022 |

Snapshot KPIs still use the last report date inside the window. The title only describes the window.

---

## Vaccinated (7-day avg)

Folder: Outcomes. Format: Decimal number `#,0.0`. Day 9.

```dax
Vaccinated (7-day avg) :=
VAR AnchorDate =
    MAX ( 'core DimDate'[DateKey] )
VAR LastSeven =
    DATESINPERIOD ( 'core DimDate'[DateKey], AnchorDate, -7, DAY )
RETURN
AVERAGEX (
    LastSeven,
    [Vaccinated (New)]
)
```

No golden number on 1 July 2021. Negative daily doses are revisions (`REV_VAX`). `AVERAGEX` includes them.

---

## Doses per 100k

Folder: Rates. Format: Decimal number `#,0.0`. Day 9.

```dax
Doses per 100k :=
DIVIDE (
    [Vaccinated (Cumulative)],
    [Population]
) * 100000
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 4,990.5 |
| Nine official provinces | 5,470.1 |

789,010 ÷ 15,810,388 × 100,000 = 4,990.5.  
3,289,900 ÷ 60,142,979 × 100,000 = 5,470.1.

This is Dose Coverage % × 100,000. UNKNOWN stays blank.

---

## Share of National Doses %

Folder: Change. Format: Percentage, 2 decimals. Day 9.

```dax
Share of National Doses % :=
DIVIDE (
    [Vaccinated (Cumulative)],
    CALCULATE (
        [Vaccinated (Cumulative)],
        ALL ( 'core DimProvince' )
    )
)
```

| Filter on 1 July 2021 | Expect |
|---|---:|
| Gauteng | 23.98% |
| No province selected | 100.00% |

789,010 ÷ 3,289,900 = 0.239828.

UNKNOWN stays in the denominator, same rule as Share of National %.

---

## Fact Rows

Folder: Quality. Format: Whole number `#,0`. Day 9.

```dax
Fact Rows :=
COUNTROWS ( 'core FactProvincialDaily' )
```

| Filter | Expect |
|---|---:|
| 1 July 2021, Gauteng | 1 |
| 1 July 2021, nine official provinces | 9 |

---

## Flagged Rows

Folder: Quality. Format: Whole number.

```dax
Flagged Rows :=
CALCULATE (
    COUNTROWS ( 'core FactProvincialDaily' ),
    NOT ISBLANK ( 'core FactProvincialDaily'[DqFlag] )
)
```

No series-wide golden number. Read it from the card.

---

## Flagged Share %

Folder: Quality. Format: Percentage, 1 decimal.

```dax
Flagged Share % :=
DIVIDE (
    [Flagged Rows],
    [Fact Rows]
)
```

---

## Flag Row Count

Folder: Quality. Format: Whole number. Day 9.

Needs the disconnected `DqFlag Catalogue` table from `docs/day-9-report.md` section 9A.

```dax
Flag Row Count :=
VAR Code =
    SELECTEDVALUE ( 'DqFlag Catalogue'[FlagCode] )
RETURN
IF (
    ISBLANK ( Code ),
    BLANK (),
    CALCULATE (
        COUNTROWS ( 'core FactProvincialDaily' ),
        CONTAINSSTRING ( 'core FactProvincialDaily'[DqFlag], Code )
    )
)
```

One fact row can match more than one catalogue code. Bar totals can exceed Flagged Rows.

---

## Peak New Confirmed

Folder: Change. Format: Whole number. Day 9.

```dax
Peak New Confirmed :=
MAXX (
    VALUES ( 'core DimDate'[DateKey] ),
    [Confirmed (New)]
)
```

---

## Peak Date

Folder: Change. Format: Date. Day 9.

If two dates tie, this returns the earlier one.

```dax
Peak Date :=
VAR PeakVal = [Peak New Confirmed]
VAR PeakDays =
    FILTER (
        VALUES ( 'core DimDate'[DateKey] ),
        [Confirmed (New)] = PeakVal
    )
RETURN
MINX ( PeakDays, 'core DimDate'[DateKey] )
```

| Filter | Expect |
|---|---|
| 1 July 2021, Gauteng | Peak New Confirmed 12,806 · Peak Date 1 July 2021 |

Do not quote a full-series peak in the README until you have read it off this measure with the date slicer cleared.

---

## Confirmed (14-day avg)

Folder: Confirmed. Format: Decimal number `#,0.0`. Day 9 stretch.

```dax
Confirmed (14-day avg) :=
VAR AnchorDate =
    MAX ( 'core DimDate'[DateKey] )
VAR LastFourteen =
    DATESINPERIOD ( 'core DimDate'[DateKey], AnchorDate, -14, DAY )
RETURN
AVERAGEX (
    LastFourteen,
    [Confirmed (New)]
)
```

No golden number tonight.

---

## How to test in the report

Slicers: `DimDate[DateKey]` = 1 July 2021, `DimProvince[ProvinceName]` = Gauteng.

Cards: Confirmed (Cumulative), Confirmed (New), Confirmed (7-day avg), Active Cases, CFR %, Cases per 100k, Dose Coverage %, Share of National %, WoW Change %.

Line chart: `DimDate[DateKey]` on the axis, Confirmed (7-day avg) on the values. The line must change when the province slicer changes.

Full walkthrough: `docs/day-7-dax.md`.
