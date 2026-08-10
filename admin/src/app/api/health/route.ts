import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    ok: true,
    service: "djmemory-admin",
    host: process.env.NEXT_PUBLIC_ACCOUNT_URL ?? "https://beatrevival.com",
    privacy: {
      audioUploadDefault: false,
      tracklistUploadDefault: false,
      diagnostics: "metadata-only",
    },
  });
}
