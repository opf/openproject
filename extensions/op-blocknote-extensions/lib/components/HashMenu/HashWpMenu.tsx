import { useEffect, useMemo, useState } from 'react';
import type { FC, RefObject } from 'react';
import type { SuggestionMenuProps } from '@blocknote/react';
import styled from 'styled-components';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { defaultWpVariables, menuSurfaceStyles } from '../WorkPackage/atoms';
import { SearchMessage } from '../Search/SearchContainer';
import { Spinner } from '../Spinner';
import { supportsHover } from '../../utils/device';
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
  ${menuSurfaceStyles}
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 320px;
  max-width: 480px;
  overflow-y: auto;
  min-height: 0;
`;

const MenuItem = styled.div.attrs({ className: 'op-bn-hash-menu-item' })<{ $highlighted:boolean }>`
  border-radius: var(--bn-border-radius-small);
  background: ${({ $highlighted }) =>
    $highlighted ? 'var(--op-item-hover-bg)' : 'transparent'};
  cursor: pointer;
  padding: 0 var(--spacer-s);
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

    const canHover = useMemo(() => supportsHover(), []);
    const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

    useEffect(() => {
      setHoveredIndex(null);
    }, [selectedIndex, items]);

    const highlightedIndex = hoveredIndex ?? selectedIndex;

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
      <Menu onMouseLeave={canHover ? () => setHoveredIndex(null) : undefined}>
        {visibleResults.map((wp, index) => (
          <MenuItem
            key={wp.id}
            $highlighted={highlightedIndex === index}
            onMouseMove={canHover ? () => setHoveredIndex(index) : undefined}
            role="button"
            onMouseDown={(e) => e.preventDefault()}
            onClick={() => {
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
