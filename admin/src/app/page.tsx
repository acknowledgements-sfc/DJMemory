import Link from "next/link";
import { Show, SignInButton, UserButton } from "@clerk/nextjs";

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-2xl flex-col justify-center gap-8 px-6 py-16">
      <div className="space-y-3">
        <p className="text-sm uppercase tracking-[0.2em] text-zinc-500">DJMemory</p>
        <h1 className="text-3xl font-semibold tracking-tight">Account (optional)</h1>
        <p className="text-zinc-400">
          Local protection never depends on an account. Audio files are never uploaded by default.
          Full tracklists stay on your Mac unless you explicitly export them.
        </p>
      </div>

      <ul className="space-y-2 text-sm text-zinc-400">
        <li>Beta invite and license status</li>
        <li>Device list and release channel</li>
        <li>Opt-in diagnostics upload (metadata only)</li>
      </ul>

      <div className="flex items-center gap-4">
        <Show when="signed-out">
          <SignInButton mode="modal">
            <button className="rounded-md bg-zinc-100 px-4 py-2 text-sm font-medium text-zinc-900">
              Sign in
            </button>
          </SignInButton>
        </Show>
        <Show when="signed-in">
          <UserButton />
          <Link href="/admin" className="text-sm text-zinc-300 underline underline-offset-4">
            Open admin
          </Link>
        </Show>
        <Link href="/api/health" className="text-sm text-zinc-500">
          Health
        </Link>
      </div>
    </main>
  );
}
