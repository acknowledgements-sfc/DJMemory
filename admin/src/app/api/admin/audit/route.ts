import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth";
import { writeAuditEvent } from "@/lib/audit";
import { getServiceSupabase } from "@/lib/supabase";

export async function GET() {
  try {
    const admin = await requireAdmin();
    const supabase = getServiceSupabase();
    const { data, error } = await supabase
      .from("admin_audit_events")
      .select("*")
      .order("created_at", { ascending: false })
      .limit(200);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    await writeAuditEvent({
      actorClerkId: admin.clerkUserId,
      actorEmail: admin.email,
      action: "audit.view",
    });

    return NextResponse.json({ events: data ?? [] });
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : message === "Forbidden" ? 403 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
