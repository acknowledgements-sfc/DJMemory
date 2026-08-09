#!/usr/bin/env bash
# Write SUPABASE_SERVICE_ROLE_KEY into admin/.env.local from the macOS clipboard.
# 1. Open https://supabase.com/dashboard/project/alywaxyxnaxwbbsiaafs/settings/api
# 2. Reveal and copy the service_role secret
# 3. Run: bash scripts/fill-supabase-service-role-from-clipboard.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/admin/.env.local"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

KEY="$(pbpaste | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
if [[ -z "$KEY" ]]; then
  echo "Clipboard is empty. Copy the Supabase service_role key first." >&2
  exit 1
fi

if [[ "$KEY" != eyJ* && "$KEY" != sb_secret_* ]]; then
  echo "Clipboard does not look like a Supabase service_role key (expected eyJ… JWT or sb_secret_…)." >&2
  exit 1
fi

# Refuse accidental paste of anon/publishable keys.
if [[ "$KEY" == sb_publishable_* ]]; then
  echo "That is a publishable key, not service_role." >&2
  exit 1
fi

python3 - "$ENV_FILE" "$KEY" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
key = sys.argv[2]
lines = path.read_text().splitlines()
out = []
found = False
for line in lines:
    if line.startswith("SUPABASE_SERVICE_ROLE_KEY="):
        out.append(f"SUPABASE_SERVICE_ROLE_KEY={key}")
        found = True
    else:
        out.append(line)
if not found:
    out.append(f"SUPABASE_SERVICE_ROLE_KEY={key}")
path.write_text("\n".join(out) + "\n")
print(f"Wrote SUPABASE_SERVICE_ROLE_KEY to {path} (len={len(key)})")
PY
