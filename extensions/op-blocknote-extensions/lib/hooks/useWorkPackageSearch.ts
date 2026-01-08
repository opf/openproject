import { useState, useEffect } from "react";
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
    const debouncedSearchQuery = setTimeout(() => {
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
      clearTimeout(debouncedSearchQuery);
    };
  }, [searchQuery, debounce]);

  return {
    searchQuery,
    setSearchQuery,
    searchResults,
    loading,
    error,
  };
}
