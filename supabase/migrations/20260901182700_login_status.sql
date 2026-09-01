-- ==============================================================================
-- LOGIN STATUS HELPERS
-- ==============================================================================
-- Migration: 20260901182700_login_status.sql
--
-- Design intent:
--   Profile creation is strictly admin-sided. There is no self-signup path.
--   Users who authenticate via Google OAuth or the publishable key without a
--   pre-existing profiles row will receive a 'no_profile' rejection from the
--   /auth/login-status endpoint and see a "contact your institution admin"
--   message. The orphan auth.users entries are cleaned up by the scheduled
--   cleanup_orphan_users.ts cron script (48-hour grace period).

-- ---------------------------------------------------------------------------
-- 1. Index on profiles(status) for fast account-status queries
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);

-- ---------------------------------------------------------------------------
-- 2. get_user_login_status(uid)
--    Returns base role, account status, and profile existence flag for a
--    given user ID. Called by the Deno /auth/login-status endpoint
--    immediately after Supabase authentication succeeds.
--
--    Returns profile_exists = FALSE when no profiles row is found —
--    the calling endpoint treats this as 'no_profile' (unauthorized).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_user_login_status(target_uid UUID)
RETURNS TABLE (
    base_role       app_role,
    account_status  account_status,
    profile_exists  BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.role          AS base_role,
        p.status        AS account_status,
        TRUE            AS profile_exists
    FROM public.profiles p
    WHERE p.id = target_uid;

    -- If no row was matched, return a sentinel row with profile_exists = FALSE.
    -- The caller must check this flag before trusting base_role / account_status.
    IF NOT FOUND THEN
        RETURN QUERY SELECT
            NULL::app_role       AS base_role,
            NULL::account_status AS account_status,
            FALSE                AS profile_exists;
    END IF;
END;
$$;

-- Grant execute to service_role (Deno backend uses the service role key)
GRANT EXECUTE ON FUNCTION public.get_user_login_status(UUID) TO service_role;

COMMENT ON FUNCTION public.get_user_login_status(UUID) IS
    'Returns base role, account status, and profile existence for a given '
    'user ID. Used by the Deno /auth/login-status endpoint to gate access '
    'after Supabase authentication succeeds. Returns profile_exists = FALSE '
    'for auth.users entries that have no corresponding profiles row '
    '(orphan accounts from Google OAuth or direct API calls — these are '
    'cleaned up by the cleanup_orphan_users.ts cron script).';
