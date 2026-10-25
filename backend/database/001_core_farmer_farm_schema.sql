-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 001_core_farmer_farm_schema.sql
-- Title: Core Farmer Identity & Parcel Geometry
-- Scope: Manages user credentials, farmer profiles, farm parcels with PostGIS boundary polygons and crop cultivation cycles.
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
-- Table: farmers
-- Comment: Central farmer profile registry with contact coordinates and kisan id
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS farmers (
    farmer_id                    UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_auth_id                 UUID                 NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name                    VARCHAR(150)         NOT NULL,
    phone_number                 VARCHAR(20)          NOT NULL UNIQUE,
    national_farmer_id           VARCHAR(64)          UNIQUE,
    primary_language_code        VARCHAR(10)          DEFAULT 'en',
    district_name                VARCHAR(100)         NOT NULL,
    state_name                   VARCHAR(100)         NOT NULL,
    country_code                 VARCHAR(3)           DEFAULT 'IND',
    postal_pincode               VARCHAR(12)          NOT NULL,
    is_verified_grower           BOOLEAN              DEFAULT FALSE,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP,
    updated_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE farmers IS 'Central farmer profile registry with contact coordinates and kisan id';

-- ----------------------------------------------------------------------------
-- Table: farm_parcels
-- Comment: Georeferenced agricultural fields and boundary shapefiles
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS farm_parcels (
    parcel_id                    UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id                    UUID                 NOT NULL REFERENCES farmers(farmer_id) ON DELETE CASCADE,
    parcel_name                  VARCHAR(120)         NOT NULL,
    total_acreage                NUMERIC(10, 2)       NOT NULL CHECK (total_acreage > 0),
    soil_texture_type            VARCHAR(50)          DEFAULT 'Clay Loam',
    soil_ph                      NUMERIC(4, 2)        CHECK (soil_ph BETWEEN 3.5 AND 10.0),
    soil_organic_carbon_pct      NUMERIC(5, 2)        DEFAULT 0.75,
    irrigation_source            VARCHAR(80)          DEFAULT 'Drip / Tube Well',
    boundary_geometry            GEOMETRY(Polygon, 4326) NOT NULL,
    centroid_point               GEOMETRY(Point, 4326) NOT NULL,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE farm_parcels IS 'Georeferenced agricultural fields and boundary shapefiles';

-- ----------------------------------------------------------------------------
-- Table: crop_cultivation_cycles
-- Comment: Seasonal planting, growth progression and harvest records
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS crop_cultivation_cycles (
    cycle_id                     UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    parcel_id                    UUID                 NOT NULL REFERENCES farm_parcels(parcel_id) ON DELETE CASCADE,
    crop_type                    VARCHAR(80)          NOT NULL,
    cultivar_variety             VARCHAR(100)         NOT NULL,
    sowing_date                  DATE                 NOT NULL,
    expected_harvest_date        DATE                 NOT NULL,
    actual_harvest_date          DATE                 NULL,
    current_phenological_stage   VARCHAR(50)          DEFAULT 'Vegetative',
    target_yield_quintals        NUMERIC(10, 2)       DEFAULT 50.0,
    achieved_yield_quintals      NUMERIC(10, 2)       NULL,
    is_active_cycle              BOOLEAN              DEFAULT TRUE
);

COMMENT ON TABLE crop_cultivation_cycles IS 'Seasonal planting, growth progression and harvest records';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_parcels_boundary_gist ON farm_parcels USING GIST (boundary_geometry);
CREATE INDEX IF NOT EXISTS idx_parcels_centroid_gist ON farm_parcels USING GIST (centroid_point);
CREATE INDEX IF NOT EXISTS idx_farmers_phone_trgm ON farmers USING GIN (phone_number gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_cycles_parcel_active ON crop_cultivation_cycles USING BTREE (parcel_id, is_active_cycle);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_calculate_parcel_area_hectares(p_parcel_id UUID)
RETURNS NUMERIC(12, 4)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    SELECT ST_Area(boundary_geometry::geography) / 10000.0 INTO v_rows_affected FROM farm_parcels WHERE parcel_id = p_parcel_id;
    RETURN COALESCE(v_rows_affected, 0.0);
END;
$$;

COMMIT;
