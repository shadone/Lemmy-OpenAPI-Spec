#!/bin/sh
# Build redoc HTML reference docs for every published spec into a static site:
#   <out>/<surface>/<version>/index.html  + a landing <out>/index.html
# Used by the docs/Pages workflow; runnable locally for preview.
#
# Usage: scripts/build-docs.sh [out-dir]   (default: site)
set -eu
cd "$(dirname "$0")/.."
out="${1:-site}"
rm -rf "$out"
mkdir -p "$out"

items=""
for f in $(ls specs/v3/*/openapi.yaml specs/v4/*/openapi.yaml 2>/dev/null | sort -V); do
  surface=$(echo "$f" | cut -d/ -f2)
  version=$(echo "$f" | cut -d/ -f3)
  dir="$out/$surface/$version"
  mkdir -p "$dir"
  npx -y @redocly/cli@2.32.2 build-docs "$f" -o "$dir/index.html" >/dev/null
  items="$items      <li><a href=\"./$surface/$version/\">$surface / $version</a></li>\n"
  echo "built $dir/index.html"
done

{
  echo '<!doctype html>'
  echo '<html lang="en"><head><meta charset="utf-8">'
  echo '<meta name="viewport" content="width=device-width, initial-scale=1">'
  echo '<title>Lemmy client API — OpenAPI versions</title>'
  echo '<style>body{font-family:system-ui,sans-serif;max-width:42rem;margin:3rem auto;padding:0 1rem;line-height:1.6}h1{font-size:1.4rem}code{background:#f2f2f2;padding:.1em .3em;border-radius:3px}</style>'
  echo '</head><body>'
  echo '<h1>Lemmy client API (unofficial OpenAPI)</h1>'
  echo '<p>Per-version reference docs. <code>v3</code> is the 0.19.x API; <code>v4</code> is the Lemmy 1.0 API &mdash; a rewrite, not backward-compatible with v3.</p>'
  echo '<ul>'
  printf "%b" "$items"
  echo '</ul>'
  echo '</body></html>'
} > "$out/index.html"
echo "wrote $out/index.html"
