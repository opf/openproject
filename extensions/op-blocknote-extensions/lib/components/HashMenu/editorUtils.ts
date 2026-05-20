import type { BlockNoteEditor } from "@blocknote/core";
import type { InlineWpSize } from "../WorkPackage/types";
import { makeInstanceId } from "../../services/utils";
import type { WorkPackage } from "../../openProjectTypes";

export type AnyEditor = BlockNoteEditor<any, any, any>;

/**
 * Determines the inline chip size based on how many `#` characters
 * the user typed before the search query in the current block.
 *
 *   #query -> "xxs" (ID only)
 *   ##query -> "xs" (ID + Type + Subject)
 *   ###query -> "s" (ID + Type + Status + Subject)
 */
export function getSizeFromCurrentBlock(editor: AnyEditor): InlineWpSize {
  const block = editor.getTextCursorPosition()?.block;
  if (!block) return "xxs";

  const content = (block.content ?? []) as any[];
  let lastHashCount: number | null = null;

  for (const node of content) {
    if (node.type !== "text") continue;
    const text = node.text as string;
    const matches = [...text.matchAll(/#+/g)];
    if (matches.length > 0) {
      lastHashCount = matches[matches.length - 1][0].length;
    }
  }

  if (lastHashCount === null) return "xxs";
  if (lastHashCount >= 3) return "s";
  if (lastHashCount === 2) return "xs";
  return "xxs";
}

/**
 * Inserts a chip at the cursor and removes the `#query` trigger before it.
 * The chip acts as a position anchor so we don't need cursor offsets.
 */
export function insertWpChip(editor: AnyEditor, wp: WorkPackage, size: InlineWpSize): void {
  const instanceId = makeInstanceId();

  (editor.insertInlineContent as (content: unknown[]) => void)([
    { type: "openProjectWorkPackageInline", props: { wpid: String(wp.id), instanceId, size } },
    { type: "text", text: " ", styles: {} },
  ]);

  removeTriggerBeforeChip(editor, instanceId);

  editor.focus();
}

/**
 * Trims the trailing `#query` from the text node right before the chip.
 * Returns the block ID if the operation completed (with or without changes), or null if no block.
 */
export function removeTriggerBeforeChip(editor: AnyEditor, instanceId: string): string | null {
  const block = editor.getTextCursorPosition()?.block;
  if (!block) return null;

  const content = (block.content ?? []) as any[];
  const chipIndex = content.findIndex(
    (n) => n.type === "openProjectWorkPackageInline" && n.props?.instanceId === instanceId
  );
  if (chipIndex <= 0) return block.id;

  const prev = content[chipIndex - 1];
  if (prev.type !== "text") return block.id;

  const match = (prev.text as string).match(/#+\S*$/);
  if (!match) return block.id;

  const before = (prev.text as string).slice(0, match.index);
  const newContent = [...content];

  if (before.length > 0) {
    newContent[chipIndex - 1] = { ...prev, text: before };
  } else {
    newContent.splice(chipIndex - 1, 1);
  }

  editor.updateBlock(block.id, { content: newContent } as any);
  return block.id;
}