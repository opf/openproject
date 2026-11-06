import { blockToNode } from '@blocknote/core';
import { UniqueID } from '@blocknote/core/extensions';
import type { Fragment, Node, ResolvedPos } from 'prosemirror-model';
import type { Transaction } from 'prosemirror-state';
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
    const lineId = $from.parent.inlineContent ? blockIdOf($from.node(-1)) : undefined;

    if (!lineId) {
      if ($from.parent.inlineContent) tr.delete(from, to);
      return editor.insertBlocks([insertion], enclosingBlockId($from), 'after')[0].id;
    }

    const before = $from.parent.content.cut(0, $from.parentOffset);
    const after = $from.parent.content.cut($from.parentOffset + to - from);
    if (isBlank(before) && isBlank(after)) {
      editor.updateBlock(lineId, insertion);
      return lineId;
    }

    tr.delete(from, to);
    const $position = tr.doc.resolve(from);
    const blockNode = blockToNode(insertion, editor.pmSchema);
    if (isBlank(before)) {
      tr.delete($position.start(), from + leadingSpaceLength(after));
      tr.insert($position.before(-1), blockNode);
    }
    else if (isBlank(after)) {
      tr.delete(from, $position.end());
      insertAfterLine(tr, from, blockNode);
    }
    else {
      tr.delete(from, from + leadingSpaceLength(after));
      splitLine(tr, from);
      tr.insert(tr.doc.resolve(from).after(-1), blockNode);
    }
    return blockNode.attrs.id as string;
  });
}

/**
 * Mirrors BlockNote's `splitBlockTr`, which is not exported. Rewriting the line through
 * `updateBlock` instead would drop the marks BlockNote leaves out of its blocks
 * (`blocknoteIgnore`), such as comments. The nested blocks go along with the last part.
 */
function splitLine(tr:Transaction, position:number):void {
  const $position = tr.doc.resolve(position);
  const container = $position.node(-1);
  const line = $position.parent;
  tr.split(position, 2, [
    { type: container.type, attrs: { ...container.attrs, id: UniqueID.options.generateID() } },
    { type: line.type, attrs: line.attrs },
  ]);
}

// The nested blocks follow the line, so they go along with the block that ends it.
function insertAfterLine(tr:Transaction, position:number, blockNode:Node):void {
  const $position = tr.doc.resolve(position);
  const lineEnd = $position.after();
  const container = $position.node(-1);
  const nested = container.childCount > 1 ? container.lastChild : null;
  if (nested) tr.delete(lineEnd, lineEnd + nested.nodeSize);
  tr.insert(lineEnd + 1, nested ? blockNode.copy(blockNode.content.addToEnd(nested)) : blockNode);
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

// Inline nodes count as content, through their object replacement character.
function textOf(fragment:Fragment):string {
  return fragment.textBetween(0, fragment.size, '', '\ufffc');
}

function isBlank(fragment:Fragment):boolean {
  return textOf(fragment).trim() === '';
}

// A single space at the start of a new line is a leftover of the split; more are intentional.
function leadingSpaceLength(fragment:Fragment):number {
  return /^\s(?!\s)/.test(textOf(fragment)) ? 1 : 0;
}
