# Lemmy client API — OpenAPI spec (unofficial)

An OpenAPI description of Lemmy's client HTTP API: enough to generate a client
(app, web, bot) or just to read what each endpoint actually does. Unofficial —
not maintained by LemmyNet.

Lemmy has two client API surfaces, `v3` and `v4`, and they are not
interchangeable. This repo keeps a spec for each version of each.

## Layout

```
specs/
  v3/0.19.0 … 0.19.11/Lemmy.yaml   the 0.19.x API — hand-written, frozen
  v4/1.0.0-pre/
    base.json      generated upstream output, vendored as-is
    overlay.yaml   local patches and curation
    Lemmy.yaml     base + overlay — generate clients from this one
    SOURCE.md      which upstream commit base.json came from
```

The old single-file layout (one `Lemmy.yaml` at the root, a branch per version)
is gone. The pre-restructure branches are kept as `archive/0.19.*` tags, and the
root `Lemmy.yaml` is now a symlink to `specs/v3/0.19.4/Lemmy.yaml` for tools that
still expect a spec there.

## v3 and v4

`v3` (`/api/v3`) is the API that every 0.19.x server speaks, and most of the
fediverse still runs 0.19.x. It is the safe target if you want to reach the most
instances.

`v4` (`/api/v4`) is new in Lemmy 1.0. It is a rewrite, not an additive layer:
endpoints and types were renamed and reshaped, so v4 is not a superset of v3.

Lemmy 1.0 servers do still mount `/api/v3`, but only as a partial compatibility
shim — a handful of feed and auth endpoints work, while profiles, community
creation, the modlog, `federated_instances` and others are missing or broken. So
don't treat v3 as "works everywhere". If you target 1.0, use v4.

## How the specs are made

**v3 is hand-written.** It was built up by reading the API and the official
`lemmy-js-client` type exports, one release at a time, and is frozen at 0.19.11 —
the end of the 0.19 line.

**v4 is generated.** `lemmy-js-client` now emits an OpenAPI document from its
tsoa annotations. `scripts/sync-v4` runs that for a given client ref and vendors
the result as `base.json`; `scripts/build.sh` then produces the `Lemmy.yaml` that
consumers read, in two steps:

1. *normalize* — tsoa renders every integer as `number`/`double` (Rust `i32` and
   `i64` both collapse to a JS `number`). This API has no real floating-point
   fields, so they are rewritten to `integer`/`int64`. Skip this and every id and
   count generates as a `Double`.
2. *overlay* — apply `overlay.yaml` (info/branding today; curated descriptions
   belong here too).

`base.json` is never hand-edited; all v4 changes go through the overlay. The
built v4 spec is checked by generating a Swift client from it with
swift-openapi-generator, so it is known to be usable, not merely valid.

## Scripts

```
scripts/build.sh [version-dir]      build v4 Lemmy.yaml from base + overlay
scripts/validate.sh                 lint every spec
scripts/sync-v4.sh <ref> <version>  regenerate a v4 base from lemmy-js-client
scripts/drift-check.sh [ref] [ver]  fail if the vendored v4 base trails upstream
scripts/build-docs.sh [out-dir]     build the per-version redoc site
```

The v4 scripts need a local `lemmy-js-client` checkout (set `LEMMY_JS_CLIENT`,
default `../3rdparty/lemmy-js-client`) and shell out to `pnpm`, `redocly`, and
`bump-cli` through `npx`. CI lints on every push and PR, checks for upstream
drift weekly, and publishes the docs.

## Docs

Per-version reference docs (redoc): https://shadone.github.io/Lemmy-OpenAPI-Spec/

## Alternatives

- [lemmy-js-client](https://github.com/LemmyNet/lemmy-js-client) — the official
  JS/TS client and type system. The v4 base here is generated from it.
- [MV-GH/lemmy_openapi_spec](https://github.com/MV-GH/lemmy_openapi_spec) —
  another unofficial Lemmy OpenAPI spec.

See also the app list at https://join-lemmy.org/apps.

## License

BSD 2-Clause. See [LICENSE](LICENSE).
