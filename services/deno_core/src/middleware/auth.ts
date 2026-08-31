import { createClient, type User } from '@supabase/supabase-js';
import type { Context, Next } from 'hono';

export interface AuthContextVariables {
  user: User;
  token: string;
}

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'http://localhost:54321';
const supabaseSecretKey = Deno.env.get('SUPABASE_SECRET_KEY') ??
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
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
    if (error || !user) {
      return c.json({ success: false, error: 'Invalid or expired token' }, 401);
    }

    c.set('user', user);
    c.set('token', token);
    return await next();
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Authentication failed';
    return c.json({ success: false, error: message }, 401);
  }
}
