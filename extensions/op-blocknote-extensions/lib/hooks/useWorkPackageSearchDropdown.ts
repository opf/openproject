import { useRef, useState } from 'react';
import type { KeyboardEvent, RefObject } from 'react';
import type { WorkPackage } from '../openProjectTypes';
import { useWorkPackageSearch } from './useWorkPackageSearch';

interface UseWorkPackageSearchDropdownOptions {
  onSelect:(wp:WorkPackage) => void;
  onEscape:() => void;
}

interface UseWorkPackageSearchDropdownResult {
  searchQuery:string;
  setSearchQuery:(q:string) => void;
  searchResults:WorkPackage[];
  focusedIndex:number;
  setFocusedIndex:(i:number) => void;
  isDropdownOpen:boolean;
  setIsDropdownOpen:(open:boolean) => void;

  // Exposed so SearchDropdown can set it in onMouseDown before blur fires
  isSelectingRef:RefObject<boolean>;
  handleKeyDown:(e:KeyboardEvent<HTMLInputElement>) => void;
}

export function useWorkPackageSearchDropdown({
  onSelect,
  onEscape,
}:UseWorkPackageSearchDropdownOptions):UseWorkPackageSearchDropdownResult {
  const { searchQuery, setSearchQuery, searchResults } = useWorkPackageSearch();
  const [focusedIndex, setFocusedIndex] = useState(-1);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  // useRef instead of useState changing this flag must not trigger a re-render,
  // it only needs to be readable in the onBlur timeout in SearchDropdown.
  const isSelectingRef = useRef(false);

  const handleKeyDown = (e:KeyboardEvent<HTMLInputElement>) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        if (!isDropdownOpen) setIsDropdownOpen(true);
        setFocusedIndex((p) => Math.min(p + 1, searchResults.length - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setFocusedIndex((p) => Math.max(p - 1, 0));
        break;
      case 'Enter':
        if (focusedIndex >= 0 && searchResults[focusedIndex]) {
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
    focusedIndex,
    setFocusedIndex,
    isDropdownOpen,
    setIsDropdownOpen,
    isSelectingRef,
    handleKeyDown,
  };
}