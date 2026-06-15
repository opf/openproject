import { useEffect, useState, useCallback } from "react";
import type { WorkPackage } from "../openProjectTypes";
import { OpenProjectApiError, fetchWorkPackage } from "../services/openProjectApi";

const wpCache: Record<number, WorkPackage> = {};

export function useWorkPackage(wpid: number|undefined) {
  const [workPackage, setWorkPackage] = useState<WorkPackage | null>(
    () => (wpid != null ? wpCache[wpid] ?? null : null)
  );
  const [loading, setLoading] = useState(false);
  const [unauthorized, setUnauthorized] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getWorkPackage = useCallback(async () => {
    if (!wpid) {
      setWorkPackage(null);
      return;
    }
    if (wpCache[wpid]) {
      setWorkPackage(wpCache[wpid]);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const data = await fetchWorkPackage(wpid);
      wpCache[wpid] = data as WorkPackage;
      setWorkPackage(data as WorkPackage);
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
    getWorkPackage();
  }, [getWorkPackage]);

  return { workPackage, loading, unauthorized, error };
}
