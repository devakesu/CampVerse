-- ==============================================================================
-- 0. EXTENSIONS & TRIGGERS
-- ==============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Generic updated_at trigger function
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

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

CREATE TYPE org_type AS ENUM (
    'student_union',
    'club'
);

CREATE TYPE event_status AS ENUM ('draft', 'published', 'cancelled', 'completed');
CREATE TYPE ticket_status AS ENUM ('reserved', 'confirmed', 'used', 'cancelled');

-- ==============================================================================
-- 2. ACADEMIC TOPOLOGY (Multi-Tenant Hierarchy)
-- ==============================================================================

CREATE TABLE institutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    domain TEXT UNIQUE,
    
    -- Configs & Branding
    branding JSONB DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL,          -- e.g., 'CSE', 'ECE'
    hod_id UUID,                 -- FK to profiles (added later to avoid circular refs)
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(institute_id, code)
);

CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    name TEXT NOT NULL,          -- e.g., 'Computer Science and Business Systems'
    course_code TEXT NOT NULL,   -- e.g., 'CSBS'  
    degree_type TEXT NOT NULL,   -- e.g., 'B.Tech.', 'B.Sc.', 'M.Sc.', 'M.Tech.', 'PhD'
    degree_level TEXT NOT NULL,  -- 'UG', 'PG', 'PhD'
    duration_years INT NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(institute_id, course_code)
);

CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    
    -- Cohort Identification
    admission_year INT NOT NULL, 
    grad_year INT NOT NULL,
    current_semester INT NOT NULL DEFAULT 1,
    division TEXT,               -- e.g., 'A', 'B'
    
    -- Leadership 
    staff_advisor_id UUID,       -- FK to profiles (Class Tutor)
    class_reps JSONB DEFAULT '[]', -- Array of Student Profile UUIDs
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    CONSTRAINT check_years CHECK (grad_year > admission_year)
);

-- ==============================================================================
-- 3. IDENTITY & PROFILES (With FLE for Sensitive Data)
-- ==============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Routing & Hierarchy
    institute_id UUID REFERENCES institutes(id) ON DELETE SET NULL,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    
    -- Query-Critical Public Data
    full_name TEXT NOT NULL,
    university_reg_no TEXT UNIQUE,  -- e.g., KTU Register Number
    role app_role DEFAULT 'student'::app_role,
    avatar_path TEXT,
    
    -- Field-Level Encryption (FLE) Columns (App-side AES-256-GCM ciphertext)
    phone_enc TEXT,
    dob_enc TEXT,
    blood_group_enc TEXT,
    emergency_contact_enc TEXT,
    
    -- Extensible Data
    academic_metrics JSONB DEFAULT '{}', -- Activity points, SGPA/CGPA snapshots
    preferences JSONB DEFAULT '{}',
    
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Resolve deferred FKs
ALTER TABLE departments ADD CONSTRAINT fk_hod FOREIGN KEY (hod_id) REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE classes ADD CONSTRAINT fk_advisor FOREIGN KEY (staff_advisor_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- ==============================================================================
-- 4. ORGANIZATIONS (Clubs & Student Unions)
-- ==============================================================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    org_type org_type NOT NULL,
    
    -- Leadership & Meta
    core_team JSONB DEFAULT '[]', -- Array of objects: { profile_id, position }
    social_links JSONB DEFAULT '{}',
    logo_path TEXT,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(institute_id, slug)
);

CREATE UNIQUE INDEX unique_student_union_per_institute 
ON organizations (institute_id) 
WHERE (org_type = 'student_union');

-- ==============================================================================
-- 5. EVENTS & TICKETING
-- ==============================================================================

CREATE TABLE events (
    -- Query-Critical Columns
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
    
    -- State & Config Columns
    reg_config BOOLEAN DEFAULT false,    
    status event_status DEFAULT 'draft', 
    
    -- Payload Columns (JSONB for multi-value flexibility)
    eligibility JSONB DEFAULT '{}',       
    collaborators JSONB DEFAULT '[]',    
    itinerary JSONB DEFAULT '[]',
    pricing JSONB DEFAULT '{}',
    incentives JSONB DEFAULT '{}',
    contacts JSONB DEFAULT '[]',
    links JSONB DEFAULT '{}',
    media_urls JSONB DEFAULT '[]',

    -- Audit Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    -- Inline Data Integrity Checks
    CONSTRAINT check_event_chronology CHECK (start_time < end_time),
    CONSTRAINT check_registration_window CHECK (reg_end <= start_time)
);

CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    status ticket_status DEFAULT 'confirmed'::ticket_status,
    qr_payload TEXT NOT NULL UNIQUE,
    
    -- Financial/Access Details
    payment_data JSONB DEFAULT '{}', -- order_id, receipt info
    scanned_at TIMESTAMPTZ,
    scanned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(event_id, user_id)
);

-- ==============================================================================
-- 6. APPLY AUTOMATIC TRIGGERS
-- ==============================================================================
CREATE TRIGGER set_timestamp_institutes BEFORE UPDATE ON institutes FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_departments BEFORE UPDATE ON departments FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_classes BEFORE UPDATE ON classes FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_profiles BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_orgs BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER set_timestamp_events BEFORE UPDATE ON events FOR EACH ROW EXECUTE PROCEDURE update_modified_column();