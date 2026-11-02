import type { AnyEditor } from '../editorTypes';

const PARAGRAPH_BLOCK_TYPE = 'paragraph';

interface SelectedBlock {
  id:string;
  type:string;
  children?:unknown[];
}

function currentBlock(editor:AnyEditor):{ type:string; content?:unknown } | undefined {
  return editor.getTextCursorPosition()?.block;
}

function isEmpty(block:{ content?:unknown }):boolean {
  return Array.isArray(block.content) && block.content.length === 0;
}

function isPlainParagraph(block:SelectedBlock):boolean {
  return block.type === PARAGRAPH_BLOCK_TYPE && (block.children?.length ?? 0) === 0;
}

export function isCurrentBlockEmpty(editor:AnyEditor):boolean {
  const block = currentBlock(editor);
  return block !== undefined && isEmpty(block);
}

export function canBlockWorkPackageReplaceCurrentBlock(editor:AnyEditor):boolean {
  const block = currentBlock(editor);
  return block?.type === PARAGRAPH_BLOCK_TYPE && isEmpty(block);
}

export function fullySelectedParagraphIds(editor:AnyEditor):string[] {
  if (editor.prosemirrorState.selection.empty) return [];

  const { blocks, blockCutAtStart, blockCutAtEnd } = editor.getSelectionCutBlocks();
  // A cut block is one the selection only reaches into, not one it hands over whole.
  if (blockCutAtStart !== undefined || blockCutAtEnd !== undefined) return [];

  const selected = blocks as SelectedBlock[];
  if (selected.length === 0 || !selected.every(isPlainParagraph)) return [];

  return selected.map((block) => block.id);
}
