import { useEffect, useMemo, useRef, useState } from 'react';
import type { ReactNode } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import type { SuggestionMenuProps } from '@blocknote/react';
import type { SuggestionMenuItem, SuggestionSearchState } from '../../hooks/useSuggestionSearch';
import { editorThemeVariables, menuSurfaceStyles } from './theme';
import { SearchMessage } from './SearchMessage';
import { Spinner } from '../Spinner';
import { supportsHover } from '../../utils/device';
import { useActiveOptionInView } from '../../hooks/useActiveOptionInView';
import { useTapActivation } from '../../utils/tapActivation';

const Menu = styled.div`
  ${editorThemeVariables}
  ${menuSurfaceStyles}
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 320px;
  max-width: 480px;
  overflow-y: auto;
  min-height: 0;
`;

const MenuItem = styled.div<{ $highlighted:boolean }>`
  border-radius: var(--bn-border-radius-small);
  background: ${({ $highlighted }) => ($highlighted ? 'var(--op-item-hover-bg)' : 'transparent')};
  cursor: pointer;
  padding: 0 var(--spacer-s);
`;

interface SuggestionListboxProps<T> extends SuggestionMenuProps<SuggestionMenuItem> {
  // Names the classes and test id: `op-bn-<name>`, `op-bn-<name>-item`, `<name>`.
  name:string;
  ariaLabel:string;
  loadingMessage:string;
  searchState:SuggestionSearchState<T>;
  // Shown for an empty query instead of the search outcome.
  promptMessage?:string;
  optionKey:(option:T) => string | number;
  renderOption:(option:T) => ReactNode;
}

export function SuggestionListbox<T>({
  items, loadingState, selectedIndex, onItemClick,
  name, ariaLabel, loadingMessage, searchState, promptMessage, optionKey, renderOption,
}:SuggestionListboxProps<T>) {
  const { t } = useTranslation();
  const { query, results: options, error } = searchState;
  const canHover = useMemo(() => supportsHover(), []);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const tapProps = useTapActivation();

  useActiveOptionInView(menuRef, selectedIndex ?? -1, options);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setHoveredIndex(null);
  }, [selectedIndex, options]);

  const surface = { className: `op-bn-${name}`, 'data-testid': name };

  let emptyMessage:string | null = null;
  if (promptMessage !== undefined && !query) emptyMessage = promptMessage;
  else if (error) emptyMessage = t('search.error');
  else if (options.length === 0) emptyMessage = t('search.noResults');

  const pick = (index:number) => {
    const item = items[index];
    if (item) onItemClick?.(item);
  };

  if (loadingState !== 'loaded') {
    return <Menu {...surface}><SearchMessage>{loadingMessage}<Spinner /></SearchMessage></Menu>;
  }

  if (emptyMessage !== null) {
    return <Menu {...surface}><SearchMessage>{emptyMessage}</SearchMessage></Menu>;
  }

  const highlightedIndex = hoveredIndex ?? selectedIndex;

  return (
    <Menu
      {...surface}
      ref={menuRef}
      role="listbox"
      aria-label={ariaLabel}
      onMouseLeave={canHover ? () => setHoveredIndex(null) : undefined}
    >
      {options.map((option, index) => (
        <MenuItem
          key={optionKey(option)}
          className={`op-bn-${name}-item`}
          $highlighted={highlightedIndex === index}
          onMouseMove={canHover ? () => setHoveredIndex(index) : undefined}
          role="option"
          aria-selected={selectedIndex === index}
          onMouseDown={(event) => event.preventDefault()}
          {...tapProps(() => pick(index))}
        >
          {renderOption(option)}
        </MenuItem>
      ))}
    </Menu>
  );
}
