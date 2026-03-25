import { useEffect, useRef } from "react";
import { useTranslation } from "react-i18next";
import type { WorkPackage } from "../openProjectTypes";
import { useWorkPackageSearchDropdown } from "../hooks/useWorkPackageSearchDropdown";
import {
  SearchInput,
  DropdownList,
  DropdownItem,
  SearchIconWrapper,
} from "./InlineWorkPackage/InlineWorkPackageShared";
import { SearchIcon } from "@primer/octicons-react";
import { WorkPackageElement } from "../elements/workPackageElement";

const MAX_RESULTS = 5;

interface SearchDropdownProps {
  onSelect: (wp: WorkPackage) => void;
  onCancel?: () => void;
  autoFocus?: boolean;
}

export const SearchDropdown = ({ onSelect, onCancel, autoFocus }: SearchDropdownProps) => {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!autoFocus) return;
    const frame = requestAnimationFrame(() => {
      inputRef.current?.focus();
    });
    return () => cancelAnimationFrame(frame);
  }, [autoFocus]);

  const {
    searchQuery,
    setSearchQuery,
    searchResults,
    focusedIndex,
    setFocusedIndex,
    isDropdownOpen,
    setIsDropdownOpen,
    isSelectingRef,
    handleKeyDown,
  } = useWorkPackageSearchDropdown({
    onSelect,
    onEscape: onCancel ?? (() => {}),
  });

  return (
    <>
      <div style={{ position: "relative" }}>
        <SearchIconWrapper>
          <SearchIcon size={16} />
        </SearchIconWrapper>

        <SearchInput
          ref={inputRef}
          type="text"
          placeholder={t("search.placeholder")}
          value={searchQuery}
          onChange={(e) => {
            setSearchQuery(e.target.value);
            setIsDropdownOpen(e.target.value.length > 0);
          }}
          onKeyDown={handleKeyDown}
          style={{ paddingLeft: "28px" }}
          onBlur={() => {
            // Delay to allow onMouseDown on dropdown items to fire before blur.
            // Without this, clicking a result closes the dropdown before onSelect is called.
            setTimeout(() => {
              if (isSelectingRef.current) {
                isSelectingRef.current = false;
                return;
              }
              onCancel?.();
            }, 150);
          }}
        />
      </div>

      {isDropdownOpen && searchResults.length > 0 && (
        <DropdownList>
          {searchResults.slice(0, MAX_RESULTS).map((wp, index) => (
            <DropdownItem
              key={wp.id}
              $selected={focusedIndex === index}
              onMouseDown={(e) => {
                e.preventDefault();
                isSelectingRef.current = true;
                onSelect(wp);
              }}
              onMouseEnter={() => setFocusedIndex(index)}
            >
              <WorkPackageElement workPackage={wp} inDropdown />
            </DropdownItem>
          ))}
        </DropdownList>
      )}
    </>
  );
};