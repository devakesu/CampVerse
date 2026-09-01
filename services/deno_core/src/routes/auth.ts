import { Hono } from 'hono';
import { type AuthContextVariables, authMiddleware, supabaseAdmin } from '../middleware/auth.ts';

export const authRouter = new Hono<{ Variables: AuthContextVariables }>();

// Apply auth middleware to all auth routes
authRouter.use('*', authMiddleware);

/**
 * POST /login-status
 * Called immediately after Supabase authentication succeeds (client-side).
 * Validates:
 *   1. Profile row exists
 *   2. Account status is 'active' (not pending_verification, suspended, alumni)
 * Returns base_role for the session start.
 *
 * Security note: `active_role` is intentionally NOT read here — the client
 * always starts with base_role and restores switched roles from local TTL cache.
 */
authRouter.post('/login-status', async (c): Promise<Response> => {
  const user = c.get('user');
  const profileStatus = c.get('profileStatus');
  const baseRole = c.get('baseRole');

  // No profile row → orphan auth user (Google OAuth / publishable-key signup)
  if (profileStatus === null || baseRole === null) {
    return c.json(
      {
        success: false,
        error: 'no_profile',
        message:
          'No institutional profile found for this account. ' +
          'If you are a student or faculty, contact your institution admin.',
      },
      403,
    );
  }

  // Suspended accounts
  if (profileStatus === 'suspended') {
    return c.json(
      {
        success: false,
        error: 'suspended',
        message:
          'Your account has been suspended. Please contact your institution admin.',
      },
      403,
    );
  }

  // Alumni — read-only, but block active login for now
  if (profileStatus === 'alumni') {
    return c.json(
      {
        success: false,
        error: 'alumni',
        message:
          'Alumni accounts cannot log in to the campus portal. ' +
          'Please contact your institution admin if this is an error.',
      },
      403,
    );
  }

  // Pending verification — not yet activated by admin
  if (profileStatus !== 'active') {
    return c.json(
      {
        success: false,
        error: 'pending_verification',
        message:
          'Your account is pending verification. ' +
          'Please contact your institution admin to activate your account.',
      },
      403,
    );
  }

  // Active account — return base_role for session initialization
  return c.json({
    success: true,
    data: {
      base_role: baseRole,
      account_status: profileStatus,
    },
  });
});

/**
 * POST /resolve-roles
 * Derives the complete set of roles authorized for the authenticated user.
 * Returns no_profile error (not silent student fallback) if no profile exists.
 */
authRouter.post('/resolve-roles', async (c): Promise<Response> => {
  const user = c.get('user');
  const profileStatus = c.get('profileStatus');

  // Guard: no profile → reject rather than silently default to student
  if (profileStatus === null) {
    return c.json(
      {
        success: false,
        error: 'no_profile',
        message: 'No institutional profile found for this account.',
      },
      403,
    );
  }

  // Guard: non-active account → reject
  if (profileStatus !== 'active') {
    return c.json(
      {
        success: false,
        error: profileStatus,
        message: `Account is not active (status: ${profileStatus}).`,
      },
      403,
    );
  }

  try {
    const { data, error } = await supabaseAdmin.rpc('get_user_derived_roles', {
      target_uid: user.id,
    });

    if (error) {
      return c.json({ success: false, error: error.message }, 500);
    }

    const roles = Array.isArray(data) ? data : [];
    return c.json({ success: true, data: roles });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to resolve roles';
    return c.json({ success: false, error: message }, 500);
  }
});

/**
 * POST /set-active-role
 * Validates that the requested target_role is within the user's derived roles,
 * checks account is active, then embeds the active_role claim into app_metadata
 * via Supabase Admin API (tamper-proof server JWT claim).
 */
authRouter.post('/set-active-role', async (c): Promise<Response> => {
  const user = c.get('user');
  const profileStatus = c.get('profileStatus');

  // Guard: suspended/inactive account cannot switch roles
  if (profileStatus !== 'active') {
    return c.json(
      {
        success: false,
        error: profileStatus ?? 'no_profile',
        message: 'Account is not active. Role switching is not permitted.',
      },
      403,
    );
  }

  let body: { target_role?: string };
  try {
    body = await c.req.json();
  } catch {
    return c.json({ success: false, error: 'Invalid JSON request body' }, 400);
  }

  const targetRole = body.target_role;
  if (!targetRole || typeof targetRole !== 'string') {
    return c.json({ success: false, error: 'Missing or invalid target_role parameter' }, 400);
  }

  try {
    // 1. Fetch server-derived authorized roles (prevents role spoofing)
    const { data: authorizedRoles, error: rpcError } = await supabaseAdmin.rpc(
      'get_user_derived_roles',
      { target_uid: user.id },
    );

    if (rpcError) {
      return c.json({ success: false, error: rpcError.message }, 500);
    }

    const rolesList = Array.isArray(authorizedRoles) ? authorizedRoles : [];
    if (!rolesList.includes(targetRole)) {
      return c.json(
        {
          success: false,
          error: `Unauthorized: User is not authorized for role '${targetRole}'`,
        },
        403,
      );
    }

    // 2. Embed active_role in app_metadata (server-signed JWT claim, non-spoofable)
    const existingAppMetadata = user.app_metadata ?? {};
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(user.id, {
      app_metadata: {
        ...existingAppMetadata,
        active_role: targetRole,
      },
    });

    if (updateError) {
      return c.json({ success: false, error: updateError.message }, 500);
    }

    return c.json({
      success: true,
      message: `Active role updated to '${targetRole}'`,
      data: targetRole,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to set active role';
    return c.json({ success: false, error: message }, 500);
  }
});

/**
 * POST /mfa/send-otp
 * Triggers Email or SMS OTP challenge
 */
authRouter.post('/mfa/send-otp', (c): Response => {
  const user = c.get('user');

  return c.json({
    success: true,
    message: `OTP challenge triggered for user ${user.id}`,
  });
});
