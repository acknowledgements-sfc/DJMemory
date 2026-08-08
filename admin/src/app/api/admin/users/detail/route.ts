import { NextRequest, NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth";
import { writeAuditEvent } from "@/lib/audit";
import { getServiceSupabase } from "@/lib/supabase";

export async function GET(request: NextRequest) {
  try {
    const admin = await requireAdmin();
    const userId = request.nextUrl.searchParams.get("userId");
    if (!userId) {
      return NextResponse.json({ error: "userId required" }, { status: 400 });
    }

    const supabase = getServiceSupabase();
    const [devices, licenses, diagnostics] = await Promise.all([
      supabase.from("devices").select("*").eq("user_id", userId).order("last_seen", { ascending: false }),
      supabase.from("licenses").select("*").eq("user_id", userId).order("created_at", { ascending: false }),
      supabase
        .from("diagnostic_uploads")
        .select("id, user_id, metadata, created_at")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(20),
    ]);

    if (devices.error || licenses.error || diagnostics.error) {
      return NextResponse.json(
        {
          error:
            devices.error?.message ||
            licenses.error?.message ||
            diagnostics.error?.message ||
            "lookup failed",
        },
        { status: 500 }
      );
    }

    await writeAuditEvent({
      actorClerkId: admin.clerkUserId,
      actorEmail: admin.email,
      action: "users.detail",
      target: userId,
    });

    return NextResponse.json({
      devices: devices.data ?? [],
      licenses: licenses.data ?? [],
      diagnostics: diagnostics.data ?? [],
      restrictions: {
        audioPlayback: false,
        tracklistContents: false,
        note: "Admins cannot access user audio or full tracklists.",
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : message === "Forbidden" ? 403 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
