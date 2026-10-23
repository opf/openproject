import type { WorkPackage } from '../openProjectTypes';
import { fetchWorkPackage, fetchWorkPackages, OpenProjectApiError } from './openProjectApi';

interface Batch {
  ids:Set<number>;
  loaded:Promise<Map<number, WorkPackage>>;
}

const cache = new Map<number, WorkPackage>();
const inFlight = new Map<number, Promise<WorkPackage>>();
let nextBatch:Batch | null = null;

export function cachedWorkPackage(id:number):WorkPackage | undefined {
  return cache.get(id);
}

export function clearWorkPackageCache():void {
  cache.clear();
  inFlight.clear();
}

function joinNextBatch(id:number):Promise<Map<number, WorkPackage>> {
  if (!nextBatch) {
    const ids = new Set<number>();
    // Waits for the other node views of the document to ask for theirs.
    const loaded = new Promise((resolve) => { setTimeout(resolve, 0); })
      .then(() => {
        nextBatch = null;
        return fetchWorkPackages([...ids]);
      })
      .then((workPackages) => new Map(workPackages.map((workPackage) => [workPackage.id, workPackage])));
    nextBatch = { ids, loaded };
  }

  nextBatch.ids.add(id);
  return nextBatch.loaded;
}

export function loadWorkPackage(id:number):Promise<WorkPackage> {
  const cached = cache.get(id);
  if (cached) return Promise.resolve(cached);

  const pending = inFlight.get(id);
  if (pending) return pending;

  const load = joinNextBatch(id).then(
    (workPackages) => {
      const workPackage = workPackages.get(id);
      // The single resource answers 404 for both, and so do we.
      if (!workPackage) throw new OpenProjectApiError(`Work package ${id} not found or not visible`, 404);
      return workPackage;
    },
    // One broken work package fails the whole batch, so only that one may end up showing the error.
    () => fetchWorkPackage(id)
  );

  inFlight.set(id, load);
  // A load the cache was cleared under must not refill it.
  const isCurrent = () => inFlight.get(id) === load;
  load.then(
    (workPackage) => {
      if (!isCurrent()) return;
      cache.set(id, workPackage);
      inFlight.delete(id);
    },
    () => {
      if (isCurrent()) inFlight.delete(id);
    }
  );

  return load;
}
