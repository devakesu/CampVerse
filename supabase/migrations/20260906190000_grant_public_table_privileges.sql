-- ==============================================================================
-- GRANT PUBLIC TABLE, SEQUENCE, AND ROUTINE PRIVILEGES TO CLIENT ROLES
-- ==============================================================================
-- Migration: 20260906190000_grant_public_table_privileges.sql
--
-- Ensure anon, authenticated, and service_role have schema & table-level privileges.
-- Row Level Security (RLS) policies continue to enforce granular row-level access.

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;

-- ------------------------------------------------------------------------------
-- Defense in depth: Re-apply column-level write revocations for encrypted/FLE columns
-- ------------------------------------------------------------------------------
REVOKE INSERT (
    full_name_enc, full_name_bidx, bio_enc, avatar_path_enc,
    university_reg_no_enc, university_reg_no_bidx,
    admission_no_enc, admission_no_bidx,
    phone_enc, phone_bidx,
    dob_enc, gender_enc, blood_group_enc,
    emergency_contact_enc, address_enc, identity_doc_enc,
    academic_metrics_enc, metadata_enc, social_profiles_enc,
    fcm_tokens_enc
), UPDATE (
    full_name_enc, full_name_bidx, bio_enc, avatar_path_enc,
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
