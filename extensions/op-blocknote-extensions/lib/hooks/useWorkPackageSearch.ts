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
          setSearchResults(results);
        })
        .catch((err) => {
          setError(err.message || "Unknown error");
          setSearchResults([]);
        })
        .finally(() => {
          setLoading(false);
        });
    }, debounce);

    return () => clearTimeout(timer);
  }, [searchQuery, debounce]);

  return {
    searchQuery,
    setSearchQuery,
    searchResults,
    loading,
    error,
  };
}
