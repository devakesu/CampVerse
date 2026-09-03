CREATE OR REPLACE FUNCTION public.debug_session_info()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN jsonb_build_object(
        'current_user', current_user,
        'session_user', session_user,
        'jwt_claims', nullif(current_setting('request.jwt.claims', true), ''),
        'jwt_claim_role', nullif(current_setting('request.jwt.claim.role', true), ''),
        'is_server_role', public.is_server_role(),
        'auth_role', public.auth_role(),
        'auth_uid', auth.uid()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.debug_session_info() TO authenticated, anon, service_role;
