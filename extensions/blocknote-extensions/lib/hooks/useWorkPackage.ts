import { useEffect, useState } from 'react';
import type { WorkPackage } from '../openProjectTypes';
import { OpenProjectApiError } from '../services/openProjectApi';
import { cachedWorkPackage, loadWorkPackage } from '../services/workPackageLoader';

export function useWorkPackage(wpid:number|undefined) {
  const [workPackage, setWorkPackage] = useState<WorkPackage | null>(
    () => (wpid != null ? cachedWorkPackage(wpid) ?? null : null)
  );
  const [loading, setLoading] = useState(false);
  const [unauthorized, setUnauthorized] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setError(null);
    setUnauthorized(false);

    const cached = wpid ? cachedWorkPackage(wpid) : undefined;
    if (!wpid || cached) {
      setWorkPackage(cached ?? null);
      setLoading(false);
      return;
    }

    let superseded = false;
    setLoading(true);

    loadWorkPackage(wpid)
      .then((data) => {
        if (!superseded) setWorkPackage(data);
      })
      .catch((error:unknown) => {
        if (superseded) return;
        if (error instanceof OpenProjectApiError && error.responseStatus === 404) {
          setUnauthorized(true);
        } else {
          setError((error as Error).message);
        }
        setWorkPackage(null);
      })
      .finally(() => {
        if (!superseded) setLoading(false);
      });

    return () => { superseded = true; };
  }, [wpid]);

  return { workPackage, loading, unauthorized, error };
}
