-- ZA Pulse — Day 1B
-- Run this while connected to database: za_pulse
-- Creates the four schemas used for the rest of the project.

CREATE SCHEMA IF NOT EXISTS raw;   -- exact copies of source files
CREATE SCHEMA IF NOT EXISTS stg;   -- cleaned, unpivoted rows
CREATE SCHEMA IF NOT EXISTS core;  -- dimensions and facts for analysis
CREATE SCHEMA IF NOT EXISTS meta;  -- source registry, load log, manual notes

COMMENT ON SCHEMA raw  IS 'Landing zone. Do not clean data here.';
COMMENT ON SCHEMA stg  IS 'Staging. Typed and unpivoted.';
COMMENT ON SCHEMA core IS 'Star schema used by notebooks and Power BI.';
COMMENT ON SCHEMA meta IS 'Lineage, load history, manual observations.';
