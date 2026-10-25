-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 007_satellite_remote_sensing_parcels.sql
-- Title: Satellite Remote Sensing & Vegetation Health
-- Scope: Stores Sentinel-2 scene references, cloud cover percentages, parcel NDVI time-series and stress polygons.
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
-- Table: satellite_tile_catalog
-- Comment: Index of multispectral scenes captured over agricultural clusters
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS satellite_tile_catalog (
    scene_id                     VARCHAR(100)         PRIMARY KEY,
    satellite_mission            VARCHAR(50)          DEFAULT 'Sentinel-2A',
    acquisition_datetime         TIMESTAMPTZ          NOT NULL,
    cloud_coverage_percentage    NUMERIC(5, 2)        NOT NULL,
    scene_footprint_geometry     GEOMETRY(Polygon, 4326) NOT NULL
);

COMMENT ON TABLE satellite_tile_catalog IS 'Index of multispectral scenes captured over agricultural clusters';

-- ----------------------------------------------------------------------------
-- Table: parcel_vegetation_indices
-- Comment: Extracted parcel-level mean NDVI, NDRE, EVI timeseries
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS parcel_vegetation_indices (
    index_record_id              BIGSERIAL            PRIMARY KEY,
    parcel_id                    UUID                 NOT NULL REFERENCES farm_parcels(parcel_id) ON DELETE CASCADE,
    scene_id                     VARCHAR(100)         NOT NULL REFERENCES satellite_tile_catalog(scene_id),
    observation_date             DATE                 NOT NULL,
    mean_ndvi                    NUMERIC(5, 4)        CHECK (mean_ndvi BETWEEN -1.0 AND 1.0),
    mean_ndre                    NUMERIC(5, 4)        CHECK (mean_ndre BETWEEN -1.0 AND 1.0),
    mean_evi                     NUMERIC(5, 4)        CHECK (mean_evi BETWEEN -1.0 AND 1.0),
    vegetation_vigor_category    VARCHAR(30)          DEFAULT 'Optimal',
    stressed_area_hectares       NUMERIC(8, 2)        DEFAULT 0.0
);

COMMENT ON TABLE parcel_vegetation_indices IS 'Extracted parcel-level mean NDVI, NDRE, EVI timeseries';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_parcel_ndvi_date ON parcel_vegetation_indices USING BTREE (parcel_id, observation_date DESC);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_detect_ndvi_drop_anomaly(p_parcel_id UUID)
RETURNS NUMERIC(6, 2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    DECLARE v_drop NUMERIC;
    BEGIN
    SELECT (lag(mean_ndvi) OVER (ORDER BY observation_date) - mean_ndvi) * 100.0
    INTO v_drop FROM parcel_vegetation_indices WHERE parcel_id = p_parcel_id
    ORDER BY observation_date DESC LIMIT 1;
    RETURN COALESCE(v_drop, 0.0);
    END;
END;
$$;

COMMIT;
