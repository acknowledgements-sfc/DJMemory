"use client";

import { FormEvent, useState } from "react";

type UserRow = {
  id: string;
  email: string;
  display_name: string | null;
  status: string;
  release_channel: string;
  created_at: string;
};

type Detail = {
  devices: Array<{
    id: string;
    device_name: string;
    app_version: string | null;
    last_seen: string;
    revoked_at: string | null;
  }>;
  licenses: Array<{
    id: string;
    plan: string;
    status: string;
    renews_or_expires_at: string | null;
  }>;
  diagnostics: Array<{
    id: string;
    metadata: Record<string, unknown>;
    created_at: string;
  }>;
  restrictions: { note: string };
};

export default function AdminUsersPage() {
  const [email, setEmail] = useState("");
  const [users, setUsers] = useState<UserRow[]>([]);
  const [selected, setSelected] = useState<UserRow | null>(null);
  const [detail, setDetail] = useState<Detail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function search(event?: FormEvent) {
    event?.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/admin/users?email=${encodeURIComponent(email)}`);
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "search failed");
      setUsers(json.users ?? []);
      setSelected(null);
      setDetail(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "search failed");
    } finally {
      setBusy(false);
    }
  }

  async function openUser(user: UserRow) {
    setSelected(user);
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/admin/users/detail?userId=${encodeURIComponent(user.id)}`);
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "detail failed");
      setDetail(json);
    } catch (err) {
      setError(err instanceof Error ? err.message : "detail failed");
    } finally {
      setBusy(false);
    }
  }

  async function setChannel(channel: string) {
    if (!selected) return;
    setBusy(true);
    try {
      const res = await fetch("/api/admin/users", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId: selected.id, releaseChannel: channel }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "update failed");
      setSelected(json.user);
      await search();
    } catch (err) {
      setError(err instanceof Error ? err.message : "update failed");
    } finally {
      setBusy(false);
    }
  }

  async function revoke(action: "revoke_device" | "revoke_license", id: string) {
    setBusy(true);
    try {
      const body =
        action === "revoke_device"
          ? { action, deviceId: id }
          : { action, licenseId: id };
      const res = await fetch("/api/admin/revoke", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || "revoke failed");
      if (selected) await openUser(selected);
    } catch (err) {
      setError(err instanceof Error ? err.message : "revoke failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Users</h1>
        <p className="text-sm text-zinc-500">Search by email. Diagnostics show metadata only.</p>
      </div>

      <form onSubmit={search} className="flex gap-2">
        <input
          className="w-full max-w-md rounded-md border border-zinc-700 bg-zinc-900 px-3 py-2 text-sm"
          placeholder="email@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <button
          type="submit"
          disabled={busy}
          className="rounded-md bg-zinc-100 px-4 py-2 text-sm font-medium text-zinc-900 disabled:opacity-50"
        >
          Search
        </button>
      </form>

      {error ? <p className="text-sm text-red-400">{error}</p> : null}

      <div className="overflow-hidden rounded-lg border border-zinc-800">
        <table className="w-full text-left text-sm">
          <thead className="bg-zinc-900 text-zinc-500">
            <tr>
              <th className="px-3 py-2 font-medium">Email</th>
              <th className="px-3 py-2 font-medium">Status</th>
              <th className="px-3 py-2 font-medium">Channel</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr
                key={user.id}
                className="cursor-pointer border-t border-zinc-800 hover:bg-zinc-900/60"
                onClick={() => openUser(user)}
              >
                <td className="px-3 py-2">{user.email}</td>
                <td className="px-3 py-2">{user.status}</td>
                <td className="px-3 py-2">{user.release_channel}</td>
              </tr>
            ))}
            {users.length === 0 ? (
              <tr>
                <td colSpan={3} className="px-3 py-6 text-zinc-600">
                  No users yet. Apply the Supabase migration and seed after Clerk sign-up.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>

      {selected && detail ? (
        <div className="space-y-4 rounded-lg border border-zinc-800 p-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 className="text-lg font-medium">{selected.email}</h2>
              <p className="text-xs text-zinc-500">{detail.restrictions.note}</p>
            </div>
            <div className="flex gap-2">
              {["stable", "beta", "internal"].map((channel) => (
                <button
                  key={channel}
                  type="button"
                  disabled={busy}
                  onClick={() => setChannel(channel)}
                  className="rounded border border-zinc-700 px-2 py-1 text-xs"
                >
                  Channel: {channel}
                </button>
              ))}
            </div>
          </div>

          <section>
            <h3 className="mb-2 text-sm font-medium text-zinc-300">Devices</h3>
            <ul className="space-y-2 text-sm text-zinc-400">
              {detail.devices.map((device) => (
                <li key={device.id} className="flex items-center justify-between gap-3">
                  <span>
                    {device.device_name} · {device.app_version ?? "—"} ·{" "}
                    {device.revoked_at ? "revoked" : "active"}
                  </span>
                  {!device.revoked_at ? (
                    <button
                      type="button"
                      className="text-xs text-red-400"
                      onClick={() => revoke("revoke_device", device.id)}
                    >
                      Revoke
                    </button>
                  ) : null}
                </li>
              ))}
              {detail.devices.length === 0 ? <li>No devices</li> : null}
            </ul>
          </section>

          <section>
            <h3 className="mb-2 text-sm font-medium text-zinc-300">Licenses</h3>
            <ul className="space-y-2 text-sm text-zinc-400">
              {detail.licenses.map((license) => (
                <li key={license.id} className="flex items-center justify-between gap-3">
                  <span>
                    {license.plan} · {license.status}
                  </span>
                  {license.status !== "revoked" ? (
                    <button
                      type="button"
                      className="text-xs text-red-400"
                      onClick={() => revoke("revoke_license", license.id)}
                    >
                      Revoke
                    </button>
                  ) : null}
                </li>
              ))}
              {detail.licenses.length === 0 ? <li>No licenses</li> : null}
            </ul>
          </section>

          <section>
            <h3 className="mb-2 text-sm font-medium text-zinc-300">Diagnostics (metadata only)</h3>
            <ul className="space-y-2 font-mono text-xs text-zinc-500">
              {detail.diagnostics.map((row) => (
                <li key={row.id} className="rounded border border-zinc-800 p-2">
                  <div className="mb-1 text-zinc-400">{row.created_at}</div>
                  <pre className="overflow-x-auto whitespace-pre-wrap">
                    {JSON.stringify(row.metadata, null, 2)}
                  </pre>
                </li>
              ))}
              {detail.diagnostics.length === 0 ? <li>No uploads</li> : null}
            </ul>
          </section>
        </div>
      ) : null}
    </div>
  );
}
