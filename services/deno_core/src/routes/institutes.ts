import { type Context, Hono } from 'hono';
import { type AuthContextVariables, authMiddleware, supabaseAdmin } from '../middleware/auth.ts';
import { computeBlindIndex, encryptAesGcm, toByteaHex } from '../crypto/fle.ts';

export const institutesRouter = new Hono<{ Variables: AuthContextVariables }>();

// Protect all institute management endpoints with authentication
institutesRouter.use('*', authMiddleware);

interface CreateInstituteRequestBody {
  institute?: {
    name?: string;
    slug?: string;
    domain?: string | null;
    university_id?: string | null;
    is_autonomous?: boolean;
    is_active?: boolean;
  };
  principal?: {
    name?: string;
    email?: string;
    password?: string;
    phone?: string | null;
  };
  office_admin?: {
    name?: string;
    email?: string;
    password?: string;
    phone?: string | null;
  };
}

/**
 * POST /
 * Onboard a new campus tenant along with initial Principal and Office Admin
 * auth credentials and FLE-encrypted profile records.
 *
 * Restricted strictly to Super Administrators.
 */
institutesRouter.post('/', async (c: Context<{ Variables: AuthContextVariables }>): Promise<Response> => {
  const user = c.get('user');
  const baseRole = c.get('baseRole');
  const activeRole = (user.app_metadata as Record<string, unknown> | undefined)?.active_role;

  // Authorization check: Must be Super Admin
  if (baseRole !== 'super_admin' && activeRole !== 'super_admin') {
    return c.json(
      {
        success: false,
        error: 'Unauthorized: Only Super Administrators can onboard new institutes.',
      },
      403,
    );
  }

  let body: CreateInstituteRequestBody;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ success: false, error: 'Invalid JSON request payload' }, 400);
  }

  const { institute, principal, office_admin } = body;

  // 1. Validation
  if (!institute?.name?.trim() || !institute.slug?.trim()) {
    return c.json(
      { success: false, error: 'Institute name and code/slug are required.' },
      400,
    );
  }

  if (!principal?.name?.trim() || !principal.email?.trim() || !principal.password) {
    return c.json(
      { success: false, error: 'Principal full name, email, and password are required.' },
      400,
    );
  }

  if (!office_admin?.name?.trim() || !office_admin.email?.trim() || !office_admin.password) {
    return c.json(
      { success: false, error: 'Office Admin full name, email, and password are required.' },
      400,
    );
  }

  const principalEmail = principal.email.trim().toLowerCase();
  const officeAdminEmail = office_admin.email.trim().toLowerCase();

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(principalEmail)) {
    return c.json({ success: false, error: 'Principal email address is invalid.' }, 400);
  }
  if (!emailRegex.test(officeAdminEmail)) {
    return c.json({ success: false, error: 'Office Admin email address is invalid.' }, 400);
  }

  if (principalEmail === officeAdminEmail) {
    return c.json(
      {
        success: false,
        error: 'Principal and Office Admin must have distinct email addresses.',
      },
      400,
    );
  }

  if (principal.password.length < 6 || office_admin.password.length < 6) {
    return c.json(
      { success: false, error: 'Initial passwords must be at least 6 characters long.' },
      400,
    );
  }

  const fleMasterKey = Deno.env.get('FLE_MASTER_KEY');
  const hmacPepper = Deno.env.get('HMAC_PEPPER');

  // Rollback tracking state
  let createdInstituteId: string | null = null;
  const createdUserIds: string[] = [];

  const rollback = async (): Promise<void> => {
    const userDeletions = createdUserIds.map((uid) =>
      supabaseAdmin.auth.admin.deleteUser(uid).catch((e: unknown) => {
        console.error(`Rollback error deleting user ${uid}:`, e);
      }),
    );
    await Promise.all(userDeletions);

    if (createdInstituteId) {
      try {
        await supabaseAdmin.from('institutes').delete().eq('id', createdInstituteId);
      } catch (e: unknown) {
        console.error(`Rollback error deleting institute ${createdInstituteId}:`, e);
      }
    }
  };

  try {
    // 2. Insert Institute Record
    const institutePayload = {
      name: institute.name.trim(),
      slug: institute.slug.trim().toUpperCase(),
      domain: institute.domain?.trim().toLowerCase() || null,
      university_id: institute.university_id || null,
      is_autonomous: institute.is_autonomous ?? false,
      is_active: institute.is_active ?? true,
    };

    const { data: newInstitute, error: instError } = await supabaseAdmin
      .from('institutes')
      .insert(institutePayload)
      .select()
      .single();

    if (instError || !newInstitute) {
      return c.json(
        { success: false, error: `Failed to create institute: ${instError?.message}` },
        400,
      );
    }
    createdInstituteId = newInstitute.id as string;

    // 3. Create Principal Auth User
    const { data: pAuth, error: pAuthErr } = await supabaseAdmin.auth.admin.createUser({
      email: principalEmail,
      password: principal.password,
      email_confirm: true,
      user_metadata: {
        full_name: principal.name.trim(),
        role: 'principal',
      },
      app_metadata: {
        active_role: 'principal',
        roles: ['principal'],
        institute_id: createdInstituteId,
      },
    });

    if (pAuthErr || !pAuth.user) {
      await rollback();
      return c.json(
        { success: false, error: `Failed to create Principal auth account: ${pAuthErr?.message}` },
        400,
      );
    }
    createdUserIds.push(pAuth.user.id);

    // 4. Encrypt Principal Profile & Insert
    const pNameEnc = toByteaHex(await encryptAesGcm(principal.name.trim(), fleMasterKey));
    const pNameBidx = toByteaHex(await computeBlindIndex(principal.name.trim(), hmacPepper));
    let pPhoneEnc: string | null = null;
    let pPhoneBidx: string | null = null;
    if (principal.phone && principal.phone.trim()) {
      pPhoneEnc = toByteaHex(await encryptAesGcm(principal.phone.trim(), fleMasterKey));
      pPhoneBidx = toByteaHex(await computeBlindIndex(principal.phone.trim(), hmacPepper));
    }

    const { error: pProfErr } = await supabaseAdmin.from('profiles').insert({
      id: pAuth.user.id,
      institute_id: createdInstituteId,
      role: 'principal',
      status: 'active',
      full_name_enc: pNameEnc,
      full_name_bidx: pNameBidx,
      phone_enc: pPhoneEnc,
      phone_bidx: pPhoneBidx,
    });

    if (pProfErr) {
      await rollback();
      return c.json(
        { success: false, error: `Failed to create Principal profile: ${pProfErr.message}` },
        500,
      );
    }

    // 5. Create Office Admin Auth User
    const { data: aAuth, error: aAuthErr } = await supabaseAdmin.auth.admin.createUser({
      email: officeAdminEmail,
      password: office_admin.password,
      email_confirm: true,
      user_metadata: {
        full_name: office_admin.name.trim(),
        role: 'office_admin',
      },
      app_metadata: {
        active_role: 'office_admin',
        roles: ['office_admin'],
        institute_id: createdInstituteId,
      },
    });

    if (aAuthErr || !aAuth.user) {
      await rollback();
      return c.json(
        {
          success: false,
          error: `Failed to create Office Admin auth account: ${aAuthErr?.message}`,
        },
        400,
      );
    }
    createdUserIds.push(aAuth.user.id);

    // 6. Encrypt Office Admin Profile & Insert
    const aNameEnc = toByteaHex(await encryptAesGcm(office_admin.name.trim(), fleMasterKey));
    const aNameBidx = toByteaHex(await computeBlindIndex(office_admin.name.trim(), hmacPepper));
    let aPhoneEnc: string | null = null;
    let aPhoneBidx: string | null = null;
    if (office_admin.phone && office_admin.phone.trim()) {
      aPhoneEnc = toByteaHex(await encryptAesGcm(office_admin.phone.trim(), fleMasterKey));
      aPhoneBidx = toByteaHex(await computeBlindIndex(office_admin.phone.trim(), hmacPepper));
    }

    const { error: aProfErr } = await supabaseAdmin.from('profiles').insert({
      id: aAuth.user.id,
      institute_id: createdInstituteId,
      role: 'office_admin',
      status: 'active',
      designation: 'admin_staff',
      full_name_enc: aNameEnc,
      full_name_bidx: aNameBidx,
      phone_enc: aPhoneEnc,
      phone_bidx: aPhoneBidx,
    });

    if (aProfErr) {
      await rollback();
      return c.json(
        { success: false, error: `Failed to create Office Admin profile: ${aProfErr.message}` },
        500,
      );
    }

    // 7. Return Success
    return c.json(
      {
        success: true,
        data: {
          institute: newInstitute,
          principal: {
            id: pAuth.user.id,
            name: principal.name.trim(),
            email: principalEmail,
            role: 'principal',
          },
          office_admin: {
            id: aAuth.user.id,
            name: office_admin.name.trim(),
            email: officeAdminEmail,
            role: 'office_admin',
          },
        },
      },
      201,
    );
  } catch (err: unknown) {
    await rollback();
    const message = err instanceof Error ? err.message : 'Unknown onboarding error';
    return c.json({ success: false, error: message }, 500);
  }
});
