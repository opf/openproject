import { useEffect, useState, useCallback } from "react";
import type { WorkPackage } from "../openProjectTypes";
import { fetchWorkPackage } from "../services/openProjectApi";

export function useWorkPackage(wpid: string | null) {
  const [workPackage, setWorkPackage] = useState<WorkPackage | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getWorkPackage = useCallback(async () => {
    if (!wpid) {
      setWorkPackage(null);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const data = await fetchWorkPackage(wpid);
      setWorkPackage(data as WorkPackage);
    } catch (err) {
      setError((err as Error).message);
      setWorkPackage(null);
    } finally {
      setLoading(false);
    }
  }, [wpid]);

  useEffect(() => {
    getWorkPackage();
  }, [getWorkPackage]);

  return { workPackage, loading, error };
}
