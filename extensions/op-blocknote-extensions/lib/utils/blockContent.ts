import type { BlockNoteEditor } from '@blocknote/core';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

export function isCurrentBlockEmpty(editor:AnyEditor):boolean {
  const block = editor.getTextCursorPosition()?.block;
  if (!block) return false;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access
  const content = (block as any).content;
  return Array.isArray(content) && content.length === 0;
}