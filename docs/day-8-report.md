# Day 8 — Report pages 1 and 2

Goal: an executive story, not a dump of charts. Two pages only.

- Page 1 — National pulse
- Page 2 — Province comparison

No vaccination page. No quality page. Those are Day 9.

## Visual inventory (do not add extras)

**Pulse — 13 visuals**

| # | Name in Selection pane | Type | Field / measure |
|---|---|---|---|
| 1 | `title_pulse` | Text box | `ZA Pulse  ·  National COVID-19 pulse` |
| 2 | `card_context` | Card | Report Context |
| 3 | `slicer_date` | Slicer | DimDate[DateKey], Between |
| 4 | `slicer_province` | Slicer | DimProvince[ProvinceName], Dropdown |
| 5 | `slicer_wave` | Slicer | DimDate[WaveName], Dropdown |
| 6 | `kpi_confirmed` | Card | Confirmed (Cumulative) |
| 7 | `kpi_deaths` | Card | Deaths (Cumulative) |
| 8 | `kpi_recovered` | Card | Recovered (Cumulative) |
| 9 | `kpi_active` | Card | Active Cases |
| 10 | `kpi_pace` | Card | Confirmed (7-day avg) |
| 11 | `chart_trend` | Area or line | DateKey × Confirmed (7-day avg), legend WaveName |
| 12 | `bar_burden` | Clustered bar | ProvinceName × Cases per 100k |
| 13 | `footer_pulse` | Text box | Source credit |

**Provinces — 8 visuals**

| # | Name in Selection pane | Type | Field / measure |
|---|---|---|---|
| 1 | `title_provinces` | Text box | `ZA Pulse  ·  Province comparison` |
| 2 | `card_context_p2` | Card | Report Context |
| 3 | `slicer_date_p2` | Slicer | same DateKey, synced from Pulse |
| 4 | `slicer_province_p2` | Slicer | same ProvinceName, synced |
| 5 | `slicer_wave_p2` | Slicer | same WaveName, synced |
| 6 | `bar_incidence` | Clustered bar | ProvinceName × New Cases per 100k |
| 7 | `matrix_provinces` | Matrix | Province rows × 8 measures |
| 8 | `chart_multiples` | Line + small multiples | DateKey × Confirmed (7-day avg), multiples = ProvinceName |

No map. No extra cards. No DimEvent slicer.

### Name vs title in this Power BI build

General → Properties has no Name box (only Size, Position, Padding). The Selection pane string and the on-canvas Title are the same field. Double-clicking Selection pane therefore reprints `kpi_deaths` on the page.

Tonight: put the reader title in Format → General → **Title → Text**. Let the Selection pane match. Do not use `kpi_*` names. Layer order only sends a visual forward or back.

Work in the same Import model from Days 6–7. Do not add calculated columns. Do not reconnect PostgreSQL unless a refresh is needed.

**How we work:** one section, then a check, then the next section.

**Anchor date for every numeric check tonight:** 1 July 2021.

---

## Before you start

Day 7 must already be in the model:

- Measures live on the `Measures` table
- Gauteng 1 July 2021: Confirmed (Cumulative) **662,300**, Confirmed (New) **12,806**, Confirmed (7-day avg) **10,613.0**, Active Cases **94,677**
- DimDate is marked as a date table
- Relationships: fact → DimDate and fact → DimProvince
- DimEvent and meta Source stay disconnected

If those cards are wrong, stop and fix Day 7. Do not design pages on a broken measure pack.

Table names in DAX stay:

| In the model | In DAX |
|---|---|
| `core FactProvincialDaily` | `'core FactProvincialDaily'` |
| `core DimDate` | `'core DimDate'` |
| `core DimProvince` | `'core DimProvince'` |
| `core DimEvent` | `'core DimEvent'` |

---

## 8A — Two extra measures

Page 2 asks “who was hit hardest per capita?” Cumulative Cases per 100k is already in the pack. The ranked bar also needs daily / period incidence.

Create both on the `Measures` table. Display folder: Rates.

### New Cases per 100k

Format: Decimal number `#,0.0`.

```dax
New Cases per 100k :=
DIVIDE (
    [Confirmed (New)],
    [Population]
) * 100000
```

On one selected day this is that day’s incidence. On a date range it is the sum of new cases in the range ÷ population × 100,000. That is the honest “how hard was this window” number.

### Confirmed (7-day avg) per 100k

Format: Decimal number `#,0.0`.

```dax
Confirmed (7-day avg) per 100k :=
DIVIDE (
    [Confirmed (7-day avg)],
    [Population]
) * 100000
```

Smoother than a single-day incidence bar. Use this on Page 2 if the daily bar looks jumpy.

### Report Context (optional title)

Folder: Change. Format: Text.

`ISFILTERED ( ProvinceName )` misses a slicer on `ProvinceCode`, a filter that only sits on other cards, and a slicer whose Edit interactions are set to None. Use the row count of visible official provinces instead.

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

If it still says South Africa after you pick Gauteng: select the province slicer → Format → Edit interactions → the Report Context card must be **Filter**, not None. The slicer field must be `ProvinceName`. Do not test Gauteng only as a visual-level filter on the rate cards.

**Check — slicer 1 July 2021**

| Filter | New Cases per 100k | 7-day avg per 100k |
|---|---:|---:|
| Gauteng | 81.0 | 67.1 |
| All nine provinces | 35.9 | 28.1 |

Arithmetic:

- GP new: 12,806 ÷ 15,810,388 × 100,000 = **81.0**
- GP 7-day: 10,613.0 ÷ 15,810,388 × 100,000 = **67.1**
- National new: 21,583 ÷ 60,142,979 × 100,000 = **35.9**
- National 7-day: 16,916.1 ÷ 60,142,979 × 100,000 = **28.1**

UNKNOWN must stay blank on both. There is no population.

Do not start Page 1 until these two cards match.

---

## 8B — Page setup

1. Open the report view. Rename the existing scratch page (the Day 7 card + line) to `Pulse`.
2. Home → New page. Rename it `Provinces`.
3. View → Page view → Fit to page.
4. View → Gridlines and Snap to grid on.
5. Canvas: keep 16:9 (the Power BI default).
6. View → Theme → use the built-in **Executive** theme, or stay on the current theme. Do not hunt for a custom theme tonight.
7. View → Selection pane on. Name every visual after you place it (`kpi_confirmed`, `slicer_date`, …). That saves time when two cards look identical.

**Sync slicers later, not now.** Build Pulse first. Copy slicers to Provinces only after Pulse checks pass.

---

## 8C — Pulse slicers

Put three slicers on the left of **Pulse**. Keep them narrow.

| Slicer | Field | Style |
|---|---|---|
| Date | `'core DimDate'[DateKey]` | Between |
| Province | `'core DimProvince'[ProvinceName]` | Dropdown |
| Wave | `'core DimDate'[WaveName]` | Dropdown |

Wave comes from **DimDate**, not DimEvent. Day 2 already stamped WaveName onto the calendar:

| WaveName on DimDate | Window |
|---|---|
| Wave 1 — ancestral / D614G | 2020-06-01 to 2020-09-30 |
| Wave 2 — Beta | 2020-11-15 to 2021-02-28 |
| Wave 3 — Delta | 2021-05-15 to 2021-09-30 |
| Wave 4 — Omicron BA.1 | 2021-11-15 to 2022-02-15 |
| (blank) | Days outside those four bands |

DimEvent stays disconnected. Do not drop EventName on a slicer and expect the fact to filter. A lockdown row covers many dates; a relationship would duplicate fact rows. Day 9 can add a TREATAS pattern if you want a lockdown slicer.

**Slicer hygiene**

- Province slicer → Filters pane → ProvinceName is not `Not allocated`.
- Wave slicer → Filters pane → WaveName is not blank, if you only want named waves in the list. Leave blanks in the data; just hide them from the list.
- Date slicer: for the numeric checks set both ends to **1 July 2021**. For the story, open it to 1 Mar 2020 – 31 Dec 2022.

**What the wave slicer does to KPIs**

Snapshot measures use the last report date inside the current filter. If you pick Wave 3 and clear the date slicer, Confirmed (Cumulative) becomes the stock on **30 Sep 2021**, not 1 July 2021. That is correct. It is not the check date.

---

## 8D — Pulse title and KPI row

Top of Pulse, full width:

- Insert a text box: `ZA Pulse  ·  National COVID-19 pulse`
- Under it, a card with `Report Context` (no category label). This card should read `South Africa  ·  as of 01 Jul 2021` when the date slicer is pinned to that day.

Five KPI cards in one row under the title. Left to right:

| Card | Measure | Format already set on Day 7 |
|---|---|---|
| Confirmed | Confirmed (Cumulative) | Whole number |
| Deaths | Deaths (Cumulative) | Whole number |
| Recovered | Recovered (Cumulative) | Whole number |
| Active | Active Cases | Whole number |
| Daily pace | Confirmed (7-day avg) | 1 decimal |

Turn category labels on. Rename each card title in the visual so the page does not say the raw measure name only.

On every card: Format visual → Callout value → Display units = **None**. Apply settings to **this measure**, not All. The new card visual hides the unit until you do that (Day 7 note).

**Check — date slicer 1 July 2021, no province**

| Card | Expect |
|---:|---:|
| Confirmed | 1,995,556 |
| Deaths | 61,029 |
| Recovered | 1,754,793 |
| Active | 179,734 |
| Daily pace | 16,916.1 |

**Check — same date, Gauteng**

| Card | Expect |
|---:|---:|
| Confirmed | 662,300 |
| Deaths | 13,094 |
| Recovered | 554,529 |
| Active | 94,677 |
| Daily pace | 10,613.0 |

`Report Context` must switch to `Gauteng  ·  as of 01 Jul 2021`.

If Confirmed jumps into the hundreds of millions, you dropped `CumConfirmed` on the card instead of the snapshot measure. Delete the card and use Confirmed (Cumulative).

---

## 8E — Pulse trend

Under the KPI row, a wide line or area chart.

- X-axis: `'core DimDate'[DateKey]`
- Y-axis: Confirmed (7-day avg)
- Legend: `'core DimDate'[WaveName]`

Legend splits the line into the four wave colours plus a blank segment between waves. That is the band. You do not need a shape file or an analytics-pane rectangle.

Optional second Y-axis (Day 7 combo): Confirmed (Cumulative) on the secondary axis. Only do this if the 7-day line is still readable. A two-year cumulative dominates the eye; the pulse story is the daily pace.

**Do not put raw `CumConfirmed` on this axis.** Use the snapshot measure, or leave cumulative off.

**Check**

1. Date slicer open (full series). Province cleared.
2. The line must show four humps that line up with the wave names in the legend.
3. Wave 3 (mid-2021) is the tallest of the first three waves on the 7-day average.
4. Click Gauteng. The shape must change. Click Western Cape. It must change again.
5. Set Wave slicer to `Wave 3 — Delta`. The axis should shrink to May–Sep 2021.

If the line ignores the province slicer, the measure is not using the fact relationship. Go back to Day 7D.

---

## 8F — Pulse ranking (no map)

Do not add a South Africa shape file tonight. The plan allows a ranked bar instead.

Right of the trend, or under it if the canvas is tight:

- Clustered bar
- Axis: `'core DimProvince'[ProvinceName]`
- Values: Cases per 100k
- Sort descending by Cases per 100k
- Visual filter: ProvinceName is not `Not allocated`
- Data labels on

Title: `Cumulative confirmed per 100,000 people`

Caption under the chart (text box):

> Population is Stats SA P0302 2021 mid-year. UNKNOWN has no population and is excluded. This is cumulative burden by 1 July 2021 when the date slicer is pinned there.

**Check — 1 July 2021, no province selected**

- Nine bars, not ten.
- Gauteng Cases per 100k = **4,189.0**.
- National (if you add a total label) = **3,318.0**.
- You can answer “who was hit hardest per capita by this date?” by reading the top bar. Do not invent a rank list from memory — the bar is the answer.

---

## 8G — Pulse footer

Bottom of the page, small text box:

> Official provincial series compiled by Data Science for Social Impact, University of Pretoria (dsfsi/covid19za), from NICD / Department of Health. Licence CC BY-SA 4.0. Active cases = confirmed − recovered − deaths. Vaccination is not on this page.

Leave space. Day 9 adds doses and a quality page.

---

## 8H — Provinces page

Copy the three slicers from Pulse.

1. Select a slicer → Format → Properties → Advanced options is not needed yet.
2. View → Sync slicers.
3. Tick Pulse and Provinces for Date, Province, and Wave.
4. Keep “sync field changes” on so both pages see the same 1 July 2021 pin.

Title text box: `ZA Pulse  ·  Province comparison`

Card with `Report Context` under the title.

### Visual 1 — clustered bar, period incidence

- Axis: ProvinceName
- Values: New Cases per 100k
- Sort descending
- Visual filter: hide `Not allocated`
- Title: `New confirmed per 100,000 in the selected window`

**Check — date slicer 1 July 2021 only, no province**

| Province | Expect |
|---|---:|
| Gauteng | 81.0 |

Nine bars. Gauteng should be among the tallest that day (12,806 new cases, large population). If every bar is blank, Population is not in the model — refresh `core DimProvince` from PostgreSQL.

If the date slicer is a range (for example all of Wave 3), the bar becomes period incidence. That is intended. The 1 July check only holds when both ends of the slicer are that day.

### Visual 2 — matrix

Rows: ProvinceName  
Values, in this order:

| Measure | Conditional formatting |
|---|---|
| Confirmed (Cumulative) | None |
| Confirmed (New) | Background, diverging, on the measure |
| Confirmed (7-day avg) | None |
| Cases per 100k | Background, sequential, on the measure |
| CFR % | Background, sequential |
| Recovery Rate % | None |
| Share of National % | None |
| WoW Change % | Background, diverging, centred on 0 |

Visual filter: hide `Not allocated`.

Column headers wrap. Values right-aligned.

**Check — 1 July 2021, Gauteng row**

| Column | Expect |
|---|---:|
| Confirmed (Cumulative) | 662,300 |
| Confirmed (New) | 12,806 |
| Confirmed (7-day avg) | 10,613.0 |
| Cases per 100k | 4,189.0 |
| CFR % | 1.98% |
| Recovery Rate % | 83.73% |
| Share of National % | 33.19% |
| WoW Change % | 27.8% |

Matrix total row for Confirmed (Cumulative) on that day: **1,995,556** (nine provinces; UNKNOWN is hidden and was 0 that day).

### Visual 3 — small multiples

Line chart:

- X-axis: DateKey
- Y-axis: Confirmed (7-day avg)
- Small multiples: ProvinceName
- Visual filter: hide `Not allocated`
- Date slicer: open the full series, or Wave 3 if you want a shorter canvas

If small multiples are missing in your Power BI version, use a single line with ProvinceName as legend instead. Same measure.

**Check:** nine panes. Gauteng’s mid-2021 hump is visibly taller than Limpopo’s. Clearing the province slicer must show all nine. Selecting Western Cape must leave one pane, or one legend item.

---

## 8I — The question the pages must answer

Hand the file to someone who did not build it. They should be able to say, without opening PostgreSQL:

1. How large was the published national stock on 1 July 2021?  
   Pulse KPI: **1,995,556** confirmed.
2. Which province carried the most cumulative burden per capita by that date?  
   Pulse ranked bar: read the top Cases per 100k bar.
3. Which province was adding cases fastest per capita on that day?  
   Provinces clustered bar: read the top New Cases per 100k bar.
4. Was 1 July 2021 inside a named wave?  
   Wave slicer / legend: **Wave 3 — Delta**.

If they cannot answer those four, move visuals. Do not add a third page.

---

## What not to do

| Temptation | Why it fails |
|---|---|
| SA shapefile from a random download | Extra join, extra licence, not required tonight |
| Slicer on DimEvent[EventName] | Table is disconnected. Nothing on the fact moves |
| Relationship from fact to DimEvent | Lockdown / wave rows span many dates. Fact grain explodes |
| Raw `CumConfirmed` on a card or a 2-year line | Sums every daily running total |
| UNKNOWN on a per-100k bar | No population. Rate is blank or wrong |
| Dose Coverage % on Pulse | That caption belongs on the Day 9 vaccination page |
| A third page | Stop at two. Commit. |

---

## Commit

Files to add or update:

- `docs/day-8-report.md`
- `docs/dax-measures.md` (the two per-100k measures + Report Context)

Screenshots (create `docs/screenshots/` if it is missing):

- `docs/screenshots/day-8-pulse.png`
- `docs/screenshots/day-8-provinces.png`

Suggested message: `Day 8: Pulse and Provinces report pages`

Do not commit `powerbi.pbix` unless you have already decided the file stays small enough for GitHub.

---

## Done when

- Two pages exist: Pulse and Provinces
- 1 July 2021 national and Gauteng KPI cards match the check tables
- Ranked per-100k bar has nine provinces and answers “hit hardest per capita”
- Matrix Gauteng row matches the Day 7 pack
- Wave slicer uses DimDate[WaveName], not a fake relationship to DimEvent
- No calculated columns were added
- No vaccination or quality page yet
