// Compiles ink/*.ink -> public/ink/*.json using inkjs' bundled compiler.
// Run automatically via `predev` / `prebuild`. Fails loudly on ink errors.
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from "node:fs";
import { join, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { Compiler, CompilerOptions } from "inkjs/compiler/Compiler";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const srcDir = join(root, "ink");
const outDir = join(root, "public", "ink");
mkdirSync(outDir, { recursive: true });

let failed = false;
for (const file of readdirSync(srcDir).filter((f) => f.endsWith(".ink"))) {
  const text = readFileSync(join(srcDir, file), "utf8");
  const errors = [];
  const warnings = [];
  const options = new CompilerOptions(
    null,
    [],
    // countAllVisits lets the web app ask "was this knot visited?" for any knot.
    true,
    (message, type) => (type === 2 ? errors : warnings).push(message),
  );
  let json = null;
  try {
    json = new Compiler(text, options).Compile().ToJson();
  } catch (e) {
    errors.push(String(e));
  }
  warnings.forEach((w) => console.warn(`[ink] ${file}: ${w}`));
  if (!json || errors.length) {
    errors.forEach((e) => console.error(`[ink] ${file}: ${e}`));
    failed = true;
    continue;
  }
  writeFileSync(join(outDir, basename(file, ".ink") + ".json"), json);
  console.log(`[ink] compiled ${file} (${warnings.length} warnings)`);
}
if (failed) process.exit(1);
