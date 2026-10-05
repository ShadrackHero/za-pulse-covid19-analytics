-- ZA Pulse — Day 3B
-- Run this while connected to database: za_pulse
--
-- Load official confirmed + recoveries into raw landing tables.
-- Edit the two file paths first. They must match the printout from the notebook.
--
-- COPY reads the file from THIS computer (local PostgreSQL on Windows).
-- Use forward slashes in the path.
--
-- Empty province cells in the official confirmed file become NULL, not 0.
-- That is the photocopy. Do not invent numbers in raw.

TRUNCATE TABLE raw."Confirmed";
TRUNCATE TABLE raw."Recoveries";

COPY raw."Confirmed" (
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
FROM 'C:/Users/shadr/Desktop/za-pulse-covid19-analytics/data/landing/confirmed.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '');

COPY raw."Recoveries" (
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
FROM 'C:/Users/shadr/Desktop/za-pulse-covid19-analytics/data/landing/recoveries.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '');

INSERT INTO meta."LoadLog" ("SourceId", "RowCount", "Status", "Message")
VALUES
    ('SRC-001', 864, 'success', 'Day 3 COPY official confirmed CSV into raw.Confirmed'),
    ('SRC-002', 805, 'success', 'Day 3 COPY official recoveries CSV into raw.Recoveries');
