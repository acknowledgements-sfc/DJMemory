import { auth, currentUser } from "@clerk/nextjs/server";
import { getServiceSupabase, type AdminRole } from "./supabase";

const MUTATING_ROLES: AdminRole[] = ["owner", "support", "release_manager"];

export async function requireSignedIn() {
  const session = await auth();
  if (!session.userId) {
    throw new Error("Unauthorized");
  }
  return session;
}

export async function requireAdmin(): Promise<{
  clerkUserId: string;
  email: string | null;
  role: AdminRole;
}> {
  const session = await auth();
  if (!session.userId) {
    throw new Error("Unauthorized");
  }

  const supabase = getServiceSupabase();
  const { data, error } = await supabase
    .from("admin_roles")
    .select("role, email")
    .eq("clerk_user_id", session.userId)
    .maybeSingle();

  if (error) {
    throw new Error(`Admin role lookup failed: ${error.message}`);
  }
  if (!data?.role) {
    throw new Error("Forbidden");
  }

  const user = await currentUser();
  const email =
    data.email ||
    user?.primaryEmailAddress?.emailAddress ||
    user?.emailAddresses[0]?.emailAddress ||
    null;

  return {
    clerkUserId: session.userId,
    email,
    role: data.role as AdminRole,
  };
}

export function canMutate(role: AdminRole): boolean {
  return MUTATING_ROLES.includes(role);
}

export function canManageInvites(role: AdminRole): boolean {
  return role === "owner" || role === "release_manager" || role === "support";
}
