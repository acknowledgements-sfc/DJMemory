import { NextRequest, NextResponse } from "next/server";
import { canMutate, requireAdmin } from "@/lib/auth";
import { writeAuditEvent } from "@/lib/audit";
import { getServiceSupabase } from "@/lib/supabase";

export async function POST(request: NextRequest) {
  try {
    const admin = await requireAdmin();
    if (!canMutate(admin.role)) {
      return NextResponse.json({ error: "Read-only role cannot mutate" }, { status: 403 });
    }

    const body = (await request.json()) as {
      deviceId?: string;
      licenseId?: string;
      action?: "revoke_device" | "revoke_license";
    };

    const supabase = getServiceSupabase();

    if (body.action === "revoke_device" && body.deviceId) {
      const { data, error } = await supabase
        .from("devices")
        .update({ revoked_at: new Date().toISOString() })
        .eq("id", body.deviceId)
        .select("*")
        .maybeSingle();
      if (error) {
        return NextResponse.json({ error: error.message }, { status: 500 });
      }
      await writeAuditEvent({
        actorClerkId: admin.clerkUserId,
        actorEmail: admin.email,
        action: "devices.revoke",
        target: body.deviceId,
      });
      return NextResponse.json({ device: data });
    }

    if (body.action === "revoke_license" && body.licenseId) {
      const { data, error } = await supabase
        .from("licenses")
        .update({ status: "revoked", updated_at: new Date().toISOString() })
        .eq("id", body.licenseId)
        .select("*")
        .maybeSingle();
      if (error) {
        return NextResponse.json({ error: error.message }, { status: 500 });
      }
      await writeAuditEvent({
        actorClerkId: admin.clerkUserId,
        actorEmail: admin.email,
        action: "licenses.revoke",
        target: body.licenseId,
      });
      return NextResponse.json({ license: data });
    }

    return NextResponse.json({ error: "action and id required" }, { status: 400 });
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : message === "Forbidden" ? 403 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
