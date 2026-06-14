#!/bin/sh
# Detect whether a vendored v4 base has drifted from upstream. Regenerates the
# base from the js-client (default ref: main) and diffs it against the committed
# base.json. Exits non-zero on drift. Intended for CI so the spec cannot silently
# fall behind the upstream types/endpoints again.
#
# Usage: scripts/drift-check [js-client-ref] [out-version]
set -eu
ref="${1:-main}"
outver="${2:-1.0.0-pre}"

cd "$(dirname "$0")/.."
committed="specs/v4/$outver/base.json"
[ -f "$committed" ] || { echo "no vendored base at $committed"; exit 1; }

tmp="$(mktemp -t drift-XXXXXX).json"
trap 'rm -f "$tmp"' EXIT
scripts/gen-v4-swagger.sh "$ref" "$tmp" >/dev/null

if diff -q "$committed" "$tmp" >/dev/null; then
  echo "no drift: specs/v4/$outver/base.json matches lemmy-js-client@$ref"
else
  echo "DRIFT: specs/v4/$outver/base.json differs from lemmy-js-client@$ref"
  echo "  re-sync with: scripts/sync-v4 $ref $outver && scripts/build.sh specs/v4/$outver"
  diff "$committed" "$tmp" | head -40 || true
  exit 1
fi
