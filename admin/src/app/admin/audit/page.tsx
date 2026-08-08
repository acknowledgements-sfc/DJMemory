"use client";

import { useEffect, useState } from "react";

type AuditEvent = {
  id: string;
  actor_clerk_id: string;
  actor_email: string | null;
  action: string;
  target: string | null;
  result: string;
  created_at: string;
};

export default function AdminAuditPage() {
  const [events, setEvents] = useState<AuditEvent[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void (async () => {
      try {
        const res = await fetch("/api/admin/audit");
        const json = await res.json();
        if (!res.ok) throw new Error(json.error || "load failed");
        setEvents(json.events ?? []);
      } catch (err) {
        setError(err instanceof Error ? err.message : "load failed");
      }
    })();
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Audit log</h1>
        <p className="text-sm text-zinc-500">
          Admin sign-ins, record views, and mutations. Actor, target, timestamp, action, result.
        </p>
      </div>

      {error ? <p className="text-sm text-red-400">{error}</p> : null}

      <div className="overflow-hidden rounded-lg border border-zinc-800">
        <table className="w-full text-left text-sm">
          <thead className="bg-zinc-900 text-zinc-500">
            <tr>
              <th className="px-3 py-2 font-medium">When</th>
              <th className="px-3 py-2 font-medium">Actor</th>
              <th className="px-3 py-2 font-medium">Action</th>
              <th className="px-3 py-2 font-medium">Target</th>
              <th className="px-3 py-2 font-medium">Result</th>
            </tr>
          </thead>
          <tbody>
            {events.map((event) => (
              <tr key={event.id} className="border-t border-zinc-800">
                <td className="px-3 py-2 font-mono text-xs text-zinc-500">{event.created_at}</td>
                <td className="px-3 py-2">{event.actor_email || event.actor_clerk_id}</td>
                <td className="px-3 py-2">{event.action}</td>
                <td className="px-3 py-2 text-zinc-400">{event.target || "—"}</td>
                <td className="px-3 py-2">{event.result}</td>
              </tr>
            ))}
            {events.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-3 py-6 text-zinc-600">
                  No audit events yet.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}
