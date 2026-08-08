import { NextRequest, NextResponse } from "next/server";
import { canMutate, requireAdmin } from "@/lib/auth";
import { writeAuditEvent } from "@/lib/audit";
import { getServiceSupabase } from "@/lib/supabase";

export async function GET(request: NextRequest) {
  try {
    const admin = await requireAdmin();
    const email = request.nextUrl.searchParams.get("email")?.trim().toLowerCase();

    const supabase = getServiceSupabase();
    let query = supabase.from("users").select("*").order("created_at", { ascending: false }).limit(50);
    if (email) {
      query = query.ilike("email", `%${email}%`);
    }

    const { data, error } = await query;
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    await writeAuditEvent({
      actorClerkId: admin.clerkUserId,
      actorEmail: admin.email,
      action: "users.search",
      target: email || "list",
    });

    return NextResponse.json({ users: data ?? [] });
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : message === "Forbidden" ? 403 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const admin = await requireAdmin();
    if (!canMutate(admin.role)) {
      return NextResponse.json({ error: "Read-only role cannot mutate" }, { status: 403 });
    }

    const body = (await request.json()) as {
      userId?: string;
      status?: string;
      releaseChannel?: string;
    };

    if (!body.userId) {
      return NextResponse.json({ error: "userId required" }, { status: 400 });
    }

    const updates: Record<string, string> = {};
    if (body.status) updates.status = body.status;
    if (body.releaseChannel) updates.release_channel = body.releaseChannel;

    const supabase = getServiceSupabase();
    const { data, error } = await supabase
      .from("users")
      .update(updates)
      .eq("id", body.userId)
      .select("*")
      .maybeSingle();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    await writeAuditEvent({
      actorClerkId: admin.clerkUserId,
      actorEmail: admin.email,
      action: "users.update",
      target: body.userId,
    });

    return NextResponse.json({ user: data });
  } catch (error) {
    const message = error instanceof Error ? error.message : "error";
    const status = message === "Unauthorized" ? 401 : message === "Forbidden" ? 403 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}
