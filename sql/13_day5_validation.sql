-- ZA Pulse — Day 5C validation
-- Run this while connected to database: za_pulse
-- Read only. Does not insert, update, or delete.
--
-- pgAdmin will open one result tab per statement.
-- Send back: 5C-2, 5C-3, 5C-6, 5C-7.

-- 5C-1  Grain: one row per province per date
-- Expect: 0 rows
SELECT "ReportDate", "ProvinceCode", COUNT(*) AS "Dupes"
FROM core."FactProvincialDaily"
GROUP BY 1, 2
HAVING COUNT(*) > 1;

-- 5C-2  Golden row  (GP 2021-07-01)
-- Expect: CumConfirmed 662300, CumRecovered 554529
SELECT "CumConfirmed", "CumRecovered", "CumDeaths", "CumVaccinated",
       "NewConfirmed", "ActiveCases", "DqFlag"
FROM core."FactProvincialDaily"
WHERE "ReportDate" = DATE '2021-07-01'
  AND "ProvinceCode" = 'GP';

-- 5C-3  National total vs sum of provinces on 2021-07-01
-- Expect: Gap is 0 or a small UNKNOWN leftover, not thousands
SELECT
    raw."Total" AS "SourceTotal",
    fact."SumProvinces",
    raw."Total" - fact."SumProvinces" AS "Gap"
FROM raw."Confirmed" AS raw
CROSS JOIN (
    SELECT SUM("CumConfirmed") AS "SumProvinces"
    FROM core."FactProvincialDaily"
    WHERE "ReportDate" = DATE '2021-07-01'
) AS fact
WHERE TO_DATE(raw."DateText", 'DD-MM-YYYY') = DATE '2021-07-01';

-- 5C-4  Recovered greater than confirmed
SELECT COUNT(*) AS "RecGtConfRows"
FROM core."FactProvincialDaily"
WHERE "DqFlag" LIKE '%REC_GT_CONF%';

SELECT "ReportDate", "ProvinceCode", "CumConfirmed", "CumRecovered"
FROM core."FactProvincialDaily"
WHERE "DqFlag" LIKE '%REC_GT_CONF%'
ORDER BY "ReportDate", "ProvinceCode"
LIMIT 20;

-- 5C-5  Deaths going backwards (source revisions)
SELECT COUNT(*) AS "DeathRevisions"
FROM core."FactProvincialDaily"
WHERE "DqFlag" LIKE '%REV_DEATH%';

SELECT "ReportDate", "ProvinceCode", "CumDeaths", "NewDeaths"
FROM core."FactProvincialDaily"
WHERE "DqFlag" LIKE '%REV_DEATH%'
ORDER BY "ReportDate", "ProvinceCode"
LIMIT 20;

-- 5C-6  Flag summary
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

-- 5C-7  No ZA roll-up row
-- Expect: 0
SELECT COUNT(*) AS "ZaRows"
FROM core."FactProvincialDaily"
WHERE "ProvinceCode" = 'ZA';
