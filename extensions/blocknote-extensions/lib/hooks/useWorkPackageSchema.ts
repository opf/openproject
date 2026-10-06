import { useEffect, useState } from 'react';
import type { WorkPackageSchema } from '../openProjectTypes';
import { fetchWorkPackageSchema } from '../services/openProjectApi';

// Keyed by href: every work package of the same project and type shares one schema.
const schemaCache = new Map<string, Promise<WorkPackageSchema>>();

export function clearWorkPackageSchemaCache():void {
  schemaCache.clear();
}

export function loadWorkPackageSchema(href:string):Promise<WorkPackageSchema> {
  let pending = schemaCache.get(href);
  if (!pending) {
    pending = fetchWorkPackageSchema(href);
    pending.catch(() => schemaCache.delete(href));
    schemaCache.set(href, pending);
  }
  return pending;
}

interface LoadedSchema {
  href:string;
  attempt:number;
  schema:WorkPackageSchema | null;
}

export function useWorkPackageSchema(href:string | undefined) {
  const [loaded, setLoaded] = useState<LoadedSchema | null>(null);
  // A failed request leaves the cache, so another attempt asks the server again.
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    if (!href) return;
    let current = true;
    loadWorkPackageSchema(href).then(
      (schema) => { if (current) setLoaded({ href, attempt, schema }); },
      () => { if (current) setLoaded({ href, attempt, schema: null }); },
    );
    return () => { current = false; };
  }, [href, attempt]);

  const settled = !!href && loaded?.href === href && loaded.attempt === attempt;
  return {
    schema: settled ? loaded.schema : null,
    loading: !!href && !settled,
    error: settled && !loaded.schema,
    retry: () => setAttempt((count) => count + 1),
  };
}
