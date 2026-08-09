import { NextRequest, NextResponse } from "next/server";
import { requireSignedIn } from "@/lib/auth";
import { ensureAppUser, sanitizeDiagnosticMetadata } from "@/lib/users";
import { getServiceSupabase } from "@/lib/supabase";

/**
 * POST /api/diagnostics — user-initiated metadata-only upload.
 * Rejects track titles/artists/tracklists. Never called from archive/scan paths.
 */
export async function POST(request: NextRequest) {
  try {
    const session = await requireSignedIn();
    const body = (await request.json()) as { metadata?: unknown };
    if (body.metadata === undefined || body.metadata === null) {
      return NextResponse.json({ error: "metadata required" }, { status: 400 });
    }

    const sanitized = sanitizeDiagnosticMetadata(body.metadata);
    const forbiddenHit = ["title", "artist", "tracks", "tracklist"].some((key) =>
      Object.prototype.hasOwnProperty.call(
        typeof body.metadata === "object" && body.metadata !== null
          ? (body.metadata as Record<string, unknown>)
          : {},
        key
      )
    );
    if (forbiddenHit) {
      return NextResponse.json(
        {
          error:
            "Diagnostics must be metadata only — title, artist, tracks, and tracklist fields are not accepted.",
        },
        { status: 400 }
      );
    }

    const user = await ensureAppUser(session.userId!);
    if (user.status === "disabled") {
      return NextResponse.json({ error: "Account disabled" }, { status: 403 });
    }

    const supabase = getServiceSupabase();
    const { data, error } = await supabase
      .from("diagnostic_uploads")
      .insert({
        user_id: user.id,
        metadata: sanitized,
      })
      .select("id, user_id, created_at")
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(
      {
        upload: data,
        restrictions: {
          audio: false,
          tracklistContents: false,
          note: "Diagnostics exports contain metadata only — paths, timings, counts, and error strings.",
        },
      },
      { status: 201 }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
