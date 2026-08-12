import { useState, useEffect, useCallback, useRef } from 'react';
import type { WorkPackage } from '../openProjectTypes';
import { searchWorkPackages } from '../services/openProjectApi';

interface UseWorkPackageSearchOptions {
  debounce?:number;
}

export function useWorkPackageSearch(
  options:UseWorkPackageSearchOptions = {}
) {
  const { debounce = 300 } = options;

  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<WorkPackage[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Used to cancel debounce in imperative search()
  const debounceTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pendingResolveRef = useRef<((results:WorkPackage[]) => void) | null>(null);

  // Reactive search (used by SearchDropdown)
  useEffect(() => {
    let active = true;

    if (!searchQuery) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
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
        .catch((error:unknown) => {
          if (active) {
            setError(error instanceof Error ? error.message : 'Unknown error');
            console.error('[work package search] Failed to load work packages from OpenProject:', error);
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
    (query:string):Promise<WorkPackage[]> => {
      // A superseded call must still settle, otherwise its caller awaits forever
      if (debounceTimerRef.current !== null) {
        clearTimeout(debounceTimerRef.current);
        debounceTimerRef.current = null;
      }
      pendingResolveRef.current?.([]);
      pendingResolveRef.current = null;

      if (!query.trim()) {
        setSearchResults([]);
        return Promise.resolve([]);
      }

      return new Promise<WorkPackage[]>((resolve, reject) => {
        pendingResolveRef.current = resolve;
        debounceTimerRef.current = setTimeout(async () => {
          debounceTimerRef.current = null;
          pendingResolveRef.current = null;
          try {
            const results = await searchWorkPackages(query);
            setSearchResults(results);
            resolve(results);
          } catch (error) {
            setSearchResults([]);
            reject(error instanceof Error ? error : new Error(String(error)));
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
