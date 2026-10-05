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

export function useWorkPackageSchema(href:string | undefined) {
  const [loaded, setLoaded] = useState<{ href:string, schema:WorkPackageSchema | null } | null>(null);

  useEffect(() => {
    if (!href) return;
    let current = true;
    loadWorkPackageSchema(href).then(
      (schema) => { if (current) setLoaded({ href, schema }); },
      () => { if (current) setLoaded({ href, schema: null }); },
    );
    return () => { current = false; };
  }, [href]);

  const settled = !!href && loaded?.href === href;
  return {
    schema: settled ? loaded.schema : null,
    loading: !!href && !settled,
    error: settled && !loaded.schema,
  };
}
