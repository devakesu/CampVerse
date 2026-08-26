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
    
    institute_id UUID REFERENCES institutes(id) ON DELETE SET NULL,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    programme_id UUID REFERENCES programmes(id) ON DELETE SET NULL,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    
    full_name TEXT NOT NULL,
    institutional_email TEXT UNIQUE,
    university_reg_no TEXT UNIQUE,        -- e.g., KTU Register Number ('MDL25CSBS0000')
    admission_no TEXT,
    role app_role DEFAULT 'student'::app_role NOT NULL,
    designation faculty_designation,
    avatar_path TEXT,
    bio TEXT,
    
    -- Binary Ciphertexts (AES-256-GCM)
    phone_enc BYTEA,
    dob_enc BYTEA,
    gender_enc BYTEA,
    blood_group_enc BYTEA,
    emergency_contact_enc BYTEA,
    address_enc BYTEA,
    identity_doc_enc BYTEA,
    
    fcm_tokens TEXT[] DEFAULT '{}',
    
    academic_metrics JSONB DEFAULT '{
        "cgpa": null,
        "sgpa_history": {},
        "activity_points": 0
    }'::jsonb,
    
    social_profiles JSONB DEFAULT '{
        "github": null,
        "linkedin": null,
        "portfolio": null
    }'::jsonb,
    
    preferences JSONB DEFAULT '{
        "theme": "system",
        "notifications": {
            "announcements": true,
            "event_reminders": true,
            "direct_messages": true
        },
        "privacy": {
            "show_email": false,
            "show_metrics": false
        }
    }'::jsonb,
    
    metadata JSONB DEFAULT '{
        "hosteler": false,
        "hostel_room": null,
        "bus_route_no": null
    }'::jsonb,
    
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

-- Automatic Profile Creation Trigger on Supabase Auth Signup
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (
        id, 
        full_name, 
        institutional_email,
        role,
        status
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Campus Student'),
        NEW.email,
        'student'::app_role,
        'pending_verification'::account_status
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==============================================================================
-- 6. ORGANIZATIONS (Clubs & Student Unions)
-- ==============================================================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    org_type org_type NOT NULL,
    org_category TEXT,

    core_team JSONB DEFAULT '[]',
    social_links JSONB DEFAULT '{}',
    logo_path TEXT,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(institute_id, slug)
);

CREATE UNIQUE INDEX unique_student_union_per_institute 
ON organizations (institute_id) 
WHERE (org_type = 'student_union');

CREATE TABLE organization_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    role member_role DEFAULT 'member' NOT NULL,
    designation TEXT,
    joined_at TIMESTAMPTZ DEFAULT now(),
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(org_id, user_id)
);

-- ==============================================================================
-- 7. EVENTS & TICKETING
-- ==============================================================================

CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    primary_org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    venue TEXT,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    reg_end TIMESTAMPTZ,
    tags TEXT[] DEFAULT '{}',
    poster_url TEXT,
    visibility event_visibility DEFAULT 'institute',
    
    reg_config BOOLEAN DEFAULT false,    
    status event_status DEFAULT 'draft', 
    
    eligibility JSONB DEFAULT '{}',       
    collaborators JSONB DEFAULT '[]',    
    itinerary JSONB DEFAULT '[]',
    pricing JSONB DEFAULT '{}',
    incentives JSONB DEFAULT '{}',
    contacts JSONB DEFAULT '[]',
    links JSONB DEFAULT '{}',
    media_urls JSONB DEFAULT '[]',

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT check_event_chronology CHECK (start_time < end_time),
    CONSTRAINT check_registration_window CHECK (reg_end <= start_time)
);

CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    status ticket_status DEFAULT 'confirmed'::ticket_status,
    qr_payload TEXT NOT NULL UNIQUE,
    
    payment_data JSONB DEFAULT '{}',
    scanned_at TIMESTAMPTZ,
    scanned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(event_id, user_id)
);

-- ==============================================================================
-- 8. CAMPUS BROADCASTS & POSTS
-- ==============================================================================

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    org_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    media_urls TEXT[] DEFAULT '{}',
    attachments JSONB DEFAULT '[]',
    
    scope post_scope DEFAULT 'campus_wide' NOT NULL,
    status post_status DEFAULT 'published' NOT NULL,
    is_pinned BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ==============================================================================
-- 9. TIMETABLES & SCHEDULE MATRIX
-- ==============================================================================

CREATE TABLE class_timetables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    allocation_id UUID NOT NULL REFERENCES class_course_allocations(id) ON DELETE CASCADE,
    
    day day_of_week NOT NULL,
    period_number INT NOT NULL,          -- Period 1, 2, 3...
    classroom_hall TEXT,                 -- e.g., 'LH-302'
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
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
    
    title TEXT NOT NULL,
    verification_hash TEXT UNIQUE NOT NULL, -- SHA-256 validation token
    pdf_storage_path TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    
    issued_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
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
CREATE INDEX idx_profiles_institute ON profiles(institute_id);
CREATE INDEX idx_profiles_department ON profiles(department_id);
CREATE INDEX idx_profiles_class ON profiles(class_id);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_university_reg ON profiles(university_reg_no);
CREATE INDEX idx_profiles_inst_email ON profiles(institutional_email);
CREATE INDEX idx_profiles_gin_metrics ON profiles USING GIN (academic_metrics);

-- Event Discovery & QR Validation
CREATE INDEX idx_events_lookup ON events(institute_id, status, start_time);
CREATE INDEX idx_events_visibility ON events(visibility);
CREATE INDEX idx_registrations_qr ON event_registrations(qr_payload);
CREATE INDEX idx_registrations_user ON event_registrations(user_id, event_id);

-- Timetable Queries
CREATE INDEX idx_timetable_class ON class_timetables(class_id, day);

-- Certificate Verification
CREATE INDEX idx_cert_hash ON certificates(verification_hash);

-- Course & Enrollment Mappings
CREATE INDEX idx_programme_courses_course ON programme_courses(course_id);
CREATE INDEX idx_class_alloc_course ON class_course_allocations(course_id);
CREATE INDEX idx_enrollments_student ON student_course_enrollments(student_id, allocation_id);
CREATE INDEX idx_enrollments_status ON student_course_enrollments(status);

-- Organizations
CREATE INDEX idx_org_members_org ON organization_members(org_id);
CREATE INDEX idx_org_members_user ON organization_members(user_id);