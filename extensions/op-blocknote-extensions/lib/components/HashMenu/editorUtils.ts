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
    const match = text.match(/(#+)/);
    if (match) {
      const hashCount = match[1].length;
      if (hashCount >= 3) return "s";
      if (hashCount === 2) return "xs";
      return "xxs";
    }
  }

  return "xxs";
}

export function clearTriggerText(editor: AnyEditor): string | null {
  const tiptap = (editor as any)._tiptapEditor;
  if (!tiptap) return null;

  const { state, view } = tiptap;
  const { selection } = state;
  const { $from, from } = selection;

  const textBefore = $from.parent.textBetween(
    Math.max(0, $from.parentOffset - 50),
    $from.parentOffset,
    undefined,
    "\n"
  );

  const match = textBefore.match(/(#+\S*)$/);
  if (!match) return null;

  const triggerLength = match[1].length;
  const tr = state.tr.delete(from - triggerLength, from);
  view.dispatch(tr);

  const block = (editor as any).getTextCursorPosition()?.block;
  return block?.id ?? null;
}

/**
 * Mouse path: inserts chip at the current cursor position via insertInlineContent.
 * Works correctly because e.preventDefault() stops BlockNote from moving the cursor.
 */
export function insertWpChip(editor: AnyEditor, wp: WorkPackage, size: InlineWpSize): void {
  const instanceId = makeInstanceId();

  clearTriggerText(editor);

  (editor.insertInlineContent as (content: unknown[]) => void)([
    { type: "openProjectWorkPackageInline", props: { wpid: String(wp.id), instanceId, size } },
    { type: "text", text: " ", styles: {} },
  ]);

  editor.focus();
}
export function insertWpChipIntoBlock(
  editor: AnyEditor,
  _blockId: string,
  wp: WorkPackage,
  size: InlineWpSize
): void {
  insertWpChip(editor, wp, size);
}