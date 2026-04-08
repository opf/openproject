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

/**
 * Removes the # trigger text (and any extra # symbols) from the current block.
 * BlockNote removes #query itself on Enter, but may leave extra # characters
 * (e.g. ## from ###query). Returns the block id, or null if nothing was found.
 */
export function clearTriggerText(editor: AnyEditor): string | null {
  const block = editor.getTextCursorPosition()?.block;
  if (!block) return null;

  const content = (block.content ?? []) as any[];

  const triggerNodeIndex = content.findIndex((n) => {
    if (n.type !== "text") return false;
    return /#+/.test(n.text as string);
  });

  if (triggerNodeIndex === -1) return null;

  const triggerNode = content[triggerNodeIndex] as { type: string; text: string; styles: any };
  const text = triggerNode.text;
  const hashIndex = text.search(/#/);
  const textBefore = hashIndex > 0 ? text.slice(0, hashIndex) : null;

  const cleanedContent = [
    ...content.slice(0, triggerNodeIndex),
    ...(textBefore ? [{ type: "text", text: textBefore, styles: triggerNode.styles }] : []),
  ];

  editor.updateBlock(block.id, { content: cleanedContent } as any);
  return block.id;
}

function focusAndMoveToEnd(editor: AnyEditor, blockId: string): void {
  requestAnimationFrame(() => {
    editor.focus();
    editor.setTextCursorPosition(blockId, "end");
  });
}

/**
 * Mouse path: inserts chip at the current cursor position via insertInlineContent.
 * Works correctly because e.preventDefault() stops BlockNote from moving the cursor.
 */
export function insertWpChip(editor: AnyEditor, wp: WorkPackage, size: InlineWpSize): void {
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
/**
 * Keyboard (Enter) path: inserts chip directly into block content by ID,
 * bypassing cursor position entirely to avoid race conditions with
 * BlockNote's Enter handling which moves the cursor to a new block.
 */
export function insertWpChipIntoBlock(
  editor: AnyEditor,
  blockId: string,
  wp: WorkPackage,
  size: InlineWpSize,
): void {
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

  focusAndMoveToEnd(editor, blockId);
}