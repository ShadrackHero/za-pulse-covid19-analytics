-- ZA Pulse — Day 5
-- Run this while connected to database: za_pulse
--
-- Purpose: build the one analysis table Power BI will use.
--   Grain: one row per province per date that appears in ANY staging table.
--
-- Do not add a ZA national row. DimProvince has no ZA code on purpose.
-- National totals in Power BI = SUM of the nine official provinces + UNKNOWN.
-- Do not treat UNKNOWN as a tenth real province (no population, no rates).
--
-- How to run: paste one section, F5, run the check, then the next section.
-- Naming rule stays: schemas lowercase, tables and columns PascalCase and quoted.
--
-- New* is "this report minus the previous report for that province".
-- That is not the same as "new cases on this calendar day" when NICD skipped a day.
-- A negative New* value is a source revision, not negative incidence.

-- ===========================================================================
-- 5A  Create the empty fact table
-- ===========================================================================

DROP TABLE IF EXISTS core."FactProvincialDaily";
DROP TABLE IF EXISTS core.fact_provincial_daily;

CREATE TABLE core."FactProvincialDaily" (
    "ReportDate"      DATE         NOT NULL,
    "ProvinceCode"    VARCHAR(10)  NOT NULL,
    "CumConfirmed"    BIGINT,
    "CumRecovered"    BIGINT,
    "CumDeaths"       BIGINT,
    "CumVaccinated"   BIGINT,
    "NewConfirmed"    BIGINT,
    "NewRecovered"    BIGINT,
    "NewDeaths"       BIGINT,
    "NewVaccinated"   BIGINT,
    "ActiveCases"     BIGINT,
    "DqFlag"          TEXT,
    "HasConfirmed"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "HasRecovered"    BOOLEAN      NOT NULL DEFAULT FALSE,
    "HasDeaths"       BOOLEAN      NOT NULL DEFAULT FALSE,
    "HasVaccinated"   BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT "FactProvincialDailyPk"
        PRIMARY KEY ("ReportDate", "ProvinceCode"),
    CONSTRAINT "FactProvincialDailyDateFk"
        FOREIGN KEY ("ReportDate") REFERENCES core."DimDate" ("DateKey"),
    CONSTRAINT "FactProvincialDailyProvinceFk"
        FOREIGN KEY ("ProvinceCode") REFERENCES core."DimProvince" ("ProvinceCode")
);

COMMENT ON TABLE core."FactProvincialDaily" IS
    'Star-schema daily fact. Grain is province x report date. Cumulative values come from staging. New* and ActiveCases are derived. No ZA roll-up row.';

COMMENT ON COLUMN core."FactProvincialDaily"."CumVaccinated" IS
    'Cumulative doses as published. Not proven unique people.';

COMMENT ON COLUMN core."FactProvincialDaily"."NewConfirmed" IS
    'This report minus previous report for the same province. First report uses the cumulative itself. Negative means a revision.';

COMMENT ON COLUMN core."FactProvincialDaily"."ActiveCases" IS
    'CumConfirmed - CumRecovered - CumDeaths. NULL if any of the three is missing. Can go negative after revisions.';

COMMENT ON COLUMN core."FactProvincialDaily"."DqFlag" IS
    'Pipe-separated codes: REV_CONF, REV_REC, REV_DEATH, REV_VAX, NEG_ACTIVE, REC_GT_CONF, DEATH_GT_CONF. NULL means clean.';

-- 5A check
-- SELECT table_schema, table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'core'
-- ORDER BY table_name;
--
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema = 'core'
--   AND table_name = 'FactProvincialDaily'
-- ORDER BY ordinal_position;
--
-- SELECT COUNT(*) AS "RowCount" FROM core."FactProvincialDaily";
-- Expect: DimDate, DimEvent, DimProvince, FactProvincialDaily. RowCount 0.

-- ===========================================================================
-- 5B  Load the fact from the four long staging tables
-- ===========================================================================
--
-- Spine = every (date, province) that exists in at least one staging table
--         and also exists in DimDate / DimProvince (FK safety).
-- Missing measures stay NULL. Do not fill them with 0.
-- First-day New* = the cumulative itself (there is no previous report).

TRUNCATE TABLE core."FactProvincialDaily";

INSERT INTO core."FactProvincialDaily" (
    "ReportDate",
    "ProvinceCode",
    "CumConfirmed",
    "CumRecovered",
    "CumDeaths",
    "CumVaccinated",
    "NewConfirmed",
    "NewRecovered",
    "NewDeaths",
    "NewVaccinated",
    "ActiveCases",
    "DqFlag",
    "HasConfirmed",
    "HasRecovered",
    "HasDeaths",
    "HasVaccinated"
)
WITH spine AS (
    SELECT "ReportDate", "ProvinceCode" FROM stg."ConfirmedLong"
    UNION
    SELECT "ReportDate", "ProvinceCode" FROM stg."RecoveriesLong"
    UNION
    SELECT "ReportDate", "ProvinceCode" FROM stg."DeathsLong"
    UNION
    SELECT "ReportDate", "ProvinceCode" FROM stg."VaccinationLong"
),
joined AS (
    SELECT
        s."ReportDate",
        s."ProvinceCode",
        c."CumulativeValue" AS "CumConfirmed",
        r."CumulativeValue" AS "CumRecovered",
        d."CumulativeValue" AS "CumDeaths",
        v."CumulativeValue" AS "CumVaccinated",
        (c."CumulativeValue" IS NOT NULL) AS "HasConfirmed",
        (r."CumulativeValue" IS NOT NULL) AS "HasRecovered",
        (d."CumulativeValue" IS NOT NULL) AS "HasDeaths",
        (v."CumulativeValue" IS NOT NULL) AS "HasVaccinated"
    FROM spine AS s
    INNER JOIN core."DimDate"     AS dd ON dd."DateKey"      = s."ReportDate"
    INNER JOIN core."DimProvince" AS dp ON dp."ProvinceCode" = s."ProvinceCode"
    LEFT JOIN stg."ConfirmedLong"   AS c
           ON c."ReportDate" = s."ReportDate" AND c."ProvinceCode" = s."ProvinceCode"
    LEFT JOIN stg."RecoveriesLong"  AS r
           ON r."ReportDate" = s."ReportDate" AND r."ProvinceCode" = s."ProvinceCode"
    LEFT JOIN stg."DeathsLong"      AS d
           ON d."ReportDate" = s."ReportDate" AND d."ProvinceCode" = s."ProvinceCode"
    LEFT JOIN stg."VaccinationLong" AS v
           ON v."ReportDate" = s."ReportDate" AND v."ProvinceCode" = s."ProvinceCode"
),
with_new AS (
    SELECT
        j.*,
        CASE
            WHEN j."CumConfirmed" IS NULL THEN NULL
            WHEN LAG(j."CumConfirmed") OVER w IS NULL THEN j."CumConfirmed"
            ELSE j."CumConfirmed" - LAG(j."CumConfirmed") OVER w
        END AS "NewConfirmed",
        CASE
            WHEN j."CumRecovered" IS NULL THEN NULL
            WHEN LAG(j."CumRecovered") OVER w IS NULL THEN j."CumRecovered"
            ELSE j."CumRecovered" - LAG(j."CumRecovered") OVER w
        END AS "NewRecovered",
        CASE
            WHEN j."CumDeaths" IS NULL THEN NULL
            WHEN LAG(j."CumDeaths") OVER w IS NULL THEN j."CumDeaths"
            ELSE j."CumDeaths" - LAG(j."CumDeaths") OVER w
        END AS "NewDeaths",
        CASE
            WHEN j."CumVaccinated" IS NULL THEN NULL
            WHEN LAG(j."CumVaccinated") OVER w IS NULL THEN j."CumVaccinated"
            ELSE j."CumVaccinated" - LAG(j."CumVaccinated") OVER w
        END AS "NewVaccinated",
        CASE
            WHEN j."CumConfirmed" IS NULL
              OR j."CumRecovered" IS NULL
              OR j."CumDeaths"    IS NULL THEN NULL
            ELSE j."CumConfirmed" - j."CumRecovered" - j."CumDeaths"
        END AS "ActiveCases"
    FROM joined AS j
    WINDOW w AS (PARTITION BY j."ProvinceCode" ORDER BY j."ReportDate")
)
SELECT
    n."ReportDate",
    n."ProvinceCode",
    n."CumConfirmed",
    n."CumRecovered",
    n."CumDeaths",
    n."CumVaccinated",
    n."NewConfirmed",
    n."NewRecovered",
    n."NewDeaths",
    n."NewVaccinated",
    n."ActiveCases",
    NULLIF(CONCAT_WS('|',
        CASE WHEN n."NewConfirmed"  < 0 THEN 'REV_CONF'      END,
        CASE WHEN n."NewRecovered"  < 0 THEN 'REV_REC'       END,
        CASE WHEN n."NewDeaths"     < 0 THEN 'REV_DEATH'     END,
        CASE WHEN n."NewVaccinated" < 0 THEN 'REV_VAX'       END,
        CASE WHEN n."ActiveCases"   < 0 THEN 'NEG_ACTIVE'    END,
        CASE WHEN n."CumRecovered" IS NOT NULL
              AND n."CumConfirmed" IS NOT NULL
              AND n."CumRecovered" > n."CumConfirmed" THEN 'REC_GT_CONF' END,
        CASE WHEN n."CumDeaths" IS NOT NULL
              AND n."CumConfirmed" IS NOT NULL
              AND n."CumDeaths" > n."CumConfirmed" THEN 'DEATH_GT_CONF' END
    ), '') AS "DqFlag",
    n."HasConfirmed",
    n."HasRecovered",
    n."HasDeaths",
    n."HasVaccinated"
FROM with_new AS n;

INSERT INTO meta."LoadLog" ("SourceId", "RowCount", "Status", "Message")
SELECT
    'SRC-001',
    COUNT(*),
    'success',
    'Day 5 built core.FactProvincialDaily from four stg long tables'
FROM core."FactProvincialDaily";

-- 5B check
-- SELECT COUNT(*) AS "FactRows" FROM core."FactProvincialDaily";
-- -- expect around 8640, or a little more if the four files do not share every date
--
-- SELECT "ReportDate", "ProvinceCode",
--        "CumConfirmed", "CumRecovered", "CumDeaths", "CumVaccinated",
--        "NewConfirmed", "ActiveCases", "DqFlag"
-- FROM core."FactProvincialDaily"
-- WHERE "ReportDate" = DATE '2021-07-01'
--   AND "ProvinceCode" = 'GP';
-- -- CumConfirmed 662300, CumRecovered 554529
--
-- SELECT "ProvinceCode", COUNT(*) AS "Days"
-- FROM core."FactProvincialDaily"
-- GROUP BY 1
-- ORDER BY 1;

-- ===========================================================================
-- 5C  Validation queries (run after 5B, do not change data)
-- ===========================================================================
--
-- 5C-1  Grain: one row per province per date
-- SELECT "ReportDate", "ProvinceCode", COUNT(*) AS "Dupes"
-- FROM core."FactProvincialDaily"
-- GROUP BY 1, 2
-- HAVING COUNT(*) > 1;
-- -- expect 0 rows
--
-- 5C-2  Golden row still intact
-- SELECT "CumConfirmed", "CumRecovered"
-- FROM core."FactProvincialDaily"
-- WHERE "ReportDate" = DATE '2021-07-01'
--   AND "ProvinceCode" = 'GP';
-- -- 662300 / 554529
--
-- 5C-3  National total vs sum of provinces on 2021-07-01
-- -- Power BI will SUM the fact. Compare that sum to raw.Confirmed.Total.
-- -- UNKNOWN is included in the fact sum. Do not add a ZA row on top.
-- SELECT
--     raw."Total" AS "SourceTotal",
--     fact."SumProvinces",
--     raw."Total" - fact."SumProvinces" AS "Gap"
-- FROM raw."Confirmed" AS raw
-- CROSS JOIN (
--     SELECT SUM("CumConfirmed") AS "SumProvinces"
--     FROM core."FactProvincialDaily"
--     WHERE "ReportDate" = DATE '2021-07-01'
-- ) AS fact
-- WHERE TO_DATE(raw."DateText", 'DD-MM-YYYY') = DATE '2021-07-01';
--
-- 5C-4  Recovered should not exceed confirmed for long
-- SELECT COUNT(*) AS "RecGtConfRows"
-- FROM core."FactProvincialDaily"
-- WHERE "DqFlag" LIKE '%REC_GT_CONF%';
--
-- SELECT "ReportDate", "ProvinceCode", "CumConfirmed", "CumRecovered"
-- FROM core."FactProvincialDaily"
-- WHERE "DqFlag" LIKE '%REC_GT_CONF%'
-- ORDER BY "ReportDate", "ProvinceCode"
-- LIMIT 20;
--
-- 5C-5  Deaths should be monotonic aside from rare revisions
-- SELECT COUNT(*) AS "DeathRevisions"
-- FROM core."FactProvincialDaily"
-- WHERE "DqFlag" LIKE '%REV_DEATH%';
--
-- SELECT "ReportDate", "ProvinceCode", "CumDeaths", "NewDeaths"
-- FROM core."FactProvincialDaily"
-- WHERE "DqFlag" LIKE '%REV_DEATH%'
-- ORDER BY "ReportDate", "ProvinceCode"
-- LIMIT 20;
--
-- 5C-6  Flag summary — revisions exist in real epidemic data, do not delete them
-- SELECT
--     COUNT(*) AS "FactRows",
--     COUNT(*) FILTER (WHERE "DqFlag" IS NOT NULL) AS "FlaggedRows",
--     COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REV_CONF%')      AS "RevConf",
--     COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REV_REC%')       AS "RevRec",
--     COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REV_DEATH%')     AS "RevDeath",
--     COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REV_VAX%')       AS "RevVax",
--     COUNT(*) FILTER (WHERE "DqFlag" LIKE '%NEG_ACTIVE%')    AS "NegActive",
--     COUNT(*) FILTER (WHERE "DqFlag" LIKE '%REC_GT_CONF%')   AS "RecGtConf",
--     COUNT(*) FILTER (WHERE "DqFlag" LIKE '%DEATH_GT_CONF%') AS "DeathGtConf"
-- FROM core."FactProvincialDaily";
--
-- 5C-7  No ZA row slipped in
-- SELECT COUNT(*) AS "ZaRows"
-- FROM core."FactProvincialDaily"
-- WHERE "ProvinceCode" = 'ZA';
-- -- expect 0
