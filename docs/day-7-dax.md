# Day 7 — DAX core library

Goal: measures only. No new pages yet. One card and one line chart must follow a province slicer.

Work in Power BI Desktop on the Day 6 Import model. Do not add calculated columns. Do not re-diff `CumConfirmed` in Power Query.

PostgreSQL Import left schema names on the tables: `'core FactProvincialDaily'`, `'core DimDate'`, `'core DimProvince'`. The new Card visual hides Display units until **Apply settings to** is the measure, not All.

**How we work:** one section, then a check, then the next section. Paste the DAX from `docs/dax-measures.md`.

**Anchor date for every check tonight:** 1 July 2021.

---

## Before you start

Model must already have:

- Relationships: `FactProvincialDaily[ReportDate] → DimDate[DateKey]` and `FactProvincialDaily[ProvinceCode] → DimProvince[ProvinceCode]`
- `DimDate` marked as a date table
- Daily cases coming from `NewConfirmed` (Frequency). Gauteng 1 July 2021 daily is **12,806**, not 662,300

If a Day 6 matrix with the slicer on 1 July 2021 still shows Gauteng cumulative **662,300**, the model is ready.

---

## 7A — A home for measures

1. Home → Enter data.
2. Leave the one dummy column. Name the table `Measures`. Load.
3. In Model view, hide the dummy column (`Column1`).
4. Right-click the `Measures` table → New measure for every formula tonight.
5. After each measure: Measure tools → Display folder.

| Folder | Measures that go there |
|---|---|
| Confirmed | Confirmed (Cumulative), Confirmed (New), Confirmed (7-day avg) |
| Outcomes | Recovered (Cumulative), Deaths (Cumulative), Vaccinated (Cumulative), Active Cases |
| Rates | CFR %, Recovery Rate %, Cases per 100k, Dose Coverage %, Population |
| Change | Share of National %, WoW Change % |

If Power BI already has `Confirmed (New)` on the fact table from Day 6 notes, leave it. Do not create a second copy.

---

## 7B — Snapshot cumulatives

`CumConfirmed` is already a running total in the warehouse. If you drop it on a year and Power BI SUMs every day, the number explodes.

A snapshot measure keeps only the last report date inside the current filter.

Create these four from `docs/dax-measures.md`:

- Confirmed (Cumulative)
- Recovered (Cumulative)
- Deaths (Cumulative)
- Vaccinated (Cumulative)

Format all four as Whole number (`#,0`).

**Check — slicer 1 July 2021, no province selected**

| Card | Expect |
|---:|---:|
| Confirmed (Cumulative) | 1,995,556 |
| Recovered (Cumulative) | 1,754,793 |
| Deaths (Cumulative) | 61,029 |
| Vaccinated (Cumulative) | 3,289,900 |

**Check — same date, Gauteng only**

| Card | Expect |
|---:|---:|
| Confirmed (Cumulative) | 662,300 |
| Recovered (Cumulative) | 554,529 |
| Deaths (Cumulative) | 13,094 |
| Vaccinated (Cumulative) | 789,010 |

If Confirmed (Cumulative) is in the hundreds of millions, the measure is still summing every day. Stop and fix 7B before 7C.

---

## 7C — Frequency (already in the warehouse)

Create:

- Confirmed (New)
- Recovered (New)
- Deaths (New)
- Vaccinated (New)

These are `SUM` of the `New*` columns Day 5 already built with `LAG`. Do not write `DATEADD` against the cumulative.

Format as Whole number.

**Check — slicer 1 July 2021, Gauteng**

| Card | Expect |
|---:|---:|
| Confirmed (New) | 12,806 |

**Check — slicer 1 April 2021, Gauteng**

| Card | Expect |
|---:|---:|
| Confirmed (New) | 362 |

If 1 April shows 0, the measure is diffing a sliced window. Use `NewConfirmed`.

**Check — slicer 1 July 2021, all provinces**

| Card | Expect |
|---:|---:|
| Confirmed (New) | 21,583 |

---

## 7D — 7-day average

Create Confirmed (7-day avg).

It averages `Confirmed (New)` over the last 7 calendar days ending on the last visible date. `AVERAGEX` skips days with no NICD report. On the 1 July 2021 window every day was published, so the average is just the mean of seven numbers.

Format as Decimal number, 1 decimal (`#,0.0`).

**Check — slicer 1 July 2021**

| Filter | Expect |
|---|---:|
| Gauteng | 10,613.0 |
| All provinces | 16,916.1 |

Gauteng window 25 Jun–1 Jul 2021 daily confirmed:

11,782 + 11,304 + 9,861 + 8,443 + 8,927 + 11,168 + 12,806 = 74,291 ÷ 7 = **10,613**.

---

## 7E — Active, CFR, recovery rate

Create:

- Active Cases
- CFR %
- Recovery Rate %

Active Cases uses the three snapshot cumulatives, not `SUM` of the warehouse `ActiveCases` column across a date range.

CFR and Recovery Rate use `DIVIDE`, never `/`.

Format Active Cases as Whole number. Format the two rates as Percentage, 2 decimals.

**Check — slicer 1 July 2021**

| Filter | Active Cases | CFR % | Recovery Rate % |
|---|---:|---:|---:|
| Gauteng | 94,677 | 1.98% | 83.73% |
| All provinces | 179,734 | 3.06% | 87.94% |

Gauteng arithmetic: 662,300 − 554,529 − 13,094 = 94,677.

---

## 7F — Population and per-capita

Create:

- Population
- Cases per 100k
- Dose Coverage %

`Population` is `SUM` of `DimProvince[Population]`. UNKNOWN has no population, so it drops out of the sum on its own. Do not force UNKNOWN into a rate.

Dose Coverage % is **doses ÷ 2021 Stats SA population**. It is not “people vaccinated”. It can pass 100% later in the series. Put that sentence on the Day 8 / Day 9 page, not only in this file.

Format Population as Whole number. Cases per 100k as Decimal, 1 decimal. Dose Coverage % as Percentage, 2 decimals.

**Check — slicer 1 July 2021**

| Filter | Population | Cases per 100k | Dose Coverage % |
|---|---:|---:|---:|
| Gauteng | 15,810,388 | 4,189.0 | 4.99% |
| Nine provinces (UNKNOWN off or ignored) | 60,142,979 | 3,318.0 | 5.47% |

---

## 7G — Share of national

Create Share of National % on confirmed cumulative.

Denominator is `ALL ( 'DimProvince' )`, so a Gauteng card answers “what share of the published national total is Gauteng?” UNKNOWN stays in the denominator. On 1 July 2021 UNKNOWN is 0, so it does not change the answer.

Format as Percentage, 2 decimals.

**Check — slicer 1 July 2021, Gauteng**

| Card | Expect |
|---:|---:|
| Share of National % | 33.19% |

662,300 ÷ 1,995,556 = 0.331887.

With no province selected the share is 100%. That is correct.

---

## 7H — Week-on-week

Create WoW Change %.

This week = last 7 days of `Confirmed (New)` ending on the visible date. Prior week = the 7 days before that. `DIVIDE` the difference by the prior week.

Format as Percentage, 1 decimal.

**Check — slicer 1 July 2021**

| Filter | This week new | Prior week new | WoW Change % |
|---|---:|---:|---:|
| Gauteng | 74,291 | 58,136 | 27.8% |
| All provinces | 118,413 | 91,064 | 30.0% |

Windows: this week 25 Jun–1 Jul 2021. Prior week 18–24 Jun 2021.

---

## 7I — The two visuals that close the day

Do not design Page 1 tonight. Two visuals on the blank report page are enough.

**Slicers**

- `DimDate[DateKey]` (use 1 July 2021 for the checks, then a range)
- `DimProvince[ProvinceName]`

**Card**

Drop Confirmed (Cumulative). Click Gauteng. The card must move from 1,995,556 to 662,300.

**Line chart**

- X-axis: `DimDate[DateKey]`
- Y-axis: Confirmed (7-day avg)
- Province slicer: Gauteng, then Western Cape, then clear

The line must change shape when the province changes. If it does not, the measure is ignoring the province relationship.

Leave `CumConfirmed` off this axis. A cumulative on a line across two years is a different story. Day 8 can add it as a second page if you want.

---

## What not to do

| Temptation | Why it fails |
|---|---|
| Calculated column for CFR | It cannot see the slicer. A measure can. |
| `DATEADD` on `CumConfirmed` to invent daily cases | Looks at calendar yesterday, not the previous NICD report |
| `SUM ( ActiveCases )` on a year with no snapshot | Adds estimated active stock across hundreds of days |
| Divide with `/` | A zero denominator errors. `DIVIDE` returns blank |
| Per-100k on UNKNOWN | There is no population. Leave it blank |
| Calling Dose Coverage % “people vaccinated” | The file is cumulative doses |

---

## Commit

Files to add or update in the repo:

- `docs/dax-measures.md`
- `docs/day-7-dax.md`

Suggested message: `Day 7: DAX measure pack v1`

A screenshot of the Gauteng 1 July 2021 cards helps the README later. Suggested path: `docs/screenshots/day-7-gauteng-cards.png`.

Do not commit `powerbi.pbix` unless you have already decided the file stays small enough for GitHub.

---

## Done when

- All measures in the table in `docs/dax-measures.md` exist in the model
- Gauteng 1 July 2021 cards match the check table
- One card and one line chart follow the province slicer
- No calculated columns were added for these metrics
