import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({
    ok: true,
    service: "djmemory-admin",
    privacy: {
      audioUploadDefault: false,
      tracklistUploadDefault: false,
      diagnostics: "metadata-only",
    },
  });
}
