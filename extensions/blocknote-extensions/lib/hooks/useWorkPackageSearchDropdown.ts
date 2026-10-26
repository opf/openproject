import { useEffect, useMemo, useRef, useState } from 'react';
import type { KeyboardEvent, RefObject } from 'react';
import type { WorkPackage } from '../openProjectTypes';
import { subjectOf } from '../utils/subject';
import { MAX_SEARCH_RESULTS, useWorkPackageSearch } from './useWorkPackageSearch';

interface UseWorkPackageSearchDropdownOptions {
  onSelect:(wp:WorkPackage) => void;
  onEscape:() => void;
  onCreate?:(subject:string) => void;
}

interface UseWorkPackageSearchDropdownResult {
  searchQuery:string;
  setSearchQuery:(q:string) => void;
  searchResults:WorkPackage[];
  loading:boolean;
  error:string | null;
  focusedIndex:number;
  setFocusedIndex:(i:number) => void;
  isDropdownOpen:boolean;
  setIsDropdownOpen:(open:boolean) => void;
  // The index of the option offering to create a work package, -1 while it is not offered.
  createIndex:number;
  create:() => void;

  // Exposed so SearchDropdown can set it in onMouseDown before blur fires
  isSelectingRef:RefObject<boolean>;
  handleKeyDown:(e:KeyboardEvent<HTMLInputElement>) => void;
}

export function useWorkPackageSearchDropdown({
  onSelect,
  onEscape,
  onCreate,
}:UseWorkPackageSearchDropdownOptions):UseWorkPackageSearchDropdownResult {
  const { searchQuery, setSearchQuery, searchResults: allResults, loading, error } = useWorkPackageSearch();
  const searchResults = useMemo(() => allResults.slice(0, MAX_SEARCH_RESULTS), [allResults]);
  const [focusedIndex, setFocusedIndex] = useState(-1);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  const subject = subjectOf(searchQuery);
  // Held back while searching, so it cannot take the focus the results reset on arrival.
  const createIndex = onCreate && subject && !loading ? searchResults.length : -1;
  const optionCount = createIndex === -1 ? searchResults.length : createIndex + 1;

  // Creating is never preselected: Enter on a query that found nothing must not open a form.
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setFocusedIndex(searchResults.length > 0 ? 0 : -1);
  }, [searchResults]);

  // useRef instead of useState changing this flag must not trigger a re-render,
  // it only needs to be readable in the onBlur timeout in SearchDropdown.
  const isSelectingRef = useRef(false);

  const create = () => {
    isSelectingRef.current = true;
    onCreate?.(subject);
  };

  const handleKeyDown = (e:KeyboardEvent<HTMLInputElement>) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        if (!isDropdownOpen) setIsDropdownOpen(true);
        setFocusedIndex((p) => Math.min(p + 1, optionCount - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setFocusedIndex((p) => Math.max(p - 1, 0));
        break;
      case 'Enter':
        if (focusedIndex >= 0 && focusedIndex === createIndex) {
          e.preventDefault();
          create();
        } else if (focusedIndex >= 0 && searchResults[focusedIndex]) {
          e.preventDefault();
          isSelectingRef.current = true;
          onSelect(searchResults[focusedIndex]);
        }
        break;
      case 'Escape':
        onEscape();
        break;
    }
  };

  return {
    searchQuery,
    setSearchQuery,
    searchResults,
    loading,
    error,
    focusedIndex,
    setFocusedIndex,
    isDropdownOpen,
    setIsDropdownOpen,
    createIndex,
    create,
    isSelectingRef,
    handleKeyDown,
  };
}
