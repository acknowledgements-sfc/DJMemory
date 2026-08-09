#!/usr/bin/env bash
# Push admin/.env.local values into a linked Vercel project (production).
# Usage: from admin/, after `npx vercel link` and SUPABASE_SERVICE_ROLE_KEY is set:
#   bash ../scripts/push-accounts-vercel-env.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADMIN="$ROOT/admin"
ENV_FILE="$ADMIN/.env.local"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

if [[ ! -f "$ADMIN/.vercel/project.json" ]]; then
  echo "Vercel project not linked. Run: cd admin && npx vercel link" >&2
  exit 1
fi

get_var() {
  local key="$1"
  local line
  line="$(grep -E "^${key}=" "$ENV_FILE" | tail -1 || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  echo "${line#*=}"
}

require_var() {
  local key="$1"
  local val
  val="$(get_var "$key")"
  if [[ -z "$val" ]]; then
    echo "Missing or empty $key in admin/.env.local" >&2
    exit 1
  fi
  echo "$val"
}

CLERK_PK="$(require_var NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY)"
CLERK_SK="$(require_var CLERK_SECRET_KEY)"
SUPABASE_URL="$(require_var SUPABASE_URL)"
SUPABASE_SRK="$(require_var SUPABASE_SERVICE_ROLE_KEY)"
SIGN_IN="$(get_var NEXT_PUBLIC_CLERK_SIGN_IN_URL)"
ACCOUNT_URL="$(get_var NEXT_PUBLIC_ACCOUNT_URL)"
SIGN_IN="${SIGN_IN:-/sign-in}"

cd "$ADMIN"

upsert() {
  local key="$1"
  local value="$2"
  # Remove existing production value if present, then add.
  npx vercel env rm "$key" production --yes >/dev/null 2>&1 || true
  printf '%s' "$value" | npx vercel env add "$key" production
  echo "Set $key (production)"
}

upsert NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY "$CLERK_PK"
upsert CLERK_SECRET_KEY "$CLERK_SK"
upsert NEXT_PUBLIC_CLERK_SIGN_IN_URL "$SIGN_IN"
upsert SUPABASE_URL "$SUPABASE_URL"
upsert SUPABASE_SERVICE_ROLE_KEY "$SUPABASE_SRK"

if [[ -n "$ACCOUNT_URL" ]]; then
  upsert NEXT_PUBLIC_ACCOUNT_URL "$ACCOUNT_URL"
fi

echo "Done. Deploy with: cd admin && npx vercel --prod"
