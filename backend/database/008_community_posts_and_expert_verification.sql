-- ============================================================================
-- CropVision Enterprise Database Architecture
-- File: 008_community_posts_and_expert_verification.sql
-- Title: Farmer Community Knowledge Hub
-- Scope: Social forum posts, image carousels, certified agronomist verified stamps, comments and upvoting.
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
-- Table: community_discussions
-- Comment: Farmer-submitted field queries, pest outbreaks, and cultivation advice
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS community_discussions (
    discussion_id                UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_farmer_id             UUID                 NOT NULL REFERENCES farmers(farmer_id) ON DELETE CASCADE,
    crop_subject                 VARCHAR(80)          NOT NULL,
    title                        VARCHAR(200)         NOT NULL,
    body_content                 TEXT                 NOT NULL,
    attached_media_urls          TEXT[]               DEFAULT '{}',
    upvotes_count                INTEGER              DEFAULT 0,
    is_resolved_by_expert        BOOLEAN              DEFAULT FALSE,
    expert_verifier_notes        TEXT                 NULL,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE community_discussions IS 'Farmer-submitted field queries, pest outbreaks, and cultivation advice';

-- ----------------------------------------------------------------------------
-- Table: discussion_responses
-- Comment: Peer farmer comments and agronomist clinical prescriptions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS discussion_responses (
    response_id                  UUID                 PRIMARY KEY DEFAULT uuid_generate_v4(),
    discussion_id                UUID                 NOT NULL REFERENCES community_discussions(discussion_id) ON DELETE CASCADE,
    responder_farmer_id          UUID                 NOT NULL REFERENCES farmers(farmer_id) ON DELETE CASCADE,
    response_text                TEXT                 NOT NULL,
    is_certified_agronomist_answer BOOLEAN              DEFAULT FALSE,
    upvotes_count                INTEGER              DEFAULT 0,
    created_at                   TIMESTAMPTZ          DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE discussion_responses IS 'Peer farmer comments and agronomist clinical prescriptions';

-- ============================================================================
-- Performance Optimization & Spatial Indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_discussions_crop_time ON community_discussions USING BTREE (crop_subject, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_responses_disc_time ON discussion_responses USING BTREE (discussion_id, created_at ASC);

-- ============================================================================
-- Pl/pgSQL Business Logic Stored Procedures & Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_upvote_discussion(p_discussion_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_rows_affected INTEGER := 0;
BEGIN
    UPDATE community_discussions SET upvotes_count = upvotes_count + 1 WHERE discussion_id = p_discussion_id RETURNING upvotes_count INTO v_rows_affected;
    RETURN v_rows_affected;
END;
$$;

COMMIT;
