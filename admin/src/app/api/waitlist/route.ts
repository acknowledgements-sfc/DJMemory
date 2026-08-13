import { NextRequest, NextResponse } from "next/server";
import { getServiceSupabase } from "@/lib/supabase";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as {
      email?: string;
      djSoftware?: string[];
      macosVersion?: string;
      djType?: string;
      recordingFrequency?: string;
      currentWorkflow?: string;
      biggestPain?: string;
      willingToTest?: boolean;
      researchComplete?: boolean;
      source?: string;
    };
    const email = body.email?.trim().toLowerCase() ?? "";
    if (!email || !EMAIL_RE.test(email)) {
      return NextResponse.json({ error: "A valid email is required." }, { status: 400 });
    }

    const supabase = getServiceSupabase();

    const { data: existing, error: existingError } = await supabase
      .from("beta_invites")
      .select("id, status")
      .eq("email", email)
      .eq("status", "pending")
      .maybeSingle();

    if (existingError) {
      return NextResponse.json({ error: existingError.message }, { status: 500 });
    }

    const researchFields = {
      dj_software: sanitizeList(body.djSoftware),
      macos_version: sanitizeText(body.macosVersion, 80),
      dj_type: sanitizeText(body.djType, 80),
      recording_frequency: sanitizeText(body.recordingFrequency, 80),
      current_workflow: sanitizeText(body.currentWorkflow, 600),
      biggest_pain: sanitizeText(body.biggestPain, 600),
      willing_to_test: typeof body.willingToTest === "boolean" ? body.willingToTest : null,
      research_completed_at: body.researchComplete ? new Date().toISOString() : null,
      source: sanitizeText(body.source, 80) || "waitlist",
    };

    if (existing) {
      if (body.researchComplete) {
        const { error: updateError } = await supabase
          .from("beta_invites")
          .update(researchFields)
          .eq("id", existing.id);
        if (updateError) {
          return NextResponse.json({ error: updateError.message }, { status: 500 });
        }
      }
      return NextResponse.json({
        ok: true,
        alreadyListed: true,
        message: body.researchComplete
          ? "Thanks — your beta profile is complete."
          : "You are already on the waitlist.",
      });
    }

    const { data, error } = await supabase
      .from("beta_invites")
      .insert({
        email,
        status: "pending",
        created_by_clerk_id: null,
        ...researchFields,
      })
      .select("id, email, status, sent_at")
      .maybeSingle();

    if (error) {
      // Unique (email, status) race or duplicate
      if (error.code === "23505") {
        return NextResponse.json({
          ok: true,
          alreadyListed: true,
          message: "You are already on the waitlist.",
        });
      }
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(
      {
        ok: true,
        alreadyListed: false,
        message: "You are on the waitlist. We will email you when a beta invite is ready.",
        invite: data,
      },
      { status: 201 },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

function sanitizeText(value: unknown, maxLength: number) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) || null : null;
}

function sanitizeList(value: unknown) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim().slice(0, 40))
    .filter(Boolean)
    .slice(0, 8);
}
