import styled from "styled-components";
import { defaultWpVariables } from "../WorkPackage/atoms";

export const SEARCH_INPUT_ID = "op-bn-wp-search-input";

/**
 * Container for the work package search UI.
 *
 * $floating — renders as an absolutely positioned popover (used inside
 * InlineWorkPackageChip where the search appears overlaid on the editor).
 * Without $floating it renders as a normal block element (used in BlockWorkPackage).
 */
export const SearchContainer = styled.div.attrs({
  className: "op-bn-search",
})<{ $floating?: boolean }>`
  ${defaultWpVariables}
  position: ${({ $floating }) => ($floating ? "absolute" : "relative")};
  z-index: ${({ $floating }) => ($floating ? 9999 : "auto")};
  top: ${({ $floating }) => ($floating ? "1.6em" : "auto")};
  left: ${({ $floating }) => ($floating ? 0 : "auto")};
  overflow: ${({ $floating }) => ($floating ? "hidden" : "visible")};
  width: ${({ $floating }) => ($floating ? "400px" : "100%")};
  padding: var(--spacer-m) var(--spacer-xl);
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  line-height: 1.5;

  @media (min-width: 1120px) {
    width: ${({ $floating }) => ($floating ? "400px" : "500px")};
  }
`;

/**
 * Accessible label for the search input.
 * Linked to SearchInput via htmlFor / id = SEARCH_INPUT_ID.
 */
export const SearchLabel = styled.label.attrs({
  className: "op-bn-search--label",
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

export const DropdownList = styled.div`
  overflow: hidden;
  padding-top: var(--spacer-m);
`;

export const DropdownItem = styled.div.attrs<{
  $selected: boolean;
  "data-testid"?: string;
}>({
  "data-testid": "dropdown-item",
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