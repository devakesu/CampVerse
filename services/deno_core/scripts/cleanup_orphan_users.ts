#!/usr/bin/env -S deno run --allow-env --allow-net
/**
 * cleanup_orphan_users.ts
 * ──────────────────────────────────────────────────────────────────────────
 * Removes orphan auth.users entries that have no corresponding profiles row,
 * or whose profiles row has status = 'pending_verification' AND the auth user
 * was created more than ORPHAN_GRACE_PERIOD_HOURS hours ago.
 *
 * These orphans accumulate when:
 *   • Someone signs up via Google OAuth with an unregistered Google account
 *   • Someone calls the Supabase publishable-key signup endpoint directly
 *
 * Safe to run as a cron job. Dry-run mode (`--dry-run` flag) logs what
 * would be deleted without performing any actual deletion.
 *
 * Usage:
 *   # Run cleanup (requires runtime env vars)
 *   deno run --allow-env --allow-net scripts/cleanup_orphan_users.ts
 *
 *   # Dry run — logs only, no deletions
 *   deno run --allow-env --allow-net scripts/cleanup_orphan_users.ts --dry-run
 *
 * Cron (daily at 02:00 UTC):
 *   0 2 * * * infisical run -- deno run --allow-env --allow-net \
 *     /app/scripts/cleanup_orphan_users.ts >> /var/log/campverse/cleanup.log 2>&1
 *
 * Environment variables required (same as deno_core runtime):
 *   SUPABASE_URL        — Supabase project URL
 *   SUPABASE_SECRET_KEY — Service role key (admin access)
 * ──────────────────────────────────────────────────────────────────────────
 */

import { createClient } from '@supabase/supabase-js';

// ── Configuration ────────────────────────────────────────────────────────────

/** Hours after account creation before a pending/orphan user is eligible for deletion. */
const ORPHAN_GRACE_PERIOD_HOURS = 48;

const isDryRun = Deno.args.includes('--dry-run');

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? 'http://localhost:54321';
const supabaseSecretKey =
  Deno.env.get('SUPABASE_SECRET_KEY') ??
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
  '';

if (!supabaseSecretKey) {
  console.error('[cleanup] ERROR: SUPABASE_SECRET_KEY is not set. Aborting.');
  Deno.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseSecretKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function log(msg: string) {
  console.log(`[cleanup ${new Date().toISOString()}] ${msg}`);
}

function logError(msg: string, err?: unknown) {
  const detail = err instanceof Error ? err.message : String(err ?? '');
  console.error(`[cleanup ${new Date().toISOString()}] ERROR: ${msg}${detail ? ' — ' + detail : ''}`);
}

// ── Main Logic ────────────────────────────────────────────────────────────────

async function main() {
  log(`Starting orphan auth.users cleanup${isDryRun ? ' (DRY RUN)' : ''}`);
  log(`Grace period: ${ORPHAN_GRACE_PERIOD_HOURS}h`);

  // 1. List all auth users (paginated, up to 1000 per call)
  let page = 1;
  let totalDeleted = 0;
  let totalScanned = 0;

  while (true) {
    const { data: authData, error: listError } = await supabase.auth.admin.listUsers({
      page,
      perPage: 1000,
    });

    if (listError) {
      logError('Failed to list auth users', listError);
      Deno.exit(1);
    }

    const users = authData?.users ?? [];
    if (users.length === 0) break;

    totalScanned += users.length;
    log(`Page ${page}: scanning ${users.length} auth users...`);

    // 2. For each user, check profile existence and eligibility
    for (const authUser of users) {
      const createdAt = new Date(authUser.created_at);
      const ageHours = (Date.now() - createdAt.getTime()) / (1000 * 60 * 60);

      // Skip users created within the grace period (may still be in onboarding)
      if (ageHours < ORPHAN_GRACE_PERIOD_HOURS) continue;

      // Query the profiles row
      const { data: profileRows, error: profileError } = await supabase
        .from('profiles')
        .select('id, status')
        .eq('id', authUser.id)
        .maybeSingle();

      if (profileError) {
        logError(`Failed to query profile for user ${authUser.id}`, profileError);
        continue;
      }

      const isOrphan = !profileRows;
      const isPending = profileRows?.status === 'pending_verification';

      if (!isOrphan && !isPending) continue;

      const reason = isOrphan ? 'no_profile' : 'pending_verification';
      const email = authUser.email ?? authUser.phone ?? '<no identifier>';

      if (isDryRun) {
        log(`[DRY RUN] Would delete: ${authUser.id} (${email}) — ${reason}, age: ${Math.round(ageHours)}h`);
        totalDeleted++;
        continue;
      }

      // 3. Delete the auth user (cascades to profiles via ON DELETE CASCADE)
      const { error: deleteError } = await supabase.auth.admin.deleteUser(authUser.id);

      if (deleteError) {
        logError(`Failed to delete user ${authUser.id} (${email})`, deleteError);
      } else {
        log(`Deleted orphan user: ${authUser.id} (${email}) — ${reason}, age: ${Math.round(ageHours)}h`);
        totalDeleted++;
      }
    }

    // Check if there are more pages
    if (users.length < 1000) break;
    page++;
  }

  log(
    `Cleanup complete. Scanned: ${totalScanned}, ` +
    `${isDryRun ? 'Would delete' : 'Deleted'}: ${totalDeleted}`,
  );
}

await main();
