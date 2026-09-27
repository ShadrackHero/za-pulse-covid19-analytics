-- ZA Pulse — Day 3C
-- Run this while connected to database: za_pulse
--
-- Purpose: turn the wide raw photocopies into long staging tables.
--   raw."Confirmed"   (one row per date, provinces as columns)
--     -> stg."ConfirmedLong"   (one row per date per province)
--   raw."Recoveries"
--     -> stg."RecoveriesLong"
--
-- Do not load deaths or vaccination today.
-- Do not build the fact table today (that is Day 5).
--
-- How to run: same as Day 2. Paste one section, F5, run the check, then the next section.
--
-- Naming rule stays: schemas lowercase, tables and columns PascalCase and quoted.

-- ===========================================================================
-- 3C-1  Create empty staging tables
-- ===========================================================================

DROP TABLE IF EXISTS stg."ConfirmedLong";
DROP TABLE IF EXISTS stg."RecoveriesLong";
DROP TABLE IF EXISTS stg.confirmed_long;
DROP TABLE IF EXISTS stg.recoveries_long;

CREATE TABLE stg."ConfirmedLong" (
    "ReportDate"        DATE         NOT NULL,
    "DateText"          TEXT         NOT NULL,
    "YearMonthDay"      TEXT,
    "ProvinceCode"      VARCHAR(10)  NOT NULL,
    "CumulativeValue"   BIGINT,
    "SourceText"        TEXT,
    "SourceId"          VARCHAR(16)  NOT NULL DEFAULT 'SRC-001',
    CONSTRAINT "ConfirmedLongPk" UNIQUE ("ReportDate", "ProvinceCode"),
    CONSTRAINT "ConfirmedLongProvinceFk"
        FOREIGN KEY ("ProvinceCode") REFERENCES core."DimProvince" ("ProvinceCode"),
    CONSTRAINT "ConfirmedLongSourceFk"
        FOREIGN KEY ("SourceId") REFERENCES meta."Source" ("SourceId")
);

COMMENT ON TABLE stg."ConfirmedLong" IS
    'Unpivoted official confirmed cases. One row per report date per province. Values stay cumulative.';

CREATE TABLE stg."RecoveriesLong" (
    "ReportDate"        DATE         NOT NULL,
    "DateText"          TEXT         NOT NULL,
    "YearMonthDay"      TEXT,
    "ProvinceCode"      VARCHAR(10)  NOT NULL,
    "CumulativeValue"   BIGINT,
    "SourceText"        TEXT,
    "SourceId"          VARCHAR(16)  NOT NULL DEFAULT 'SRC-002',
    CONSTRAINT "RecoveriesLongPk" UNIQUE ("ReportDate", "ProvinceCode"),
    CONSTRAINT "RecoveriesLongProvinceFk"
        FOREIGN KEY ("ProvinceCode") REFERENCES core."DimProvince" ("ProvinceCode"),
    CONSTRAINT "RecoveriesLongSourceFk"
        FOREIGN KEY ("SourceId") REFERENCES meta."Source" ("SourceId")
);

COMMENT ON TABLE stg."RecoveriesLong" IS
    'Unpivoted official recoveries. One row per report date per province. Values stay cumulative.';

-- 3C-1 check
-- SELECT table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'stg'
-- ORDER BY table_name;
--
-- SELECT COUNT(*) AS "RowCount" FROM stg."ConfirmedLong";
-- SELECT COUNT(*) AS "RowCount" FROM stg."RecoveriesLong";
-- Expect: ConfirmedLong, RecoveriesLong. Both counts 0.

-- ===========================================================================
-- 3C-2  Unpivot raw."Confirmed" into stg."ConfirmedLong"
-- ===========================================================================
--
-- DateText is DD-MM-YYYY (confirmed in Day 3A).
-- UNKNOWN in the official file is stored as "UnknownCount" in raw.
-- "Total" is a source roll-up, not a province. Do not unpivot it.
-- Empty province cells stay NULL. Do not turn them into 0.

TRUNCATE TABLE stg."ConfirmedLong";

INSERT INTO stg."ConfirmedLong" (
    "ReportDate", "DateText", "YearMonthDay",
    "ProvinceCode", "CumulativeValue", "SourceText", "SourceId"
)
SELECT TO_DATE(src."DateText", 'DD-MM-YYYY'), src."DateText", src."YearMonthDay",
       u."ProvinceCode", u."CumulativeValue", src."SourceText", 'SRC-001'
FROM raw."Confirmed" AS src
CROSS JOIN LATERAL (
    VALUES
        ('EC',      src."EC"),
        ('FS',      src."FS"),
        ('GP',      src."GP"),
        ('KZN',     src."KZN"),
        ('LP',      src."LP"),
        ('MP',      src."MP"),
        ('NC',      src."NC"),
        ('NW',      src."NW"),
        ('WC',      src."WC"),
        ('UNKNOWN', src."UnknownCount")
) AS u ("ProvinceCode", "CumulativeValue");

INSERT INTO meta."LoadLog" ("SourceId", "RowCount", "Status", "Message")
SELECT
    'SRC-001',
    COUNT(*),
    'success',
    'Day 3C unpivot raw.Confirmed -> stg.ConfirmedLong'
FROM stg."ConfirmedLong";

-- 3C-2 check
-- SELECT COUNT(*) AS "RowCount" FROM stg."ConfirmedLong";
-- -- expect 8640  (864 dates x 10 province codes)
--
-- SELECT "DateText", "ProvinceCode", "CumulativeValue"
-- FROM stg."ConfirmedLong"
-- WHERE "DateText" = '01-07-2021'
--   AND "ProvinceCode" = 'GP';
-- -- expect 662300

-- ===========================================================================
-- 3C-3  Unpivot raw."Recoveries" into stg."RecoveriesLong"
-- ===========================================================================

TRUNCATE TABLE stg."RecoveriesLong";

INSERT INTO stg."RecoveriesLong" (
    "ReportDate", "DateText", "YearMonthDay",
    "ProvinceCode", "CumulativeValue", "SourceText", "SourceId"
)
SELECT TO_DATE(src."DateText", 'DD-MM-YYYY'), src."DateText", src."YearMonthDay",
       u."ProvinceCode", u."CumulativeValue", src."SourceText", 'SRC-002'
FROM raw."Recoveries" AS src
CROSS JOIN LATERAL (
    VALUES
        ('EC',      src."EC"),
        ('FS',      src."FS"),
        ('GP',      src."GP"),
        ('KZN',     src."KZN"),
        ('LP',      src."LP"),
        ('MP',      src."MP"),
        ('NC',      src."NC"),
        ('NW',      src."NW"),
        ('WC',      src."WC"),
        ('UNKNOWN', src."UnknownCount")
) AS u ("ProvinceCode", "CumulativeValue");

INSERT INTO meta."LoadLog" ("SourceId", "RowCount", "Status", "Message")
SELECT
    'SRC-002',
    COUNT(*),
    'success',
    'Day 3C unpivot raw.Recoveries -> stg.RecoveriesLong'
FROM stg."RecoveriesLong";

-- 3C-3 check
-- SELECT COUNT(*) AS "RowCount" FROM stg."RecoveriesLong";
-- -- expect 8050  (805 dates x 10 province codes)
--
-- SELECT "DateText", "ProvinceCode", "CumulativeValue"
-- FROM stg."RecoveriesLong"
-- WHERE "DateText" = '01-07-2021'
--   AND "ProvinceCode" = 'GP';
-- -- expect 554529

-- ===========================================================================
-- 3C-4  End-of-section checks (run after 3C-2 and 3C-3)
-- ===========================================================================
--
-- -- no duplicate (date, province)
-- SELECT "ReportDate", "ProvinceCode", COUNT(*) AS "Dupes"
-- FROM stg."ConfirmedLong"
-- GROUP BY 1, 2
-- HAVING COUNT(*) > 1;
--
-- SELECT "ReportDate", "ProvinceCode", COUNT(*) AS "Dupes"
-- FROM stg."RecoveriesLong"
-- GROUP BY 1, 2
-- HAVING COUNT(*) > 1;
--
-- -- how many NULL cumulative cells survived the unpivot
-- SELECT
--     COUNT(*) FILTER (WHERE "CumulativeValue" IS NULL) AS "NullValues",
--     COUNT(*) FILTER (WHERE "CumulativeValue" IS NOT NULL) AS "FilledValues"
-- FROM stg."ConfirmedLong";
--
-- -- province codes in staging must all exist in DimProvince
-- SELECT DISTINCT l."ProvinceCode"
-- FROM stg."ConfirmedLong" AS l
-- LEFT JOIN core."DimProvince" AS p
--   ON p."ProvinceCode" = l."ProvinceCode"
-- WHERE p."ProvinceCode" IS NULL;
--
-- -- latest load_log rows
-- SELECT "LoadId", "SourceId", "LoadedAt", "RowCount", "Status", "Message"
-- FROM meta."LoadLog"
-- ORDER BY "LoadId" DESC
-- LIMIT 6;
