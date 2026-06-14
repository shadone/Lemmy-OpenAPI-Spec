## Scripts

```
scripts/build.sh [version-dir]      build v4 openapi.yaml from base + overlay
scripts/validate.sh                 lint every spec
scripts/sync-v4.sh <ref> <version>  regenerate a v4 base from lemmy-js-client
scripts/drift-check.sh [ref] [ver]  fail if the vendored v4 base trails upstream
scripts/build-docs.sh [out-dir]     build the per-version redoc site
```

The v4 scripts need a local `lemmy-js-client` checkout (set `LEMMY_JS_CLIENT`,
default `../3rdparty/lemmy-js-client`) and shell out to `pnpm`, `redocly`, and
`bump-cli` through `npx`. CI lints on every push and PR, checks for upstream
drift weekly, and publishes the docs.
