-- ZA Pulse — Day 4E
-- Run while connected to database: za_pulse
--
-- Five analyst notes. SRC-007.
-- Safe to re-run only if the same notes are not already present.

INSERT INTO meta."ManualObservation" (
    "ObsDate", "ProvinceCode", "Note", "CreatedBy"
)
SELECT s."ObsDate", s."ProvinceCode", s."Note", s."CreatedBy"
FROM (VALUES
    (
        DATE '2021-07-01',
        'GP',
        'Wave 3 (Delta) was already running. Use 1 Jul 2021 as the fixed golden-row date across confirmed, recoveries, deaths and vaccination.',
        'Shadreck Ngomane'
    ),
    (
        DATE '2021-03-21',
        'GP',
        'Human Rights Day and other public holidays often show reporting lag. A flat or missing day is not automatically a real drop in incidence.',
        'Shadreck Ngomane'
    ),
    (
        DATE '2021-02-17',
        'WC',
        'Vaccination series starts 17 Feb 2021. Early provincial cells are often blank. Treat vaccination as cumulative doses, not unique people.',
        'Shadreck Ngomane'
    ),
    (
        DATE '2020-03-05',
        'UNKNOWN',
        'UNKNOWN is unallocated cases, not a tenth province. Do not give it a population. Do not add it into a national roll-up if Total already exists on the source row.',
        'Shadreck Ngomane'
    ),
    (
        DATE '2021-07-01',
        'KZN',
        'Official provincial files are cumulative. Daily new cases must be computed later with LAG. A one-day fall in the cumulative series is a revision, not negative incidence.',
        'Shadreck Ngomane'
    )
) AS s ("ObsDate", "ProvinceCode", "Note", "CreatedBy")
WHERE NOT EXISTS (
    SELECT 1
    FROM meta."ManualObservation" AS m
    WHERE m."ObsDate" = s."ObsDate"
      AND m."ProvinceCode" = s."ProvinceCode"
      AND m."Note" = s."Note"
);

INSERT INTO meta."LoadLog" ("SourceId", "RowCount", "Status", "Message")
SELECT
    'SRC-007',
    5,
    'success',
    'Day 4E five manual observations typed in pgAdmin'
WHERE NOT EXISTS (
    SELECT 1
    FROM meta."LoadLog"
    WHERE "Message" = 'Day 4E five manual observations typed in pgAdmin'
);
