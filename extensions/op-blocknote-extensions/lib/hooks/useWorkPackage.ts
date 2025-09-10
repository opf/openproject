import { useEffect, useState, useCallback } from "react";
import type { WorkPackage } from "../openProjectTypes";

export function useWorkPackage(wpid: string | null) {
  const [workPackage, setWorkPackage] = useState<WorkPackage | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchWorkPackage = useCallback(async () => {
    if (!wpid) {
      setWorkPackage(null);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`api/v3/work_packages/${wpid}`, {
        method: "GET",
        headers: { "Content-Type": "application/json" },
      });
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setWorkPackage(data as WorkPackage);
    } catch (err) {
      setError((err as Error).message);
      setWorkPackage(null);
    } finally {
      setLoading(false);
    }
  }, [wpid]);

  useEffect(() => {
    fetchWorkPackage();
  }, [fetchWorkPackage]);

  return { workPackage, loading, error };
}
