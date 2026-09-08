-- ==============================================================================
-- Migration: Update event_registrations to support flexible check-in modes
-- ==============================================================================
-- 1. Make qr_payload optional (nullable) for online/non-QR event types
-- 2. Add secret_code column (e.g. 8-digit code) unique per event for internal desk check-ins
-- 3. Add scan & checkpoint properties: is_single_scan, scan_count, allowed_scan_types, scan_history
-- 4. Drop obsolete scanned_by column
-- 5. Rename scanned_at to used_at

-- 1. Make qr_payload optional
ALTER TABLE public.event_registrations
    ALTER COLUMN qr_payload DROP NOT NULL;

-- 2. Add secret_code column
ALTER TABLE public.event_registrations
    ADD COLUMN IF NOT EXISTS secret_code TEXT;

-- Enforce uniqueness of secret_code per event when non-null
CREATE UNIQUE INDEX IF NOT EXISTS idx_registrations_event_secret_code
    ON public.event_registrations (event_id, secret_code)
    WHERE secret_code IS NOT NULL;

-- 3. Add scan configuration and tracking properties
ALTER TABLE public.event_registrations
    ADD COLUMN IF NOT EXISTS is_single_scan BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS scan_count INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS allowed_scan_types TEXT[] NOT NULL DEFAULT '{"entry"}',
    ADD COLUMN IF NOT EXISTS scan_history JSONB NOT NULL DEFAULT '[]'::jsonb;

-- 4. Drop scanned_by
ALTER TABLE public.event_registrations
    DROP CONSTRAINT IF EXISTS event_registrations_scanned_by_fkey;

ALTER TABLE public.event_registrations
    DROP COLUMN IF EXISTS scanned_by;

-- 5. Rename scanned_at to used_at
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'event_registrations'
          AND column_name = 'scanned_at'
    ) THEN
        ALTER TABLE public.event_registrations
            RENAME COLUMN scanned_at TO used_at;
    END IF;
END $$;

-- 6. Backfill existing sample registrations with realistic secret codes and scan types
UPDATE public.event_registrations
SET secret_code = 'HM8821',
    allowed_scan_types = '{"entry", "food", "kit"}'
WHERE qr_payload LIKE '%HACKMEC%' AND secret_code IS NULL;

UPDATE public.event_registrations
SET secret_code = 'RD4419',
    allowed_scan_types = '{"entry", "donor_kit"}'
WHERE qr_payload LIKE '%RAKTADAAN%' AND secret_code IS NULL;
