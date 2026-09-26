-- ZA Pulse — Day 2D
-- Run this after 02, 03 and 04. These are checks, not changes.
-- Day 2 is done when the province check returns 10 rows.

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'stg', 'core', 'meta')
ORDER BY schema_name;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('raw', 'core', 'meta')
  AND table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;

SELECT "ProvinceCode", "ProvinceName", "RegionGroup", "Population"
FROM core."DimProvince"
ORDER BY "ProvinceCode";

SELECT
    COUNT(*)                    AS "DayCount",
    MIN("DateKey")              AS "FirstDay",
    MAX("DateKey")              AS "LastDay",
    COUNT("WaveName")           AS "DaysInsideAWave",
    COUNT(*) - COUNT("WaveName") AS "DaysBetweenWaves"
FROM core."DimDate";

SELECT "DateKey", "WeekdayName", "IsWeekend"
FROM core."DimDate"
WHERE "DateKey" = DATE '2020-03-01';

SELECT "SourceId", "SourceName", "IngestMethod", "TargetTable"
FROM meta."Source"
ORDER BY "SourceId";

SELECT "EventType", COUNT(*) AS "Events"
FROM core."DimEvent"
GROUP BY "EventType"
ORDER BY "EventType";

SELECT "EventId", "EventName", "EventType", "StartDate", "EndDate", "DatePrecision"
FROM core."DimEvent"
ORDER BY "StartDate", "EventType", "EventId";

SELECT 'raw.Confirmed'    AS "TableName", COUNT(*) AS "RowCount" FROM raw."Confirmed"
UNION ALL
SELECT 'raw.Recoveries',  COUNT(*) FROM raw."Recoveries"
UNION ALL
SELECT 'raw.Deaths',      COUNT(*) FROM raw."Deaths"
UNION ALL
SELECT 'raw.Vaccination', COUNT(*) FROM raw."Vaccination"
UNION ALL
SELECT 'meta.LoadLog',    COUNT(*) FROM meta."LoadLog";
