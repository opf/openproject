import type { BlockNoteEditor } from '@blocknote/core';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

export function moveCursorAfterBlock(editor:AnyEditor, blockId:string):void {
  editor.focus();
  editor.setTextCursorPosition(blockId, 'end');

  const cursor = editor.getTextCursorPosition();
  const blockSchema = editor.schema.blockSchema as Record<string, { content?:string } | undefined>;
  const nextType = cursor?.nextBlock?.type as string | undefined;

  // A block without content of its own — another card, an image — takes a NodeSelection
  // instead of a caret, which renders nothing and swallows what is typed next.
  const nextTakesCursor = nextType !== undefined && blockSchema[nextType]?.content !== 'none';

  if (cursor?.block && !nextTakesCursor) {
    editor.insertBlocks([{ type: 'paragraph', content: [] }], cursor.block.id, 'after');
  }

  const updated = editor.getTextCursorPosition();
  if (updated?.nextBlock) {
    editor.setTextCursorPosition(updated.nextBlock.id, 'start');
  }
}

