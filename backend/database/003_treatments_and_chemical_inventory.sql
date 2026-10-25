-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 003_treatments_and_chemical_inventory.sql
-- Title: Chemical Registry & Spray Compliance
-- Scope: Stores chemical active ingredients, FRAC codes, pre-harvest intervals and farmer application logs.
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
-- Table: agrochemical_master
-- Comment: Standardized repository of fungicides, bactericides and biologicals
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agrochemical_master (
    chemical_id                  VARCHAR(64)          PRIMARY KEY,
    active_ingredient            VARCHAR(120)         NOT NULL,
    chemical_family              VARCHAR(100)         NOT NULL,
    frac_group_code              VARCHAR(20)          NOT NULL,
    commercial_formulation_type  VARCHAR(50)          NOT NULL,
    default_rate_per_hectare     VARCHAR(80)          NOT NULL,
    water_volume_l_ha            INTEGER              DEFAULT 400,
    pre_harvest_interval_days    INTEGER              NOT NULL DEFAULT 7,
    restricted_entry_interval_hours INTEGER              NOT NULL DEFAULT 24,
    max_sequential_sprays        INTEGER              DEFAULT 2,
    is_organic_certified         BOOLEAN              DEFAULT FALSE,
    is_banned_restricted         BOOLEAN              DEFAULT FALSE
);

COMMENT ON TABLE agrochemical_master IS 'Standardized repository of fungicides, bactericides and biologicals';

-- ----------------------------------------------------------------------------
-- Table: farmer_spray_applications
-- Comment: Verified logs of chemical and bio-fungicide sprays applied on field
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS farmer_spray_applications (
    spray_event_id               UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    parcel_id                    UUID                 NOT NULL REFERENCES farm_parcels(parcel_id) ON DELETE CASCADE,
    diagnosis_id                 UUID                 REFERENCES leaf_diagnoses(diagnosis_id) ON DELETE SET NULL,
    chemical_id                  VARCHAR(64)          NOT NULL REFERENCES agrochemical_master(chemical_id),
    product_brand_name           VARCHAR(120)         NOT NULL,
    total_tank_mix_liters        NUMERIC(10, 2)       NOT NULL,
    total_product_quantity_kg_l  NUMERIC(10, 3)       NOT NULL,
    application_date             DATE                 NOT NULL,
    wind_speed_during_spray_kmh  NUMERIC(5, 2)        DEFAULT 5.0,
    nozzle_pressure_bar          NUMERIC(5, 2)        DEFAULT 3.0,
    operator_protective_gear_worn BOOLEAN              DEFAULT TRUE,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE farmer_spray_applications IS 'Verified logs of chemical and bio-fungicide sprays applied on field';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_chemical_frac_code ON agrochemical_master USING BTREE (frac_group_code);
CREATE INDEX IF NOT EXISTS idx_spray_parcel_date ON farmer_spray_applications USING BTREE (parcel_id, application_date DESC);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_check_chemical_rotation_safety(p_parcel_id UUID, p_new_frac VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    DECLARE v_consecutive INTEGER;
    BEGIN
    SELECT COUNT(*) INTO v_consecutive FROM (
        SELECT m.frac_group_code FROM farmer_spray_applications s
        JOIN agrochemical_master m ON s.chemical_id = m.chemical_id
        WHERE s.parcel_id = p_parcel_id
        ORDER BY s.application_date DESC LIMIT 2
    ) sub WHERE sub.frac_group_code = p_new_frac;
    RETURN v_consecutive < 2;
    END;
END;
$$;

COMMIT;
