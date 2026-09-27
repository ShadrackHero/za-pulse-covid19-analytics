-- ZA Pulse — Day 4D
-- Run while connected to database: za_pulse
--
-- SRC-005: Stats SA mid-year population estimates 2021 (P0302).
-- One snapshot, not a time series. UNKNOWN stays NULL.
-- National total in the publication is 60 142 978 / 60 142 979 (rounding).
-- We do not insert a ZA row. Power BI will sum the nine provinces.

UPDATE core."DimProvince" AS p
SET "Population" = s."Population"
FROM (VALUES
    ('EC',  6676590),
    ('FS',  2932441),
    ('GP',  15810388),
    ('KZN', 11513575),
    ('LP',  5926724),
    ('MP',  4743584),
    ('NC',  1303047),
    ('NW',  4122854),
    ('WC',  7113776)
) AS s ("ProvinceCode", "Population")
WHERE p."ProvinceCode" = s."ProvinceCode";

UPDATE core."DimProvince"
SET "Population" = NULL
WHERE "ProvinceCode" = 'UNKNOWN';

INSERT INTO meta."LoadLog" ("SourceId", "RowCount", "Status", "Message")
VALUES (
    'SRC-005',
    9,
    'success',
    'Day 4D Stats SA 2021 P0302 mid-year population onto DimProvince. UNKNOWN left NULL.'
);
