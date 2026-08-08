import Link from "next/link";
import { UserButton } from "@clerk/nextjs";

const nav = [
  { href: "/admin", label: "Overview" },
  { href: "/admin/users", label: "Users" },
  { href: "/admin/invites", label: "Beta invites" },
  { href: "/admin/audit", label: "Audit log" },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen">
      <header className="border-b border-zinc-800">
        <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-6 py-4">
          <div className="flex items-center gap-6">
            <Link href="/" className="text-sm font-medium text-zinc-200">
              DJMemory Admin
            </Link>
            <nav className="flex gap-4 text-sm text-zinc-400">
              {nav.map((item) => (
                <Link key={item.href} href={item.href} className="hover:text-zinc-100">
                  {item.label}
                </Link>
              ))}
            </nav>
          </div>
          <UserButton />
        </div>
      </header>
      <div className="mx-auto max-w-5xl px-6 py-8">{children}</div>
      <footer className="mx-auto max-w-5xl px-6 pb-10 text-xs text-zinc-600">
        Support-first admin. No audio playback or download. No tracklist contents. Every mutation
        writes an audit event.
      </footer>
    </div>
  );
}
