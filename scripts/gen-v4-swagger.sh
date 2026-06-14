#!/bin/sh
# Internal helper: generate the tsoa OpenAPI (swagger.json) for the /api/v4
# surface from the official lemmy-js-client at a given ref, into <out.json>.
# Used by sync-v4 (to vendor a base) and drift-check (to compare).
#
# Usage: scripts/gen-v4-swagger.sh <js-client-ref> <out.json>
set -eu
ref="${1:?usage: gen-v4-swagger.sh <js-client-ref> <out.json>}"
out="${2:?usage: gen-v4-swagger.sh <js-client-ref> <out.json>}"

cd "$(dirname "$0")/.."
client="${LEMMY_JS_CLIENT:-../3rdparty/lemmy-js-client}"
[ -d "$client/.git" ] || { echo "lemmy-js-client not found at $client (set LEMMY_JS_CLIENT)" >&2; exit 1; }

wt="$(mktemp -d -t ljs-XXXXXX)"
cleanup() { git -C "$client" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"; }
trap cleanup EXIT

git -C "$client" worktree add --detach "$wt" "$ref" >&2
ver="$(grep -m1 'VERSION' "$wt/src/other_types.ts" | sed 's/.*= *//; s/[";]//g')"
[ "$ver" = "v4" ] || { echo "ref $ref is client VERSION=$ver, not v4" >&2; exit 1; }

( cd "$wt" && npx -y pnpm@10.33.2 install >&2 && ./node_modules/.bin/tsoa spec-and-routes >&2 )

mkdir -p "$(dirname "$out")"
cp "$wt/tsoa_build/swagger.json" "$out"
git -C "$wt" rev-parse HEAD   # echo the source commit to stdout
