import { useEffect, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { SearchIcon } from '@primer/octicons-react';
import styled from 'styled-components';
import type { WorkPackage } from '../../openProjectTypes';
import { useWorkPackageSearchDropdown } from '../../hooks/useWorkPackageSearchDropdown';
import {
  SearchIconWrapper,
  SearchInput,
  SearchMessage,
  DropdownList,
  DropdownItem,
} from './SearchContainer';
import { Spinner } from '../Spinner';

const MAX_RESULTS = 5;

interface SearchDropdownProps {
  onSelect:(wp:WorkPackage) => void;
  onCancel?:() => void;
  autoFocus?:boolean;
  renderItem:(wp:WorkPackage) => React.ReactNode;
}

const SearchInputWrapper = styled.div`
  display: flex;
  align-items: center;
  gap: var(--spacer-s);
  border: 1px solid var(--bn-colors-border, #ccc);
  border-radius: var(--bn-border-radius-small);
  background: var(--bn-colors-menu-background, #fff);
  padding: 0 var(--spacer-m);
`;

const SearchInputWithIcon = styled(SearchInput)`
  border: none;
  padding-left: 0;
  padding-right: 0;
  background: transparent;
  flex: 1;
  min-width: 0;

  &:focus {
    outline: none;
  }
  &::-webkit-search-cancel-button,
  &::-webkit-search-decoration {
    -webkit-appearance: none;
    appearance: none;
  }
`;

export const SearchDropdown = ({ onSelect, onCancel, autoFocus, renderItem }:SearchDropdownProps) => {
  const { t } = useTranslation();
  const inputRef = useRef<HTMLInputElement>(null);
  const blurTimerRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  useEffect(() => {
    if (!autoFocus) return;
    const frame = requestAnimationFrame(() => {
      inputRef.current?.focus();
    });
    return () => cancelAnimationFrame(frame);
  }, [autoFocus]);

  useEffect(() => {
    return () => clearTimeout(blurTimerRef.current);
  }, []);

  const {
    searchQuery,
    setSearchQuery,
    searchResults,
    loading,
    error,
    focusedIndex,
    setFocusedIndex,
    isDropdownOpen,
    setIsDropdownOpen,
    isSelectingRef,
    handleKeyDown,
  } = useWorkPackageSearchDropdown({
    onSelect,
    onEscape: onCancel ?? (() => undefined),
  });

  return (
    <>
      <SearchInputWrapper>
        <SearchIconWrapper>
          <SearchIcon size={16} />
        </SearchIconWrapper>

        <SearchInputWithIcon
          ref={inputRef}
          type="search"
          autoComplete="off"
          spellCheck={false}
          placeholder={t('search.placeholder')}
          value={searchQuery}
          onChange={(e) => {
            setSearchQuery(e.target.value);
            setIsDropdownOpen(e.target.value.length > 0);
          }}
          onKeyDown={(e) => {
            e.stopPropagation();
            handleKeyDown(e);
          }}
          onBlur={() => {
            // Delay to allow onMouseDown on dropdown items to fire before blur.
            // Without this, clicking a result closes the dropdown before onSelect is called.
            blurTimerRef.current = setTimeout(() => {
              if (isSelectingRef.current) {
                isSelectingRef.current = false;
                return;
              }
              onCancel?.();
            }, 150);
          }}
        />

        {loading && (
          <SearchIconWrapper>
            <Spinner />
          </SearchIconWrapper>
        )}
      </SearchInputWrapper>

      {isDropdownOpen && !loading && searchResults.length === 0 && (
        <SearchMessage>{error ? t('search.error') : t('search.noResults')}</SearchMessage>
      )}

      {isDropdownOpen && searchResults.length > 0 && (
        <DropdownList role="listbox" aria-label={t('search.dropdownAriaLabel')}>
          {searchResults.slice(0, MAX_RESULTS).map((wp, index) => (
            <DropdownItem
              role="option" 
              aria-selected={focusedIndex === index}
              key={wp.id}
              $selected={focusedIndex === index}
              onMouseDown={(e) => {
                e.preventDefault();
                isSelectingRef.current = true;
                onSelect(wp);
              }}
              onMouseEnter={() => setFocusedIndex(index)}
            >
              {renderItem(wp)}
            </DropdownItem>
          ))}
        </DropdownList>
      )}
    </>
  );
};