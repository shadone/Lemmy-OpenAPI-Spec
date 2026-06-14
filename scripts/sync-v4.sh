#!/bin/sh
# Re-sync a v4 base from the official lemmy-js-client at a given ref and vendor it
# as specs/v4/<out-version>/base.json. Run scripts/build.sh afterwards to rebuild
# the consumer openapi.yaml from the new base + overlay.
#
# Usage: scripts/sync-v4 <js-client-ref> <out-version>
#   e.g. scripts/sync-v4 1.0.0     1.0.0      # when 1.0.0 is released
#        scripts/sync-v4 main      1.0.0-pre  # refresh the pre-release snapshot
set -eu
ref="${1:?usage: sync-v4 <js-client-ref> <out-version>}"
outver="${2:?usage: sync-v4 <js-client-ref> <out-version>}"

cd "$(dirname "$0")/.."
out="specs/v4/$outver/base.json"
commit="$(scripts/gen-v4-swagger.sh "$ref" "$out")"
echo "vendored $out from lemmy-js-client@$ref ($(echo "$commit" | cut -c1-12))"
echo "next: update specs/v4/$outver/SOURCE.md, then run: scripts/build.sh specs/v4/$outver"
