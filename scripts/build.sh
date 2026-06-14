#!/bin/sh
# Build the consumer-facing Lemmy.yaml for each vendored v4 spec by applying its
# OpenAPI Overlay to the pristine base. v3 specs are hand-authored directly and
# are not built here.
#
# Usage: scripts/build.sh [version-dir ...]
#   No args: build every specs/v4/*/ that has a base.
set -eu

cd "$(dirname "$0")/.."

build_one() {
  dir="$1"
  case "$dir" in */) ;; *) dir="$dir/";; esac
  base=""
  for cand in "${dir}base.json" "${dir}base.yaml"; do
    [ -f "$cand" ] && base="$cand" && break
  done
  [ -n "$base" ] || { echo "skip $dir (no base)"; return; }
  overlay="${dir}overlay.yaml"
  out="${dir}Lemmy.yaml"

  # 1. deterministic normalization (number/double -> integer/int64)
  norm="$(mktemp -t lemmy-base-XXXXXX).json"
  node scripts/normalize.mjs "$base" > "$norm"

  # 2. apply curation overlay (if any) -> consumer Lemmy.yaml.
  #    -o infers YAML from the .yaml extension; remove any prior output first so
  #    bump-cli doesn't prompt to overwrite (which would hang non-interactively).
  rm -f "$out"
  if [ -f "$overlay" ]; then
    CI=1 npx -y bump-cli@2.10.0 overlay "$norm" "$overlay" -o "$out" >/dev/null 2>&1 < /dev/null
  else
    npx -y @redocly/cli@2.32.2 bundle "$norm" -o "$out"
  fi
  rm -f "$norm"
  echo "built $out"
}

if [ "$#" -gt 0 ]; then
  for d in "$@"; do build_one "$d"; done
else
  for d in specs/v4/*/; do build_one "$d"; done
fi
