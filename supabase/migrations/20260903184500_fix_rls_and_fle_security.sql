-- ==============================================================================
-- FIX ALL DB RLS CONFIGS & ENFORCE SERVER-ONLY FLE WRITES
-- Migration: 20260903184500_fix_rls_and_fle_security.sql
-- ==============================================================================

-- ---------------------------------------------------------------------------
-- 1. TOPOLOGY & SCHEMA ADJUSTMENTS
-- ---------------------------------------------------------------------------

-- Add department_id to courses to enable HOD-level department authorization
ALTER TABLE public.courses
    ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_courses_department ON public.courses(department_id);

-- Add lead_id (club chair / primary lead) to organizations
ALTER TABLE public.organizations
    ADD COLUMN IF NOT EXISTS lead_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_organizations_lead ON public.organizations(lead_id);

-- ---------------------------------------------------------------------------
-- 2. SECURITY HELPER FUNCTIONS
-- ---------------------------------------------------------------------------

-- Returns TRUE if current transaction is running under server-level / service_role authority
CREATE OR REPLACE FUNCTION public.is_server_role()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_jwt_role text;
BEGIN
    -- If request came through PostgREST / Supabase API, inspect JWT claim
    v_jwt_role := coalesce(
        nullif(current_setting('request.jwt.claim.role', true), ''),
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
    );

    IF v_jwt_role IS NOT NULL THEN
        RETURN (v_jwt_role = 'service_role');
    END IF;

    -- Direct DB connection (not via PostgREST authenticator)
    RETURN (session_user IN ('postgres', 'service_role', 'supabase_admin'));
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_server_role() TO authenticated, anon, service_role;

-- Refined auth_role helper supporting service_role and verified active_role in JWT
CREATE OR REPLACE FUNCTION public.auth_role()
RETURNS app_role
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_role text;
    v_app_role app_role;
    v_base_role app_role;
BEGIN
    -- 1. Direct server / service_role authority
    IF public.is_server_role() THEN
        RETURN 'super_admin'::app_role;
    END IF;

    IF auth.uid() IS NULL THEN
        RETURN NULL;
    END IF;

    -- 2. Fetch base role from profile
    SELECT role INTO v_base_role FROM public.profiles WHERE id = auth.uid();

    -- 3. Check if active_role is present in JWT app_metadata
    v_role := (nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' ->> 'active_role');
    IF v_role IS NOT NULL THEN
        BEGIN
            v_app_role := v_role::app_role;
            -- Validate that user is authorized for this role via profile or derived roles
            IF v_app_role = v_base_role OR v_app_role = ANY(public.get_user_derived_roles(auth.uid())) THEN
                RETURN v_app_role;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
    END IF;

    RETURN v_base_role;
END;
$$;

GRANT EXECUTE ON FUNCTION public.auth_role() TO authenticated, anon, service_role;

-- Verify if user is staff or administrator in their institute
CREATE OR REPLACE FUNCTION public.is_staff_or_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT (
        public.auth_role() IN ('super_admin', 'principal', 'office_admin', 'hod', 'faculty')
    );
$$;

GRANT EXECUTE ON FUNCTION public.is_staff_or_admin() TO authenticated, anon, service_role;

-- Verify if user is an active organization lead / core member or designated club chair
CREATE OR REPLACE FUNCTION public.is_org_lead(target_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT (
        public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.organizations o
            WHERE o.id = target_org_id
              AND (o.institute_id = public.auth_institute_id() OR public.auth_role() = 'super_admin')
              AND (
                  public.auth_role() IN ('principal', 'office_admin')
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

GRANT EXECUTE ON FUNCTION public.is_org_lead(UUID) TO authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- 3. RLS POLICIES ACROSS ALL RELEVANT TABLES
-- ---------------------------------------------------------------------------

-- ==================== 1. UNIVERSITIES ====================
ALTER TABLE public.universities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public universities read" ON public.universities;
DROP POLICY IF EXISTS "Super admins can insert universities" ON public.universities;
DROP POLICY IF EXISTS "Super admins can update universities" ON public.universities;
DROP POLICY IF EXISTS "Super admins can delete universities" ON public.universities;

CREATE POLICY "Public universities read"
    ON public.universities FOR SELECT
    USING (TRUE);

CREATE POLICY "Super admins can insert universities"
    ON public.universities FOR INSERT
    WITH CHECK (public.auth_role() = 'super_admin');

CREATE POLICY "Super admins can update universities"
    ON public.universities FOR UPDATE
    USING (public.auth_role() = 'super_admin')
    WITH CHECK (public.auth_role() = 'super_admin');

CREATE POLICY "Super admins can delete universities"
    ON public.universities FOR DELETE
    USING (public.auth_role() = 'super_admin');

-- ==================== 2. INSTITUTES ====================
ALTER TABLE public.institutes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read active institutes" ON public.institutes;
DROP POLICY IF EXISTS "Admin update institute" ON public.institutes;
DROP POLICY IF EXISTS "Super admins can insert institutes" ON public.institutes;
DROP POLICY IF EXISTS "Super admins can delete institutes" ON public.institutes;

CREATE POLICY "Read active institutes"
    ON public.institutes FOR SELECT
    USING (
        is_active = TRUE
        OR public.auth_role() = 'super_admin'
        OR (id = public.auth_institute_id() AND public.auth_role() IN ('principal', 'office_admin'))
    );

CREATE POLICY "Super admins can insert institutes"
    ON public.institutes FOR INSERT
    WITH CHECK (public.auth_role() = 'super_admin');

CREATE POLICY "Admin update institute"
    ON public.institutes FOR UPDATE
    USING (
        public.auth_role() = 'super_admin'
        OR (id = public.auth_institute_id() AND public.auth_role() IN ('principal', 'office_admin'))
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (id = public.auth_institute_id() AND public.auth_role() IN ('principal', 'office_admin'))
    );

CREATE POLICY "Super admins can delete institutes"
    ON public.institutes FOR DELETE
    USING (public.auth_role() = 'super_admin');

-- ==================== 3. DEPARTMENTS ====================
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read campus departments" ON public.departments;
DROP POLICY IF EXISTS "Manage campus departments" ON public.departments;
DROP POLICY IF EXISTS "Insert campus departments" ON public.departments;
DROP POLICY IF EXISTS "Update campus departments" ON public.departments;
DROP POLICY IF EXISTS "Delete campus departments" ON public.departments;

CREATE POLICY "Read campus departments"
    ON public.departments FOR SELECT
    USING (institute_id = public.auth_institute_id() OR public.auth_role() = 'super_admin');

CREATE POLICY "Insert campus departments"
    ON public.departments FOR INSERT
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (institute_id = public.auth_institute_id() AND public.auth_role() IN ('principal', 'office_admin'))
    );

CREATE POLICY "Update campus departments"
    ON public.departments FOR UPDATE
    USING (
        public.auth_role() = 'super_admin'
        OR (
            institute_id = public.auth_institute_id()
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR hod_id = auth.uid()
            )
        )
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (
            institute_id = public.auth_institute_id()
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR hod_id = auth.uid()
            )
        )
    );

CREATE POLICY "Delete campus departments"
    ON public.departments FOR DELETE
    USING (
        public.auth_role() = 'super_admin'
        OR (institute_id = public.auth_institute_id() AND public.auth_role() IN ('principal', 'office_admin'))
    );

-- ==================== 4. PROGRAMMES ====================
ALTER TABLE public.programmes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read campus programmes" ON public.programmes;
DROP POLICY IF EXISTS "Manage campus programmes" ON public.programmes;

CREATE POLICY "Read campus programmes"
    ON public.programmes FOR SELECT
    USING (institute_id = public.auth_institute_id() OR public.auth_role() = 'super_admin');

CREATE POLICY "Manage campus programmes"
    ON public.programmes FOR ALL
    USING (
        public.auth_role() = 'super_admin'
        OR (
            institute_id = public.auth_institute_id()
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR EXISTS (
                    SELECT 1 FROM public.departments d
                    WHERE d.id = programmes.department_id AND d.hod_id = auth.uid()
                )
            )
        )
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (
            institute_id = public.auth_institute_id()
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR EXISTS (
                    SELECT 1 FROM public.departments d
                    WHERE d.id = programmes.department_id AND d.hod_id = auth.uid()
                )
            )
        )
    );

-- ==================== 5. CURRICULUM SCHEMES ====================
ALTER TABLE public.curriculum_schemes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read accessible schemes" ON public.curriculum_schemes;
DROP POLICY IF EXISTS "Manage curriculum schemes" ON public.curriculum_schemes;

CREATE POLICY "Read accessible schemes"
    ON public.curriculum_schemes FOR SELECT
    USING (
        university_id IS NOT NULL
        OR institute_id = public.auth_institute_id()
        OR public.auth_role() = 'super_admin'
    );

CREATE POLICY "Manage curriculum schemes"
    ON public.curriculum_schemes FOR ALL
    USING (
        public.auth_role() = 'super_admin'
        OR (
            institute_id IS NOT NULL
            AND institute_id = public.auth_institute_id()
            AND public.auth_role() IN ('principal', 'office_admin')
        )
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (
            institute_id IS NOT NULL
            AND institute_id = public.auth_institute_id()
            AND public.auth_role() IN ('principal', 'office_admin')
        )
    );

-- ==================== 6. COURSES ====================
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read accessible courses" ON public.courses;
DROP POLICY IF EXISTS "Manage courses" ON public.courses;

CREATE POLICY "Read accessible courses"
    ON public.courses FOR SELECT
    USING (
        university_id IS NOT NULL
        OR institute_id = public.auth_institute_id()
        OR public.auth_role() = 'super_admin'
    );

CREATE POLICY "Manage courses"
    ON public.courses FOR ALL
    USING (
        public.auth_role() = 'super_admin'
        OR (
            institute_id IS NOT NULL
            AND institute_id = public.auth_institute_id()
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR (
                    courses.department_id IS NOT NULL
                    AND EXISTS (
                        SELECT 1 FROM public.departments d
                        WHERE d.id = courses.department_id AND d.hod_id = auth.uid()
                    )
                )
            )
        )
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (
            institute_id IS NOT NULL
            AND institute_id = public.auth_institute_id()
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR (
                    courses.department_id IS NOT NULL
                    AND EXISTS (
                        SELECT 1 FROM public.departments d
                        WHERE d.id = courses.department_id AND d.hod_id = auth.uid()
                    )
                )
            )
        )
    );

-- ==================== 7. PROGRAMME COURSES ====================
ALTER TABLE public.programme_courses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read programme course mappings" ON public.programme_courses;
DROP POLICY IF EXISTS "Manage programme course mappings" ON public.programme_courses;

CREATE POLICY "Read programme course mappings"
    ON public.programme_courses FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.programmes p 
            WHERE p.id = programme_courses.programme_id 
              AND (p.institute_id = public.auth_institute_id() OR public.auth_role() = 'super_admin')
        )
    );

CREATE POLICY "Manage programme course mappings"
    ON public.programme_courses FOR ALL
    USING (
        public.auth_role() = 'super_admin'
        OR (
            EXISTS (
                SELECT 1 FROM public.programmes p 
                WHERE p.id = programme_courses.programme_id 
                  AND p.institute_id = public.auth_institute_id()
            )
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR EXISTS (
                    SELECT 1 FROM public.courses c
                    JOIN public.departments d ON d.id = c.department_id
                    WHERE c.id = programme_courses.course_id AND d.hod_id = auth.uid()
                )
                OR EXISTS (
                    SELECT 1 FROM public.programmes p
                    JOIN public.departments d ON d.id = p.department_id
                    WHERE p.id = programme_courses.programme_id AND d.hod_id = auth.uid()
                )
            )
        )
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (
            EXISTS (
                SELECT 1 FROM public.programmes p 
                WHERE p.id = programme_courses.programme_id 
                  AND p.institute_id = public.auth_institute_id()
            )
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR EXISTS (
                    SELECT 1 FROM public.courses c
                    JOIN public.departments d ON d.id = c.department_id
                    WHERE c.id = programme_courses.course_id AND d.hod_id = auth.uid()
                )
                OR EXISTS (
                    SELECT 1 FROM public.programmes p
                    JOIN public.departments d ON d.id = p.department_id
                    WHERE p.id = programme_courses.programme_id AND d.hod_id = auth.uid()
                )
            )
        )
    );

-- ==================== 8. CLASSES ====================
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read campus classes" ON public.classes;
DROP POLICY IF EXISTS "Manage campus classes" ON public.classes;
DROP POLICY IF EXISTS "Insert campus classes" ON public.classes;
DROP POLICY IF EXISTS "Update campus classes" ON public.classes;
DROP POLICY IF EXISTS "Delete campus classes" ON public.classes;

CREATE POLICY "Read campus classes"
    ON public.classes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.programmes p 
            WHERE p.id = classes.programme_id 
              AND (p.institute_id = public.auth_institute_id() OR public.auth_role() = 'super_admin')
        )
    );

CREATE POLICY "Insert campus classes"
    ON public.classes FOR INSERT
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.programmes p 
            WHERE p.id = classes.programme_id 
              AND p.institute_id = public.auth_institute_id()
              AND (
                  public.auth_role() IN ('principal', 'office_admin')
                  OR EXISTS (
                      SELECT 1 FROM public.departments d 
                      WHERE d.id = p.department_id AND d.hod_id = auth.uid()
                  )
              )
        )
    );

CREATE POLICY "Update campus classes"
    ON public.classes FOR UPDATE
    USING (
        public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.programmes p 
            WHERE p.id = classes.programme_id 
              AND p.institute_id = public.auth_institute_id()
              AND (
                  public.auth_role() IN ('principal', 'office_admin')
                  OR classes.staff_advisor_id = auth.uid()
                  OR EXISTS (
                      SELECT 1 FROM public.departments d 
                      WHERE d.id = p.department_id AND d.hod_id = auth.uid()
                  )
              )
        )
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.programmes p 
            WHERE p.id = classes.programme_id 
              AND p.institute_id = public.auth_institute_id()
              AND (
                  public.auth_role() IN ('principal', 'office_admin')
                  OR classes.staff_advisor_id = auth.uid()
                  OR EXISTS (
                      SELECT 1 FROM public.departments d 
                      WHERE d.id = p.department_id AND d.hod_id = auth.uid()
                  )
              )
        )
    );

CREATE POLICY "Delete campus classes"
    ON public.classes FOR DELETE
    USING (
        public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.programmes p 
            WHERE p.id = classes.programme_id 
              AND p.institute_id = public.auth_institute_id()
              AND (
                  public.auth_role() IN ('principal', 'office_admin')
                  OR EXISTS (
                      SELECT 1 FROM public.departments d 
                      WHERE d.id = p.department_id AND d.hod_id = auth.uid()
                  )
              )
        )
    );

-- ==================== 9. CLASS COURSE ALLOCATIONS ====================
ALTER TABLE public.class_course_allocations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read course allocations" ON public.class_course_allocations;
DROP POLICY IF EXISTS "Manage course allocations" ON public.class_course_allocations;

CREATE POLICY "Read course allocations"
    ON public.class_course_allocations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.classes c 
            JOIN public.programmes p ON p.id = c.programme_id 
            WHERE c.id = class_course_allocations.class_id 
              AND (p.institute_id = public.auth_institute_id() OR public.auth_role() = 'super_admin')
        )
    );

CREATE POLICY "Manage course allocations"
    ON public.class_course_allocations FOR ALL
    USING (
        public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.classes c 
            JOIN public.programmes p ON p.id = c.programme_id 
            WHERE c.id = class_course_allocations.class_id 
              AND p.institute_id = public.auth_institute_id()
              AND (
                  public.auth_role() IN ('principal', 'office_admin')
                  OR c.staff_advisor_id = auth.uid()
                  OR EXISTS (
                      SELECT 1 FROM public.departments d 
                      WHERE d.id = p.department_id AND d.hod_id = auth.uid()
                  )
              )
        )
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.classes c 
            JOIN public.programmes p ON p.id = c.programme_id 
            WHERE c.id = class_course_allocations.class_id 
              AND p.institute_id = public.auth_institute_id()
              AND (
                  public.auth_role() IN ('principal', 'office_admin')
                  OR c.staff_advisor_id = auth.uid()
                  OR EXISTS (
                      SELECT 1 FROM public.departments d 
                      WHERE d.id = p.department_id AND d.hod_id = auth.uid()
                  )
              )
        )
    );

-- ==================== 10. STUDENT COURSE ENROLLMENTS ====================
ALTER TABLE public.student_course_enrollments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read own or advised student enrollments" ON public.student_course_enrollments;
DROP POLICY IF EXISTS "Manage student enrollments" ON public.student_course_enrollments;

CREATE POLICY "Read own or advised student enrollments"
    ON public.student_course_enrollments FOR SELECT
    USING (
        student_id = auth.uid()
        OR public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.class_course_allocations cca
            JOIN public.classes c ON c.id = cca.class_id
            JOIN public.programmes p ON p.id = c.programme_id
            WHERE cca.id = student_course_enrollments.allocation_id
              AND p.institute_id = public.auth_institute_id()
              AND public.is_staff_or_admin()
        )
    );

CREATE POLICY "Manage student enrollments"
    ON public.student_course_enrollments FOR ALL
    USING (
        student_id = auth.uid()
        OR public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.class_course_allocations cca
            JOIN public.classes c ON c.id = cca.class_id
            JOIN public.programmes p ON p.id = c.programme_id
            WHERE cca.id = student_course_enrollments.allocation_id
              AND p.institute_id = public.auth_institute_id()
              AND public.is_staff_or_admin()
        )
    )
    WITH CHECK (
        student_id = auth.uid()
        OR public.auth_role() = 'super_admin'
        OR EXISTS (
            SELECT 1 FROM public.class_course_allocations cca
            JOIN public.classes c ON c.id = cca.class_id
            JOIN public.programmes p ON p.id = c.programme_id
            WHERE cca.id = student_course_enrollments.allocation_id
              AND p.institute_id = public.auth_institute_id()
              AND public.is_staff_or_admin()
        )
    );

-- ==================== 11. PROFILES ====================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View campus member profiles" ON public.profiles;
DROP POLICY IF EXISTS "Update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Server insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Server delete profiles" ON public.profiles;

CREATE POLICY "View campus member profiles"
    ON public.profiles FOR SELECT
    USING (
        institute_id = public.auth_institute_id()
        OR id = auth.uid()
        OR public.auth_role() = 'super_admin'
    );

CREATE POLICY "Server insert profiles"
    ON public.profiles FOR INSERT
    WITH CHECK (public.is_server_role());

CREATE POLICY "Update own profile"
    ON public.profiles FOR UPDATE
    USING (
        id = auth.uid()
        OR public.auth_role() = 'super_admin'
        OR (institute_id = public.auth_institute_id() AND public.auth_role() IN ('principal', 'office_admin'))
        OR public.is_server_role()
    )
    WITH CHECK (
        id = auth.uid()
        OR public.auth_role() = 'super_admin'
        OR (institute_id = public.auth_institute_id() AND public.auth_role() IN ('principal', 'office_admin'))
        OR public.is_server_role()
    );

CREATE POLICY "Server delete profiles"
    ON public.profiles FOR DELETE
    USING (public.is_server_role());

-- ==================== 12. ORGANIZATIONS ====================
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View campus organizations" ON public.organizations;
DROP POLICY IF EXISTS "Manage organizations" ON public.organizations;
DROP POLICY IF EXISTS "Insert organizations" ON public.organizations;
DROP POLICY IF EXISTS "Update organizations" ON public.organizations;
DROP POLICY IF EXISTS "Delete organizations" ON public.organizations;

CREATE POLICY "View campus organizations"
    ON public.organizations FOR SELECT
    USING (institute_id = public.auth_institute_id() OR public.auth_role() = 'super_admin');

CREATE POLICY "Insert organizations"
    ON public.organizations FOR INSERT
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (public.auth_role() IN ('principal', 'office_admin') AND institute_id = public.auth_institute_id())
    );

-- Update permitted for super_admin, principal, office_admin, and the club chair / lead (lead_id)
CREATE POLICY "Update organizations"
    ON public.organizations FOR UPDATE
    USING (
        public.auth_role() = 'super_admin'
        OR (
            institute_id = public.auth_institute_id()
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR lead_id = auth.uid()
            )
        )
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (
            institute_id = public.auth_institute_id()
            AND (
                public.auth_role() IN ('principal', 'office_admin')
                OR lead_id = auth.uid()
            )
        )
    );

CREATE POLICY "Delete organizations"
    ON public.organizations FOR DELETE
    USING (
        public.auth_role() = 'super_admin'
        OR (public.auth_role() IN ('principal', 'office_admin') AND institute_id = public.auth_institute_id())
    );

-- ==================== 13. ORGANIZATION MEMBERS ====================
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View organization members" ON public.organization_members;
DROP POLICY IF EXISTS "Manage organization members" ON public.organization_members;

CREATE POLICY "View organization members"
    ON public.organization_members FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.organizations o 
            WHERE o.id = organization_members.org_id 
              AND (o.institute_id = public.auth_institute_id() OR public.auth_role() = 'super_admin')
        )
    );

CREATE POLICY "Manage organization members"
    ON public.organization_members FOR ALL
    USING (public.is_org_lead(org_id))
    WITH CHECK (public.is_org_lead(org_id));

-- ==================== 14. EVENTS ====================
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View published events" ON public.events;
DROP POLICY IF EXISTS "Create and manage club events" ON public.events;

CREATE POLICY "View published events"
    ON public.events FOR SELECT
    USING (
        (status = 'published' AND (
            visibility = 'public'
            OR (visibility = 'institute' AND institute_id = public.auth_institute_id())
            OR (visibility = 'club' AND public.is_org_lead(primary_org_id))
        ))
        OR public.is_org_lead(primary_org_id)
        OR public.auth_role() = 'super_admin'
        OR (public.auth_role() IN ('principal', 'office_admin') AND institute_id = public.auth_institute_id())
    );

CREATE POLICY "Create and manage club events"
    ON public.events FOR ALL
    USING (
        public.is_org_lead(primary_org_id)
        OR public.auth_role() = 'super_admin'
        OR (public.auth_role() IN ('principal', 'office_admin') AND institute_id = public.auth_institute_id())
    )
    WITH CHECK (
        public.is_org_lead(primary_org_id)
        OR public.auth_role() = 'super_admin'
        OR (public.auth_role() IN ('principal', 'office_admin') AND institute_id = public.auth_institute_id())
    );

-- ==================== 15. POSTS ====================
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View scoped posts" ON public.posts;
DROP POLICY IF EXISTS "Publish posts" ON public.posts;
DROP POLICY IF EXISTS "Update posts" ON public.posts;
DROP POLICY IF EXISTS "Delete posts" ON public.posts;

CREATE POLICY "View scoped posts"
    ON public.posts FOR SELECT
    USING (
        public.auth_role() = 'super_admin'
        OR (
            status = 'published'
            AND institute_id = public.auth_institute_id()
            AND (
                scope = 'campus_wide'
                OR (scope = 'department' AND department_id = (SELECT department_id FROM public.profiles WHERE id = auth.uid()))
                OR (scope = 'class_only' AND class_id = (SELECT class_id FROM public.profiles WHERE id = auth.uid()))
                OR (scope = 'club_members' AND public.is_org_lead(org_id))
            )
        )
    );

CREATE POLICY "Publish posts"
    ON public.posts FOR INSERT
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (
            institute_id = public.auth_institute_id()
            AND (
                public.is_staff_or_admin()
                OR (org_id IS NOT NULL AND public.is_org_lead(org_id))
            )
        )
    );

CREATE POLICY "Update posts"
    ON public.posts FOR UPDATE
    USING (
        public.auth_role() = 'super_admin'
        OR author_id = auth.uid()
        OR (institute_id = public.auth_institute_id() AND public.is_staff_or_admin())
        OR (org_id IS NOT NULL AND public.is_org_lead(org_id))
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR author_id = auth.uid()
        OR (institute_id = public.auth_institute_id() AND public.is_staff_or_admin())
        OR (org_id IS NOT NULL AND public.is_org_lead(org_id))
    );

CREATE POLICY "Delete posts"
    ON public.posts FOR DELETE
    USING (
        public.auth_role() = 'super_admin'
        OR author_id = auth.uid()
        OR (institute_id = public.auth_institute_id() AND public.is_staff_or_admin())
        OR (org_id IS NOT NULL AND public.is_org_lead(org_id))
    );

-- ==================== 16. CERTIFICATES ====================
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Read own certificates or verify hash" ON public.certificates;
DROP POLICY IF EXISTS "Issue certificates" ON public.certificates;
DROP POLICY IF EXISTS "Update certificates" ON public.certificates;
DROP POLICY IF EXISTS "Delete certificates" ON public.certificates;

CREATE POLICY "Read own certificates or verify hash"
    ON public.certificates FOR SELECT
    USING (
        recipient_id = auth.uid()
        OR public.auth_role() = 'super_admin'
        OR verification_hash IS NOT NULL
    );

CREATE POLICY "Issue certificates"
    ON public.certificates FOR INSERT
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (
            institute_id = public.auth_institute_id()
            AND (
                public.is_staff_or_admin()
                OR (event_id IS NOT NULL AND EXISTS (
                    SELECT 1 FROM public.events e WHERE e.id = event_id AND public.is_org_lead(e.primary_org_id)
                ))
            )
        )
    );

CREATE POLICY "Update certificates"
    ON public.certificates FOR UPDATE
    USING (
        public.auth_role() = 'super_admin'
        OR (institute_id = public.auth_institute_id() AND public.is_staff_or_admin())
    )
    WITH CHECK (
        public.auth_role() = 'super_admin'
        OR (institute_id = public.auth_institute_id() AND public.is_staff_or_admin())
    );

CREATE POLICY "Delete certificates"
    ON public.certificates FOR DELETE
    USING (
        public.auth_role() = 'super_admin'
        OR (institute_id = public.auth_institute_id() AND public.is_staff_or_admin())
    );

-- ---------------------------------------------------------------------------
-- 4. FLE SERVER-ONLY COLUMN ENFORCEMENT (TRIGGERS & PRIVILEGES)
-- ---------------------------------------------------------------------------

-- 4.1 PROFILES FLE TRIGGER
CREATE OR REPLACE FUNCTION public.trg_enforce_profiles_fle_server_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_server_role() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.full_name_enc IS NOT NULL OR NEW.full_name_bidx IS NOT NULL
           OR NEW.bio_enc IS NOT NULL OR NEW.avatar_path_enc IS NOT NULL
           OR NEW.institutional_email_enc IS NOT NULL OR NEW.institutional_email_bidx IS NOT NULL
           OR NEW.university_reg_no_enc IS NOT NULL OR NEW.university_reg_no_bidx IS NOT NULL
           OR NEW.admission_no_enc IS NOT NULL OR NEW.admission_no_bidx IS NOT NULL
           OR NEW.phone_enc IS NOT NULL OR NEW.phone_bidx IS NOT NULL
           OR NEW.dob_enc IS NOT NULL OR NEW.gender_enc IS NOT NULL
           OR NEW.blood_group_enc IS NOT NULL OR NEW.emergency_contact_enc IS NOT NULL
           OR NEW.address_enc IS NOT NULL OR NEW.identity_doc_enc IS NOT NULL
           OR NEW.academic_metrics_enc IS NOT NULL OR NEW.metadata_enc IS NOT NULL
           OR NEW.social_profiles_enc IS NOT NULL OR NEW.fcm_tokens_enc IS NOT NULL THEN
            RAISE EXCEPTION 'FLE columns in profiles can only be written by the server';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.full_name_enc IS DISTINCT FROM OLD.full_name_enc
           OR NEW.full_name_bidx IS DISTINCT FROM OLD.full_name_bidx
           OR NEW.bio_enc IS DISTINCT FROM OLD.bio_enc
           OR NEW.avatar_path_enc IS DISTINCT FROM OLD.avatar_path_enc
           OR NEW.institutional_email_enc IS DISTINCT FROM OLD.institutional_email_enc
           OR NEW.institutional_email_bidx IS DISTINCT FROM OLD.institutional_email_bidx
           OR NEW.university_reg_no_enc IS DISTINCT FROM OLD.university_reg_no_enc
           OR NEW.university_reg_no_bidx IS DISTINCT FROM OLD.university_reg_no_bidx
           OR NEW.admission_no_enc IS DISTINCT FROM OLD.admission_no_enc
           OR NEW.admission_no_bidx IS DISTINCT FROM OLD.admission_no_bidx
           OR NEW.phone_enc IS DISTINCT FROM OLD.phone_enc
           OR NEW.phone_bidx IS DISTINCT FROM OLD.phone_bidx
           OR NEW.dob_enc IS DISTINCT FROM OLD.dob_enc
           OR NEW.gender_enc IS DISTINCT FROM OLD.gender_enc
           OR NEW.blood_group_enc IS DISTINCT FROM OLD.blood_group_enc
           OR NEW.emergency_contact_enc IS DISTINCT FROM OLD.emergency_contact_enc
           OR NEW.address_enc IS DISTINCT FROM OLD.address_enc
           OR NEW.identity_doc_enc IS DISTINCT FROM OLD.identity_doc_enc
           OR NEW.academic_metrics_enc IS DISTINCT FROM OLD.academic_metrics_enc
           OR NEW.metadata_enc IS DISTINCT FROM OLD.metadata_enc
           OR NEW.social_profiles_enc IS DISTINCT FROM OLD.social_profiles_enc
           OR NEW.fcm_tokens_enc IS DISTINCT FROM OLD.fcm_tokens_enc THEN
            RAISE EXCEPTION 'FLE columns in profiles can only be written by the server';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_fle_enforce ON public.profiles;
CREATE TRIGGER trg_profiles_fle_enforce
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_profiles_fle_server_only();

-- 4.2 INSTITUTES SECRETS TRIGGER
CREATE OR REPLACE FUNCTION public.trg_enforce_institutes_secrets_server_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_server_role() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' AND NEW.secrets IS NOT NULL THEN
        RAISE EXCEPTION 'Institute secrets can only be written by the server';
    ELSIF TG_OP = 'UPDATE' AND NEW.secrets IS DISTINCT FROM OLD.secrets THEN
        RAISE EXCEPTION 'Institute secrets can only be written by the server';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_institutes_secrets_enforce ON public.institutes;
CREATE TRIGGER trg_institutes_secrets_enforce
    BEFORE INSERT OR UPDATE ON public.institutes
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_institutes_secrets_server_only();

-- 4.3 ORGANIZATIONS FLE TRIGGER
CREATE OR REPLACE FUNCTION public.trg_enforce_organizations_fle_server_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_server_role() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.description_enc IS NOT NULL OR NEW.contacts_enc IS NOT NULL
           OR NEW.social_links_enc IS NOT NULL OR NEW.secrets_enc IS NOT NULL
           OR NEW.core_team_enc IS NOT NULL THEN
            RAISE EXCEPTION 'FLE columns in organizations can only be written by the server';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.description_enc IS DISTINCT FROM OLD.description_enc
           OR NEW.contacts_enc IS DISTINCT FROM OLD.contacts_enc
           OR NEW.social_links_enc IS DISTINCT FROM OLD.social_links_enc
           OR NEW.secrets_enc IS DISTINCT FROM OLD.secrets_enc
           OR NEW.core_team_enc IS DISTINCT FROM OLD.core_team_enc THEN
            RAISE EXCEPTION 'FLE columns in organizations can only be written by the server';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_organizations_fle_enforce ON public.organizations;
CREATE TRIGGER trg_organizations_fle_enforce
    BEFORE INSERT OR UPDATE ON public.organizations
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_organizations_fle_server_only();

-- 4.4 ORGANIZATION MEMBERS FLE TRIGGER
CREATE OR REPLACE FUNCTION public.trg_enforce_org_members_fle_server_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_server_role() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.designation_enc IS NOT NULL OR NEW.internal_notes_enc IS NOT NULL THEN
            RAISE EXCEPTION 'FLE columns in organization_members can only be written by the server';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.designation_enc IS DISTINCT FROM OLD.designation_enc
           OR NEW.internal_notes_enc IS DISTINCT FROM OLD.internal_notes_enc THEN
            RAISE EXCEPTION 'FLE columns in organization_members can only be written by the server';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_org_members_fle_enforce ON public.organization_members;
CREATE TRIGGER trg_org_members_fle_enforce
    BEFORE INSERT OR UPDATE ON public.organization_members
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_org_members_fle_server_only();

-- 4.5 EVENTS FLE TRIGGER
CREATE OR REPLACE FUNCTION public.trg_enforce_events_fle_server_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_server_role() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' AND NEW.internal_notes_enc IS NOT NULL THEN
        RAISE EXCEPTION 'FLE columns in events can only be written by the server';
    ELSIF TG_OP = 'UPDATE' AND NEW.internal_notes_enc IS DISTINCT FROM OLD.internal_notes_enc THEN
        RAISE EXCEPTION 'FLE columns in events can only be written by the server';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_events_fle_enforce ON public.events;
CREATE TRIGGER trg_events_fle_enforce
    BEFORE INSERT OR UPDATE ON public.events
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_events_fle_server_only();

-- 4.6 EVENT REGISTRATIONS FLE TRIGGER
CREATE OR REPLACE FUNCTION public.trg_enforce_event_regs_fle_server_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_server_role() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.payment_data_enc IS NOT NULL OR NEW.custom_responses_enc IS NOT NULL THEN
            RAISE EXCEPTION 'FLE columns in event_registrations can only be written by the server';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.payment_data_enc IS DISTINCT FROM OLD.payment_data_enc
           OR NEW.custom_responses_enc IS DISTINCT FROM OLD.custom_responses_enc THEN
            RAISE EXCEPTION 'FLE columns in event_registrations can only be written by the server';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_event_regs_fle_enforce ON public.event_registrations;
CREATE TRIGGER trg_event_regs_fle_enforce
    BEFORE INSERT OR UPDATE ON public.event_registrations
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_event_regs_fle_server_only();

-- 4.7 POSTS FLE TRIGGER
CREATE OR REPLACE FUNCTION public.trg_enforce_posts_fle_server_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_server_role() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.title_enc IS NOT NULL OR NEW.content_enc IS NOT NULL
           OR NEW.media_urls_enc IS NOT NULL OR NEW.attachments_enc IS NOT NULL THEN
            RAISE EXCEPTION 'FLE columns in posts can only be written by the server';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.title_enc IS DISTINCT FROM OLD.title_enc
           OR NEW.content_enc IS DISTINCT FROM OLD.content_enc
           OR NEW.media_urls_enc IS DISTINCT FROM OLD.media_urls_enc
           OR NEW.attachments_enc IS DISTINCT FROM OLD.attachments_enc THEN
            RAISE EXCEPTION 'FLE columns in posts can only be written by the server';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_posts_fle_enforce ON public.posts;
CREATE TRIGGER trg_posts_fle_enforce
    BEFORE INSERT OR UPDATE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_posts_fle_server_only();

-- 4.8 CERTIFICATES FLE TRIGGER
CREATE OR REPLACE FUNCTION public.trg_enforce_certificates_fle_server_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.is_server_role() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.title_enc IS NOT NULL OR NEW.pdf_storage_path_enc IS NOT NULL
           OR NEW.metadata_enc IS NOT NULL THEN
            RAISE EXCEPTION 'FLE columns in certificates can only be written by the server';
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.title_enc IS DISTINCT FROM OLD.title_enc
           OR NEW.pdf_storage_path_enc IS DISTINCT FROM OLD.pdf_storage_path_enc
           OR NEW.metadata_enc IS DISTINCT FROM OLD.metadata_enc THEN
            RAISE EXCEPTION 'FLE columns in certificates can only be written by the server';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_certificates_fle_enforce ON public.certificates;
CREATE TRIGGER trg_certificates_fle_enforce
    BEFORE INSERT OR UPDATE ON public.certificates
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_enforce_certificates_fle_server_only();

-- 4.9 DEFENSE IN DEPTH: REVOKE COLUMN-LEVEL WRITE PRIVILEGES FOR CLIENT ROLES
REVOKE INSERT (
    full_name_enc, full_name_bidx, bio_enc, avatar_path_enc,
    institutional_email_enc, institutional_email_bidx,
    university_reg_no_enc, university_reg_no_bidx,
    admission_no_enc, admission_no_bidx,
    phone_enc, phone_bidx,
    dob_enc, gender_enc, blood_group_enc,
    emergency_contact_enc, address_enc, identity_doc_enc,
    academic_metrics_enc, metadata_enc, social_profiles_enc,
    fcm_tokens_enc
), UPDATE (
    full_name_enc, full_name_bidx, bio_enc, avatar_path_enc,
    institutional_email_enc, institutional_email_bidx,
    university_reg_no_enc, university_reg_no_bidx,
    admission_no_enc, admission_no_bidx,
    phone_enc, phone_bidx,
    dob_enc, gender_enc, blood_group_enc,
    emergency_contact_enc, address_enc, identity_doc_enc,
    academic_metrics_enc, metadata_enc, social_profiles_enc,
    fcm_tokens_enc
) ON public.profiles FROM authenticated, anon;

REVOKE INSERT (secrets), UPDATE (secrets)
ON public.institutes FROM authenticated, anon;

REVOKE INSERT (description_enc, contacts_enc, social_links_enc, secrets_enc, core_team_enc),
       UPDATE (description_enc, contacts_enc, social_links_enc, secrets_enc, core_team_enc)
ON public.organizations FROM authenticated, anon;

REVOKE INSERT (designation_enc, internal_notes_enc),
       UPDATE (designation_enc, internal_notes_enc)
ON public.organization_members FROM authenticated, anon;

REVOKE INSERT (internal_notes_enc), UPDATE (internal_notes_enc)
ON public.events FROM authenticated, anon;

REVOKE INSERT (payment_data_enc, custom_responses_enc),
       UPDATE (payment_data_enc, custom_responses_enc)
ON public.event_registrations FROM authenticated, anon;

REVOKE INSERT (title_enc, content_enc, media_urls_enc, attachments_enc),
       UPDATE (title_enc, content_enc, media_urls_enc, attachments_enc)
ON public.posts FROM authenticated, anon;

REVOKE INSERT (title_enc, pdf_storage_path_enc, metadata_enc),
       UPDATE (title_enc, pdf_storage_path_enc, metadata_enc)
ON public.certificates FROM authenticated, anon;
