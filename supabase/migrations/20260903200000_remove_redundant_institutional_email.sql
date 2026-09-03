-- ==============================================================================
-- REMOVE REDUNDANT INSTITUTIONAL EMAIL COLUMNS
-- Migration: 20260903200000_remove_redundant_institutional_email.sql
-- ==============================================================================
-- Institutional email is already uniquely stored, indexed, and authenticated
-- in auth.users(email). Keeping institutional_email_enc and institutional_email_bidx
-- in public.profiles introduces redundant storage, sync overhead, and duplicates auth state.

DROP INDEX IF EXISTS public.idx_profiles_email_bidx;

ALTER TABLE public.profiles DROP COLUMN IF EXISTS institutional_email_enc;
ALTER TABLE public.profiles DROP COLUMN IF EXISTS institutional_email_bidx;

-- Update trigger trg_enforce_profiles_fle_server_only to remove dropped columns
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
