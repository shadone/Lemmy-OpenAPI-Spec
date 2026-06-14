# Lemmy client API — OpenAPI spec (unofficial)

An OpenAPI description of Lemmy's client HTTP API: enough to generate a client
(app, web, bot) or just to read what each endpoint actually does. Unofficial —
not maintained by LemmyNet.

Lemmy has two client API surfaces, `v3` and `v4`, and they are not
interchangeable. This repo keeps a spec for each version of each.

## Layout

```
specs/
  v3/0.19.*/openapi.yaml the 0.19.x API — hand-written, frozen
  v4/*/
    base.json      generated upstream output, vendored as-is
    overlay.yaml   local patches and curation
    openapi.yaml   base + overlay — generate clients from this one
    SOURCE.md      which upstream commit base.json came from
```

## How the specs are made

**v3 is hand-written.** It was built up by reading the API and the official
`lemmy-js-client` type exports, one release at a time.

**v4 is generated.** `lemmy-js-client` now emits an OpenAPI document from its
tsoa annotations. `scripts/sync-v4` runs that for a given client ref and vendors
the result as `base.json`; `scripts/build.sh` then produces the `openapi.yaml`
that consumers read, in two steps:

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

Build, validation, and sync helpers live in [`scripts/`](scripts/README.md).

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
