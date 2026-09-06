-- ==============================================================================
-- 8. VENUES (CAMPUS FACILITIES & LOCATIONS)
-- ==============================================================================
-- Migration: 20260906200000_create_venues_table.sql
--
-- Dedicated table for tracking campus venues per institute with case-insensitive
-- uniqueness, capacities, and access control.

CREATE TABLE IF NOT EXISTS public.venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES public.institutes(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    building TEXT,
    capacity INT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Case-insensitive uniqueness: "Block A" and "block a" shall not be allowed per institute
CREATE UNIQUE INDEX IF NOT EXISTS venues_institute_name_lower_idx
    ON public.venues (institute_id, LOWER(TRIM(name)));

-- Index for fast foreign key lookups by institute
CREATE INDEX IF NOT EXISTS idx_venues_institute
    ON public.venues (institute_id);

-- Auto-update updated_at timestamp trigger
CREATE TRIGGER set_timestamp_venues
    BEFORE UPDATE ON public.venues
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- Row Level Security (RLS)
ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Read active venues" ON public.venues
    FOR SELECT
    USING (
        (is_active = true) OR
        (auth_role() = 'super_admin'::app_role) OR
        ((institute_id = auth_institute_id()) AND (auth_role() = ANY (ARRAY['principal'::app_role, 'office_admin'::app_role])))
    );

CREATE POLICY "Manage venues" ON public.venues
    FOR ALL
    USING (
        (auth_role() = 'super_admin'::app_role) OR
        ((institute_id = auth_institute_id()) AND (auth_role() = ANY (ARRAY['principal'::app_role, 'office_admin'::app_role])))
    );

-- Table & Routine grants for client roles
GRANT ALL ON public.venues TO anon, authenticated, service_role;
