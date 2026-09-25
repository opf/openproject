// CLI entry point.
//   web-ifc-xeokit-metadata <input.ifc> <output.json>
//
// Drop-in replacement for the .NET-based xeokit-metadata invoked by
// modules/bim/app/services/bim/ifc_models/view_converter_service.rb.
import { writeFile } from "node:fs/promises";
import { extractMetaModel } from "./extractor.js";

const [ifcPath, jsonPath] = process.argv.slice(2);

if (!ifcPath || !jsonPath) {
  console.error("Usage: web-ifc-xeokit-metadata <input.ifc> <output.json>");
  process.exit(1);
}

try {
  const meta = await extractMetaModel(ifcPath);
  await writeFile(jsonPath, JSON.stringify(meta, null, 2));
} catch (err) {
  console.error(err instanceof Error ? err.message : String(err));
  process.exit(1);
}
