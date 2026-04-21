import { useState, useEffect, useCallback, useRef } from "react";
import type { WorkPackage } from "../openProjectTypes";
import { searchWorkPackages } from "../services/openProjectApi";

interface UseWorkPackageSearchOptions {
  debounce?: number;
}

export function useWorkPackageSearch(
  options: UseWorkPackageSearchOptions = {}
) {
  const { debounce = 300 } = options;

  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<WorkPackage[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Used to cancel debounce in imperative search()
  const debounceTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Reactive search (used by SearchDropdown)
  useEffect(() => {
    let active = true;

    if (!searchQuery) {
      setSearchResults([]);
      setLoading(false);
      setError(null);
      return;
    }

    setLoading(true);
    setError(null);
    const timer = setTimeout(() => {
      searchWorkPackages(searchQuery)
        .then((results) => {
          if (active) {
            setSearchResults(results);
          }
        })
        .catch((err) => {
          if (active) {
            setError(err.message || "Unknown error");
            setSearchResults([]);
          }
        })
        .finally(() => {
          if (active) {
            setLoading(false);
          }
        });
    }, debounce);

    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [searchQuery, debounce]);

  // Imperative search (used by BlockNote getItems — must return results immediately)
  const search = useCallback(
    (query: string): Promise<WorkPackage[]> => {
      if (!query.trim()) {
        setSearchResults([]);
        return Promise.resolve([]);
      }

      if (debounceTimerRef.current !== null) {
        clearTimeout(debounceTimerRef.current);
      }

      return new Promise<WorkPackage[]>((resolve) => {
        debounceTimerRef.current = setTimeout(async () => {
          debounceTimerRef.current = null;
          try {
            const results = await searchWorkPackages(query);
            setSearchResults(results);
            resolve(results);
          } catch {
            setSearchResults([]);
            resolve([]);
          }
        }, debounce);
      });
    },
    [debounce]
  );

  return {
    searchQuery,
    setSearchQuery,
    searchResults,
    loading,
    error,
    search,
  };
}
