import styled from 'styled-components';
import { defaultWpVariables } from '../WorkPackage/atoms';
import { FLOATING_Z_INDEX } from '../../utils/zIndex';

export const SEARCH_INPUT_ID = 'op-bn-wp-search-input';

/**
 * Popover surface for the work package search UI, overlaying the pending chip or block
 * it belongs to. Positioned by useAnchoredPopover whenever an anchor element is known.
 */
export const SearchContainer = styled.div.attrs({
  className: 'op-bn-search',
})`
  ${defaultWpVariables}
  position: absolute;
  z-index: ${FLOATING_Z_INDEX.search};
  top: 1.6em;
  left: 0;
  overflow: hidden;
  width: 400px;
  padding: var(--spacer-m) var(--spacer-xl);
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  line-height: 1.5;
`;

export const SearchLabel = styled.label.attrs({
  className: 'op-bn-search--label',
  htmlFor: SEARCH_INPUT_ID,
})`
  font-weight: normal !important;
`;

export const SearchIconWrapper = styled.div`
  display: flex;
  align-items: center;
  flex-shrink: 0;
  color: var(--bn-colors-editor-text, #333);
`;

export const SearchInput = styled.input.attrs({
  id: SEARCH_INPUT_ID,
})`
  width: 100%;
  padding: var(--spacer-m) var(--spacer-l);
  border: none !important;
  outline: none !important;
  box-shadow: none !important;
  appearance: none;
  background: transparent;
  color: var(--bn-colors-editor-text, #333);
  font-size: 0.9em;
  box-sizing: border-box;
`;

export const SearchMessage = styled.div.attrs({
  className: 'op-bn-search--message',
  role: 'status',
})`
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--spacer-m);
  padding: var(--spacer-m) var(--spacer-l);
  font-size: 0.85em;
  color: var(--bn-colors-highlights-gray-text, #888);
`;

export const DropdownList = styled.div`
  overflow: hidden;
  padding-top: var(--spacer-m);
`;

export const DropdownItem = styled.div.attrs<{
  $selected:boolean;
  'data-testid'?:string;
}>({
  'data-testid': 'dropdown-item',
})<{
  $selected:boolean;
}>`
  background-color: ${({ $selected }) =>
    $selected ? 'var(--op-item-hover-bg)' : 'transparent'};
  &:hover {
    background: var(--op-item-hover-bg);
  }
  border-radius: var(--bn-border-radius-small);
  margin: var(--spacer-s) 0;
  padding: 0 var(--spacer-m);
  cursor: pointer;
`;