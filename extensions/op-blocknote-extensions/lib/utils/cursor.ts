import type { BlockNoteEditor } from '@blocknote/core';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

export function moveCursorAfterBlock(editor:AnyEditor, blockId:string):void {
  editor.focus();
  editor.setTextCursorPosition(blockId, 'end');

  const cursor = editor.getTextCursorPosition();
  if (!cursor?.nextBlock && cursor?.block) {
    editor.insertBlocks([{ type: 'paragraph', content: [] }], cursor.block.id, 'after');
  }

  const updated = editor.getTextCursorPosition();
  if (updated?.nextBlock) {
    editor.setTextCursorPosition(updated.nextBlock.id, 'start');
  }
}

