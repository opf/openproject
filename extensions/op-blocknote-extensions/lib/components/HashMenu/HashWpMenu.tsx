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
  clearTriggerText,
  insertWpChip,
  insertWpChipIntoBlock,
} from "./editorUtils";

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
    $selected ? "var(--bn-colors-highlights-gray-background, #f0f0f0)" : "transparent"};
  cursor: pointer;
  padding: 0 var(--spacer-s);

  &:hover {
    background: var(--bn-colors-highlights-gray-background, #f0f0f0);
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
    const searchQuery = items[0]?.title ?? "";
    const visibleResults = (resultsRef.current ?? []).slice(0, MAX_RESULTS);

    // Mutate each item's onItemClick so BlockNote's keyboard handler
    // (Enter / PgUp / PgDn) calls the correct insertion for that result.
    visibleResults.forEach((wp, index) => {
      if (!items[index]) return;

      const size = getSizeFromCurrentBlock(editor);
      const blockId = editor.getTextCursorPosition()?.block?.id;

      items[index].onItemClick = () => {
        requestAnimationFrame(() => {
          if (!blockId) return;
          editor.focus();

          // BlockNote splits the block on Enter - remove the new empty block it created.
          const currentBlock = editor.getTextCursorPosition()?.block;
          if (currentBlock && currentBlock.id !== blockId) {
            editor.removeBlocks([currentBlock.id]);
          }

          clearTriggerText(editor);
          insertWpChipIntoBlock(editor, blockId, wp, size);
        });
      };
    });

    if (!searchQuery) {
      return (
        <Menu>
          <EmptyState>Type to search work packages…</EmptyState>
        </Menu>
      );
    }

    if (visibleResults.length === 0) {
      return (
        <Menu>
          <EmptyState>No results for "{searchQuery}"</EmptyState>
        </Menu>
      );
    }

    return (
      <Menu>
        {visibleResults.map((wp, index) => (
          <MenuItem
            key={wp.id}
            $selected={selectedIndex === index}
            // Mouse path: e.preventDefault() stops BlockNote from doing its own
            // cleanup, so we clear the trigger text manually before inserting.
            onMouseDown={(e) => {
              e.preventDefault();
              const size = getSizeFromCurrentBlock(editor);
              const blockId = clearTriggerText(editor);
              if (blockId) {
                editor.focus();
                editor.setTextCursorPosition(blockId, "end");
              }
              insertWpChip(editor, wp, size);
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