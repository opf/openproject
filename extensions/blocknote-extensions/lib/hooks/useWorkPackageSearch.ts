import { useState, useEffect, useCallback, useRef } from 'react';
import type { WorkPackage } from '../openProjectTypes';
import { searchWorkPackages } from '../services/openProjectApi';
import { useDebouncedSearch } from './useDebouncedSearch';

export const MAX_SEARCH_RESULTS = 5;

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

  const { search: debouncedSearch, cancel: cancelSearch } = useDebouncedSearch(searchWorkPackages, { debounce });

  // Imperative search (used by BlockNote getItems — must return results immediately)
  const latestCallRef = useRef(0);

  const search = useCallback(async (query:string):Promise<WorkPackage[]> => {
    latestCallRef.current += 1;
    const call = latestCallRef.current;
    try {
      const results = await debouncedSearch(query);
      if (call === latestCallRef.current) setSearchResults(results);
      return results;
    } catch (error) {
      if (call === latestCallRef.current) setSearchResults([]);
      throw error;
    }
  }, [debouncedSearch]);

  return {
    searchQuery,
    setSearchQuery,
    searchResults,
    loading,
    error,
    search,
    cancelSearch,
  };
}
