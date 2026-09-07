-- ==============================================================================
-- Migration: Replace gender_restriction with allowed_sex (M, F, T) combos
-- ==============================================================================

-- 1. Initialize allowed_sex = [] and clean obsolete gender_restriction for all events
UPDATE events
SET eligibility = jsonb_set(
  COALESCE(eligibility, '{}'::jsonb) - 'gender_restriction',
  '{allowed_sex}',
  '[]'::jsonb
);

-- 2. Combo 1: "F" only (Female Only)
-- InspireHer 2026: Women in STEM Conclave & Panel
UPDATE events
SET eligibility = jsonb_set(
  eligibility,
  '{allowed_sex}',
  '["F"]'::jsonb
)
WHERE title LIKE 'InspireHer 2026%';

-- 3. Combo 2: "M" only (Male Only)
-- Rust & Linux Kernel Systems Workshop
UPDATE events
SET eligibility = jsonb_set(
  eligibility,
  '{allowed_sex}',
  '["M"]'::jsonb
)
WHERE title LIKE 'Rust & Linux%';

-- 4. Combo 3: "F", "T" cross case (Female & Transgender)
-- Snehasparsham: Tribal School Educational Outreach
UPDATE events
SET eligibility = jsonb_set(
  eligibility,
  '{allowed_sex}',
  '["F", "T"]'::jsonb
)
WHERE title LIKE 'Snehasparsham%';

-- 5. Combo 4: "M", "F", "T" all explicitly listed
-- Git & Open Source Launchpad for Freshers
UPDATE events
SET eligibility = jsonb_set(
  eligibility,
  '{allowed_sex}',
  '["M", "F", "T"]'::jsonb
)
WHERE title LIKE 'Git & Open Source%';

-- Note: HackMEC 2026, RoboQuest, AI Horizon, Raktadaan remain allowed_sex: [] (Open to all)
