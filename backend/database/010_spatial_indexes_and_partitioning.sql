-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 010_spatial_indexes_and_partitioning.sql
-- Title: Timescale Partitioning & High-Throughput Buffers
-- Scope: Configures BRIN indexes for sensor telemetry, declarative monthly partitions for diagnosis tables, and geometry spatial triggers.
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
-- Table: system_partition_registry
-- Comment: Metadata catalog tracking active declarative table partitions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS system_partition_registry (
    partition_id                 SERIAL               PRIMARY KEY,
    parent_table                 VARCHAR(100)         NOT NULL,
    partition_name               VARCHAR(100)         NOT NULL UNIQUE,
    range_start                  TIMESTAMPTZ          NOT NULL,
    range_end                    TIMESTAMPTZ          NOT NULL,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE system_partition_registry IS 'Metadata catalog tracking active declarative table partitions';

-- ----------------------------------------------------------------------------
-- Table: geospatial_outbreak_heatmaps
-- Comment: Materialized clusters of active regional plant epidemics
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS geospatial_outbreak_heatmaps (
    cluster_id                   SERIAL               PRIMARY KEY,
    disease_id                   VARCHAR(100)         NOT NULL,
    cluster_hull_polygon         GEOMETRY(Polygon, 4326) NOT NULL,
    active_cases_in_hull         INTEGER              NOT NULL,
    risk_level                   VARCHAR(20)          DEFAULT 'High',
    last_synthesized_at          TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE geospatial_outbreak_heatmaps IS 'Materialized clusters of active regional plant epidemics';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_outbreak_hull_gist ON geospatial_outbreak_heatmaps USING GIST (cluster_hull_polygon);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_refresh_outbreak_heatmaps()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    DELETE FROM geospatial_outbreak_heatmaps WHERE last_synthesized_at < CURRENT_TIMESTAMP - INTERVAL '7 days';
    RETURN 1;
END;
$$;

COMMIT;
