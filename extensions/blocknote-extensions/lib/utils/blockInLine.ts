import { contentNodeToInlineContent } from '@blocknote/core';
import type { Fragment, Node, ResolvedPos } from 'prosemirror-model';
import { TextSelection } from 'prosemirror-state';
import type { AnyEditor } from '../editorTypes';
import { moveCursorAfterBlock } from './cursor';

type BlockInsertion = Parameters<AnyEditor['insertBlocks']>[0][number];
interface LineRange { from:number; to:number }
interface BlockToInsert { type:string; props:Record<string, unknown> }

export function insertBlockInLine(editor:AnyEditor, range:LineRange, block:BlockToInsert):void {
  editor.transact(() => moveCursorAfterBlock(editor, placeBlockInLine(editor, range, block)));
}

/**
 * Puts `block` in place of the range from `from` to `to` and returns its id. A block
 * cannot sit inside a line, so the line is split around it. Elsewhere, such as in a
 * table cell or on a selected block, it follows the enclosing block instead.
 */
export function placeBlockInLine(editor:AnyEditor, range:LineRange, block:BlockToInsert):string {
  const insertion = block as BlockInsertion;

  return editor.transact((tr) => {
    const { from } = range;
    let { to } = range;
    if (!tr.doc.resolve(from).sameParent(tr.doc.resolve(to))) {
      tr.delete(from, to);
      to = from;
    }

    const $from = tr.doc.resolve(from);
    const line = $from.parent;
    const lineId = line.inlineContent ? blockIdOf($from.node(-1)) : undefined;

    if (!lineId) {
      if (line.inlineContent) tr.delete(from, to);
      return editor.insertBlocks([insertion], enclosingBlockId($from), 'after')[0].id;
    }

    const fromOffset = $from.parentOffset;
    const toOffset = fromOffset + to - from;
    const before = line.content.cut(0, fromOffset);
    const after = line.content.cut(toOffset);
    const { selection } = tr;
    const caret = selection.empty && selection.$from.parent === line ? selection.$from.parentOffset : undefined;

    if (isBlank(before) && isBlank(after)) {
      editor.updateBlock(lineId, insertion);
      return lineId;
    }
    if (isBlank(before)) {
      editor.updateBlock(lineId, { content: inlineContentOf(editor, line, after) });
      const [inserted] = editor.insertBlocks([insertion], lineId, 'before');
      if (caret !== undefined && caret >= toOffset) restoreCaret(editor, lineId, caret - toOffset);
      return inserted.id;
    }

    // The nested blocks follow the line, so they go along with its last part.
    const { children } = editor.getBlock(lineId)!;
    if (children.length > 0) editor.removeBlocks(children);
    editor.updateBlock(lineId, { content: inlineContentOf(editor, line, before) });
    const rest = isBlank(after)
      ? []
      : [{ type: line.type.name, props: line.attrs, content: inlineContentOf(editor, line, after), children }];
    const [inserted, restBlock] = editor.insertBlocks(
      [{ ...insertion, children: rest.length > 0 ? [] : children }, ...rest] as BlockInsertion[],
      lineId,
      'after',
    );

    if (caret !== undefined && caret <= fromOffset) restoreCaret(editor, lineId, caret);
    else if (caret !== undefined && caret >= toOffset && restBlock) restoreCaret(editor, restBlock.id, caret - toOffset);
    return inserted.id;
  });
}

function restoreCaret(editor:AnyEditor, blockId:string, offset:number):void {
  editor.setTextCursorPosition(blockId, 'start');
  editor.transact((tr) => {
    tr.setSelection(TextSelection.create(tr.doc, tr.selection.from + offset));
  });
}

function blockIdOf(node:Node):string | undefined {
  const id = node.attrs.id as unknown;
  return typeof id === 'string' ? id : undefined;
}

function enclosingBlockId($position:ResolvedPos):string {
  const selectedBlockId = $position.nodeAfter ? blockIdOf($position.nodeAfter) : undefined;
  if (selectedBlockId) return selectedBlockId;

  for (let depth = $position.depth; depth > 0; depth -= 1) {
    const id = blockIdOf($position.node(depth));
    if (id) return id;
  }
  throw new Error('Position is outside of any block');
}

function inlineContentOf(editor:AnyEditor, line:Node, content:Fragment) {
  return contentNodeToInlineContent(line.copy(content), editor.schema.inlineContentSchema, editor.schema.styleSchema);
}

// Inline nodes count as content, through their object replacement character.
function isBlank(fragment:Fragment):boolean {
  return fragment.textBetween(0, fragment.size, '', '\ufffc').trim() === '';
}
