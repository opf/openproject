import type { FC, RefObject } from 'react';
import type { SuggestionMenuProps } from '@blocknote/react';
import styled from 'styled-components';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { defaultWpVariables } from '../WorkPackage/atoms';
import { SearchMessage } from '../Search/SearchContainer';
import { Spinner } from '../Spinner';
import type { HashMenuItem, HashSearchState } from './types';
import { useTranslation } from 'react-i18next';

/*
 * BlockNote's GenericPopover wrapper (data-floating-ui-focusable) is the
 * element FloatingUI applies max-height to via its `size` middleware, but
 * this `Menu` element is the painted surface (white background, shadow,
 * rounded corners). Without our own height limit and overflow constraint,
 * the result rows render outside the painted card and ghost over the
 * editor content behind — visible on iOS Safari in particular.
 *
 * The painted surface and the overflow container must be the same
 * element, so the rounded corners clip the scroll area cleanly. The
 * `min-height: 0` line is the iOS Safari flex-child-with-overflow quirk:
 * a flex item won't actually clip / scroll unless its min-height is
 * explicitly zero. (Harmless on non-flex layouts.)
 */
const Menu = styled.div.attrs({ className: 'op-bn-hash-menu' })`
  ${defaultWpVariables}
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 320px;
  max-width: 480px;
  overflow-y: auto;
  min-height: 0;
`;

const MenuItem = styled.div<{ $selected:boolean }>`
  border-radius: var(--bn-border-radius-small);
  background: ${({ $selected }) =>
    $selected ? 'var(--op-item-hover-bg)' : 'transparent'};
  cursor: pointer;
  padding: 0 var(--spacer-s);

  &:hover {
    background: var(--op-item-hover-bg);
  }
`;

const MAX_RESULTS = 5;

export function createHashWpMenuComponent(
  searchStateRef:RefObject<HashSearchState>,
):FC<SuggestionMenuProps<HashMenuItem>> {
  const HashWpMenuComponent:FC<SuggestionMenuProps<HashMenuItem>> = ({
    items,
    loadingState,
    selectedIndex,
    onItemClick,
  }) => {
    const { t } = useTranslation();
    const { query, results, error } = searchStateRef.current;
    const visibleResults = results.slice(0, MAX_RESULTS);

    if (loadingState !== 'loaded') {
      return (
        <Menu>
          <SearchMessage>
            {t('hashMenu.typeToSearch')}
            <Spinner />
          </SearchMessage>
        </Menu>
      );
    }

    if (!query) {
      return (
        <Menu>
          <SearchMessage>{t('hashMenu.typeToSearch')}</SearchMessage>
        </Menu>
      );
    }

    if (error || visibleResults.length === 0) {
      return (
        <Menu>
          <SearchMessage>{error ? t('search.error') : t('search.noResults')}</SearchMessage>
        </Menu>
      );
    }

    return (
      <Menu>
        {visibleResults.map((wp, index) => (
          <MenuItem
            key={wp.id}
            $selected={selectedIndex === index}
            // Mouse path: e.preventDefault() prevents the editor from losing focus.
            // This allows us to safely insert the chip without needing TipTap to restore the cursor.
            onMouseDown={(e) => {
              e.preventDefault();
              if (items[index]) onItemClick?.(items[index]);
            }}
          >
            <BlockCard workPackage={wp} inDropdown />
          </MenuItem>
        ))}
      </Menu>
    );
  };

  HashWpMenuComponent.displayName = 'HashWpMenu';
  return HashWpMenuComponent;
}
