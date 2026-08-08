import { getServiceSupabase } from "./supabase";

export async function writeAuditEvent(input: {
  actorClerkId: string;
  actorEmail?: string | null;
  action: string;
  target?: string | null;
  result?: string;
  ipContext?: string | null;
}) {
  const supabase = getServiceSupabase();
  const { error } = await supabase.from("admin_audit_events").insert({
    actor_clerk_id: input.actorClerkId,
    actor_email: input.actorEmail ?? null,
    action: input.action,
    target: input.target ?? null,
    result: input.result ?? "ok",
    ip_context: input.ipContext ?? null,
  });

  if (error) {
    console.error("audit write failed", error.message);
  }
}

/** Reject payloads that look like they contain tracklist/audio content. */
export function assertMetadataOnly(metadata: Record<string, unknown>) {
  const banned = ["title", "artist", "tracks", "tracklist", "audio", "waveform"];
  for (const key of Object.keys(metadata)) {
    if (banned.includes(key.toLowerCase())) {
      throw new Error(
        `Diagnostics metadata must not include "${key}". Metadata only — counts, paths, timings, errors.`
      );
    }
  }
}
