# Lemmy OpenAPI Spec — versioning & sourcing strategy

Date: 2026-06-14
Status: Approved (design); implementation plan to follow
Repo: `Lemmy-OpenAPI-Spec`

## Problem

The handwritten `Lemmy.yaml` (OpenAPI 3.1.0, ~8k lines, 91 paths, 230 schemas)
is stuck at Lemmy `0.19.4` (June 2024). The goal was to produce specs for the
Lemmy versions released since `0.19.3`. While investigating, we found the
landscape has changed enough that "keep hand-authoring one branch per version"
is no longer the right approach.

## Key findings that drive the design

1. **The official `lemmy-js-client` now generates its own OpenAPI spec.**
   `http.ts` carries full tsoa decorators (`@Route("api/v4")`, `@Get`/`@Post`,
   `@Tags`, `@Security`, `@Body`, `@Queries`), and `pnpm tsoa` runs
   `tsoa spec-and-routes && redocly build-docs tsoa_build/swagger.json`, emitting
   a complete OpenAPI 3 document. The schemas come from `src/types/*.ts`, which
   are mechanically exported from the Rust server via ts-rs
   (`copy_generated_types_from_lemmy.sh`).

2. **That generation is new and v4-only.** It was introduced in client PR #458
   (`tsoa.json` + decorators). The `0.19.4` tag has **zero** tsoa decorators and
   no `tsoa.json`. Upstream does **not commit** the generated spec — `pnpm tsoa`
   produces it on demand, so we would generate-and-vendor it ourselves per tag.

3. **v3 and v4 are two distinct APIs — v4 is a rewrite, not an additive layer.**
   - `0.19.x` servers mount **only `/api/v3`** (client `VERSION = "v3"`). This is
     the real, full API for the majority of today's fediverse.
   - `1.0` servers mount `/api/v4` (the real 1.0 API — a **rewrite** with renamed
     and reshaped endpoints/types) **plus a thin, incomplete `/api/v3` compat
     shim**. The `routes_v3` crate re-exposes only a subset of v3: core feed/auth
     actions — `get_site`; post get·list·like·save·report·delete·update; comment
     list·like·save·report·delete·update; community get·list·follow·block;
     user logout·unread_count·block; login. Profile reads (`/user`), community
     create/edit, `/modlog`, `/federated_instances`, honored search params, and
     much else are **absent or broken** on 1.0's v3. v4 was introduced during the
     1.0 cycle (server PR #6031).
   - Therefore a client **cannot** treat v3 as a universal baseline. To support
     1.0 instances properly it must speak **v4**; v3 remains the API for 0.19.x
     instances. "Support both" means implementing two real surfaces — not using
     v3 everywhere with v4 as a bonus.

4. **The v3 delta since 0.19.4 is small and additive.** e.g. `0.19.4 → 0.19.6`
   is ~10 files / 43 lines (ImageDetails, RegistrationApplication, Search,
   GetPosts params). Filling in the rest of the v3 line is modest, mechanical
   work.

5. **State of the world (as of 2026-06):** vendored Lemmy server is
   `1.0.0-alpha.18`; `lemmy-js-client` has stable tags through `v1.0.16`
   (`v1.0.17-beta6` in flight). 1.0 is **not released** for general use — only a
   few test instances run it; the fediverse is overwhelmingly on 0.19.x.

## Decisions

- **Purpose of this repo going forward:** (1) a historical, per-version record
  of the Lemmy client API, and (2) the codegen source for LemmyKit — owned by us
  so we can patch it independently of upstream. Curated reference docs are no
  longer a separate hand-authored deliverable; they ride along as spec
  `description:` fields (see "Docs flow").
- **v3 scope:** extend the handwritten spec from `0.19.4` to `0.19.11` by
  type-diffing the official client, then freeze the v3 line.
- **LemmyKit target:** support **both** surfaces as distinct APIs — v3 for
  0.19.x instances, v4 for 1.0 instances — routed at runtime by `GetSite`
  version. (Not "v3 everywhere + v4 extras": 1.0's v3 compat shim is partial.)
- **Archive key:** API-surface-first (`v3/`, `v4/`), server version beneath.
- **First v4 base:** pin to `lemmy-js-client` tag `v1.0.16`, folder labelled
  `1.0.0` (the contract is stable across the 1.0.x patch line).

## Non-goals

- Reworking LemmyKit's client architecture. Adding the v4 surface to LemmyKit
  (required to support 1.0 instances, since 1.0's v3 shim is partial) is real
  work, but it is a LemmyKit concern tracked separately from this repo.
- Building a generator that synthesizes v3 OpenAPI from `http.ts` + types. The
  0.19.x line is closed; hand-extending to 0.19.11 then freezing is cheaper.
- $ref-splitting the monolithic file as a primary goal. Under the mirror model we
  stop hand-editing large files (the v4 base is never hand-edited; only the small
  overlay is), so splitting becomes optional rather than necessary.

## Design

### Repo model — directory-per-version, single branch

Retire branch-per-version + merge-forward. Preserve the existing
`0.19.0`/`0.19.2`/`0.19.3`/`0.19.4` branches as `archive/*` tags for history,
then do all work on `main`. "What changed between version X and Y" becomes a
plain `diff` of two files instead of a branch checkout.

```
specs/
  v3/                         # universal baseline — handwritten lineage
    0.19.0/Lemmy.yaml         #   migrated from existing branches
    0.19.2/Lemmy.yaml
    0.19.3/Lemmy.yaml
    0.19.4/Lemmy.yaml
    0.19.6/Lemmy.yaml         # NEW: type-diffed from js-client tag 0.19.6
    0.19.9/Lemmy.yaml         # NEW: js-client tag 0.19.9
    0.19.11/Lemmy.yaml        # NEW: js-client tag 0.19.11-beta.0; then v3 frozen
  v4/                         # 1.0+ feature layer — vendored from upstream
    1.0.0/
      base.yaml               #   generated via `pnpm tsoa` @ js-client v1.0.16 — pristine, never hand-edited
      overlay.yaml            #   OUR patches + curated descriptions (OpenAPI Overlay 1.0)
      Lemmy.yaml              #   built = base ⊕ overlay — consumed by LemmyKit/redoc
```

(Exact top-level directory name — `specs/` vs keeping files at repo root — to be
finalized in the implementation plan; the structure above is the intent.)

### Two eras, two base sources

- **v3 (handwritten):** the only OpenAPI that will ever exist for this surface.
  Extend `0.19.4 → 0.19.11` by diffing `src/types/*.ts` and `src/http.ts`
  between the closest clean js-client tags (`0.19.6`, `0.19.9`,
  `0.19.11-beta.0`) and hand-applying the deltas. Then freeze — the 0.19.x line
  is closed. v3@0.19.11 is the canonical *full* v3; do **not** treat 1.0's
  partial v3 compat shim as equivalent.

- **v4 (vendored):** `base.yaml` is generated from the official client and
  vendored verbatim. `pnpm tsoa` reads only `http.ts` + `src/types/` already in
  the client checkout (it does **not** need the Rust repo — only
  `copy_generated_types_from_lemmy.sh` does). Pipeline:
  1. `git -C lemmy-js-client checkout <tag>` (e.g. `v1.0.16`)
  2. `pnpm install && pnpm tsoa` → `tsoa_build/swagger.json`
  3. Vendor as `base.yaml` (convert JSON→YAML for consistency; redocly can do
     this).

### Patches via OpenAPI Overlay (v4 only)

Keep `base.yaml` pristine so re-syncing a newer upstream tag never clobbers our
work. `overlay.yaml` (OpenAPI Overlay 1.0) holds our actions: fixing awkward
shapes for clean Swift codegen, correcting bugs, and adding curated
descriptions. The build step applies the overlay to produce `Lemmy.yaml`, which
is what consumers read. Re-sync flow: regenerate `base.yaml` from the new tag,
re-apply the overlay, review the resulting `Lemmy.yaml` diff.

Tooling: OpenAPI Overlay is a standard; candidate implementations include
Redocly CLI (already in this repo's toolchain), `speakeasy openapi overlay`, or
`openapi-overlays`. Exact tool/command chosen in the implementation plan. v3
needs no overlay — it is hand-authored directly.

### Docs flow — one source, three outputs

Curated descriptions live in the spec (`description:` fields): in the overlay for
v4, inline for v3. From there:
- **LemmyKit:** swift-openapi-generator emits `description:` as Swift doc
  comments — LemmyKit becomes the in-IDE docs home for free.
- **Reference HTML:** redoc renders the same descriptions.
- **Upstream:** the identical text is what we would submit upstream as PRs (or as
  ts-rs doc comments), so curation is no longer throwaway.

### LemmyKit consumption (downstream; informs but is not built here)

LemmyKit generates from `v3/<latest>/Lemmy.yaml` (universal) and, additively,
`v4/<latest>/Lemmy.yaml` (1.0 features). At runtime it inspects `GetSite`
version/build to decide whether the v4 surface is available on a given instance.
This repo's responsibility ends at publishing both lines; the dual-surface client
design is a LemmyKit concern tracked separately.

### Tooling & CI

- `scripts/sync-v4 <js-client-tag>` — regenerate `base.yaml` from the client.
- `scripts/build` — apply overlays → built `Lemmy.yaml` for every version.
- `scripts/validate` — redocly lint across all specs (existing `validate.sh`
  generalized).
- `scripts/drift-check` — diff each spec against the generated ts-rs types so the
  spec cannot silently rot again; run in CI.
- redoc/GitHub Pages workflow generalized to build per-version (or latest-of-each
  surface) docs.

### Cleanup

- Untrack the stale committed `redoc-static.html` (already in `.gitignore`; a
  2.8 MB Feb-2024 build tracked by mistake).
- Tag old version branches as `archive/0.19.x` before consolidating onto `main`.

## Risks / open questions

- **tsoa output quality.** The generated v4 base may produce awkward Swift in
  LemmyKit (naming, optionality, additionalProperties). Mitigated by the
  overlay, but the size of the overlay is unknown until we generate the first
  base and run it through swift-openapi-generator. Validation step: generate
  `v4/1.0.0/base.yaml` and do a trial LemmyKit codegen before committing to the
  approach at scale.
- **1.0's v3 compat shim is partial** (profile/community-create/modlog/
  federated_instances/search-params absent or broken). Not a problem for the
  archive — we spec full v3 at 0.19.11 and the real v4 separately — but LemmyKit
  must not assume a v3 call works against a 1.0 instance; it must route to v4
  there. Tracked as a LemmyKit concern.
- **Overlay tooling maturity.** Confirm the chosen overlay tool round-trips
  3.1.0 cleanly and is reproducible in CI.
- **js-client v3 tag fidelity.** The client did not tag every server point
  release; `0.19.6`/`0.19.9`/`0.19.11-beta.0` are the closest available anchors
  for the 0.19.5–0.19.11 fill-in. Document which server versions each maps to.

## High-level implementation phases (detailed plan to follow)

1. Repo restructure: archive old branches as tags; move existing `0.19.x` specs
   into `specs/v3/<ver>/Lemmy.yaml`; untrack `redoc-static.html`.
2. Extend v3: type-diff `0.19.4 → 0.19.6 → 0.19.9 → 0.19.11`; add the three new
   snapshots; freeze v3.
3. Stand up v4: generate `v4/1.0.0/base.yaml` from js-client `v1.0.16`; trial
   LemmyKit codegen; author initial `overlay.yaml`; build `Lemmy.yaml`.
4. Tooling: `sync-v4`, `build`, `validate`, `drift-check`; generalize redoc CI.
5. Docs: migrate curated descriptions into the overlay; verify Swift doc-comment
   output.
