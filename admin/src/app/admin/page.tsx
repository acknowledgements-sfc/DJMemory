export default function AdminOverviewPage() {
  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold">Support overview</h1>
      <p className="max-w-2xl text-zinc-400">
        Look up users, manage beta invites, inspect diagnostics metadata, and review the audit log.
        Local DJMemory protection continues to work without an account.
      </p>
      <div className="grid gap-3 sm:grid-cols-3">
        {[
          ["Users", "/admin/users", "Search by email; view devices and licenses"],
          ["Beta invites", "/admin/invites", "Create or resend invites"],
          ["Audit log", "/admin/audit", "Sign-ins, views, and mutations"],
        ].map(([title, href, body]) => (
          <a
            key={href}
            href={href}
            className="rounded-lg border border-zinc-800 bg-zinc-900/50 p-4 hover:border-zinc-600"
          >
            <div className="font-medium text-zinc-100">{title}</div>
            <div className="mt-1 text-sm text-zinc-500">{body}</div>
          </a>
        ))}
      </div>
    </div>
  );
}
