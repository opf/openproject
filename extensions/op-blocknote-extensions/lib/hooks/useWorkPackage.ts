import { useEffect, useState, useCallback } from 'react';
import type { WorkPackage } from '../openProjectTypes';
import { OpenProjectApiError, fetchWorkPackage } from '../services/openProjectApi';

const workPackageCache:Record<number, WorkPackage> = {};

export function clearWorkPackageCache():void {
  for (const key in workPackageCache) {
    delete workPackageCache[key as unknown as number];
  }
}

export function useWorkPackage(wpid:number|undefined) {
  const [workPackage, setWorkPackage] = useState<WorkPackage | null>(
    () => (wpid != null ? workPackageCache[wpid] ?? null : null)
  );
  const [loading, setLoading] = useState(false);
  const [unauthorized, setUnauthorized] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getWorkPackage = useCallback(async () => {
    if (!wpid) {
      setWorkPackage(null);
      return;
    }
    if (workPackageCache[wpid]) {
      setWorkPackage(workPackageCache[wpid]);
      return;
    }
    setLoading(true);
    setError(null);
    setUnauthorized(false);
    try {
      const data = await fetchWorkPackage(wpid);
      workPackageCache[wpid] = data;
      setWorkPackage(data);
    } catch (error) {
      if (error instanceof OpenProjectApiError && error.responseStatus === 404) {
        setUnauthorized(true);
        setWorkPackage(null);
      } else {
        setError((error as Error).message);
        setWorkPackage(null);
      }
    } finally {
      setLoading(false);
    }
  }, [wpid]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void getWorkPackage();
  }, [getWorkPackage]);

  return { workPackage, loading, unauthorized, error };
}
