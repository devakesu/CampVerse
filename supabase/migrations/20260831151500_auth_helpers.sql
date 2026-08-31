-- ==============================================================================
-- AUTH & ROLE RESOLUTION HELPERS
-- ==============================================================================

-- Returns the full set of app_roles a user is authorized for
CREATE OR REPLACE FUNCTION public.get_user_derived_roles(target_uid UUID)
RETURNS app_role[]
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    derived_roles app_role[];
    base_role app_role;
    is_hod BOOLEAN := FALSE;
    is_club_admin BOOLEAN := FALSE;
    is_student_union BOOLEAN := FALSE;
BEGIN
    -- 1. Fetch base role from profile
    SELECT role INTO base_role 
    FROM public.profiles 
    WHERE id = target_uid;

    -- 2. Check if user is HOD of any department in their institute
    SELECT EXISTS (
        SELECT 1 FROM public.departments 
        WHERE hod_id = target_uid
    ) INTO is_hod;

    -- 3. Check if user is lead or core_member in any active club
    SELECT EXISTS (
        SELECT 1 FROM public.organization_members om
        JOIN public.organizations o ON o.id = om.org_id
        WHERE om.user_id = target_uid
          AND om.is_active = TRUE
          AND om.role IN ('lead', 'core_member')
          AND o.org_type = 'club'
    ) INTO is_club_admin;

    -- 4. Check if user is lead or core_member in student union
    SELECT EXISTS (
        SELECT 1 FROM public.organization_members om
        JOIN public.organizations o ON o.id = om.org_id
        WHERE om.user_id = target_uid
          AND om.is_active = TRUE
          AND om.role IN ('lead', 'core_member')
          AND o.org_type = 'student_union'
    ) INTO is_student_union;

    -- Build unique array of roles
    derived_roles := ARRAY[]::app_role[];

    IF base_role IS NOT NULL THEN
        derived_roles := array_append(derived_roles, base_role);
    END IF;

    IF is_hod AND NOT ('hod'::app_role = ANY(derived_roles)) THEN
        derived_roles := array_append(derived_roles, 'hod'::app_role);
    END IF;

    -- HOD automatically has faculty capabilities
    IF is_hod AND NOT ('faculty'::app_role = ANY(derived_roles)) THEN
        derived_roles := array_append(derived_roles, 'faculty'::app_role);
    END IF;

    IF is_club_admin AND NOT ('club_admin'::app_role = ANY(derived_roles)) THEN
        derived_roles := array_append(derived_roles, 'club_admin'::app_role);
    END IF;

    IF is_student_union AND NOT ('student_union'::app_role = ANY(derived_roles)) THEN
        derived_roles := array_append(derived_roles, 'student_union'::app_role);
    END IF;

    RETURN derived_roles;
END;
$$;
