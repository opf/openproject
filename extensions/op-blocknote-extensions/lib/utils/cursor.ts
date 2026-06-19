import type { BlockNoteEditor } from '@blocknote/core';
import type { Node as PmNode } from 'prosemirror-model';
import { TextSelection } from 'prosemirror-state';

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

function findInlineNodeRange(doc:PmNode, instanceId:string):{ from:number; to:number } | null {
  let result:{ from:number; to:number } | null = null;
  doc.descendants((node, pos) => {
    if (result) return false;
    if ((node.attrs as Record<string, unknown>)?.instanceId === instanceId) {
      result = { from: pos, to: pos + node.nodeSize };
      return false;
    }
    return true;
  });
  return result;
}

export function selectInlineNode(editor:AnyEditor, instanceId:string):void {
  const range = findInlineNodeRange(editor.prosemirrorState.doc, instanceId);
  if (!range) return;
  editor.transact((tr) => {
    tr.setSelection(TextSelection.create(tr.doc, range.from, range.to));
  });
}

export function placeCursorAfterInlineNode(editor:AnyEditor, instanceId:string):void {
  const range = findInlineNodeRange(editor.prosemirrorState.doc, instanceId);
  if (!range) return;
  editor.transact((tr) => {
    tr.setSelection(TextSelection.create(tr.doc, range.to));
  });
}
