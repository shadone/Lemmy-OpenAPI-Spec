# v4 (Lemmy 1.0) base — source provenance

- **API surface:** `/api/v4` (Lemmy 1.0)
- **Generated from:** `lemmy-js-client`
  - commit: `71f9184cde3755a75dbb70fbb437fcd486815867`
  - describe: `1.0.0-delete-pm-recipient.2-46-g71f9184`
  - client `VERSION = "v4"`
  - corresponding server: ~`1.0.0-alpha.18`
- **Method:** `pnpm install && tsoa spec-and-routes` → `tsoa_build/swagger.json`,
  vendored verbatim as `base.json` (OpenAPI 3.0.0; 123 paths, 302 schemas).
- **Generated:** 2026-06-14
- **Status:** Lemmy 1.0 is **unreleased** — this tracks pre-release `main`. The
  folder is suffixed `-pre` for that reason. When 1.0.0 (or a stable 1.0.x) is
  released, run `scripts/sync-v4 <tag>` to produce `specs/v4/1.0.0/`.

`base.json` is **pristine** — never hand-edit it. Patches and curated
descriptions live in `overlay.yaml`; the consumer-facing `Lemmy.yaml` is built
from `base.json ⊕ overlay.yaml`.
