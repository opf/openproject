import type { HalLink, WorkPackage, WorkPackageSchema } from '../openProjectTypes';
import { fetchWorkPackages, OpenProjectApiError, type WorkPackageBatch } from './openProjectApi';

interface LoadedBatch {
  workPackages:Map<number, WorkPackage>;
  schemas:Map<string, WorkPackageSchema>;
}

interface PendingBatch {
  ids:Set<number>;
  loaded:Promise<LoadedBatch>;
}

const cache = new Map<number, WorkPackage>();
const schemaCache = new Map<string, WorkPackageSchema>();
const inFlight = new Map<number, Promise<WorkPackage>>();
let nextBatch:PendingBatch | null = null;

export function cachedWorkPackage(id:number):WorkPackage | undefined {
  return cache.get(id);
}

export function cachedWorkPackageSchema(workPackage:WorkPackage):WorkPackageSchema | undefined {
  const href = workPackage._links?.schema?.href;
  return href ? schemaCache.get(href) : undefined;
}

export function clearWorkPackageCache():void {
  cache.clear();
  schemaCache.clear();
  inFlight.clear();
  nextBatch = null;
}

function selfHref(schema:WorkPackageSchema):string | null | undefined {
  return (schema._links as { self?:HalLink } | undefined)?.self?.href;
}

function indexBatch({ workPackages, schemas }:WorkPackageBatch):LoadedBatch {
  return {
    workPackages: new Map(workPackages.map((workPackage) => [workPackage.id, workPackage])),
    schemas: new Map(schemas.flatMap((schema) => {
      const href = selfHref(schema);
      return href ? [[href, schema] as const] : [];
    })),
  };
}

function loadBatch(ids:readonly number[]):Promise<LoadedBatch> {
  return fetchWorkPackages(ids).then(indexBatch);
}

function joinNextBatch(id:number):Promise<LoadedBatch> {
  if (!nextBatch) {
    const ids = new Set<number>();
    // Waits for the other node views of the document to ask for theirs.
    const loaded = new Promise((resolve) => { setTimeout(resolve, 0); })
      .then(() => {
        nextBatch = null;
        return loadBatch([...ids]);
      });
    nextBatch = { ids, loaded };
  }

  nextBatch.ids.add(id);
  return nextBatch.loaded;
}

function workPackageIn(batch:LoadedBatch, id:number):WorkPackage {
  const workPackage = batch.workPackages.get(id);
  // The single resource answers 404 for both, and so do we.
  if (!workPackage) throw new OpenProjectApiError(`Work package ${id} not found or not visible`, 404);

  return workPackage;
}

export function loadWorkPackage(id:number):Promise<WorkPackage> {
  const cached = cache.get(id);
  if (cached) return Promise.resolve(cached);

  const pending = inFlight.get(id);
  if (pending) return pending;

  const loaded = joinNextBatch(id)
    // One broken work package fails the whole batch, so only that one may end up showing the error.
    .catch(() => loadBatch([id]))
    .then((batch) => ({ workPackage: workPackageIn(batch, id), schemas: batch.schemas }));
  const load = loaded.then(({ workPackage }) => workPackage);

  inFlight.set(id, load);
  // A load the cache was cleared under must not refill it.
  const isCurrent = () => inFlight.get(id) === load;
  loaded.then(
    ({ workPackage, schemas }) => {
      if (!isCurrent()) return;

      cache.set(id, workPackage);
      schemas.forEach((schema, href) => schemaCache.set(href, schema));
      inFlight.delete(id);
    },
    () => {
      if (isCurrent()) inFlight.delete(id);
    }
  );

  return load;
}
