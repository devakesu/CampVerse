-- ==============================================================================
-- UPDATE PERMISSIONS FOR ORGANIZATIONS STORAGE BUCKET
-- Migration: 20260905203000_organizations_storage_permissions.sql
-- ==============================================================================
-- Permissions:
-- 1. SELECT (Read): Public read access for all logos & assets in 'organizations' bucket.
-- 2. INSERT / UPDATE / DELETE (Write/Manage):
--    - super_admin
--    - principal (within their institute)
--    - office_admin (within their institute)
--    - organization_members who belong to the same org_id (folder matching path `org_id/*`)
--      AND hold member_role in ('lead', 'core_member') with is_active = TRUE
--    - server / service_role

-- Helper function to check if current user is an active lead or core_member of org
CREATE OR REPLACE FUNCTION public.can_manage_org_assets(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT (
        public.is_server_role()
        OR public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.organizations o
            WHERE o.id = target_org_id
              AND (
                  (o.institute_id = public.auth_institute_id() AND public.auth_role() IN ('principal', 'office_admin'))
                  OR o.lead_id = auth.uid()
                  OR EXISTS (
                      SELECT 1 FROM public.organization_members om
                      WHERE om.org_id = target_org_id
                        AND om.user_id = auth.uid()
                        AND om.is_active = TRUE
                        AND om.role IN ('lead', 'core_member')
                  )
              )
        )
    );
$$;

GRANT EXECUTE ON FUNCTION public.can_manage_org_assets(UUID) TO authenticated, anon, service_role;

-- Helper to safely extract org UUID from storage object path (e.g., '<org_id>/logo.png')
CREATE OR REPLACE FUNCTION public.storage_path_org_id(name TEXT)
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    first_part TEXT;
BEGIN
    first_part := split_part(name, '/', 1);
    RETURN first_part::UUID;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.storage_path_org_id(TEXT) TO authenticated, anon, service_role;

-- Replace policies on storage.objects for 'organizations' bucket
DROP POLICY IF EXISTS "Authorized upload organization logos" ON storage.objects;
DROP POLICY IF EXISTS "Authorized update organization logos" ON storage.objects;
DROP POLICY IF EXISTS "Authorized delete organization logos" ON storage.objects;
DROP POLICY IF EXISTS "Manage organization assets" ON storage.objects;

-- INSERT Policy
CREATE POLICY "Authorized upload organization logos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'organizations'
        AND public.can_manage_org_assets(public.storage_path_org_id(name))
    );

-- UPDATE Policy
CREATE POLICY "Authorized update organization logos"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'organizations'
        AND public.can_manage_org_assets(public.storage_path_org_id(name))
    )
    WITH CHECK (
        bucket_id = 'organizations'
        AND public.can_manage_org_assets(public.storage_path_org_id(name))
    );

-- DELETE Policy
CREATE POLICY "Authorized delete organization logos"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'organizations'
        AND public.can_manage_org_assets(public.storage_path_org_id(name))
    );
