import Link from "next/link";
import { Show, SignInButton, UserButton } from "@clerk/nextjs";
import { WaitlistForm } from "@/components/WaitlistForm";

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-2xl flex-col justify-center gap-10 px-6 py-16">
      <div className="space-y-4">
        <p className="text-sm uppercase tracking-[0.2em] text-zinc-500">Beat Revival</p>
        <h1 className="text-4xl font-semibold tracking-tight">DJMemory</h1>
        <p className="text-lg text-zinc-300">
          Automatically archive DJ set recordings from Serato, rekordbox, Traktor, VirtualDJ, and
          djay Pro — local-first, on your Mac.
        </p>
        <p className="text-zinc-400">
          Audio files are never uploaded by default. Full tracklists stay on your Mac unless you
          explicitly export them. Local protection never depends on an account.
        </p>
      </div>

      <section className="space-y-3 rounded-lg border border-zinc-800 bg-zinc-900/40 p-5">
        <h2 className="text-sm font-medium uppercase tracking-wide text-zinc-400">
          Beta waitlist
        </h2>
        <p className="text-sm text-zinc-400">
          Join the waitlist for early access and beta invites. We will email you when a spot opens.
        </p>
        <WaitlistForm />
      </section>

      <ul className="space-y-2 text-sm text-zinc-400">
        <li>Copy-only archive — source recordings are never moved, renamed, or deleted</li>
        <li>Honest support labels for each DJ app</li>
        <li>Optional account for beta license and diagnostics metadata only</li>
      </ul>

      <div className="flex flex-wrap items-center gap-4 border-t border-zinc-800 pt-6">
        <Show when="signed-out">
          <SignInButton mode="modal">
            <button className="rounded-md border border-zinc-700 px-4 py-2 text-sm text-zinc-200">
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
        <Link href="/api/health" className="text-sm text-zinc-600">
          Health
        </Link>
      </div>
    </main>
  );
}
