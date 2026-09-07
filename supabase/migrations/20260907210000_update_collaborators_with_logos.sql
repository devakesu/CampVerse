-- ==============================================================================
-- Migration: Update collaborators with logo and title metadata for existing records
-- ==============================================================================

-- 1. HackMEC 2026: 36-Hour National Hackathon (both logo and title)
UPDATE events
SET collaborators = '{
  "IEEE MEC SB": [{"logo": "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=128&auto=format&fit=crop&q=80", "title": "Technical Partner"}],
  "Kerala Blockchain Academy": [{"logo": "https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=128&auto=format&fit=crop&q=80", "title": "Knowledge Partner"}]
}'::jsonb
WHERE title LIKE 'HackMEC 2026%';

-- 2. RoboQuest: Autonomous Line Tracer & Maze Solver (has logo, empty title -> only name & logo)
UPDATE events
SET collaborators = '{
  "Robotics Club MEC": [{"logo": "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=128&auto=format&fit=crop&q=80"}]
}'::jsonb
WHERE title LIKE 'RoboQuest%';

-- 3. Snehasparsham: Tribal School Educational Outreach (empty logo, has title -> name & title, no logo)
UPDATE events
SET collaborators = '{
  "Rotaract Club MEC": [{"title": "Community Outreach Partner"}]
}'::jsonb
WHERE title LIKE 'Snehasparsham%';

-- 4. InspireHer 2026: Women in STEM Conclave & Panel (both logo and title)
UPDATE events
SET collaborators = '{
  "IEEE WIE Kerala AG": [{"logo": "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=128&auto=format&fit=crop&q=80", "title": "Associate Partner"}]
}'::jsonb
WHERE title LIKE 'InspireHer 2026%';

-- 5. AI Horizon 2026: Edge Computing & LLM Summit (has logo, empty title -> only name & logo)
UPDATE events
SET collaborators = '{
  "IEEE Kerala Section Computer Society": [{"logo": "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=128&auto=format&fit=crop&q=80"}]
}'::jsonb
WHERE title LIKE 'AI Horizon 2026%';

-- 6. Raktadaan 2026: Campus Mega Blood Donation Drive (IMA has logo and title; NSS Unit MEC has empty array -> only name)
UPDATE events
SET collaborators = '{
  "IMA Blood Bank Ernakulam": [{"logo": "https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=128&auto=format&fit=crop&q=80", "title": "Clinical Partner"}],
  "NSS Unit MEC": []
}'::jsonb
WHERE title LIKE 'Raktadaan 2026%';

