# Day 9 — Vaccination page, quality page, richer DAX

Goal: depth. Two more pages on the same Import model. Four pages total by tonight.

- Page 3 — Vaccination
- Page 4 — Quality

No cover page. No README rewrite. Those are Day 10.

Work in the Day 6–8 `.pbix`. Do not add calculated columns. Do not reconnect PostgreSQL unless you need the two extra meta tables in 9A.

**How we work:** one section, then a check, then the next section.

**Anchor date for every numeric check tonight:** 1 July 2021.

Vaccination in this warehouse is **cumulative doses**, not unique people. Every visual on Page 3 must say so.

---

## Visual inventory (do not add extras)

**Vaccination — 12 visuals**

| # | Name in Selection pane | Type | Field / measure |
|---|---|---|---|
| 1 | `ZA Pulse  ·  Vaccination` | Text box | title |
| 2 | `Report Context` | Card | Report Context |
| 3 | Date slicer | Slicer | DimDate[DateKey], Between, synced |
| 4 | Province slicer | Slicer | DimProvince[ProvinceName], Dropdown, synced |
| 5 | Wave slicer | Slicer | DimDate[WaveName], Dropdown, synced |
| 6 | Cumulative doses | Card | Vaccinated (Cumulative) |
| 7 | New doses | Card | Vaccinated (New) |
| 8 | Dose coverage | Card | Dose Coverage % |
| 9 | Doses per 100k | Card | Doses per 100k |
| 10 | Doses over time | Line | DateKey × Vaccinated (Cumulative), legend ProvinceName only when a province is picked; otherwise national line |
| 11 | Coverage by province | Clustered bar | ProvinceName × Dose Coverage % |
| 12 | Coverage vs burden | Scatter | X = Cases per 100k, Y = Dose Coverage %, details = ProvinceName |

Footer is a text box, not a thirteenth chart. Caption is mandatory (see 9E).

**Quality — 10 visuals**

| # | Name in Selection pane | Type | Field / measure |
|---|---|---|---|
| 1 | `ZA Pulse  ·  Data quality` | Text box | title |
| 2 | `Report Context` | Card | Report Context |
| 3 | Date / Province / Wave slicers | Slicers | synced from Pulse |
| 4 | Fact rows | Card | Fact Rows |
| 5 | Flagged rows | Card | Flagged Rows |
| 6 | Flagged share | Card | Flagged Share % |
| 7 | Flags by type | Clustered bar | DqFlag Catalogue[FlagLabel] × Flag Row Count |
| 8 | Flagged fact rows | Table | ReportDate, ProvinceName, DqFlag, NewConfirmed, NewRecovered, NewDeaths, NewVaccinated, ActiveCases |
| 9 | Source catalogue | Table | meta Source columns |
| 10 | Analyst notes | Table | ManualObservation if imported; otherwise a text box listing the five Day 4E notes |

Credit footer is a text box under the source table.

No map. No DimEvent slicer. No what-if parameter tonight (stretch only, 9H).

### Name vs title

Same rule as Day 8. Put the reader title in Format → General → **Title → Text**. Do not rename from the Selection pane if that reprints the internal name on the canvas.

---

## Before you start

Day 8 pages must already work:

- Pulse and Provinces exist
- Gauteng 1 July 2021: Confirmed (Cumulative) **662,300**, Confirmed (New) **12,806**, Active Cases **94,677**
- Dose Coverage % already exists from Day 7: Gauteng **4.99%**, nine provinces **5.47%**
- Vaccinated (Cumulative) already exists: Gauteng **789,010**, nine provinces **3,289,900**
- Wave slicer is DimDate[WaveName]
- DimEvent and Source stay disconnected from the fact

If Dose Coverage % is missing, create it from `docs/dax-measures.md` before 9B. Do not design Page 3 on a blank coverage card.

Table names in DAX stay:

| In the model | In DAX |
|---|---|
| `core FactProvincialDaily` | `'core FactProvincialDaily'` |
| `core DimDate` | `'core DimDate'` |
| `core DimProvince` | `'core DimProvince'` |

---

## 9A — Two extra tables (model only)

The quality page needs a flag list you can put on an axis, and a lineage table that is not the fact.

### Flag catalogue (Enter data)

Home → Enter data. Name the table `DqFlag Catalogue`.

| FlagCode | FlagLabel | SortOrder |
|---|---|---|
| REV_CONF | Confirmed revised down | 1 |
| REV_REC | Recoveries revised down | 2 |
| REV_DEATH | Deaths revised down | 3 |
| REV_VAX | Doses revised down | 4 |
| NEG_ACTIVE | Active cases negative | 5 |
| REC_GT_CONF | Recoveries above confirmed | 6 |
| DEATH_GT_CONF | Deaths above confirmed | 7 |

Load. No relationship to the fact. DqFlag is pipe-separated text; a relationship would not match.

Column tools → Sort by column: FlagLabel sorted by SortOrder.

### Lineage tables (optional refresh)

Day 6 imported `meta Source` only. LoadLog and ManualObservation still live in PostgreSQL.

If you want the Quality page to show real ingest history:

1. Home → Get data → PostgreSQL → database `za_pulse` → Import.
2. Tick `meta.LoadLog` and `meta.ManualObservation` only.
3. Load.

Relationships:

| From | To | Direction |
|---|---|---|
| LoadLog[SourceId] | Source[SourceId] | single, many-to-one |
| (none) | ManualObservation | leave disconnected |

Do **not** relate ManualObservation[ObsDate] to DimDate. A Between slicer pinned to 1 July 2021 would hide three of the five notes.

Do **not** relate ManualObservation[ProvinceCode] to DimProvince either. The notes are documentation, not facts. A Gauteng slicer would hide the UNKNOWN and WC notes.

If the PostgreSQL refresh is a hassle tonight, skip LoadLog and ManualObservation. Use the Source table you already have, plus the text-box fallback in 9G.

**Check**

- Model view shows `DqFlag Catalogue` with 7 rows and no line to the fact.
- Source still has no line to the fact.
- Pulse and Provinces numbers have not changed.

Do not start 9B until the catalogue is in the model.

---

## 9B — Vaccination measures

Create these on the `Measures` table. Display folder: Rates, unless noted.

Paste from `docs/dax-measures.md`. Do not invent a second Dose Coverage %.

### Vaccinated (7-day avg)

Folder: Outcomes. Format: Decimal number `#,0.0`.

Same pattern as Confirmed (7-day avg), on `Vaccinated (New)`.

### Doses per 100k

Folder: Rates. Format: Decimal number `#,0.0`.

```dax
Doses per 100k :=
DIVIDE (
    [Vaccinated (Cumulative)],
    [Population]
) * 100000
```

This is Dose Coverage % × 100,000. Coverage of 4.99% is 4,990 doses per 100,000 people.

### Share of National Doses %

Folder: Change. Format: Percentage, 2 decimals.

Same shape as Share of National %, on the vaccination snapshot.

**Check — slicer 1 July 2021**

| Filter | Vaccinated (Cumulative) | Dose Coverage % | Doses per 100k | Share of National Doses % |
|---|---:|---:|---:|---:|
| Gauteng | 789,010 | 4.99% | 4,990.5 | 23.98% |
| Nine official provinces | 3,289,900 | 5.47% | 5,470.1 | 100.00% |

Arithmetic:

- GP coverage: 789,010 ÷ 15,810,388 = **4.99%**
- GP per 100k: 789,010 ÷ 15,810,388 × 100,000 = **4,990.5**
- National coverage: 3,289,900 ÷ 60,142,979 = **5.47%**
- GP share of doses: 789,010 ÷ 3,289,900 = **23.98%**

UNKNOWN stays blank on coverage and per 100k. There is no population.

Vaccinated (New) has no golden number tonight. A negative value is a source revision (`REV_VAX`), not negative doses administered.

Do not start Page 3 until the four cells in the check table match.

---

## 9C — Quality measures

Folder: Quality. Format whole numbers as `#,0`. Flagged Share % is Percentage, 1 decimal.

### Fact Rows / Flagged Rows / Flagged Share %

`Fact Rows` counts visible fact rows in the current filter (date × province).

`Flagged Rows` counts rows where `DqFlag` is not blank.

`Flagged Share %` = Flagged Rows ÷ Fact Rows.

On a single day with nine provinces you should see 9 fact rows (UNKNOWN hidden by the province slicer filter) or 10 if UNKNOWN is visible.

### Flag Row Count

This is the measure the Quality bar uses. It reads the selected catalogue code and looks inside the pipe-separated `DqFlag` text.

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

No relationship is required. `CONTAINSSTRING` does the match.

### Peak New Confirmed / Peak Date

Folder: Change.

On a one-day slicer, Peak New Confirmed equals Confirmed (New) that day. That is the check. Do not memorise a “national peak day” — the source revises, and the peak moves if you hide UNKNOWN or pin a wave.

**Check — date slicer 1 July 2021, Gauteng**

| Measure | Expect |
|---|---|
| Fact Rows | 1 |
| Peak New Confirmed | 12,806 |
| Peak Date | 1 July 2021 |
| Flagged Rows | 0 or 1 (only if that GP row itself carries a flag) |

**Check — date slicer 1 July 2021, no province, UNKNOWN hidden**

| Measure | Expect |
|---|---|
| Fact Rows | 9 |

Do not invent a flagged-row total for the full series. Read it from the card after the page is built and write the number into your commit note.

---

## 9D — Page setup and sync

1. Home → New page. Rename it `Vaccination`.
2. Home → New page. Rename it `Quality`.
3. View → Page view → Fit to page. Gridlines on.
4. Copy the three slicers from Pulse (copy visual, paste).
5. View → Sync slicers. Tick Pulse, Provinces, Vaccination, Quality for Date, Province, and Wave.
6. Keep “sync field changes” on.

Pin both ends of the date slicer to **1 July 2021** for every numeric check. Open the range only when you look at the dose line.

Do not build Quality first. Vaccination uses measures you just checked.

---

## 9E — Vaccination page

Top of the page, full width:

- Text box: `ZA Pulse  ·  Vaccination`
- Card: Report Context. Expect `South Africa  ·  as of 01 Jul 2021` with the date pin and no province.

Four KPI cards under the title:

| Card title | Measure | Display units |
|---|---|---|
| Cumulative doses | Vaccinated (Cumulative) | None |
| New doses that report | Vaccinated (New) | None |
| Dose coverage | Dose Coverage % | already a % |
| Doses per 100,000 | Doses per 100k | None |

On every whole-number card: Format visual → Callout value → Display units = **None** → Apply settings to **this measure**.

### Line — cumulative doses over time

- X-axis: `'core DimDate'[DateKey]`
- Y-axis: Vaccinated (Cumulative)
- Visual filter: ProvinceName is not `Not allocated`
- Date slicer: open the full series for this check only, then pin it back

Do **not** put raw `CumVaccinated` on the axis. Use the snapshot measure. A two-year SUM of running totals will explode the same way Day 6 exploded confirmed.

The official vaccination series starts **17 Feb 2021**. The line should be blank before that, then rise. Early 2021 is Sisonke / health workers; 1 July 2021 is still early in the public rollout, which is why coverage is about 5%.

Optional: add Vaccinated (7-day avg) on a secondary axis if the cumulative line looks like a ramp and you want pace. Only if the cumulative is still readable.

**Check**

1. Date pin 1 July 2021, no province: last point of a filtered line is **3,289,900**. Easier: the KPI card is 3,289,900.
2. Gauteng: card **789,010**.
3. Open the date range. The line must stay a stock (smooth-ish ramp), not a mountain of summed cumulatives.
4. Click Western Cape. The line must change.

### Bar — coverage by province

- Axis: ProvinceName
- Values: Dose Coverage %
- Sort descending
- Visual filter: hide `Not allocated`
- Data labels on
- Title: `Cumulative doses ÷ 2021 population`

**Check — 1 July 2021, no province**

- Nine bars.
- Gauteng = **4.99%**.
- National is not a tenth bar. It is the KPI.

### Scatter — coverage vs burden

- X-axis: Cases per 100k
- Y-axis: Dose Coverage %
- Details / legend: ProvinceName
- Visual filter: hide `Not allocated`
- Title: `Dose coverage vs cumulative cases per 100k`

This is **descriptive**. It does not say vaccines caused fewer cases, or that high-burden provinces vaccinated more. By 1 July 2021 Wave 3 was already running and the rollout was young.

**Check — 1 July 2021**

- Nine points.
- Gauteng sits at Cases per 100k **4,189.0** and coverage **4.99%**.
- No UNKNOWN point.

### Footer (mandatory)

> Cumulative doses published in the dsfsi/covid19za provincial vaccination file, divided by Stats SA P0302 2021 mid-year population. This is not people fully vaccinated and it is not unique people. A province can pass 100% later in the series when first and second doses are both in the numerator. The scatter is a snapshot, not a causal claim.

---

## 9F — The question Page 3 must answer

Someone who did not build it should be able to say:

1. How many doses had been published nationally by 1 July 2021?  
   KPI: **3,289,900**.
2. How far had Gauteng’s published doses got, as a share of its 2021 population?  
   KPI / bar: **4.99%**.
3. Are we looking at people or doses?  
   Footer: doses.
4. Does the scatter prove that vaccination reduced cases?  
   No. The caption says so.

If they cannot answer those four, move visuals. Do not add a fifth page.

---

## 9G — Quality page

Title: `ZA Pulse  ·  Data quality`

Report Context card under the title.

Three KPI cards:

| Card title | Measure |
|---|---|
| Fact rows in view | Fact Rows |
| Rows with a quality flag | Flagged Rows |
| Share flagged | Flagged Share % |

### Bar — flags by type

- Axis: `'DqFlag Catalogue'[FlagLabel]`
- Values: Flag Row Count
- Sort by SortOrder (already on the column)
- Title: `Fact rows carrying each flag`

A row can carry more than one flag (`REV_CONF|NEG_ACTIVE`). The bar total can exceed Flagged Rows. That is correct.

**Check**

- Seven bars, even if some are zero.
- Clicking a wave or a province changes the bar. If it does not, Flag Row Count is ignoring filter context — remove an ALL() you may have added.

### Table — flagged fact rows

Columns, in this order:

- `'core FactProvincialDaily'[ReportDate]`
- `'core DimProvince'[ProvinceName]`
- `'core FactProvincialDaily'[DqFlag]`
- Confirmed (New)
- Recovered (New)
- Deaths (New)
- Vaccinated (New)
- Active Cases

Filters on this visual:

- DqFlag is not blank
- ProvinceName is not `Not allocated` (keep UNKNOWN visible here — unallocated rows are a quality topic)

Sort by ReportDate descending.

Negative New* values should appear next to `REV_*` flags. That is the point of the page.

### Table — source catalogue

Drop `'meta Source'` (model name may be `meta Source`) onto a table:

- SourceId
- SourceName
- FileName
- Licence
- IngestMethod

Seven rows: SRC-001 to SRC-007. No slicer should hide them. Edit interactions: Date / Province / Wave → this table = **None**.

### Table — load log or notes

If you imported LoadLog:

- LoadedAt, SourceId, RowCount, Status, Message
- Visual-level filter: Status is `success`
- Sort LoadedAt descending

If you imported ManualObservation:

- ObsDate, ProvinceCode, Note, CreatedBy
- Show all five Day 4E notes

If you imported neither: text box with the five notes from `sql/11_manual_observations.sql` (Wave 3 golden row, holiday lag, vaccination start 17 Feb 2021, UNKNOWN rule, revisions vs negative incidence).

### Footer (mandatory)

> Official provincial series compiled by Data Science for Social Impact, University of Pretoria (dsfsi/covid19za), from NICD / Department of Health. Licence CC BY-SA 4.0. Flags are warehouse rules from Day 5 (`REV_*`, `NEG_ACTIVE`, `REC_GT_CONF`, `DEATH_GT_CONF`). A flagged row is kept. It is not deleted.

---

## 9H — Stretch only (skip if the four pages already work)

Do not start this until 9E and 9G checks pass.

### Confirmed (14-day avg)

Same as the 7-day measure with `-14`. Folder: Confirmed. No golden number tonight.

### What-if CFR

Modeling → New parameter → What if: `Scenario CFR` from 0.01 to 0.10, increment 0.005, default 0.03.

```dax
Implied Deaths (scenario) :=
[Confirmed (Cumulative)] * 'Scenario CFR'[Scenario CFR Value]
```

Put it on Quality, not Pulse. Title must say **scenario**. Default 3% is close to the published national CFR on 1 July 2021 (3.06%). This is not a forecast.

### Lockdown slicer via TREATAS

Still do not relate DimEvent to the fact. A disconnected slicer plus TREATAS can filter dates to a lockdown window. Leave it. Day 10 can add it if the report still feels thin.

---

## What not to do

| Temptation | Why it fails |
|---|---|
| Label Dose Coverage % as “% vaccinated” | The file is doses |
| SUM of `CumVaccinated` on a two-year line | Same explosion as Day 6 confirmed |
| Relationship from DqFlag Catalogue to the fact | Codes are embedded in a pipe string |
| Relationship from fact to DimEvent | Grain explodes |
| Hide flagged rows | The quality page exists to show them |
| UNKNOWN on the coverage bar or scatter | No population |
| What-if parameter on Pulse | Pulse is published stock, not a scenario |
| A fifth page | Stop at four. Commit. |

---

## Commit

Files to add or update:

- `docs/day-9-report.md`
- `docs/dax-measures.md` (vaccination extras + quality pack)

Screenshots (create `docs/screenshots/` if it is missing):

- `docs/screenshots/day-9-vaccination.png`
- `docs/screenshots/day-9-quality.png`

Suggested message: `Day 9: Vaccination and Quality report pages`

Do not commit `powerbi.pbix` unless you have already decided the file stays small enough for GitHub.

---

## Done when

- Four pages exist: Pulse, Provinces, Vaccination, Quality
- 1 July 2021 national doses = **3,289,900** and Gauteng coverage = **4.99%**
- Vaccination footer says doses, not people
- Scatter has a no-causality caption
- Quality page shows DqFlag rows instead of hiding them
- Source catalogue is visible
- Slicers sync across all four pages
- No calculated columns were added
- No cover page yet
