-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 004_weather_stations_and_epidemic_risks.sql
-- Title: Meteorological Stations & Microclimate Risk
-- Scope: Tracks hourly automated weather telemetry, Mills fungal infection hours, and microclimate risk indices.
-- PostgreSQL 15+ / PostGIS 3.3+ / Supabase Schema Migration
-- Author: RIPAN SAMUI <ripansamuix08@users.noreply.github.com>
-- ============================================================================

BEGIN;

-- Enable necessary enterprise extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- ----------------------------------------------------------------------------
-- Table: weather_stations
-- Comment: Automated IoT and national weather service telemetry stations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS weather_stations (
    station_id                   VARCHAR(64)          PRIMARY KEY,
    station_name                 VARCHAR(120)         NOT NULL,
    station_type                 VARCHAR(50)          DEFAULT 'IoT Micro-Station',
    coordinates                  GEOMETRY(Point, 4326) NOT NULL,
    elevation_meters             NUMERIC(8, 2)        DEFAULT 250.0,
    is_operational               BOOLEAN              DEFAULT TRUE,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE weather_stations IS 'Automated IoT and national weather service telemetry stations';

-- ----------------------------------------------------------------------------
-- Table: hourly_weather_observations
-- Comment: Time-series observations of temperature, humidity, and rainfall
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS hourly_weather_observations (
    observation_id               BIGSERIAL            PRIMARY KEY,
    station_id                   VARCHAR(64)          NOT NULL REFERENCES weather_stations(station_id) ON DELETE CASCADE,
    recorded_at                  TIMESTAMPTZ          NOT NULL,
    temperature_celsius          NUMERIC(5, 2)        NOT NULL,
    relative_humidity_pct        NUMERIC(5, 2)        NOT NULL CHECK (relative_humidity_pct BETWEEN 0.0 AND 100.0),
    dew_point_celsius            NUMERIC(5, 2)        NOT NULL,
    leaf_wetness_minutes         INTEGER              CHECK (leaf_wetness_minutes BETWEEN 0 AND 60),
    rainfall_mm                  NUMERIC(6, 2)        DEFAULT 0.0,
    wind_speed_kmh               NUMERIC(5, 2)        DEFAULT 0.0,
    solar_radiation_w_m2         NUMERIC(7, 2)        DEFAULT 0.0
);

COMMENT ON TABLE hourly_weather_observations IS 'Time-series observations of temperature, humidity, and rainfall';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_weather_station_time ON hourly_weather_observations USING BTREE (station_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_weather_stations_geom ON weather_stations USING GIST (coordinates);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_calculate_cumulative_leaf_wetness_24h(p_station_id VARCHAR)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    DECLARE v_total_mins INTEGER;
    BEGIN
    SELECT COALESCE(SUM(leaf_wetness_minutes), 0) INTO v_total_mins
    FROM hourly_weather_observations
    WHERE station_id = p_station_id AND recorded_at >= (CURRENT_TIMESTAMP - INTERVAL '24 hours');
    RETURN v_total_mins;
    END;
END;
$$;

COMMIT;
