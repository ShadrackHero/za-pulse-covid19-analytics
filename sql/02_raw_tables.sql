-- ZA Pulse — Day 2A
-- Run this while connected to database: za_pulse
--
-- Naming rule (from Day 2 onward):
--   Schemas stay lowercase: raw, stg, core, meta  (created on Day 1)
--   Tables and columns are PascalCase and MUST be quoted.
--   Unquoted DimProvince becomes dimprovince in PostgreSQL. Always write "DimProvince".
--
-- This script only creates empty landing tables. No rows. No dimensions.

-- If the earlier snake_case draft was run, remove it first.
DROP TABLE IF EXISTS raw.confirmed;
DROP TABLE IF EXISTS raw.recoveries;
DROP TABLE IF EXISTS raw.deaths;
DROP TABLE IF EXISTS raw.vaccination;

DROP TABLE IF EXISTS raw."Confirmed";
DROP TABLE IF EXISTS raw."Recoveries";
DROP TABLE IF EXISTS raw."Deaths";
DROP TABLE IF EXISTS raw."Vaccination";

CREATE TABLE raw."Confirmed" (
    "DateText"      TEXT,      -- CSV "date"  (usually DD-MM-YYYY)
    "YearMonthDay"  TEXT,      -- CSV "YYYYMMDD"
    "EC"            BIGINT,
    "FS"            BIGINT,
    "GP"            BIGINT,
    "KZN"           BIGINT,
    "LP"            BIGINT,
    "MP"            BIGINT,
    "NC"            BIGINT,
    "NW"            BIGINT,
    "WC"            BIGINT,
    "UnknownCount"  BIGINT,    -- CSV "UNKNOWN"
    "Total"         BIGINT,
    "SourceText"    TEXT       -- CSV "source"
);

COMMENT ON TABLE raw."Confirmed" IS
    'Landing copy of covid19za_provincial_cumulative_timeline_confirmed.csv. Cumulative cases. Not daily new cases.';

CREATE TABLE raw."Recoveries" (
    "DateText"      TEXT,
    "YearMonthDay"  TEXT,
    "EC"            BIGINT,
    "FS"            BIGINT,
    "GP"            BIGINT,
    "KZN"           BIGINT,
    "LP"            BIGINT,
    "MP"            BIGINT,
    "NC"            BIGINT,
    "NW"            BIGINT,
    "WC"            BIGINT,
    "UnknownCount"  BIGINT,
    "Total"         BIGINT,
    "SourceText"    TEXT
);

COMMENT ON TABLE raw."Recoveries" IS
    'Landing copy of covid19za_provincial_cumulative_timeline_recoveries.csv. Cumulative recoveries.';

CREATE TABLE raw."Deaths" (
    "DateText"      TEXT,
    "YearMonthDay"  TEXT,
    "EC"            BIGINT,
    "FS"            BIGINT,
    "GP"            BIGINT,
    "KZN"           BIGINT,
    "LP"            BIGINT,
    "MP"            BIGINT,
    "NC"            BIGINT,
    "NW"            BIGINT,
    "WC"            BIGINT,
    "UnknownCount"  BIGINT,
    "Total"         BIGINT,
    "SourceText"    TEXT
);

COMMENT ON TABLE raw."Deaths" IS
    'Landing copy of covid19za_provincial_cumulative_timeline_deaths.csv. Cumulative deaths.';

CREATE TABLE raw."Vaccination" (
    "DateText"      TEXT,      -- this file uses YYYY-MM-DD in "date"
    "YearMonthDay"  TEXT,
    "EC"            BIGINT,
    "FS"            BIGINT,
    "GP"            BIGINT,
    "KZN"           BIGINT,
    "LP"            BIGINT,
    "MP"            BIGINT,
    "NC"            BIGINT,
    "NW"            BIGINT,
    "WC"            BIGINT,
    "Total"         BIGINT,
    "SourceText"    TEXT
);

COMMENT ON TABLE raw."Vaccination" IS
    'Landing copy of covid19za_provincial_cumulative_timeline_vaccination.csv. No UnknownCount column in the source file. Values are cumulative doses, not proven unique people.';
