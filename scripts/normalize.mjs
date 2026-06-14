#!/usr/bin/env node
// Normalize tsoa-generated OpenAPI before overlay.
//
// Rust integer types (i32/i64) and f64 all collapse to TypeScript `number` in the
// lemmy-js-client (bigint is sed'd to number), and tsoa then emits every `number`
// as {type:"number", format:"double"}. The Lemmy client API uses NO genuine
// floating-point fields (all *Id, counts, sizes, durations, dimensions, limits
// are integers), so we deterministically rewrite number/double -> integer/int64.
//
// The conversion is logged (to stderr) per distinct key so that a future re-sync
// which introduces a real float surfaces as a new converted key for review.
//
// Usage: node scripts/normalize.mjs <openapi.json>   (normalized JSON -> stdout)
import fs from "node:fs";

const file = process.argv[2];
if (!file) {
  console.error("usage: normalize.mjs <openapi.json>");
  process.exit(1);
}

const doc = JSON.parse(fs.readFileSync(file, "utf8"));
const converted = {};

function walk(node, key) {
  if (Array.isArray(node)) {
    for (const n of node) walk(n, key);
    return;
  }
  if (!node || typeof node !== "object") return;
  if (node.type === "number" && node.format === "double") {
    node.type = "integer";
    node.format = "int64";
    converted[key] = (converted[key] || 0) + 1;
  }
  for (const [k, v] of Object.entries(node)) {
    if (v && typeof v === "object") walk(v, k);
  }
}

walk(doc.components?.schemas ?? {}, "root");
walk(doc.paths ?? {}, "root");

process.stdout.write(JSON.stringify(doc, null, 2));

const total = Object.values(converted).reduce((a, b) => a + b, 0);
const keys = Object.keys(converted).sort();
console.error(
  `normalize: number/double -> integer/int64: ${total} occurrences across ${keys.length} keys`,
);
console.error(`  keys: ${keys.join(", ")}`);
