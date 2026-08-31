-- ==============================================================================
-- 0. EXTENSIONS & TRIGGER FUNCTIONS
-- ==============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Generic updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_modified_column() 
RETURNS TRIGGER
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- ==============================================================================
-- 1. ENUMS
-- ==============================================================================
CREATE TYPE app_role AS ENUM (
    'super_admin',      -- System-wide admin
    'principal',        -- Institute head
    'office_admin',     -- Office / Management
    'student_union',    -- Student union
    'hod',              -- Department head
    'faculty',          -- Staff / Class Tutor
    'club_admin',       -- Club admin
    'student'           -- Base user
);

CREATE TYPE account_status AS ENUM (
    'pending_verification', 
    'active', 
    'suspended', 
    'alumni'
);

CREATE TYPE faculty_designation AS ENUM (
    'assistant_professor',
    'associate_professor',
    'professor',
    'hod',
    'lab_instructor',
    'guest_lecturer',
    'admin_staff'
);

CREATE TYPE org_type AS ENUM (
    'student_union',
    'club'
);

CREATE TYPE member_role AS ENUM (
    'lead', 
    'core_member', 
    'volunteer', 
    'member'
);

CREATE TYPE degree_level AS ENUM (
    'UG', 
    'PG', 
    'PhD', 
    'Diploma'
);

CREATE TYPE degree_type AS ENUM (
    'B.Tech.',
    'M.Tech.',
    'MCA',
    'B.Sc.',
    'M.Sc.',
    'B.Com.',
    'BBA',
    'MBA',
    'PhD'
);

CREATE TYPE course_type AS ENUM (
    'theory',
    'practical',
    'integrated',
    'project',
    'mooc'
);

CREATE TYPE elect_type AS ENUM (
    'regular',
    'program_elective',
    'open_elective',
    'minor',
    'honours',
    'audit',
    'repeat'
);

CREATE TYPE enrol_stat AS ENUM (
    'enrolled',
    'approved',
    'completed',
    'dropped',
    'withdrawn'
);

CREATE TYPE event_status AS ENUM (
    'draft',
    'published',
    'cancelled',
    'completed'
);

CREATE TYPE ticket_status AS ENUM (
    'reserved',
    'confirmed',
    'used',
    'cancelled'
);

CREATE TYPE event_visibility AS ENUM (
    'public',    -- Global on Campverse
    'institute', -- Only visible inside the institute portal
    'club',      -- Only visible to club members
    'custom'     -- Specific clubs selected by admin
);

CREATE TYPE post_status AS ENUM (
    'draft', 
    'published', 
    'archived'
);

CREATE TYPE post_scope AS ENUM (
    'campus_wide', 
    'department', 
    'class_only', 
    'club_members'
);

CREATE TYPE day_of_week AS ENUM (
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday'
);

-- ==============================================================================
-- 2. UNIVERSITIES & INSTITUTES (Multi-Tenant Foundation)
-- ==============================================================================

CREATE TABLE universities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,                   -- e.g., 'APJ Abdul Kalam Technological University'
    slug TEXT UNIQUE NOT NULL,            -- e.g., 'KTU'
    state TEXT NOT NULL,                  -- e.g., 'Kerala'
    website TEXT,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE institutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id UUID REFERENCES universities(id) ON DELETE SET NULL,
    
    name TEXT NOT NULL,                   -- e.g., 'Govt. Model Engineering College'
    slug TEXT UNIQUE NOT NULL,            -- e.g., 'MEC'
    domain TEXT UNIQUE,                   -- e.g., 'mec.ac.in'
    is_autonomous BOOLEAN DEFAULT FALSE,  -- True = custom syllabus; False = follows university scheme
    
    branding JSONB DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    secrets BYTEA,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name TEXT NOT NULL,                   -- e.g., 'Computer Science & Engineering'
    code TEXT NOT NULL,                   -- e.g., 'CSE', 'ECE'
    hod_id UUID,                          -- FK to profiles (resolved via deferred constraint)
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(institute_id, code)
);

CREATE TABLE programmes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    
    name TEXT NOT NULL,                   -- e.g., 'Computer Science and Business Systems'
    programme_code TEXT NOT NULL,         -- e.g., 'CSBS'
    degree_type degree_type NOT NULL,     -- e.g., 'B.Tech.', 'M.Tech.', 'MCA'
    degree_level degree_level NOT NULL,   -- 'UG', 'PG'
    duration_years INT NOT NULL DEFAULT 4,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(institute_id, programme_code)
);

-- ==============================================================================
-- 3. SYLLABUS, SCHEMES & COURSES
-- ==============================================================================

CREATE TABLE curriculum_schemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id UUID REFERENCES universities(id) ON DELETE CASCADE,
    institute_id UUID REFERENCES institutes(id) ON DELETE CASCADE,
    
    name TEXT NOT NULL,                   -- e.g., '2024 Scheme'
    scheme_year INT NOT NULL,             -- e.g., 2024
    degree_type degree_type NOT NULL,     -- e.g., 'B.Tech.'
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT check_scheme_ownership CHECK (
        (university_id IS NOT NULL AND institute_id IS NULL) OR
        (university_id IS NULL AND institute_id IS NOT NULL)
    ),
    UNIQUE(university_id, scheme_year, degree_type),
    UNIQUE(institute_id, scheme_year, degree_type)
);

CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    university_id UUID REFERENCES universities(id) ON DELETE CASCADE,
    institute_id UUID REFERENCES institutes(id) ON DELETE CASCADE,
    
    course_code TEXT NOT NULL,            -- e.g., 'MAT101', 'CST201'
    title TEXT NOT NULL,                  -- e.g., 'Linear Algebra and Calculus'
    credits NUMERIC(10, 1) NOT NULL DEFAULT 4.0,
    course_type course_type DEFAULT 'theory',
    syllabus_meta JSONB DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    CONSTRAINT check_course_ownership CHECK (
        (university_id IS NOT NULL AND institute_id IS NULL) OR
        (university_id IS NULL AND institute_id IS NOT NULL)
    ),
    UNIQUE(university_id, course_code),
    UNIQUE(institute_id, course_code)
);

CREATE TABLE programme_courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    programme_id UUID NOT NULL REFERENCES programmes(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES curriculum_schemes(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    
    semester INT NOT NULL,                -- e.g., 1 to 8
    is_elective BOOLEAN DEFAULT FALSE,
    elective_slot TEXT,                   -- e.g., 'Program Elective 1', 'Open Elective'
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(programme_id, scheme_id, course_id, semester)
);

-- ==============================================================================
-- 4. ACADEMIC COHORTS, ALLOCATIONS & ENROLLMENTS
-- ==============================================================================

CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    programme_id UUID NOT NULL REFERENCES programmes(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES curriculum_schemes(id) ON DELETE RESTRICT,
    
    admission_year INT NOT NULL,          -- e.g., 2024
    grad_year INT NOT NULL,               -- e.g., 2028
    current_semester INT NOT NULL DEFAULT 1,
    division TEXT,                        -- e.g., 'A', 'B'
    
    staff_advisor_id UUID,                -- FK to profiles
    class_reps JSONB DEFAULT '[]',        -- Array of student profile UUIDs
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT check_years CHECK (grad_year > admission_year)
);

CREATE TABLE class_course_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    
    primary_faculty_id UUID,              -- FK to profiles
    co_faculty JSONB DEFAULT '[]',        -- Array of profile UUIDs
    
    semester INT NOT NULL,
    academic_year TEXT NOT NULL,          -- e.g., '2026-2027'
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(class_id, course_id, semester)
);

CREATE TABLE student_course_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,             -- FK to profiles
    allocation_id UUID NOT NULL REFERENCES class_course_allocations(id) ON DELETE CASCADE,
    
    enrollment_type elect_type DEFAULT 'regular',
    status enrol_stat DEFAULT 'enrolled',
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(student_id, allocation_id)
);

-- ==============================================================================
-- 5. IDENTITY & PROFILES (With Binary FLE)
-- ==============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Multi-Tenant Topology
    institute_id UUID REFERENCES institutes(id) ON DELETE SET NULL,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    programme_id UUID REFERENCES programmes(id) ON DELETE SET NULL,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    role app_role DEFAULT 'student'::app_role NOT NULL,
    designation faculty_designation,
    
    -- 1. Identity & Public Persona (Encrypted)
    full_name_enc BYTEA NOT NULL,          -- AES-256-GCM ciphertext
    full_name_bidx BYTEA,                  -- HMAC-SHA256(name, pepper) for exact lookups
    bio_enc BYTEA,                         -- User biography
    avatar_path_enc BYTEA,                 -- Encrypted storage path to profile image
    
    -- 2. Searchable Identifiers & Contact PII (Encrypted Display + Blind Indexes)
    institutional_email_enc BYTEA,
    institutional_email_bidx BYTEA UNIQUE, -- HMAC-SHA256(email, pepper)
    
    university_reg_no_enc BYTEA,
    university_reg_no_bidx BYTEA UNIQUE,   -- HMAC-SHA256(reg_no, pepper)
    
    admission_no_enc BYTEA,
    admission_no_bidx BYTEA,               -- HMAC-SHA256(admission_no, pepper)
    
    phone_enc BYTEA,
    phone_bidx BYTEA,                      -- HMAC-SHA256(phone, pepper)
    
    -- 3. Confidential Personal & Regulatory Data
    dob_enc BYTEA,
    gender_enc BYTEA,
    blood_group_enc BYTEA,
    emergency_contact_enc BYTEA,           -- Encrypted JSON: { name, relation, phone }
    address_enc BYTEA,                     -- Encrypted JSON: { permanent, residential }
    identity_doc_enc BYTEA,                -- Encrypted national ID / document tokens
    
    -- 4. Academic Performance & Sensitive Metadata
    academic_metrics_enc BYTEA,            -- Encrypted JSON: { cgpa, sgpa_history, activity_points }
    metadata_enc BYTEA,                    -- Encrypted JSON: { hosteler, hostel_room, bus_route_no }
    social_profiles_enc BYTEA,             -- Encrypted JSON: { github, linkedin, portfolio }
    
    -- 5. Operational State & Push Endpoints
    fcm_tokens_enc BYTEA,                  -- Encrypted array of device push tokens
    preferences JSONB DEFAULT '{
        "theme": "system",
        "notifications": {
            "announcements": true,
            "event_reminders": true,
            "direct_messages": true
        }
    }'::jsonb,
    
    -- Lifecycle & Verification
    status account_status DEFAULT 'pending_verification'::account_status NOT NULL,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Resolve deferred FKs
ALTER TABLE departments 
    ADD CONSTRAINT fk_dept_hod 
    FOREIGN KEY (hod_id) REFERENCES profiles(id) ON DELETE SET NULL;

ALTER TABLE classes 
    ADD CONSTRAINT fk_class_staff_advisor 
    FOREIGN KEY (staff_advisor_id) REFERENCES profiles(id) ON DELETE SET NULL;

ALTER TABLE class_course_allocations 
    ADD CONSTRAINT fk_alloc_faculty 
    FOREIGN KEY (primary_faculty_id) REFERENCES profiles(id) ON DELETE SET NULL;

ALTER TABLE student_course_enrollments 
    ADD CONSTRAINT fk_enrollment_student 
    FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- ==============================================================================
-- 6. ORGANIZATIONS (Clubs & Student Unions)
-- ==============================================================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    
    -- Public Discovery & Routing (Plaintext)
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    org_type org_type NOT NULL,
    org_category TEXT,                   -- e.g., 'Technical', 'Cultural', 'Sports'
    logo_path TEXT,
    
    -- Encrypted Operational Payloads (AES-256-GCM)
    description_enc BYTEA,               -- Detailed description, constitution/bylaws
    contacts_enc BYTEA,                  -- Encrypted JSON: { email, phone, leads_contact }
    social_links_enc BYTEA,              -- Encrypted JSON: { discord, whatsapp, linkedin }
    secrets_enc BYTEA,                   -- Encrypted JSON: { payout_upi, bank_details, webhook_keys }
    core_team_enc BYTEA,                 -- Encrypted snapshot of lead profiles/responsibilities
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    UNIQUE(institute_id, slug)
);

-- Database-level constraint: exactly one Student Union per institute
CREATE UNIQUE INDEX unique_student_union_per_institute 
ON organizations (institute_id) 
WHERE (org_type = 'student_union');


-- ==============================================================================
-- 6.1 ORGANIZATION MEMBERSHIPS
-- ==============================================================================

CREATE TABLE organization_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Authorization & Access Controls (Plaintext for RLS)
    role member_role DEFAULT 'member'::member_role NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    -- Encrypted Member Data (AES-256-GCM)
    designation_enc BYTEA,               -- Custom executive title (e.g., 'Chief Technical Officer')
    internal_notes_enc BYTEA,            -- Recruitment notes, interview ratings, remarks
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    UNIQUE(org_id, user_id)
);

-- ==============================================================================
-- 7. EVENTS & TICKETING
-- ==============================================================================

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    primary_org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Core Query & Display Attributes (Plaintext for Discovery & Filtering)
    title TEXT NOT NULL,
    venue TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    reg_end TIMESTAMPTZ,
    max_capacity INT,                     -- NULL = unlimited capacity
    tags TEXT[] DEFAULT '{}',
    poster_url TEXT,
    visibility event_visibility DEFAULT 'institute' NOT NULL,
    
    -- State & Configuration Flags
    reg_config BOOLEAN DEFAULT FALSE NOT NULL,
    status event_status DEFAULT 'draft' NOT NULL,
    is_featured BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- Flexible Operational Payloads (JSONB)
    eligibility JSONB DEFAULT '{
        "allowed_programmes": [],
        "allowed_semesters": [],
        "gender_restriction": null
    }'::jsonb,
    collaborators JSONB DEFAULT '[]',     -- Co-organizing clubs or partner institutes
    itinerary JSONB DEFAULT '[]',         -- Agenda/timeline items
    pricing JSONB DEFAULT '{
        "is_paid": false,
        "base_price_cents": 0,
        "currency": "INR",
        "tiers": []
    }'::jsonb,
    incentives JSONB DEFAULT '{
        "ktu_activity_points": 0,
        "certificate_provided": true,
        "duty_leave_approved": false
    }'::jsonb,
    contacts JSONB DEFAULT '[]',          -- Public coordinator contact list: [{ name, role, phone }]
    links JSONB DEFAULT '{}',             -- Social, brochure, discord links
    media_urls JSONB DEFAULT '[]',
    
    -- Encrypted Internal Planning (AES-256-GCM)
    internal_notes_enc BYTEA,            -- Private budget info, judge rubrics, sponsor contracts

    -- Audit Timestamps
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Integrity Constraints
    CONSTRAINT check_event_chronology CHECK (start_time < end_time),
    CONSTRAINT check_registration_window CHECK (reg_end IS NULL OR reg_end <= start_time)
);

CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Pass & Gate Verification
    status ticket_status DEFAULT 'confirmed'::ticket_status NOT NULL,
    qr_payload TEXT NOT NULL UNIQUE,      -- Cryptographic random pass token (e.g. UUIDv4 or HMAC token)
    
    -- Financial & Form Responses (Encrypted Payloads)
    payment_data_enc BYTEA,               -- Encrypted JSON: { order_id, payment_id, receipt_no, amount, currency }
    custom_responses_enc BYTEA,           -- Encrypted JSON: { dietary, resume_url, t_shirt, custom_answers }
    
    -- Gate Check-in Metadata
    scanned_at TIMESTAMPTZ,
    scanned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Enforce 1 registration per user per event
    UNIQUE(event_id, user_id)
);

-- ==============================================================================
-- 8. CAMPUS BROADCASTS & POSTS
-- ==============================================================================

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Scoped Routing (Plaintext for Fast Joins & RLS)
    org_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    
    scope post_scope DEFAULT 'campus_wide'::post_scope NOT NULL,
    status post_status DEFAULT 'published'::post_status NOT NULL,
    is_pinned BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- Encrypted Notice Payloads (AES-256-GCM)
    title_enc BYTEA NOT NULL,
    content_enc BYTEA NOT NULL,
    media_urls_enc BYTEA,                -- Encrypted JSON array of image/video URLs
    attachments_enc BYTEA,               -- Encrypted JSON array: [{ name, url, file_size, mime_type }]
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ==============================================================================
-- 9. TIMETABLES & SCHEDULE MATRIX
-- ==============================================================================

CREATE TABLE class_timetables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    allocation_id UUID NOT NULL REFERENCES class_course_allocations(id) ON DELETE CASCADE,
    
    day day_of_week NOT NULL,
    period_number INT NOT NULL,          -- Period slot 1, 2, 3...
    classroom_hall TEXT,                 -- e.g., 'LH-302', 'CS Lab 2'
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    
    -- Prevent double-booking a single class period
    UNIQUE(class_id, day, period_number)
);

-- ==============================================================================
-- 10. DIGITAL CERTIFICATE VAULT
-- ==============================================================================

CREATE TABLE certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,
    recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Public Verification Index
    verification_hash TEXT UNIQUE NOT NULL, -- SHA-256 token for instant QR/web validation
    
    -- Encrypted Certificate Assets (AES-256-GCM)
    title_enc BYTEA NOT NULL,            -- Encrypted title (e.g., 'Certificate of Merit')
    pdf_storage_path_enc BYTEA NOT NULL, -- Encrypted private storage path
    metadata_enc BYTEA,                  -- Encrypted JSON: { rank, score, issue_authority, template_id }
    
    issued_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ==============================================================================
-- 11. APPLY AUTOMATIC TRIGGERS
-- ==============================================================================
CREATE TRIGGER set_timestamp_universities BEFORE UPDATE ON universities FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_institutes BEFORE UPDATE ON institutes FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_departments BEFORE UPDATE ON departments FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_programmes BEFORE UPDATE ON programmes FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_curriculum_schemes BEFORE UPDATE ON curriculum_schemes FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_courses BEFORE UPDATE ON courses FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_programme_courses BEFORE UPDATE ON programme_courses FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_classes BEFORE UPDATE ON classes FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_class_course_allocations BEFORE UPDATE ON class_course_allocations FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_student_course_enrollments BEFORE UPDATE ON student_course_enrollments FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_profiles BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_orgs BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_organization_members BEFORE UPDATE ON organization_members FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_events BEFORE UPDATE ON events FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_event_registrations BEFORE UPDATE ON event_registrations FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_posts BEFORE UPDATE ON posts FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_class_timetables BEFORE UPDATE ON class_timetables FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_certificates BEFORE UPDATE ON certificates FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- ==============================================================================
-- 12. PERFORMANCE & LOOKUP INDEXES
-- ==============================================================================

-- Profiles
CREATE INDEX idx_profiles_institute ON profiles(institute_id);
CREATE INDEX idx_profiles_department ON profiles(department_id);
CREATE INDEX idx_profiles_class ON profiles(class_id);
CREATE INDEX idx_profiles_role ON profiles(role);

CREATE INDEX idx_profiles_name_bidx ON profiles(full_name_bidx);
CREATE INDEX idx_profiles_email_bidx ON profiles(institutional_email_bidx);
CREATE INDEX idx_profiles_reg_no_bidx ON profiles(university_reg_no_bidx);
CREATE INDEX idx_profiles_phone_bidx ON profiles(phone_bidx);

-- Course & Enrollment Mappings
CREATE INDEX idx_programme_courses_course ON programme_courses(course_id);
CREATE INDEX idx_class_alloc_course ON class_course_allocations(course_id);
CREATE INDEX idx_enrollments_student ON student_course_enrollments(student_id, allocation_id);
CREATE INDEX idx_enrollments_status ON student_course_enrollments(status);

-- Organizations
CREATE INDEX idx_org_members_org ON organization_members(org_id);
CREATE INDEX idx_org_members_user ON organization_members(user_id);
CREATE INDEX idx_org_members_role ON organization_members(role);
CREATE INDEX idx_orgs_institute ON organizations(institute_id);
CREATE INDEX idx_orgs_type ON organizations(org_type);

-- Event Discovery & QR Validation
CREATE INDEX idx_events_institute ON events(institute_id);
CREATE INDEX idx_events_org ON events(primary_org_id);
CREATE INDEX idx_events_status_time ON events(status, start_time);
CREATE INDEX idx_events_visibility ON events(visibility);
CREATE INDEX idx_events_gin_tags ON events USING GIN (tags);

CREATE INDEX idx_registrations_qr ON event_registrations(qr_payload);
CREATE INDEX idx_registrations_user_event ON event_registrations(user_id, event_id);
CREATE INDEX idx_registrations_status ON event_registrations(status);

-- Posts Performance & Feed Queries
CREATE INDEX idx_posts_feed ON posts(institute_id, scope, status, created_at DESC);
CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_class ON posts(class_id) WHERE class_id IS NOT NULL;
CREATE INDEX idx_posts_dept ON posts(department_id) WHERE department_id IS NOT NULL;
CREATE INDEX idx_posts_org ON posts(org_id) WHERE org_id IS NOT NULL;

-- Timetable Schedule Matrix
CREATE INDEX idx_timetable_lookup ON class_timetables(class_id, day, period_number);
CREATE INDEX idx_timetable_allocation ON class_timetables(allocation_id);

-- Instant Certificate Hash Verification
CREATE INDEX idx_certificates_hash ON certificates(verification_hash);
CREATE INDEX idx_certificates_recipient ON certificates(recipient_id);

-- ==============================================================================
-- 13. RLS HELPER FUNCTIONS
-- ==============================================================================

-- Extract current user's institute
CREATE OR REPLACE FUNCTION public.auth_institute_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT institute_id FROM public.profiles WHERE id = auth.uid();
$$;

-- Extract current user's role
CREATE OR REPLACE FUNCTION public.auth_role()
RETURNS app_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- Verify if user has administrative or faculty standing
CREATE OR REPLACE FUNCTION public.is_staff_or_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() 
          AND role IN ('super_admin', 'principal', 'office_admin', 'hod', 'faculty')
    );
$$;

-- Verify if user is an active lead/core member of a specific organization
CREATE OR REPLACE FUNCTION public.is_org_lead(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.organization_members
        WHERE org_id = target_org_id 
          AND user_id = auth.uid() 
          AND is_active = TRUE 
          AND role IN ('lead', 'core_member')
    ) OR public.auth_role() IN ('super_admin', 'principal');
$$;

-- ==============================================================================
-- 14. ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- ==============================================================================
ALTER TABLE universities ENABLE ROW LEVEL SECURITY;
ALTER TABLE institutes ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE programmes ENABLE ROW LEVEL SECURITY;
ALTER TABLE curriculum_schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE programme_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_course_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_course_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 15. TENANT & ACADEMIC TOPOLOGY POLICIES
-- ==============================================================================

-- Universities: Public read; Super Admin write
CREATE POLICY "Public universities read"
    ON universities FOR SELECT
    USING (TRUE);

-- Institutes: Read active institutes; Super Admin / Principal modify
CREATE POLICY "Read active institutes"
    ON institutes FOR SELECT
    USING (is_active = TRUE OR auth_role() = 'super_admin');

CREATE POLICY "Admin update institute"
    ON institutes FOR UPDATE
    USING (auth_role() = 'super_admin' OR (id = auth_institute_id() AND auth_role() = 'principal'));

-- Academic Structure: Read by campus members; Modified by Institute Staff
CREATE POLICY "Read campus departments"
    ON departments FOR SELECT
    USING (institute_id = auth_institute_id() OR auth_role() = 'super_admin');

CREATE POLICY "Manage campus departments"
    ON departments FOR ALL
    USING (institute_id = auth_institute_id() AND is_staff_or_admin());

CREATE POLICY "Read campus programmes"
    ON programmes FOR SELECT
    USING (institute_id = auth_institute_id() OR auth_role() = 'super_admin');

CREATE POLICY "Manage campus programmes"
    ON programmes FOR ALL
    USING (institute_id = auth_institute_id() AND is_staff_or_admin());

-- Curriculum & Courses: Read university schemes + own college courses
CREATE POLICY "Read accessible schemes"
    ON curriculum_schemes FOR SELECT
    USING (
        university_id IS NOT NULL OR 
        institute_id = auth_institute_id() OR 
        auth_role() = 'super_admin'
    );

CREATE POLICY "Read accessible courses"
    ON courses FOR SELECT
    USING (
        university_id IS NOT NULL OR 
        institute_id = auth_institute_id() OR 
        auth_role() = 'super_admin'
    );

CREATE POLICY "Read programme course mappings"
    ON programme_courses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM programmes p 
            WHERE p.id = programme_courses.programme_id 
              AND (p.institute_id = auth_institute_id() OR auth_role() = 'super_admin')
        )
    );

-- ==============================================================================
-- 16. COHORTS, ALLOCATIONS & ENROLLMENTS POLICIES
-- ==============================================================================

CREATE POLICY "Read campus classes"
    ON classes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM programmes p 
            WHERE p.id = classes.programme_id 
              AND (p.institute_id = auth_institute_id() OR auth_role() = 'super_admin')
        )
    );

CREATE POLICY "Read course allocations"
    ON class_course_allocations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM classes c 
            JOIN programmes p ON p.id = c.programme_id 
            WHERE c.id = class_course_allocations.class_id 
              AND (p.institute_id = auth_institute_id() OR auth_role() = 'super_admin')
        )
    );

-- Enrollments: Students see own enrollments; Teachers see class enrollments
CREATE POLICY "Read own or advised student enrollments"
    ON student_course_enrollments FOR SELECT
    USING (
        student_id = auth.uid() OR
        is_staff_or_admin()
    );

CREATE POLICY "Manage student enrollments"
    ON student_course_enrollments FOR ALL
    USING (
        student_id = auth.uid() OR
        is_staff_or_admin()
    );

-- ==============================================================================
-- 17. PROFILES SECURITY POLICIES
-- ==============================================================================

-- Profiles: Users can view profiles belonging to their institute
CREATE POLICY "View campus member profiles"
    ON profiles FOR SELECT
    USING (
        institute_id = auth_institute_id() OR 
        id = auth.uid() OR 
        auth_role() = 'super_admin'
    );

-- Profiles: Users can update their own profile; Admins can verify
CREATE POLICY "Update own profile"
    ON profiles FOR UPDATE
    USING (id = auth.uid() OR is_staff_or_admin());

-- ==============================================================================
-- 18. ORGANIZATIONS & MEMBERSHIPS POLICIES
-- ==============================================================================

CREATE POLICY "View campus organizations"
    ON organizations FOR SELECT
    USING (institute_id = auth_institute_id() OR auth_role() = 'super_admin');

CREATE POLICY "Manage organizations"
    ON organizations FOR ALL
    USING (
        auth_role() IN ('super_admin', 'principal', 'student_union') AND 
        institute_id = auth_institute_id()
    );

CREATE POLICY "View organization members"
    ON organization_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM organizations o 
            WHERE o.id = organization_members.org_id 
              AND (o.institute_id = auth_institute_id() OR auth_role() = 'super_admin')
        )
    );

CREATE POLICY "Manage organization members"
    ON organization_members FOR ALL
    USING (is_org_lead(org_id));

-- ==============================================================================
-- 19. EVENTS & TICKETING POLICIES
-- ==============================================================================

-- Events: Visibility-scoped read rules
CREATE POLICY "View published events"
    ON events FOR SELECT
    USING (
        (status = 'published' AND (
            visibility = 'public' OR
            (visibility = 'institute' AND institute_id = auth_institute_id()) OR
            (visibility = 'club' AND is_org_lead(primary_org_id))
        )) OR
        is_org_lead(primary_org_id) OR
        auth_role() IN ('super_admin', 'principal')
    );

CREATE POLICY "Create and manage club events"
    ON events FOR ALL
    USING (is_org_lead(primary_org_id) OR auth_role() IN ('super_admin', 'principal'));

-- Registrations: User can view/buy own tickets; Leads can scan & check-in
CREATE POLICY "View own tickets or scanned tickets"
    ON event_registrations FOR SELECT
    USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM events e 
            WHERE e.id = event_registrations.event_id 
              AND is_org_lead(e.primary_org_id)
        )
    );

CREATE POLICY "Register for events"
    ON event_registrations FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Update check-in status"
    ON event_registrations FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM events e 
            WHERE e.id = event_registrations.event_id 
              AND (is_org_lead(e.primary_org_id) OR is_staff_or_admin())
        )
    );

-- ==============================================================================
-- 20. BROADCASTS, TIMETABLES & CERTIFICATES POLICIES
-- ==============================================================================

-- Posts: Scope-based feed resolution
CREATE POLICY "View scoped posts"
    ON posts FOR SELECT
    USING (
        status = 'published' AND
        institute_id = auth_institute_id() AND (
            scope = 'campus_wide' OR
            (scope = 'department' AND department_id = (SELECT department_id FROM profiles WHERE id = auth.uid())) OR
            (scope = 'class_only' AND class_id = (SELECT class_id FROM profiles WHERE id = auth.uid())) OR
            (scope = 'club_members' AND is_org_lead(org_id))
        )
    );

CREATE POLICY "Publish posts"
    ON posts FOR INSERT
    WITH CHECK (
        institute_id = auth_institute_id() AND
        (is_staff_or_admin() OR (org_id IS NOT NULL AND is_org_lead(org_id)))
    );

-- Timetables: Campus read; Advisor/Faculty write
CREATE POLICY "View class timetables"
    ON class_timetables FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM classes c 
            JOIN programmes p ON p.id = c.programme_id 
            WHERE c.id = class_timetables.class_id 
              AND (p.institute_id = auth_institute_id() OR auth_role() = 'super_admin')
        )
    );

CREATE POLICY "Manage class timetables"
    ON class_timetables FOR ALL
    USING (is_staff_or_admin());

-- Certificates: Recipient reads their own; Anyone with verification hash validates
CREATE POLICY "Read own certificates or verify hash"
    ON certificates FOR SELECT
    USING (
        recipient_id = auth.uid() OR
        auth_role() = 'super_admin' OR
        verification_hash IS NOT NULL -- Allows public unauthenticated hash check
    );

CREATE POLICY "Issue certificates"
    ON certificates FOR INSERT
    WITH CHECK (
        institute_id = auth_institute_id() AND
        (is_staff_or_admin() OR (event_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM events e WHERE e.id = event_id AND is_org_lead(e.primary_org_id)
        )))
    );