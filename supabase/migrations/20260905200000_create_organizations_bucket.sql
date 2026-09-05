-- ==============================================================================
-- CREATE STORAGE BUCKET FOR ORGANIZATIONS (LOGOS & ASSETS)
-- Migration: 20260905200000_create_organizations_bucket.sql
-- ==============================================================================

-- 1. Insert organizations bucket into storage.buckets if not already existing
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'organizations',
    'organizations',
    true,
    10485760, -- 10MB
    ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/svg+xml', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Storage RLS Policies for organizations bucket
-- Anyone (authenticated or public) can view organization logos & assets
DROP POLICY IF EXISTS "Public view organization logos" ON storage.objects;
CREATE POLICY "Public view organization logos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'organizations');

-- Staff/Admin or Super Admin or Org Lead can upload/modify organization logos
DROP POLICY IF EXISTS "Authorized upload organization logos" ON storage.objects;
CREATE POLICY "Authorized upload organization logos"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'organizations'
        AND (
            public.is_server_role()
            OR public.auth_role() = 'super_admin'
            OR public.auth_role() IN ('principal', 'office_admin')
        )
    );

DROP POLICY IF EXISTS "Authorized update organization logos" ON storage.objects;
CREATE POLICY "Authorized update organization logos"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'organizations'
        AND (
            public.is_server_role()
            OR public.auth_role() = 'super_admin'
            OR public.auth_role() IN ('principal', 'office_admin')
        )
    )
    WITH CHECK (
        bucket_id = 'organizations'
        AND (
            public.is_server_role()
            OR public.auth_role() = 'super_admin'
            OR public.auth_role() IN ('principal', 'office_admin')
        )
    );

DROP POLICY IF EXISTS "Authorized delete organization logos" ON storage.objects;
CREATE POLICY "Authorized delete organization logos"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'organizations'
        AND (
            public.is_server_role()
            OR public.auth_role() = 'super_admin'
            OR public.auth_role() IN ('principal', 'office_admin')
        )
    );
