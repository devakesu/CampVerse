-- ==============================================================================
-- AUTH HELPER PERMISSIONS & RPC GRANTS
-- ==============================================================================
-- Migration: 20260901200000_auth_grants.sql

-- Grant execute permissions on role derivation and login status functions
-- to ensure direct client fallback RPCs succeed without permission errors.

GRANT EXECUTE ON FUNCTION public.get_user_derived_roles(UUID) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.get_user_login_status(UUID) TO authenticated, anon, service_role;
