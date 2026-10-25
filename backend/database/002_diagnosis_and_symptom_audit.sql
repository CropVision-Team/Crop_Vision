-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 002_diagnosis_and_symptom_audit.sql
-- Title: Plant Disease Diagnostic Telemetry
-- Scope: Audits raw smartphone leaf scans, MobileViT inference confidence logs, and bounding box coordinates.
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
-- Table: leaf_diagnoses
-- Comment: Central historical ledger of all plant disease diagnostic events
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS leaf_diagnoses (
    diagnosis_id                 UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id                    UUID                 NOT NULL REFERENCES farmers(farmer_id) ON DELETE CASCADE,
    parcel_id                    UUID                 REFERENCES farm_parcels(parcel_id) ON DELETE SET NULL,
    crop_type                    VARCHAR(80)          NOT NULL,
    predicted_disease_id         VARCHAR(100)         NOT NULL,
    model_confidence_score       NUMERIC(6, 4)        NOT NULL CHECK (model_confidence_score BETWEEN 0.0 AND 1.0),
    top3_predictions_json        JSONB                NOT NULL DEFAULT '{}'::jsonb,
    severity_tier                VARCHAR(30)          DEFAULT 'Moderate',
    infected_leaf_surface_pct    NUMERIC(5, 2)        CHECK (infected_leaf_surface_pct BETWEEN 0.0 AND 100.0),
    image_storage_uri            VARCHAR(500)         NOT NULL,
    image_sha256_hash            VARCHAR(64)          NOT NULL,
    gps_capture_location         GEOMETRY(Point, 4326) NULL,
    client_app_version           VARCHAR(20)          DEFAULT '2.4.0',
    is_verified_by_expert        BOOLEAN              DEFAULT FALSE,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE leaf_diagnoses IS 'Central historical ledger of all plant disease diagnostic events';

-- ----------------------------------------------------------------------------
-- Table: diagnosis_bounding_boxes
-- Comment: Detected lesion coordinates and Grad-CAM attention regions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS diagnosis_bounding_boxes (
    box_id                       UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    diagnosis_id                 UUID                 NOT NULL REFERENCES leaf_diagnoses(diagnosis_id) ON DELETE CASCADE,
    lesion_class                 VARCHAR(80)          NOT NULL,
    box_x_min                    NUMERIC(6, 4)        NOT NULL,
    box_y_min                    NUMERIC(6, 4)        NOT NULL,
    box_x_max                    NUMERIC(6, 4)        NOT NULL,
    box_y_max                    NUMERIC(6, 4)        NOT NULL,
    lesion_confidence            NUMERIC(6, 4)        NOT NULL
);

COMMENT ON TABLE diagnosis_bounding_boxes IS 'Detected lesion coordinates and Grad-CAM attention regions';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_diagnoses_farmer_created ON leaf_diagnoses USING BTREE (farmer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_diagnoses_disease_btree ON leaf_diagnoses USING BTREE (predicted_disease_id);
CREATE INDEX IF NOT EXISTS idx_diagnoses_gps_gist ON leaf_diagnoses USING GIST (gps_capture_location);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_get_recent_outbreaks_within_radius(p_point GEOMETRY, p_radius_km NUMERIC, p_days INTEGER)
RETURNS TABLE(disease_id VARCHAR, cases_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    RETURN QUERY
    SELECT predicted_disease_id, COUNT(*) AS cases
    FROM leaf_diagnoses
    WHERE ST_DWithin(gps_capture_location::geography, p_point::geography, p_radius_km * 1000.0)
      AND created_at >= (CURRENT_TIMESTAMP - (p_days || ' days')::INTERVAL)
    GROUP BY predicted_disease_id ORDER BY cases DESC;
END;
$$;

COMMIT;
