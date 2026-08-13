"use client";

const SESSION_KEY = "djmemory_marketing_session";

function sessionID() {
  const existing = window.sessionStorage.getItem(SESSION_KEY);
  if (existing) return existing;
  const created = crypto.randomUUID();
  window.sessionStorage.setItem(SESSION_KEY, created);
  return created;
}

export function trackMarketingEvent(
  event: string,
  properties: Record<string, string> = {},
) {
  const source = new URLSearchParams(window.location.search).get("utm_source") ?? "direct";
  void fetch("/api/events", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    keepalive: true,
    body: JSON.stringify({ event, properties, source, sessionId: sessionID() }),
  });
}
