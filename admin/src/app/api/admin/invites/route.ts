import { NextRequest, NextResponse } from "next/server";
import { canManageInvites, requireAdmin } from "@/lib/auth";
import { writeAuditEvent } from "@/lib/audit";
import { getServiceSupabase } from "@/lib/supabase";

export async function GET() {
  try {
    const admin = await requireAdmin();
    const supabase = getServiceSupabase();
    const { data, error } = await supabase
      .from("beta_invites")
      .select("*")
      .order("sent_at", { ascending: false })
      .limit(100);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    await writeAuditEvent({
      actorClerkId: admin.clerkUserId,
      actorEmail: admin.email,
      action: "invites.list",
    });

    return NextResponse.json({ invites: data ?? [] });
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : message === "Forbidden" ? 403 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}

export async function POST(request: NextRequest) {
  try {
    const admin = await requireAdmin();
    if (!canManageInvites(admin.role)) {
      return NextResponse.json({ error: "Role cannot manage invites" }, { status: 403 });
    }

    const body = (await request.json()) as { email?: string; resendId?: string };

    const supabase = getServiceSupabase();

    if (body.resendId) {
      const { data, error } = await supabase
        .from("beta_invites")
        .update({ status: "pending", sent_at: new Date().toISOString() })
        .eq("id", body.resendId)
        .select("*")
        .maybeSingle();

      if (error) {
        return NextResponse.json({ error: error.message }, { status: 500 });
      }

      await writeAuditEvent({
        actorClerkId: admin.clerkUserId,
        actorEmail: admin.email,
        action: "invites.resend",
        target: body.resendId,
      });

      // No email provider wired yet — bump sent_at / audit only.
      return NextResponse.json({
        invite: data,
        emailDelivery: "not_sent",
        message: "Invite recorded — email not sent yet.",
      });
    }

    const email = body.email?.trim().toLowerCase();
    if (!email) {
      return NextResponse.json({ error: "email required" }, { status: 400 });
    }

    const { data, error } = await supabase
      .from("beta_invites")
      .insert({
        email,
        status: "pending",
        created_by_clerk_id: admin.clerkUserId,
      })
      .select("*")
      .maybeSingle();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    await writeAuditEvent({
      actorClerkId: admin.clerkUserId,
      actorEmail: admin.email,
      action: "invites.create",
      target: email,
    });

    // No email provider wired yet — DB + audit only.
    return NextResponse.json(
      {
        invite: data,
        emailDelivery: "not_sent",
        message: "Invite recorded — email not sent yet.",
      },
      { status: 201 }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : message === "Forbidden" ? 403 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
