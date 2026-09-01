import { createClient, type User } from '@supabase/supabase-js';
import type { Context, Next } from 'hono';

export interface AuthContextVariables {
  user: User;
  token: string;
  /** Account status from profiles table: 'active' | 'suspended' | 'pending_verification' | 'alumni' | null */
  profileStatus: string | null;
  /** Base role from profiles table (e.g. 'student', 'faculty'). Null if no profile row. */
  baseRole: string | null;
}

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'http://localhost:54321';
const supabaseSecretKey =
  Deno.env.get('SUPABASE_SECRET_KEY') ??
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
  'dummy_secret_key';

export const supabaseAdmin = createClient(supabaseUrl, supabaseSecretKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

export async function authMiddleware(
  c: Context<{ Variables: AuthContextVariables }>,
  next: Next,
): Promise<Response | void> {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ success: false, error: 'Missing or malformed Authorization header' }, 401);
  }

  const token = authHeader.replace('Bearer ', '').trim();

  try {
    const {
      data: { user },
      error,
    } = await supabaseAdmin.auth.getUser(token);

    if (error || !user) {
      return c.json({ success: false, error: 'Invalid or expired token' }, 401);
    }

    // Fetch profile status and base role in one query to avoid N+1 in routes
    const { data: profileRows } = await supabaseAdmin.rpc('get_user_login_status', {
      target_uid: user.id,
    });

    let profileStatus: string | null = null;
    let baseRole: string | null = null;

    if (Array.isArray(profileRows) && profileRows.length > 0) {
      const row = profileRows[0] as { base_role: string | null; account_status: string | null; profile_exists: boolean };
      if (row.profile_exists) {
        profileStatus = row.account_status;
        baseRole = row.base_role;
      }
    }

    c.set('user', user);
    c.set('token', token);
    c.set('profileStatus', profileStatus);
    c.set('baseRole', baseRole);

    return await next();
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Authentication failed';
    return c.json({ success: false, error: message }, 401);
  }
}
