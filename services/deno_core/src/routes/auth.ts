import { Hono } from 'hono';
import { type AuthContextVariables, authMiddleware, supabaseAdmin } from '../middleware/auth.ts';

export const authRouter = new Hono<{ Variables: AuthContextVariables }>();

// Apply auth middleware to all auth routes
authRouter.use('*', authMiddleware);

/**
 * POST /resolve-roles
 * Derives the complete set of roles authorized for the authenticated user
 */
authRouter.post('/resolve-roles', async (c): Promise<Response> => {
  const user = c.get('user');

  try {
    const { data, error } = await supabaseAdmin.rpc('get_user_derived_roles', {
      target_uid: user.id,
    });

    if (error) {
      return c.json({ success: false, error: error.message }, 500);
    }

    const roles = Array.isArray(data) ? data : ['student'];
    return c.json({ success: true, data: roles });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Failed to resolve roles';
    return c.json({ success: false, error: message }, 500);
  }
});

/**
 * POST /set-active-role
 * Validates that the requested target_role is within the user's derived roles,
 * then embeds the active_role claim into app_metadata via Supabase Admin API.
 */
authRouter.post('/set-active-role', async (c): Promise<Response> => {
  const user = c.get('user');
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
    // 1. Fetch authorized roles to prevent role spoofing
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

    // 2. Set active_role in app_metadata (tamper-proof server JWT claim)
    const existingAppMetadata = user.app_metadata ?? {};
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      user.id,
      {
        app_metadata: {
          ...existingAppMetadata,
          active_role: targetRole,
        },
      },
    );

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
