-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 005_mandi_prices_and_market_trades.sql
-- Title: APMC Mandi Register & Commodity Pricing
-- Scope: Registers agricultural produce market yards, daily arrivals, modal auction rates and price trend forecasts.
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
-- Table: apmc_market_yards
-- Comment: Official agricultural market yards (Mandis) and administrative jurisdictions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS apmc_market_yards (
    market_yard_id               VARCHAR(64)          PRIMARY KEY,
    yard_name                    VARCHAR(150)         NOT NULL,
    district_name                VARCHAR(100)         NOT NULL,
    state_name                   VARCHAR(100)         NOT NULL,
    coordinates                  GEOMETRY(Point, 4326) NOT NULL,
    operating_days               VARCHAR(50)          DEFAULT 'Mon-Sat',
    is_enam_integrated           BOOLEAN              DEFAULT TRUE
);

COMMENT ON TABLE apmc_market_yards IS 'Official agricultural market yards (Mandis) and administrative jurisdictions';

-- ----------------------------------------------------------------------------
-- Table: daily_commodity_prices
-- Comment: Daily arrival volumes and trade price percentiles per commodity
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS daily_commodity_prices (
    price_record_id              BIGSERIAL            PRIMARY KEY,
    market_yard_id               VARCHAR(64)          NOT NULL REFERENCES apmc_market_yards(market_yard_id) ON DELETE CASCADE,
    trade_date                   DATE                 NOT NULL,
    commodity_name               VARCHAR(80)          NOT NULL,
    commodity_variety            VARCHAR(80)          DEFAULT 'Hybrid / Common',
    arrival_quantity_tonnes      NUMERIC(10, 2)       NOT NULL,
    minimum_price_per_quintal    NUMERIC(10, 2)       NOT NULL,
    maximum_price_per_quintal    NUMERIC(10, 2)       NOT NULL,
    modal_price_per_quintal      NUMERIC(10, 2)       NOT NULL,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE daily_commodity_prices IS 'Daily arrival volumes and trade price percentiles per commodity';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_mandi_prices_trade_date ON daily_commodity_prices USING BTREE (commodity_name, trade_date DESC);
CREATE INDEX IF NOT EXISTS idx_mandi_yards_geom ON apmc_market_yards USING GIST (coordinates);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_find_highest_paying_mandi_nearby(p_lat NUMERIC, p_lon NUMERIC, p_crop VARCHAR, p_radius_km NUMERIC)
RETURNS TABLE(yard_name VARCHAR, modal_price NUMERIC, dist_km NUMERIC)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    RETURN QUERY
    SELECT y.yard_name, p.modal_price_per_quintal,
           ROUND((ST_Distance(y.coordinates::geography, ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography) / 1000.0)::numeric, 2) AS dist_km
    FROM apmc_market_yards y
    JOIN daily_commodity_prices p ON y.market_yard_id = p.market_yard_id
    WHERE p.commodity_name ILIKE p_crop AND p.trade_date = CURRENT_DATE
      AND ST_DWithin(y.coordinates::geography, ST_SetSRID(ST_MakePoint(p_lon, p_lat), 4326)::geography, p_radius_km * 1000.0)
    ORDER BY p.modal_price_per_quintal DESC LIMIT 5;
END;
$$;

COMMIT;
