import type { FC, RefObject } from "react";
import type { SuggestionMenuProps } from "@blocknote/react";
import styled from "styled-components";
import { BlockCard } from "../BlockWorkPackage/BlockCard";
import { defaultWpVariables } from "../WorkPackage/atoms";
import type { WorkPackage } from "../../openProjectTypes";
import type { HashMenuItem } from "./types";
import type { AnyEditor } from "./editorUtils";
import {
  getSizeFromCurrentBlock,
  insertWpChip,
} from "./editorUtils";
import { useTranslation } from "react-i18next";

const Menu = styled.div.attrs({ className: "op-bn-hash-menu" })`
  ${defaultWpVariables}
  background: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 320px;
  max-width: 480px;
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
  editor: AnyEditor,
  resultsRef: RefObject<WorkPackage[]>,
): FC<SuggestionMenuProps<HashMenuItem>> {
  const HashWpMenuComponent: FC<SuggestionMenuProps<HashMenuItem>> = ({
    items,
    selectedIndex,
  }) => {
    const { t } = useTranslation();
    const searchQuery = items[0]?.title ?? "";
    const visibleResults = (resultsRef.current ?? []).slice(0, MAX_RESULTS);

    const currentSize = getSizeFromCurrentBlock(editor);
    const currentBlockId = editor.getTextCursorPosition()?.block?.id;

    // Mutate each item's onItemClick so BlockNote's keyboard handler
    // (Enter / PgUp / PgDn) calls the correct insertion for that result.
    visibleResults.forEach((wp, index) => {
      if (!items[index]) return;

      items[index].onItemClick = () => {
        requestAnimationFrame(() => {
          if (!currentBlockId) return;

          const currentBlock = editor.getTextCursorPosition()?.block;

          // BlockNote's default "Enter" behavior splits the block.
          // If the block ID changed, it was a keyboard Enter, so we remove the new empty block.
          const isKeyboardEnter = currentBlock && currentBlock.id !== currentBlockId;

          if (isKeyboardEnter) {
            editor.removeBlocks([currentBlock.id]);
          }

          editor.focus();

          insertWpChip(editor, wp, currentSize);
        });
      };
    });

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
              items[index]?.onItemClick();
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