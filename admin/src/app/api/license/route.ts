import { NextResponse } from "next/server";
import { requireSignedIn } from "@/lib/auth";
import { ensureAppUser } from "@/lib/users";
import { getServiceSupabase } from "@/lib/supabase";

/**
 * GET /api/license — optional after sign-in.
 * Cache locally; when unreachable, clients keep full local features.
 * Never required for local archive/scan/protection.
 */
export async function GET() {
  try {
    const session = await requireSignedIn();
    const user = await ensureAppUser(session.userId!);
    const supabase = getServiceSupabase();

    const { data: licenses, error } = await supabase
      .from("licenses")
      .select("*")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(5);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    const active =
      (licenses ?? []).find((row) => row.status === "active" || row.status === "trial") ??
      null;

    return NextResponse.json({
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        status: user.status,
        releaseChannel: user.release_channel,
      },
      license: active
        ? {
            id: active.id,
            plan: active.plan,
            status: active.status,
            renewsOrExpiresAt: active.renews_or_expires_at,
          }
        : {
            id: null,
            plan: "free",
            status: "active",
            renewsOrExpiresAt: null,
          },
      localFeatures: {
        // Product non-negotiable: offline / no license = full local protection.
        archiveScanProtect: true,
        note: "Local archive, scan, and protection never depend on license status.",
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
