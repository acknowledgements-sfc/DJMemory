import { NextRequest, NextResponse } from "next/server";
import { requireSignedIn } from "@/lib/auth";
import { ensureAppUser } from "@/lib/users";
import { getServiceSupabase } from "@/lib/supabase";

/**
 * POST /api/devices — optional after sign-in.
 * Body: { deviceName, appVersion?, installChannel?, platformDeviceId? }
 * Upserts by user + stable lookup name. Never required for local protection.
 */
export async function POST(request: NextRequest) {
  try {
    const session = await requireSignedIn();
    const body = (await request.json()) as {
      deviceName?: string;
      appVersion?: string;
      installChannel?: string;
      platformDeviceId?: string;
    };

    const deviceName = body.deviceName?.trim();
    if (!deviceName) {
      return NextResponse.json({ error: "deviceName required" }, { status: 400 });
    }

    const user = await ensureAppUser(session.userId!);
    if (user.status === "disabled") {
      return NextResponse.json({ error: "Account disabled" }, { status: 403 });
    }

    const supabase = getServiceSupabase();
    const installChannel = body.installChannel?.trim() || "local";
    const appVersion = body.appVersion?.trim() || null;
    const platformKey = body.platformDeviceId?.trim();
    const lookupName = platformKey ? `${deviceName} [${platformKey}]` : deviceName;
    const now = new Date().toISOString();

    const { data: matches, error: matchError } = await supabase
      .from("devices")
      .select("*")
      .eq("user_id", user.id)
      .is("revoked_at", null)
      .eq("device_name", lookupName)
      .limit(1);

    if (matchError) {
      return NextResponse.json({ error: matchError.message }, { status: 500 });
    }

    if (matches && matches.length > 0) {
      const { data, error } = await supabase
        .from("devices")
        .update({
          app_version: appVersion,
          install_channel: installChannel,
          last_seen: now,
        })
        .eq("id", matches[0].id)
        .select("*")
        .single();
      if (error) {
        return NextResponse.json({ error: error.message }, { status: 500 });
      }
      return NextResponse.json({ device: data, created: false });
    }

    const { data, error } = await supabase
      .from("devices")
      .insert({
        user_id: user.id,
        device_name: lookupName,
        app_version: appVersion,
        install_channel: installChannel,
        last_seen: now,
      })
      .select("*")
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ device: data, created: true }, { status: 201 });
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
