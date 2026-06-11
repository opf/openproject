import type { BlockNoteEditor } from "@blocknote/core";

type AnyEditor = BlockNoteEditor<any, any, any>;

export function isCurrentBlockEmpty(editor: AnyEditor): boolean {
  const block = editor.getTextCursorPosition()?.block;
  if (!block) return false;
  const content = (block as any).content;
  return Array.isArray(content) && content.length === 0;
}