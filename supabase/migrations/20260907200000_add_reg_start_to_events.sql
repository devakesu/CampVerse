-- ==============================================================================
-- Migration: Add reg_start to events table and prefill existing records
-- ==============================================================================

-- 1. Add column if it doesn't already exist
ALTER TABLE events
    ADD COLUMN IF NOT EXISTS reg_start TIMESTAMPTZ;

-- 2. Add chronology check constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'check_registration_chronology'
    ) THEN
        ALTER TABLE events
            ADD CONSTRAINT check_registration_chronology
            CHECK (reg_start IS NULL OR reg_end IS NULL OR reg_start <= reg_end);
    END IF;
END $$;

-- 3. Prefill data for existing records
UPDATE events
SET reg_start = '2026-08-15 00:00:00+00'
WHERE title LIKE 'HackMEC 2026%' AND reg_start IS NULL;

UPDATE events
SET reg_start = '2026-08-25 00:00:00+00'
WHERE title LIKE 'Rust & Linux Kernel%' AND reg_start IS NULL;

UPDATE events
SET reg_start = '2026-08-20 00:00:00+00'
WHERE title LIKE 'AI Horizon 2026%' AND reg_start IS NULL;

UPDATE events
SET reg_start = '2026-08-28 00:00:00+00'
WHERE title LIKE 'RoboQuest%' AND reg_start IS NULL;

UPDATE events
SET reg_start = '2026-08-26 00:00:00+00'
WHERE title LIKE 'Raktadaan 2026%' AND reg_start IS NULL;

UPDATE events
SET reg_start = '2026-08-22 00:00:00+00'
WHERE title LIKE 'Snehasparsham%' AND reg_start IS NULL;

UPDATE events
SET reg_start = '2026-08-25 00:00:00+00'
WHERE title LIKE 'Git & Open Source Launchpad%' AND reg_start IS NULL;

UPDATE events
SET reg_start = '2026-09-01 00:00:00+00'
WHERE title LIKE 'InspireHer 2026%' AND reg_start IS NULL;

-- 4. Fallback for any other existing or future records without reg_start
UPDATE events
SET reg_start = COALESCE(reg_end - INTERVAL '14 days', start_time - INTERVAL '14 days')
WHERE reg_start IS NULL;
