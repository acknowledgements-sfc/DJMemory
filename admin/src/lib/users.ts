import { currentUser } from "@clerk/nextjs/server";
import { getServiceSupabase, type DbUser } from "./supabase";

/** Ensure a `users` row exists for the signed-in Clerk user. Creates a free license on first sight. */
export async function ensureAppUser(clerkUserId: string): Promise<DbUser> {
  const supabase = getServiceSupabase();
  const { data: existing, error: lookupError } = await supabase
    .from("users")
    .select("*")
    .eq("clerk_user_id", clerkUserId)
    .maybeSingle();

  if (lookupError) {
    throw new Error(`User lookup failed: ${lookupError.message}`);
  }
  if (existing) {
    return existing as DbUser;
  }

  const clerkUser = await currentUser();
  const email =
    clerkUser?.primaryEmailAddress?.emailAddress ||
    clerkUser?.emailAddresses[0]?.emailAddress ||
    `${clerkUserId}@users.clerk.local`;
  const displayName =
    clerkUser?.fullName ||
    clerkUser?.username ||
    clerkUser?.firstName ||
    null;

  const { data: created, error: insertError } = await supabase
    .from("users")
    .insert({
      clerk_user_id: clerkUserId,
      email,
      display_name: displayName,
      status: "active",
      release_channel: "stable",
    })
    .select("*")
    .single();

  if (insertError) {
    // Race: another request inserted first.
    const { data: raced, error: raceError } = await supabase
      .from("users")
      .select("*")
      .eq("clerk_user_id", clerkUserId)
      .maybeSingle();
    if (raceError || !raced) {
      throw new Error(`User create failed: ${insertError.message}`);
    }
    return raced as DbUser;
  }

  const user = created as DbUser;
  const { error: licenseError } = await supabase.from("licenses").insert({
    user_id: user.id,
    plan: "free",
    status: "active",
  });
  if (licenseError) {
    // Non-fatal for subsequent GET /api/license which will still default offline-full.
    console.error("license seed failed", licenseError.message);
  }

  return user;
}

const FORBIDDEN_DIAGNOSTIC_KEYS = new Set([
  "title",
  "artist",
  "tracks",
  "tracklist",
  "titles",
  "artists",
  "trackTitles",
  "track_titles",
]);

/** Strip forbidden keys recursively so metadata stays counts/paths/errors only. */
export function sanitizeDiagnosticMetadata(
  input: unknown
): Record<string, unknown> {
  if (input === null || typeof input !== "object" || Array.isArray(input)) {
    return {};
  }

  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input as Record<string, unknown>)) {
    if (FORBIDDEN_DIAGNOSTIC_KEYS.has(key)) {
      continue;
    }
    if (value !== null && typeof value === "object" && !Array.isArray(value)) {
      out[key] = sanitizeDiagnosticMetadata(value);
    } else if (Array.isArray(value)) {
      out[key] = value.map((item) =>
        item !== null && typeof item === "object" && !Array.isArray(item)
          ? sanitizeDiagnosticMetadata(item)
          : item
      );
    } else {
      out[key] = value;
    }
  }
  return out;
}
