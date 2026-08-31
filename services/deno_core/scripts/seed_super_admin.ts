import { createClient } from '@supabase/supabase-js';

// Helper functions for AES-256-GCM and HMAC-SHA256 Blind Indexing
async function encryptAesGcm(plainText: string, keyHexOrBase64?: string): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const data = encoder.encode(plainText);

  let keyBytes: Uint8Array;
  if (keyHexOrBase64 && keyHexOrBase64.length === 64) {
    keyBytes = new Uint8Array(
      keyHexOrBase64.match(/.{1,2}/g)!.map((byte) => parseInt(byte, 16)),
    );
  } else {
    // Generate deterministic or random 32-byte key if not provided
    keyBytes = crypto.getRandomValues(new Uint8Array(32));
  }

  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    keyBytes.buffer as ArrayBuffer,
    { name: 'AES-GCM' },
    false,
    ['encrypt'],
  );

  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encryptedBuffer = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    cryptoKey,
    data,
  );

  // Combine IV (12 bytes) + Ciphertext + Tag
  const combined = new Uint8Array(iv.length + encryptedBuffer.byteLength);
  combined.set(iv, 0);
  combined.set(new Uint8Array(encryptedBuffer), iv.length);
  return combined;
}

async function computeBlindIndex(value: string, pepperHex?: string): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const data = encoder.encode(value.trim().toLowerCase());

  let pepperBytes: Uint8Array;
  if (pepperHex && pepperHex.length === 64) {
    pepperBytes = new Uint8Array(
      pepperHex.match(/.{1,2}/g)!.map((byte) => parseInt(byte, 16)),
    );
  } else {
    pepperBytes = new Uint8Array(32); // Fallback zeroed pepper
  }

  const key = await crypto.subtle.importKey(
    'raw',
    pepperBytes.buffer as ArrayBuffer,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign('HMAC', key, data);
  return new Uint8Array(signature);
}

function parseArgs(): { email: string; pass: string; name: string } {
  const args = Deno.args;
  let email = Deno.env.get('SUPERADMIN_EMAIL');
  let pass = Deno.env.get('SUPERADMIN_PASSWORD');
  let name = Deno.env.get('SUPERADMIN_NAME');

  for (let i = 0; i < args.length; i++) {
    const nextArg = args[i + 1];
    if (args[i] === '--email' && typeof nextArg === 'string') {
      email = nextArg;
    } else if (args[i] === '--password' && typeof nextArg === 'string') {
      pass = nextArg;
    } else if (args[i] === '--name' && typeof nextArg === 'string') {
      name = nextArg;
    }
  }

  if (!email || !pass || !name) {
    console.error(
      'Error: Super admin credentials required.\n' +
      'Provide via flags: --email <email> --password <pass> --name <name>\n' +
      'Or via env vars: SUPERADMIN_EMAIL, SUPERADMIN_PASSWORD, SUPERADMIN_NAME',
    );
    Deno.exit(1);
  }

  return { email, pass, name };
}

async function main() {
  console.log('----------------------------------------------------');
  console.log('CampVerse Initial Super Admin Seed Script');
  console.log('----------------------------------------------------');

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'http://localhost:54321';
  const supabaseSecretKey = Deno.env.get('SUPABASE_SECRET_KEY') ??
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseSecretKey) {
    console.error('Error: SUPABASE_SECRET_KEY environment variable is required.');
    Deno.exit(1);
  }

  const fleMasterKey = Deno.env.get('FLE_MASTER_KEY');
  const hmacPepper = Deno.env.get('HMAC_PEPPER');

  if (fleMasterKey) {
    console.log('FLE encryption active with configured FLE_MASTER_KEY.');
  } else {
    console.log('Notice: No FLE_MASTER_KEY provided; generating payload with standard key.');
  }

  const { email, pass, name } = parseArgs();
  console.log(`Target Super Admin: ${email}`);

  const supabase = createClient(supabaseUrl, supabaseSecretKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // 1. Create or retrieve auth user
  let userId: string;
  const { data: existingUsers } = await supabase.auth.admin.listUsers();
  const existing = existingUsers?.users?.find((u) => u.email?.toLowerCase() === email.toLowerCase());

  if (existing) {
    console.log(`User already exists in auth.users (ID: ${existing.id}). Updating claims...`);
    userId = existing.id;
    await supabase.auth.admin.updateUserById(userId, {
      password: pass,
      user_metadata: { role: 'super_admin' },
      app_metadata: { active_role: 'super_admin', roles: ['super_admin'] },
    });
  } else {
    console.log('Creating new auth user in Supabase Auth...');
    const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
      email,
      password: pass,
      email_confirm: true,
      user_metadata: { role: 'super_admin' },
      app_metadata: { active_role: 'super_admin', roles: ['super_admin'] },
    });

    if (createError || !newUser.user) {
      console.error('Failed to create user:', createError);
      Deno.exit(1);
    }
    userId = newUser.user.id;
  }

  // 2. Encrypt profile fields
  const fullNameEnc = await encryptAesGcm(name, fleMasterKey);
  const emailEnc = await encryptAesGcm(email, fleMasterKey);
  const fullNameBidx = await computeBlindIndex(name, hmacPepper);
  const emailBidx = await computeBlindIndex(email, hmacPepper);

  // Convert Uint8Array to Postgres bytea hex format (\x...)
  const toByteaHex = (bytes: Uint8Array) =>
    '\\x' + Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');

  // 3. Upsert profile into public.profiles
  console.log('Upserting super_admin profile into public.profiles...');
  const { error: profileError } = await supabase.from('profiles').upsert({
    id: userId,
    role: 'super_admin',
    status: 'active',
    full_name_enc: toByteaHex(fullNameEnc),
    full_name_bidx: toByteaHex(fullNameBidx),
    institutional_email_enc: toByteaHex(emailEnc),
    institutional_email_bidx: toByteaHex(emailBidx),
    updated_at: new Date().toISOString(),
  });

  if (profileError) {
    console.error('Failed to upsert profile record:', profileError);
    Deno.exit(1);
  }

  console.log('----------------------------------------------------');
  console.log('Super Admin user created successfully!');
  console.log(`User ID : ${userId}`);
  console.log(`Email   : ${email}`);
  console.log(`Password: ${pass}`);
  console.log(`Role    : super_admin`);
  console.log('----------------------------------------------------');
}

if (import.meta.main) {
  main();
}
