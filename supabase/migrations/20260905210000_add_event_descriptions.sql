-- ==============================================================================
-- Migration: Add short_description and description to events table
-- ==============================================================================

ALTER TABLE events
    ADD COLUMN IF NOT EXISTS short_description TEXT,
    ADD COLUMN IF NOT EXISTS description TEXT;

-- Populate descriptions for existing events

-- 1. HackMEC 2026
UPDATE events
SET short_description = '36-hour non-stop national hackathon bringing together 250+ student developers to build AI, Web3, and IoT solutions.',
    description = 'HackMEC 2026 is Kerala''s premier 36-hour student hackathon organized by FOSSMEC in collaboration with IEEE MEC SB and Kerala Blockchain Academy. Participants get hands-on mentorship from industry leaders, computing credits, round-the-clock food and refreshments, and the opportunity to compete for ₹1,00,000+ in cash prizes across AI, Web3, and Open Source tracks. Official duty leave sanctioned and 20 KTU activity points credited upon verified gate check-in.'
WHERE title LIKE 'HackMEC 2026%';

-- 2. Rust & Linux Kernel Systems Workshop
UPDATE events
SET short_description = 'Deep-dive systems programming workshop exploring Rust memory safety and writing custom Linux kernel modules.',
    description = 'Master modern low-level systems programming with FOSSMEC. This intensive hands-on workshop covers Rust language fundamentals, ownership and borrowing, unsafe Rust, and compiling loadable kernel modules (LKMs) on Linux. Tailored for S4 and S6 CSE students aiming for systems software and embedded engineering roles. Lab workstations provided in CCF Lab Block C with 10 KTU activity points.'
WHERE title LIKE 'Rust & Linux Kernel%';

-- 3. AI Horizon 2026: Edge Computing & LLM Summit
UPDATE events
SET short_description = '2-day summit on Small Language Models (SLMs), model quantization with ONNX Runtime, and edge AI hardware deployments.',
    description = 'Explore the frontier of edge artificial intelligence at AI Horizon 2026, hosted by IEEE MEC SB in partnership with IEEE Kerala Section Computer Society. Featuring technical keynotes from AI researchers, interactive lab sessions on running quantized open-source LLMs on edge devices, and a student poster competition with cash awards. Certificate provided and 15 KTU activity points awarded.'
WHERE title LIKE 'AI Horizon 2026%';

-- 4. RoboQuest: Autonomous Line Tracer & Maze Solver
UPDATE events
SET short_description = 'High-speed autonomous robotics challenge featuring line tracing heats and micromouse grid maze solving.',
    description = 'Put your embedded firmware and sensor calibration to the test at RoboQuest 2026! Teams of up to 3 students compete in two intense arena categories: high-speed PID line tracking and autonomous maze navigation. Includes arena familiarization, qualifying heats, and grand showdowns. Duty leave approved for class hours, 15 KTU activity points, and verified merit certificates.'
WHERE title LIKE 'RoboQuest%';

-- 5. Raktadaan 2026: Campus Mega Blood Donation Drive
UPDATE events
SET short_description = 'Annual campus-wide voluntary blood donation drive organized in partnership with IMA Blood Bank Ernakulam & NSS MEC.',
    description = 'Join hands with Thanal MEC and NSS Unit MEC for the annual Raktadaan blood donation drive. Professional medical screening, sterile medical facilities from IMA Blood Bank, donor refreshment kits, and commemorative certificates provided. Every donation saves up to three lives. Approved for duty leave and 10 KTU activity points.'
WHERE title LIKE 'Raktadaan 2026%';

-- 6. Snehasparsham: Tribal School Educational Outreach
UPDATE events
SET short_description = 'Community outreach and STEM learning fair for primary students at Kuttampuzha Tribal Welfare School.',
    description = 'Snehasparsham is Thanal MEC''s flagship social impact initiative. Volunteers will travel via college bus to Kuttampuzha Tribal School to conduct interactive science demonstrations, distribute school bags and learning kits, and facilitate digital literacy sessions. Limited to 40 student volunteers from S4, S6, and S8 cohorts. Full-day duty leave sanctioned with 15 KTU activity points.'
WHERE title LIKE 'Snehasparsham%';

-- 7. Git & Open Source Launchpad for Freshers
UPDATE events
SET short_description = 'Hands-on induction to Git, GitHub collaboration, branching workflows, and making your first open-source pull request.',
    description = 'Tailored specifically for S1 and S2 engineering freshers, the Git & Open Source Launchpad equips beginners with industry-standard version control skills. Learn commit hygiene, resolve merge conflicts, collaborate on GitHub repositories, and submit your very first live Pull Request with live 1-on-1 assistance from senior student mentors. Earn 5 KTU activity points and a verified completion certificate.'
WHERE title LIKE 'Git & Open Source Launchpad%';

-- 8. InspireHer 2026: Women in STEM Conclave & Panel
UPDATE events
SET short_description = 'Inspirational leadership conclave celebrating women in engineering, tech entrepreneurship, and research.',
    description = 'Presented by IEEE MEC SB and IEEE WIE Kerala Affinity Group, InspireHer 2026 brings together prominent women technology leaders, startup founders, and distinguished MEC alumni. Features panel discussions on navigating deep tech careers, fireside chats, networking high tea, and 1-on-1 mentorship connects. Open to all students with duty leave approved and 10 KTU activity points.'
WHERE title LIKE 'InspireHer 2026%';
