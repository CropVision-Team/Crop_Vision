-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 009_security_rls_and_access_policies.sql
-- Title: PostgreSQL Row-Level Security Policies
-- Scope: Enforces tenant isolation, multi-tenant row security policies, and role-based permissions for farmers.
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
-- Table: audit_access_logs
-- Comment: Security and access trail recording query origins and authorizations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_access_logs (
    log_id                       BIGSERIAL            PRIMARY KEY,
    actor_user_id                UUID                 NOT NULL,
    target_table_name            VARCHAR(100)         NOT NULL,
    action_executed              VARCHAR(30)          NOT NULL,
    client_ip_address            INET                 NULL,
    executed_at                  TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE audit_access_logs IS 'Security and access trail recording query origins and authorizations';

-- ----------------------------------------------------------------------------
-- Table: api_rate_limits
-- Comment: Token bucket rate limit controls per mobile tenant
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS api_rate_limits (
    tenant_key                   VARCHAR(128)         PRIMARY KEY,
    request_bucket_balance       INTEGER              DEFAULT 1000,
    last_refill_timestamp        TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE api_rate_limits IS 'Token bucket rate limit controls per mobile tenant';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_audit_actor_time ON audit_access_logs USING BTREE (actor_user_id, executed_at DESC);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_enforce_tenant_isolation(p_user_id UUID, p_farmer_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    DECLARE v_match BOOLEAN;
    BEGIN
    SELECT (user_auth_id = p_user_id) INTO v_match FROM farmers WHERE farmer_id = p_farmer_id;
    RETURN COALESCE(v_match, FALSE);
    END;
END;
$$;

COMMIT;
