#!/bin/sh
# Lint every published spec (v3 hand-authored + v4 built). Cosmetic rules that an
# auto-generated (tsoa) spec inherently trips are skipped so that a failure means
# a real structural problem, not a missing summary/4xx/orphan-type.
set -eu
cd "$(dirname "$0")/.."

SKIP="--skip-rule info-license-url \
--skip-rule operation-summary \
--skip-rule operation-4xx-response \
--skip-rule no-unused-components"

status=0
for f in specs/v3/*/Lemmy.yaml specs/v4/*/Lemmy.yaml; do
  [ -f "$f" ] || continue
  echo "== lint $f =="
  # shellcheck disable=SC2086
  npx -y @redocly/cli@latest lint $SKIP "$f" || status=1
done
exit $status
