import type { FC, RefObject } from "react";
import type { BlockNoteEditor } from "@blocknote/core";
import type { SuggestionMenuProps } from "@blocknote/react";
import styled from "styled-components";
import { BlockCard } from "../BlockWorkPackage/BlockCard";
import { defaultWpVariables } from "../WorkPackage/atoms";
import type { InlineWpSize } from "./types";
import { makeInstanceId } from "../../services/utils";
import type { WorkPackage } from "../../openProjectTypes";

type AnyEditor = BlockNoteEditor<any, any, any>;

export function isHashWpQuery(query: string): boolean {
  return query.trim().length > 0;
}

export interface HashMenuItem {
  title: string;
  onItemClick: () => void;
}

// Determines chip size based on the number of # characters before the query:
// #query -> xxs, ##query -> xs, ###query -> s
function getSizeFromCurrentBlock(editor: AnyEditor): InlineWpSize {
  const block = editor.getTextCursorPosition()?.block;
  if (!block) return "xxs";

  const content = (block.content ?? []) as any[];

  for (const node of content) {
    if (node.type !== "text") continue;
    const text = node.text as string;
    const match = text.match(/(#+)[^#]/);
    if (match) {
      const hashCount = match[1].length;
      if (hashCount >= 3) return "s";
      if (hashCount === 2) return "xs";
      return "xxs";
    }
  }

  return "xxs";
}

// Removes the # trigger text (and any extra # symbols) from the current block.
// Used in the mouse path on Enter, BlockNote already clears #query itself,
// but may leave extra # characters (e.g. ## from ###query), so we call this
// after rAF in the keyboard path too to clean up any leftovers.
function clearTriggerText(editor: AnyEditor): string | null {
  const block = editor.getTextCursorPosition()?.block;
  if (!block) return null;

  const content = (block.content ?? []) as any[];

  const triggerNodeIndex = content.findIndex((n) => {
    if (n.type !== "text") return false;
    return /#+/.test(n.text as string);
  });

  // No # found BlockNote already cleaned everything, nothing to do
  if (triggerNodeIndex === -1) return null;

  const triggerNode = content[triggerNodeIndex] as { type: string; text: string; styles: any };
  const text = triggerNode.text;

  // Preserve any text that was typed before the # in the same node (e.g. "Hello " from "Hello ##query")
  const hashIndex = text.search(/#/);
  const textBefore = hashIndex > 0 ? text.slice(0, hashIndex) : null;

  const cleanedContent = [
    ...content.slice(0, triggerNodeIndex),
    ...(textBefore ? [{ type: "text", text: textBefore, styles: triggerNode.styles }] : []),
  ];

  editor.updateBlock(block.id, { content: cleanedContent } as any);
  return block.id;
}

// Mouse path: inserts chip at current cursor position via insertInlineContent.
// Works correctly because e.preventDefault() stops BlockNote from moving the cursor.
function insertWpChip(editor: AnyEditor, wp: WorkPackage, size: InlineWpSize): void {
  const instanceId = makeInstanceId();

  (editor.insertInlineContent as (content: unknown[]) => void)([
    { type: "inlineWorkPackage", props: { wpid: String(wp.id), instanceId, size } },
    { type: "text", text: " ", styles: {} },
  ]);

  requestAnimationFrame(() => {
    editor.focus();
    const cursor = editor.getTextCursorPosition();
    if (cursor?.block?.id) {
      editor.setTextCursorPosition(cursor.block.id, "end");
    }
  });
}

// Keyboard (Enter) path: inserts chip directly into block content by ID,
// bypassing cursor position entirely to avoid race conditions with
// BlockNote's Enter handling which moves the cursor to a new block.
function insertWpChipIntoBlock(editor: AnyEditor, blockId: string, wp: WorkPackage, size: InlineWpSize): void {
  const instanceId = makeInstanceId();
  const block = editor.getBlock(blockId);
  if (!block) return;

  const content = (block.content ?? []) as any[];

  editor.updateBlock(blockId, {
    content: [
      ...content,
      { type: "inlineWorkPackage", props: { wpid: String(wp.id), instanceId, size } },
      { type: "text", text: " ", styles: {} },
    ],
  } as any);

  requestAnimationFrame(() => {
    editor.focus();
    editor.setTextCursorPosition(blockId, "end");
  });
}

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
  // Ref is populated by the parent component via useWorkPackageSearch.
  // We use a ref (not state) so that getItems can return the correct item
  // count for keyboard navigation without causing extra re-renders.
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
    // size and blockId are captured synchronously here while # is still in
    // the document. Insertion is deferred via rAF so it runs after BlockNote
    // finishes its own cleanup (removing #query and creating a new block on Enter).
    visibleResults.forEach((wp, index) => {
      if (items[index]) {
        const size = getSizeFromCurrentBlock(editor);
        const blockId = editor.getTextCursorPosition()?.block?.id;
        items[index].onItemClick = () => {
          requestAnimationFrame(() => {
            if (!blockId) return;
            editor.focus();

            // BlockNote splits the block on Enter — remove the new empty block it created
            const currentBlock = editor.getTextCursorPosition()?.block;
            if (currentBlock && currentBlock.id !== blockId) {
              editor.removeBlocks([currentBlock.id]);
            }

            // Clean up any leftover # symbols BlockNote didn't remove (e.g. ## from ###query)
            clearTriggerText(editor);

            // Insert directly into the original block by ID, not by cursor position
            insertWpChipIntoBlock(editor, blockId, wp, size);
          });
        };
      }
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