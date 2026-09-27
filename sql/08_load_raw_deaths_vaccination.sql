-- ZA Pulse — Day 4B
-- Run this while connected to database: za_pulse
--
-- Deaths COPY is a straight BIGINT load.
-- Vaccination exported from pandas often has 5.0 instead of 5.
-- Land vaccination as TEXT first, then cast 5.0 -> 5.

TRUNCATE TABLE raw."Deaths";
TRUNCATE TABLE raw."Vaccination";

COPY raw."Deaths" (
    "DateText",
    "YearMonthDay",
    "EC",
    "FS",
    "GP",
    "KZN",
    "LP",
    "MP",
    "NC",
    "NW",
    "WC",
    "UnknownCount",
    "Total",
    "SourceText"
)
FROM 'C:/Users/shadr/Desktop/za-pulse-covid19-analytics/data/landing/deaths.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '');

DROP TABLE IF EXISTS raw."VaccinationText";
CREATE TABLE raw."VaccinationText" (
    "DateText"      TEXT,
    "YearMonthDay"  TEXT,
    "EC"            TEXT,
    "FS"            TEXT,
    "GP"            TEXT,
    "KZN"           TEXT,
    "LP"            TEXT,
    "MP"            TEXT,
    "NC"            TEXT,
    "NW"            TEXT,
    "WC"            TEXT,
    "Total"         TEXT,
    "SourceText"    TEXT
);

COPY raw."VaccinationText" (
    "DateText",
    "YearMonthDay",
    "EC",
    "FS",
    "GP",
    "KZN",
    "LP",
    "MP",
    "NC",
    "NW",
    "WC",
    "Total",
    "SourceText"
)
FROM 'C:/Users/shadr/Desktop/za-pulse-covid19-analytics/data/landing/vaccination.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '');

INSERT INTO raw."Vaccination" (
    "DateText", "YearMonthDay",
    "EC", "FS", "GP", "KZN", "LP", "MP", "NC", "NW", "WC",
    "Total", "SourceText"
)
SELECT
    "DateText",
    "YearMonthDay",
    NULLIF("EC",   '')::numeric::bigint,
    NULLIF("FS",   '')::numeric::bigint,
    NULLIF("GP",   '')::numeric::bigint,
    NULLIF("KZN",  '')::numeric::bigint,
    NULLIF("LP",   '')::numeric::bigint,
    NULLIF("MP",   '')::numeric::bigint,
    NULLIF("NC",   '')::numeric::bigint,
    NULLIF("NW",   '')::numeric::bigint,
    NULLIF("WC",   '')::numeric::bigint,
    NULLIF("Total",'')::numeric::bigint,
    "SourceText"
FROM raw."VaccinationText";

DROP TABLE raw."VaccinationText";

INSERT INTO meta."LoadLog" ("SourceId", "RowCount", "Status", "Message")
VALUES
    ('SRC-004', 828, 'success', 'Day 4 COPY official deaths CSV into raw.Deaths'),
    ('SRC-003', 657, 'success', 'Day 4 COPY official vaccination CSV into raw.Vaccination (cast pandas floats)');
