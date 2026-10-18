// Parity test: every fixture is extracted through web-ifc and compared to the
// .NET reference output in test/golden/ (when one exists).
//
// IFC4X3 fixtures have no golden because the .NET tool cannot parse that
// schema. For those, we only assert shape: the output is a well-formed
// MetaModel, the parent links form a tree rooted at the project.

import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";
import { extractMetaModel } from "../src/extractor.js";
import type { MetaModel } from "../src/types.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const FIXTURES_DIR = resolve(__dirname, "fixtures");
const GOLDEN_DIR = resolve(__dirname, "golden");

let workDir: string;
beforeAll(() => { workDir = mkdtempSync(resolve(tmpdir(), "web-ifc-xeokit-")); });
afterAll(() => { rmSync(workDir, { recursive: true, force: true }); });

interface FixtureCase {
  name: string;
  schema: string;
  /** Whether a .NET golden output exists (false for IFC4X3, unsupported by .NET tool). */
  hasGolden: boolean;
}

const FIXTURES: FixtureCase[] = [
  { name: "minimal-IFC2X3",              schema: "IFC2X3",      hasGolden: true  },
  { name: "Building-Architecture-IFC4",  schema: "IFC4",        hasGolden: true  },
  { name: "Building-Architecture-IFC4X3", schema: "IFC4X3_ADD2", hasGolden: false },
  { name: "Infra-Rail-IFC4X3",           schema: "IFC4X3_ADD2", hasGolden: false },
];

describe.each(FIXTURES)("$name", ({ name, schema, hasGolden }) => {
  let meta: MetaModel;

  beforeAll(async () => {
    meta = await extractMetaModel(resolve(FIXTURES_DIR, `${name}.ifc`));
  });

  it("reports the correct schema", () => {
    expect(meta.schema).toBe(schema);
  });

  it("has a project at the root", () => {
    expect(meta.metaObjects.length).toBeGreaterThan(0);
    const root = meta.metaObjects[0];
    expect(root.type).toBe("IfcProject");
    expect(root.parent).toBeNull();
    expect(root.id).toBe(meta.projectId);
  });

  it("forms a tree (every non-root parent resolves)", () => {
    const ids = new Set(meta.metaObjects.map((m) => m.id));
    for (const m of meta.metaObjects) {
      if (m.parent === null) continue;
      expect(ids, `parent of ${m.id} (${m.type}) must exist`).toContain(m.parent);
    }
  });

  if (hasGolden) {
    it("matches .NET golden header", () => {
      const golden = loadGolden(name);
      expect({
        id: meta.id,
        projectId: meta.projectId,
        author: meta.author,
        createdAt: meta.createdAt,
        schema: meta.schema,
        creatingApplication: meta.creatingApplication,
      }).toEqual({
        id: golden.id,
        projectId: golden.projectId,
        author: golden.author,
        createdAt: golden.createdAt,
        schema: golden.schema,
        creatingApplication: golden.creatingApplication,
      });
    });

    it("matches .NET golden metaObjects (id/type/parent/name set)", () => {
      const golden = loadGolden(name);
      const ours = new Set(meta.metaObjects.map(serialise));
      const theirs = new Set(golden.metaObjects.map(serialise));
      expect([...theirs].filter((x) => !ours.has(x))).toEqual([]);
      expect([...ours].filter((x) => !theirs.has(x))).toEqual([]);
    });
  } else {
    it("(no golden — .NET tool rejects this schema)", () => {
      const goldenPath = resolve(GOLDEN_DIR, `${name}.json`);
      expect(existsSync(goldenPath)).toBe(false);
    });
  }
});

function loadGolden(name: string): MetaModel {
  return JSON.parse(readFileSync(resolve(GOLDEN_DIR, `${name}.json`), "utf8"));
}

function serialise(m: { id: string; name: string; type: string; parent: string | null }): string {
  return JSON.stringify([m.id, m.name, m.type, m.parent]);
}
