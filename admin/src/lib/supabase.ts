import { createClient, type SupabaseClient } from "@supabase/supabase-js";

let cached: SupabaseClient | null = null;

/** Service-role client for server routes only. Never expose to the browser. */
export function getServiceSupabase(): SupabaseClient {
  if (cached) return cached;

  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    throw new Error(
      "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY. Copy admin/.env.example to .env.local."
    );
  }

  cached = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return cached;
}

export type AdminRole = "owner" | "support" | "release_manager" | "read_only";

export type DbUser = {
  id: string;
  clerk_user_id: string;
  email: string;
  display_name: string | null;
  status: string;
  release_channel: string;
  created_at: string;
};

export type DbDevice = {
  id: string;
  user_id: string;
  device_name: string;
  app_version: string | null;
  last_seen: string;
  install_channel: string;
  revoked_at: string | null;
};

export type DbLicense = {
  id: string;
  user_id: string;
  plan: string;
  status: string;
  renews_or_expires_at: string | null;
};

export type DbInvite = {
  id: string;
  email: string;
  status: string;
  sent_at: string;
  accepted_at: string | null;
};

export type DbDiagnostic = {
  id: string;
  user_id: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
};

export type DbAuditEvent = {
  id: string;
  actor_clerk_id: string;
  actor_email: string | null;
  action: string;
  target: string | null;
  result: string;
  ip_context: string | null;
  created_at: string;
};
