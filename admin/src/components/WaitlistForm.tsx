"use client";

import { FormEvent, useState } from "react";

type WaitlistState = "idle" | "submitting" | "done" | "error";

export function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [state, setState] = useState<WaitlistState>("idle");
  const [message, setMessage] = useState<string | null>(null);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setState("submitting");
    setMessage(null);
    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const json = (await res.json()) as { error?: string; message?: string };
      if (!res.ok) {
        throw new Error(json.error || "Could not join the waitlist.");
      }
      setState("done");
      setMessage(json.message ?? "You are on the waitlist.");
      setEmail("");
    } catch (err) {
      setState("error");
      setMessage(err instanceof Error ? err.message : "Could not join the waitlist.");
    }
  }

  return (
    <div className="space-y-3">
      <form onSubmit={onSubmit} className="flex flex-col gap-2 sm:flex-row">
        <label className="sr-only" htmlFor="waitlist-email">
          Email
        </label>
        <input
          id="waitlist-email"
          type="email"
          required
          autoComplete="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={state === "submitting"}
          className="w-full rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-sm text-zinc-100 placeholder:text-zinc-600 disabled:opacity-50"
        />
        <button
          type="submit"
          disabled={state === "submitting"}
          className="shrink-0 rounded-md bg-zinc-100 px-4 py-2 text-sm font-medium text-zinc-900 disabled:opacity-50"
        >
          {state === "submitting" ? "Joining…" : "Join waitlist"}
        </button>
      </form>
      {message ? (
        <p
          className={`text-sm ${state === "error" ? "text-red-400" : "text-zinc-400"}`}
          role="status"
        >
          {message}
        </p>
      ) : (
        <p className="text-sm text-zinc-500">
          Beta invites are sent by email. Local archive protection never requires an account.
        </p>
      )}
    </div>
  );
}
