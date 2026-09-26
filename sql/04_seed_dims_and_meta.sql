-- ZA Pulse — Day 2C
-- Run this while connected to database: za_pulse
-- Seeds dimensions and the source register. Safe to re-run (ON CONFLICT / NOT EXISTS).
-- PascalCase identifiers are quoted on purpose.

-- ---------------------------------------------------------------------------
-- 1. Provinces — 9 official codes + UNKNOWN
-- Done-when check: SELECT COUNT(*) FROM core."DimProvince";  -- expect 10
-- ---------------------------------------------------------------------------
INSERT INTO core."DimProvince" ("ProvinceCode", "ProvinceName", "Population", "RegionGroup", "IsNational")
VALUES
    ('EC',      'Eastern Cape',    NULL, 'coastal',     FALSE),
    ('FS',      'Free State',      NULL, 'inland',      FALSE),
    ('GP',      'Gauteng',         NULL, 'inland',      FALSE),
    ('KZN',     'KwaZulu-Natal',   NULL, 'coastal',     FALSE),
    ('LP',      'Limpopo',         NULL, 'inland',      FALSE),
    ('MP',      'Mpumalanga',      NULL, 'inland',      FALSE),
    ('NC',      'Northern Cape',   NULL, 'coastal',     FALSE),
    ('NW',      'North West',      NULL, 'inland',      FALSE),
    ('WC',      'Western Cape',    NULL, 'coastal',     FALSE),
    ('UNKNOWN', 'Not allocated',   NULL, 'unallocated', FALSE)
ON CONFLICT ("ProvinceCode") DO UPDATE
SET "ProvinceName" = EXCLUDED."ProvinceName",
    "RegionGroup"  = EXCLUDED."RegionGroup",
    "IsNational"   = EXCLUDED."IsNational";

-- Population stays NULL until SRC-005 is loaded. Do not invent a number today.

-- ---------------------------------------------------------------------------
-- 2. Date dimension — 2020-03-01 through 2022-12-31 inclusive
-- ---------------------------------------------------------------------------
INSERT INTO core."DimDate" (
    "DateKey", "YearNum", "QuarterNum", "MonthNum", "MonthName",
    "WeekIso", "WeekdayNum", "WeekdayName", "IsWeekend", "YearMonth", "WaveName"
)
SELECT
    d::date,
    EXTRACT(YEAR    FROM d)::int,
    EXTRACT(QUARTER FROM d)::int,
    EXTRACT(MONTH   FROM d)::int,
    to_char(d, 'FMMonth'),
    EXTRACT(WEEK    FROM d)::int,
    EXTRACT(ISODOW  FROM d)::int,
    to_char(d, 'FMDay'),
    EXTRACT(ISODOW  FROM d) IN (6, 7),
    to_char(d, 'YYYY-MM'),
    NULL
FROM generate_series(DATE '2020-03-01', DATE '2022-12-31', INTERVAL '1 day') AS d
ON CONFLICT ("DateKey") DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Source register
-- ---------------------------------------------------------------------------
INSERT INTO meta."Source" (
    "SourceId", "SourceName", "FileName", "SourceUrl", "Licence", "IngestMethod", "TargetTable", "Notes"
)
VALUES
    ('SRC-001',
     'Provincial confirmed (cumulative)',
     'covid19za_provincial_cumulative_timeline_confirmed.csv',
     'https://raw.githubusercontent.com/dsfsi/covid19za/master/data/covid19za_provincial_cumulative_timeline_confirmed.csv',
     'CC BY-SA 4.0',
     'http_csv',
     'raw."Confirmed"',
     'Compiled by DSFSI, University of Pretoria, from NICD / DoH. Values are cumulative.'),
    ('SRC-002',
     'Provincial recoveries (cumulative)',
     'covid19za_provincial_cumulative_timeline_recoveries.csv',
     'https://raw.githubusercontent.com/dsfsi/covid19za/master/data/covid19za_provincial_cumulative_timeline_recoveries.csv',
     'CC BY-SA 4.0',
     'http_csv',
     'raw."Recoveries"',
     'Same compiler and licence as SRC-001.'),
    ('SRC-003',
     'Provincial vaccination (cumulative)',
     'covid19za_provincial_cumulative_timeline_vaccination.csv',
     'https://raw.githubusercontent.com/dsfsi/covid19za/master/data/covid19za_provincial_cumulative_timeline_vaccination.csv',
     'CC BY-SA 4.0',
     'http_csv',
     'raw."Vaccination"',
     'Date column uses YYYY-MM-DD. No UNKNOWN province column. Treat values as doses.'),
    ('SRC-004',
     'Provincial deaths (cumulative)',
     'covid19za_provincial_cumulative_timeline_deaths.csv',
     'https://raw.githubusercontent.com/dsfsi/covid19za/master/data/covid19za_provincial_cumulative_timeline_deaths.csv',
     'CC BY-SA 4.0',
     'http_csv',
     'raw."Deaths"',
     'Same compiler and licence as SRC-001.'),
    ('SRC-005',
     'Province population',
     'province_population.csv',
     NULL,
     'Cite Stats SA mid-year estimate used',
     'local_csv',
     'core."DimProvince"',
     'Prepared locally. Used for per-100k and coverage. Not loaded on Day 2.'),
    ('SRC-006',
     'Lockdown levels and waves',
     NULL,
     'https://www.gov.za/Coronavirus',
     'Public government information',
     'manual_insert',
     'core."DimEvent"',
     'Lockdown dates from gov.za. Wave windows are approximate national bands.'),
    ('SRC-007',
     'Analyst observations',
     NULL,
     NULL,
     'Project notes',
     'manual_insert',
     'meta."ManualObservation"',
     'Typed INSERT in pgAdmin. Always set CreatedBy.')
ON CONFLICT ("SourceId") DO UPDATE
SET "SourceName"   = EXCLUDED."SourceName",
    "FileName"     = EXCLUDED."FileName",
    "SourceUrl"    = EXCLUDED."SourceUrl",
    "Licence"      = EXCLUDED."Licence",
    "IngestMethod" = EXCLUDED."IngestMethod",
    "TargetTable"  = EXCLUDED."TargetTable",
    "Notes"        = EXCLUDED."Notes";

-- ---------------------------------------------------------------------------
-- 4. Events
-- ---------------------------------------------------------------------------
INSERT INTO core."DimEvent" ("EventName", "EventType", "StartDate", "EndDate", "DatePrecision", "Notes", "SourceNote")
SELECT v."EventName", v."EventType", v."StartDate", v."EndDate", v."DatePrecision", v."Notes", v."SourceNote"
FROM (VALUES
    ('Alert level 5',
     'lockdown', DATE '2020-03-27', DATE '2020-04-30', 'official',
     'Hard lockdown from midnight 26 March 2020. Only essential services.',
     'https://www.gov.za/Coronavirus'),
    ('Alert level 4',
     'lockdown', DATE '2020-05-01', DATE '2020-05-31', 'official',
     'Limited economic activity resumed under strict conditions.',
     'https://www.gov.za/Coronavirus'),
    ('Alert level 3',
     'lockdown', DATE '2020-06-01', DATE '2020-08-17', 'official',
     'More sectors opened, including restricted retail and some services.',
     'https://www.gov.za/Coronavirus'),
    ('Alert level 2',
     'lockdown', DATE '2020-08-18', DATE '2020-09-20', 'official',
     'Most sectors open subject to health protocols.',
     'https://www.gov.za/Coronavirus'),
    ('Alert level 1',
     'lockdown', DATE '2020-09-21', DATE '2020-12-28', 'official',
     'Lowest restriction band before the second-wave tightening.',
     'https://www.gov.za/Coronavirus'),
    ('Adjusted alert level 3',
     'lockdown', DATE '2020-12-29', DATE '2021-02-28', 'official',
     'Tightened again during the second wave / festive period.',
     'https://www.gov.za/Coronavirus'),
    ('Adjusted alert level 1',
     'lockdown', DATE '2021-03-01', DATE '2021-05-30', 'official',
     'Restrictions eased after the second wave declined.',
     'https://www.gov.za/Coronavirus'),
    ('Adjusted alert level 2',
     'lockdown', DATE '2021-05-31', DATE '2021-06-15', 'official',
     'Step-up at the start of the third wave.',
     'https://www.gov.za/Coronavirus'),
    ('Adjusted alert level 3 (June 2021)',
     'lockdown', DATE '2021-06-16', DATE '2021-06-27', 'official',
     'Short band before level 4 during the Delta wave.',
     'https://www.gov.za/Coronavirus'),
    ('Adjusted alert level 4 (Delta peak)',
     'lockdown', DATE '2021-06-28', DATE '2021-07-25', 'official',
     'Highest restriction of the third wave.',
     'https://www.gov.za/Coronavirus'),
    ('Adjusted alert level 3 (after Delta peak)',
     'lockdown', DATE '2021-07-26', DATE '2021-09-12', 'official',
     'Restrictions stepped down as incidence fell.',
     'https://www.gov.za/Coronavirus'),
    ('Adjusted alert level 2 (Sep 2021)',
     'lockdown', DATE '2021-09-13', DATE '2021-09-30', 'official',
     'Brief band before returning to level 1.',
     'https://www.gov.za/Coronavirus'),
    ('Adjusted alert level 1 (to end of disaster)',
     'lockdown', DATE '2021-10-01', DATE '2022-04-04', 'official',
     'Final alert-level band. National state of disaster lifted 5 April 2022.',
     'https://www.gov.za/Coronavirus'),
    ('National state of disaster lifted',
     'milestone', DATE '2022-04-05', DATE '2022-04-05', 'official',
     'Alert-level system ended with the state of disaster.',
     'https://www.gov.za/Coronavirus'),
    ('Wave 1 — ancestral / D614G',
     'wave', DATE '2020-06-01', DATE '2020-09-30', 'approximate',
     'First national wave. Mid-2020. Dashboard band, not an NICD legal definition.',
     'Approximate national window for report shading'),
    ('Wave 2 — Beta',
     'wave', DATE '2020-11-15', DATE '2021-02-28', 'approximate',
     'Second wave associated with Beta (B.1.351).',
     'Approximate national window for report shading'),
    ('Wave 3 — Delta',
     'wave', DATE '2021-05-15', DATE '2021-09-30', 'approximate',
     'Third wave associated with Delta (B.1.617.2). Highest severe-illness burden of the first three waves.',
     'Approximate national window for report shading'),
    ('Wave 4 — Omicron BA.1',
     'wave', DATE '2021-11-15', DATE '2022-02-15', 'approximate',
     'Fourth wave associated with Omicron BA.1. High infection, lower hospitalisation fraction than prior waves.',
     'Approximate national window for report shading')
) AS v("EventName", "EventType", "StartDate", "EndDate", "DatePrecision", "Notes", "SourceNote")
WHERE NOT EXISTS (
    SELECT 1
    FROM core."DimEvent" e
    WHERE e."EventName" = v."EventName"
      AND e."StartDate" = v."StartDate"
);

-- ---------------------------------------------------------------------------
-- 5. Stamp WaveName onto DimDate from wave events
-- ---------------------------------------------------------------------------
UPDATE core."DimDate" d
SET "WaveName" = w."EventName"
FROM core."DimEvent" w
WHERE w."EventType" = 'wave'
  AND d."DateKey" BETWEEN w."StartDate" AND COALESCE(w."EndDate", DATE '9999-12-31');
