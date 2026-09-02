import type { AnyEditor } from '../editorTypes';

const CARD_REPLACEABLE_BLOCK_TYPE = 'paragraph';

function currentBlock(editor:AnyEditor):{ type:string; content?:unknown } | undefined {
  return editor.getTextCursorPosition()?.block;
}

function isEmpty(block:{ content?:unknown }):boolean {
  return Array.isArray(block.content) && block.content.length === 0;
}

export function isCurrentBlockEmpty(editor:AnyEditor):boolean {
  const block = currentBlock(editor);
  return block !== undefined && isEmpty(block);
}

export function canCardReplaceCurrentBlock(editor:AnyEditor):boolean {
  const block = currentBlock(editor);
  return block?.type === CARD_REPLACEABLE_BLOCK_TYPE && isEmpty(block);
}
