import type { FC, RefObject } from "react";
import type { SuggestionMenuProps } from "@blocknote/react";
import styled from "styled-components";
import { BlockCard } from "../BlockWorkPackage/BlockCard";
import { defaultWpVariables } from "../WorkPackage/atoms";
import type { WorkPackage } from "../../openProjectTypes";
import type { HashMenuItem } from "./types";
import { useTranslation } from "react-i18next";

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
const Menu = styled.div.attrs({ className: "op-bn-hash-menu" })`
  ${defaultWpVariables}
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 320px;
  max-width: 480px;
  max-height: 60vh;
  overflow-y: auto;
  min-height: 0;
`;

const MenuItem = styled.div<{ $selected: boolean }>`
  border-radius: var(--bn-border-radius-small);
  background: ${({ $selected }) =>
    $selected ? "var(--op-item-hover-bg)" : "transparent"};
  cursor: pointer;
  padding: 0 var(--spacer-s);

  &:hover {
    background: var(--op-item-hover-bg);
  }
`;

const EmptyState = styled.div`
  padding: var(--spacer-m) var(--spacer-l);
  font-size: 0.85em;
  color: var(--bn-colors-highlights-gray-text, #888);
`;

const MAX_RESULTS = 5;

export function createHashWpMenuComponent(
  resultsRef: RefObject<WorkPackage[]>,
): FC<SuggestionMenuProps<HashMenuItem>> {
  const HashWpMenuComponent: FC<SuggestionMenuProps<HashMenuItem>> = ({
    items,
    selectedIndex,
    onItemClick,
  }) => {
    const { t } = useTranslation();
    const searchQuery = items[0]?.title ?? "";
    const visibleResults = (resultsRef.current ?? []).slice(0, MAX_RESULTS);

    if (!searchQuery) {
      return (
        <Menu>
          <EmptyState>{t("hashMenu.typeToSearch")}</EmptyState>
        </Menu>
      );
    }

    if (visibleResults.length === 0) {
      return (
        <Menu>
          <EmptyState>{t("hashMenu.noResults", { query: searchQuery })}</EmptyState>
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

  HashWpMenuComponent.displayName = "HashWpMenu";
  return HashWpMenuComponent;
}