-- ZA Pulse — Day 4C
-- Run this while connected to database: za_pulse
--
-- raw."Deaths"       -> stg."DeathsLong"
-- raw."Vaccination"  -> stg."VaccinationLong"
--
-- Deaths DateText is DD-MM-YYYY (slashes also parse).
-- Vaccination DateText is YYYY-MM-DD.
-- Vaccination has no UNKNOWN province column.
-- Values stay cumulative. Vaccine numbers are doses, not unique people.

-- ===========================================================================
-- 4C-1  Create empty staging tables
-- ===========================================================================

DROP TABLE IF EXISTS stg."DeathsLong";
DROP TABLE IF EXISTS stg."VaccinationLong";
DROP TABLE IF EXISTS stg.deaths_long;
DROP TABLE IF EXISTS stg.vaccination_long;

CREATE TABLE stg."DeathsLong" (
    "ReportDate"        DATE         NOT NULL,
    "DateText"          TEXT         NOT NULL,
    "YearMonthDay"      TEXT,
    "ProvinceCode"      VARCHAR(10)  NOT NULL,
    "CumulativeValue"   BIGINT,
    "SourceText"        TEXT,
    "SourceId"          VARCHAR(16)  NOT NULL DEFAULT 'SRC-004',
    CONSTRAINT "DeathsLongPk" UNIQUE ("ReportDate", "ProvinceCode"),
    CONSTRAINT "DeathsLongProvinceFk"
        FOREIGN KEY ("ProvinceCode") REFERENCES core."DimProvince" ("ProvinceCode"),
    CONSTRAINT "DeathsLongSourceFk"
        FOREIGN KEY ("SourceId") REFERENCES meta."Source" ("SourceId")
);

COMMENT ON TABLE stg."DeathsLong" IS
    'Unpivoted official deaths. One row per report date per province. Values stay cumulative.';

CREATE TABLE stg."VaccinationLong" (
    "ReportDate"        DATE         NOT NULL,
    "DateText"          TEXT         NOT NULL,
    "YearMonthDay"      TEXT,
    "ProvinceCode"      VARCHAR(10)  NOT NULL,
    "CumulativeValue"   BIGINT,
    "SourceText"        TEXT,
    "SourceId"          VARCHAR(16)  NOT NULL DEFAULT 'SRC-003',
    CONSTRAINT "VaccinationLongPk" UNIQUE ("ReportDate", "ProvinceCode"),
    CONSTRAINT "VaccinationLongProvinceFk"
        FOREIGN KEY ("ProvinceCode") REFERENCES core."DimProvince" ("ProvinceCode"),
    CONSTRAINT "VaccinationLongSourceFk"
        FOREIGN KEY ("SourceId") REFERENCES meta."Source" ("SourceId")
);

COMMENT ON TABLE stg."VaccinationLong" IS
    'Unpivoted official vaccination. Cumulative doses, not proven unique people. No UNKNOWN province.';

-- ===========================================================================
-- 4C-2  Unpivot deaths
-- ===========================================================================

TRUNCATE TABLE stg."DeathsLong";

INSERT INTO stg."DeathsLong" (
    "ReportDate", "DateText", "YearMonthDay",
    "ProvinceCode", "CumulativeValue", "SourceText", "SourceId"
)
SELECT TO_DATE(src."DateText", 'DD-MM-YYYY'), src."DateText", src."YearMonthDay",
       u."ProvinceCode", u."CumulativeValue", src."SourceText", 'SRC-004'
FROM raw."Deaths" AS src
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
    'SRC-004',
    COUNT(*),
    'success',
    'Day 4C unpivot raw.Deaths -> stg.DeathsLong'
FROM stg."DeathsLong";

-- ===========================================================================
-- 4C-3  Unpivot vaccination (no UNKNOWN, ISO dates)
-- ===========================================================================

TRUNCATE TABLE stg."VaccinationLong";

INSERT INTO stg."VaccinationLong" (
    "ReportDate", "DateText", "YearMonthDay",
    "ProvinceCode", "CumulativeValue", "SourceText", "SourceId"
)
SELECT TO_DATE(src."DateText", 'YYYY-MM-DD'), src."DateText", src."YearMonthDay",
       u."ProvinceCode", u."CumulativeValue", src."SourceText", 'SRC-003'
FROM raw."Vaccination" AS src
CROSS JOIN LATERAL (
    VALUES
        ('EC',  src."EC"),
        ('FS',  src."FS"),
        ('GP',  src."GP"),
        ('KZN', src."KZN"),
        ('LP',  src."LP"),
        ('MP',  src."MP"),
        ('NC',  src."NC"),
        ('NW',  src."NW"),
        ('WC',  src."WC")
) AS u ("ProvinceCode", "CumulativeValue");

INSERT INTO meta."LoadLog" ("SourceId", "RowCount", "Status", "Message")
SELECT
    'SRC-003',
    COUNT(*),
    'success',
    'Day 4C unpivot raw.Vaccination -> stg.VaccinationLong'
FROM stg."VaccinationLong";
