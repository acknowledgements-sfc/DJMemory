import { NextRequest, NextResponse } from "next/server";
import { getServiceSupabase } from "@/lib/supabase";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as { email?: string };
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

    if (existing) {
      return NextResponse.json({
        ok: true,
        alreadyListed: true,
        message: "You are already on the waitlist.",
      });
    }

    const { data, error } = await supabase
      .from("beta_invites")
      .insert({
        email,
        status: "pending",
        created_by_clerk_id: null,
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
