import { NextRequest, NextResponse } from "next/server";
import { getServiceSupabase } from "@/lib/supabase";

const ALLOWED_EVENTS = new Set([
  "page_view",
  "demo_view",
  "waitlist_started",
  "waitlist_joined",
  "research_completed",
]);

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as {
      event?: string;
      source?: string;
      sessionId?: string;
      properties?: Record<string, unknown>;
    };
    if (!body.event || !ALLOWED_EVENTS.has(body.event)) {
      return NextResponse.json({ error: "Unsupported event." }, { status: 400 });
    }

    const safeProperties = sanitizeProperties(body.properties);
    const { error } = await getServiceSupabase().from("marketing_events").insert({
      event_name: body.event,
      source: clean(body.source, 80) || "direct",
      session_id: clean(body.sessionId, 80),
      properties: safeProperties,
    });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ ok: true }, { status: 201 });
  } catch {
    return NextResponse.json({ error: "Could not record event." }, { status: 400 });
  }
}

function clean(value: unknown, max: number) {
  return typeof value === "string" ? value.trim().slice(0, max) || null : null;
}

function sanitizeProperties(value: unknown) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  const allowed = new Set(["djSoftware", "djType", "recordingFrequency", "placement"]);
  return Object.fromEntries(
    Object.entries(value)
      .filter(([key]) => allowed.has(key))
      .map(([key, item]) => [key, clean(item, 80)]),
  );
}
