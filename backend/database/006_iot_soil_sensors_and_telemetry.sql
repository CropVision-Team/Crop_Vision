-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 006_iot_soil_sensors_and_telemetry.sql
-- Title: Soil IoT Sensors & Time-Series Readings
-- Scope: LoRaWAN sensor registers, soil moisture probes, NPK electro-chemical sensors and battery diagnostics.
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
-- Table: soil_iot_devices
-- Comment: Hardware registry of in-field soil probes and gateway telemetry devices
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS soil_iot_devices (
    device_id                    VARCHAR(64)          PRIMARY KEY,
    parcel_id                    UUID                 NOT NULL REFERENCES farm_parcels(parcel_id) ON DELETE CASCADE,
    hardware_eui                 VARCHAR(64)          NOT NULL UNIQUE,
    device_model                 VARCHAR(80)          DEFAULT 'CropVision-SoilProbe-V3',
    firmware_version             VARCHAR(20)          DEFAULT '3.2.1',
    battery_charge_pct           NUMERIC(5, 2)        DEFAULT 98.5,
    probe_depth_cm               INTEGER              DEFAULT 30,
    is_active                    BOOLEAN              DEFAULT TRUE,
    installed_at                 TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE soil_iot_devices IS 'Hardware registry of in-field soil probes and gateway telemetry devices';

-- ----------------------------------------------------------------------------
-- Table: soil_telemetry_stream
-- Comment: Continuous telemetry readings of volumetric water content, EC, and NPK
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS soil_telemetry_stream (
    reading_id                   BIGSERIAL            PRIMARY KEY,
    device_id                    VARCHAR(64)          NOT NULL REFERENCES soil_iot_devices(device_id) ON DELETE CASCADE,
    recorded_at                  TIMESTAMPTZ          NOT NULL,
    volumetric_water_content_pct NUMERIC(5, 2)        NOT NULL,
    soil_temperature_celsius     NUMERIC(5, 2)        NOT NULL,
    electrical_conductivity_us_cm NUMERIC(7, 2)        NOT NULL,
    nitrogen_ppm                 NUMERIC(6, 2)        DEFAULT 45.0,
    phosphorus_ppm               NUMERIC(6, 2)        DEFAULT 22.0,
    potassium_ppm                NUMERIC(6, 2)        DEFAULT 180.0,
    battery_mv                   INTEGER              DEFAULT 3700
);

COMMENT ON TABLE soil_telemetry_stream IS 'Continuous telemetry readings of volumetric water content, EC, and NPK';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_telemetry_device_time ON soil_telemetry_stream USING BTREE (device_id, recorded_at DESC);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_check_irrigation_depletion_alert(p_device_id VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    DECLARE v_latest_vwc NUMERIC;
    BEGIN
    SELECT volumetric_water_content_pct INTO v_latest_vwc
    FROM soil_telemetry_stream WHERE device_id = p_device_id
    ORDER BY recorded_at DESC LIMIT 1;
    RETURN v_latest_vwc < 22.0;
    END;
END;
$$;

COMMIT;
