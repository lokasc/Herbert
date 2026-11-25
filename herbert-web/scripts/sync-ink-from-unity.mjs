// Copies the Unity .ink sources into ./ink (overwrites!). PhysicalExam.ink has
// web-only edits (see docs/DESIGN.md §6) — re-apply them after syncing, or pass
// a single file name to sync only that one.
import { copyFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const unity = join(root, "..", "Assets", "Ink");
const only = process.argv[2];
for (const f of ["ChartAndInterview.ink", "PhysicalExam.ink"]) {
  if (only && only !== f) continue;
  if (!existsSync(join(unity, f))) continue;
  copyFileSync(join(unity, f), join(root, "ink", f));
  console.log("synced", f);
}
