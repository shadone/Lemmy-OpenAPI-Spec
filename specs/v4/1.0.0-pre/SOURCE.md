# v4 (Lemmy 1.0) base — source provenance

- **API surface:** `/api/v4` (Lemmy 1.0)
- **Generated from:** `lemmy-js-client` (current `main`)
  - commit: `dafc558f18914e029317436b9591dd51fc4f61fb`
  - describe: `1.0.0-tag-id.3-8-gdafc558`
  - client `VERSION = "v4"`
- **Method:** `pnpm install && tsoa spec-and-routes` → `tsoa_build/swagger.json`,
  vendored verbatim as `base.json` (OpenAPI 3.0.0; 125 paths, 428 schemas).
- **Generated:** 2026-06-14 (re-synced from current `main`; an initial snapshot
  was mistakenly taken from a ~6-week-stale checkout at `71f9184`).
- **Status:** Lemmy 1.0 is **unreleased** — this tracks pre-release `main`. The
  folder is suffixed `-pre` for that reason. When 1.0.0 (or a stable 1.0.x) is
  released, run `scripts/sync-v4 <tag>` to produce `specs/v4/1.0.0/`.

`base.json` is **pristine** — never hand-edit it. Patches and curated
descriptions live in `overlay.yaml`; the consumer-facing `openapi.yaml` is built
from `base.json ⊕ overlay.yaml`.

## Codegen verification (2026-06-14)

The built `openapi.yaml` was run through swift-openapi-generator 1.12.0 /
runtime 1.11.0 (LemmyKit's exact toolchain, `generate: [types, client]`,
`accessModifier: public`). Result: **clean `swift build` (exit 0, no
warnings)** — generated `Types.swift` (~43k lines) + `Client.swift` (~11.8k)
compiled. All 24 `*Id` types resolve to `Swift.Int64` and there are **zero**
`Swift.Double` types, confirming the `normalize.mjs` integer fix carries
through to Swift.

