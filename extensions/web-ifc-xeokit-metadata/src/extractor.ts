import * as WebIFC from "web-ifc";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import type { MetaModel, MetaObject } from "./types.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

// web-ifc ships its .wasm files alongside its compiled JS. Point the runtime
// at that directory; the trailing "/" is load-bearing, the loader concatenates
// `prefix + filename` without inserting a separator.
const WASM_DIR = resolve(__dirname, "../node_modules/web-ifc") + "/";

interface Handle { value: number; type: number }
interface Argument<T> { value: T; type: number; name?: string }

export async function extractMetaModel(ifcPath: string): Promise<MetaModel> {
  const api = new WebIFC.IfcAPI();
  api.SetWasmPath(WASM_DIR, true);
  await api.Init();

  const buf = await readFile(ifcPath);
  const modelID = api.OpenModel(new Uint8Array(buf));
  try {
    return buildMetaModel(api, modelID);
  } finally {
    api.CloseModel(modelID);
  }
}

function buildMetaModel(api: WebIFC.IfcAPI, modelID: number): MetaModel {
  // --- Header ---
  // ISO 10303-21 FILE_NAME arguments:
  //   (name, timestamp, [authors], [organizations], preprocessor, originating_system, authorization)
  const fileName = api.GetHeaderLine(modelID, WebIFC.FILE_NAME);
  const fileSchema = api.GetHeaderLine(modelID, WebIFC.FILE_SCHEMA);

  const headerTimestamp = strArg(fileName.arguments[1]);
  const headerAuthors = listArg(fileName.arguments[2]);
  const creatingApp = strArg(fileName.arguments[5]);
  const schema = strArg(fileSchema.arguments[0]?.[0]);

  // --- IfcProject ---
  const projectIDs = api.GetLineIDsWithType(modelID, WebIFC.IFCPROJECT);
  if (projectIDs.size() === 0) {
    throw new Error("No IfcProject found in model");
  }
  const projectExpressID = projectIDs.get(0);
  const project = api.GetLine(modelID, projectExpressID);
  const projectGuid = strArg(project.GlobalId);
  const projectName = strArg(project.Name);

  // --- Relationship maps ---
  const aggregateChildren = buildRelationMap(
    api, modelID, WebIFC.IFCRELAGGREGATES, "RelatingObject", "RelatedObjects",
  );
  const containedChildren = buildRelationMap(
    api, modelID, WebIFC.IFCRELCONTAINEDINSPATIALSTRUCTURE, "RelatingStructure", "RelatedElements",
  );

  const spatialIDs = new Set<number>();
  for (const id of iterateVector(
    api.GetLineIDsWithType(modelID, WebIFC.IFCSPATIALSTRUCTUREELEMENT, true),
  )) {
    spatialIDs.add(id);
  }

  // --- Hierarchy walk (matches MetaModel.cs:158 / extractHierarchy) ---
  const out: MetaObject[] = [];
  extractHierarchy(api, modelID, projectExpressID, null, {
    aggregateChildren,
    containedChildren,
    spatialIDs,
    out,
  });

  return {
    id: projectName,
    projectId: projectGuid,
    author: headerAuthors.join(";"),
    createdAt: headerTimestamp,
    schema,
    creatingApplication: creatingApp,
    metaObjects: out,
  };
}

interface WalkCtx {
  aggregateChildren: Map<number, number[]>;
  containedChildren: Map<number, number[]>;
  spatialIDs: Set<number>;
  out: MetaObject[];
}

function extractHierarchy(
  api: WebIFC.IfcAPI,
  modelID: number,
  expressID: number,
  parentGuid: string | null,
  ctx: WalkCtx,
): void {
  const entity = api.GetLine(modelID, expressID);
  const guid = strArg(entity.GlobalId);
  const typeName = api.GetNameFromTypeCode(entity.type);

  ctx.out.push({
    id: guid,
    name: strArg(entity.Name),
    type: typeName,
    parent: parentGuid,
  });

  // Spatial elements walk their directly-contained elements first
  // (one level; further nesting is followed via aggregations, mirroring the
  // original .NET algorithm). See MetaModel.cs:174 ff.
  if (ctx.spatialIDs.has(expressID)) {
    const contained = ctx.containedChildren.get(expressID) ?? [];
    for (const childID of contained) {
      const child = api.GetLine(modelID, childID);
      const childGuid = strArg(child.GlobalId);
      ctx.out.push({
        id: childGuid,
        name: strArg(child.Name),
        type: api.GetNameFromTypeCode(child.type),
        parent: guid,
      });
      extractRelatedObjects(api, modelID, childID, childGuid, ctx);
    }
  }

  extractRelatedObjects(api, modelID, expressID, guid, ctx);
}

function extractRelatedObjects(
  api: WebIFC.IfcAPI,
  modelID: number,
  expressID: number,
  parentGuid: string,
  ctx: WalkCtx,
): void {
  const children = ctx.aggregateChildren.get(expressID) ?? [];
  for (const childID of children) {
    extractHierarchy(api, modelID, childID, parentGuid, ctx);
  }
}

function buildRelationMap(
  api: WebIFC.IfcAPI,
  modelID: number,
  relType: number,
  relatingProp: string,
  relatedProp: string,
): Map<number, number[]> {
  const map = new Map<number, number[]>();
  for (const relID of iterateVector(api.GetLineIDsWithType(modelID, relType))) {
    const rel = api.GetLine(modelID, relID);
    const relating: Handle | undefined = rel[relatingProp];
    const related: Handle[] | undefined = rel[relatedProp];
    if (!relating || !related) continue;
    const parentID = relating.value;
    const bucket = map.get(parentID) ?? [];
    for (const h of related) bucket.push(h.value);
    map.set(parentID, bucket);
  }
  return map;
}

function strArg(arg: Argument<string> | null | undefined): string {
  if (!arg) return "";
  return arg.value ?? "";
}

function listArg(arg: Argument<string>[] | null | undefined): string[] {
  if (!arg || !Array.isArray(arg)) return [];
  return arg.map((a) => a?.value ?? "");
}

interface IterableVector<T> { size(): number; get(i: number): T }

function* iterateVector<T>(v: IterableVector<T>): Generator<T> {
  const n = v.size();
  for (let i = 0; i < n; i++) yield v.get(i);
}
