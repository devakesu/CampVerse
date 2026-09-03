-- ==============================================================================
-- REFINE IS_SERVER_ROLE()
-- Migration: 20260903184800_refine_is_server_role.sql
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.is_server_role()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_jwt_role text;
BEGIN
    -- If request came through PostgREST / Supabase API, inspect JWT claim
    v_jwt_role := coalesce(
        nullif(current_setting('request.jwt.claim.role', true), ''),
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
    );

    IF v_jwt_role IS NOT NULL THEN
        RETURN (v_jwt_role = 'service_role');
    END IF;

    -- Direct DB connection (not via PostgREST authenticator)
    RETURN (session_user IN ('postgres', 'service_role', 'supabase_admin'));
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_server_role() TO authenticated, anon, service_role;
