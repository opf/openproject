import styled from "styled-components";
import { defaultWpVariables } from "../WorkPackage/atoms";

export const SearchContainer = styled.div.attrs({
  className: "op-bn-search",
})`
  ${defaultWpVariables}
  position: relative;
  padding: var(--spacer-m) var(--spacer-xl);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  width: 100%;
  @media (min-width: 1120px) {
    width: 500px;
  }
`;

export const SearchLabel = styled.label.attrs({
  className: "op-bn-search--label",
})`
  font-weight: normal !important;
`;

export const SearchIconWrapper = styled.div`
  display: flex;
  align-items: center;
  flex-shrink: 0;
  color: var(--bn-colors-editor-text, #333);
`;

export const SearchInput = styled.input`
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

export const DropdownList = styled.div`
  overflow: hidden;
  padding-top: var(--spacer-m);
`;

export const DropdownItem = styled.div.attrs<{
  $selected: boolean;
  'data-testid'?: string;
}>({
  'data-testid': 'dropdown-item',
})<{
  $selected: boolean;
}>`
  background-color: ${({ $selected }) =>
    $selected ? "var(--bn-colors-highlights-gray-background, #f0f0f0)" : "transparent"};
  border-radius: var(--bn-border-radius-small);
  margin: var(--spacer-s) 0;
  padding: 0 var(--spacer-m);
  cursor: pointer;
`;