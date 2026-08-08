"use client";

import { FormEvent, useEffect, useState } from "react";

type Invite = {
  id: string;
  email: string;
  status: string;
  sent_at: string;
  accepted_at: string | null;
};

export default function AdminInvitesPage() {
  const [invites, setInvites] = useState<Invite[]>([]);
  const [email, setEmail] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function load() {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/invites");
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "load failed");
      setInvites(json.invites ?? []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "load failed");
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    void load();
  }, []);

  async function createInvite(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/invites", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "create failed");
      setEmail("");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "create failed");
      setBusy(false);
    }
  }

  async function resend(id: string) {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/invites", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ resendId: id }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "resend failed");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "resend failed");
      setBusy(false);
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Beta invites</h1>
        <p className="text-sm text-zinc-500">Create or resend invites. Mutations write audit events.</p>
      </div>

      <form onSubmit={createInvite} className="flex gap-2">
        <input
          className="w-full max-w-md rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-sm"
          placeholder="dj@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <button
          type="submit"
          disabled={busy}
          className="rounded-md bg-zinc-100 px-4 py-2 text-sm font-medium text-zinc-900 disabled:opacity-50"
        >
          Invite
        </button>
      </form>

      {error ? <p className="text-sm text-red-400">{error}</p> : null}

      <div className="overflow-hidden rounded-lg border border-zinc-800">
        <table className="w-full text-left text-sm">
          <thead className="bg-zinc-900 text-zinc-500">
            <tr>
              <th className="px-3 py-2 font-medium">Email</th>
              <th className="px-3 py-2 font-medium">Status</th>
              <th className="px-3 py-2 font-medium">Sent</th>
              <th className="px-3 py-2 font-medium" />
            </tr>
          </thead>
          <tbody>
            {invites.map((invite) => (
              <tr key={invite.id} className="border-t border-zinc-800">
                <td className="px-3 py-2">{invite.email}</td>
                <td className="px-3 py-2">{invite.status}</td>
                <td className="px-3 py-2 font-mono text-xs text-zinc-500">{invite.sent_at}</td>
                <td className="px-3 py-2 text-right">
                  <button
                    type="button"
                    className="text-xs text-zinc-300 underline"
                    disabled={busy}
                    onClick={() => resend(invite.id)}
                  >
                    Resend
                  </button>
                </td>
              </tr>
            ))}
            {invites.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-3 py-6 text-zinc-600">
                  No invites yet.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}
