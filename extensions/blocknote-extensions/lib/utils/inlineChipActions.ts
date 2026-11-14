import type { Node as ProsemirrorNode } from 'prosemirror-model';
import { NodeSelection } from 'prosemirror-state';
import type { AnyEditor } from '../editorTypes';
import type { WorkPackage } from '../openProjectTypes';
import type { InlineWpSize, BlockWpSize } from '../components/WorkPackage/types';
import { insertBlockInLine } from './blockInLine';
import { BLOCK_WP_TYPE, INLINE_WP_TYPE } from './nodeTypes';
import { hideSafariPhantomSelection } from './selection';

// Direct, position-based operations on inline work package chips.
//
// The chip's React component locates its own ProseMirror node via its DOM
// element (`findInlineChipAtDOM`) and mutates the document directly. This
// replaces the former event bridge (`wpBridge`) that addressed chips by a
// persisted `instanceId` prop — which leaked into clipboard HTML and required
// paste-time deduplication. A position uniquely identifies one node instance,
// so copies are independent by construction.

export interface FoundInlineChip {
  position:number;
  node:ProsemirrorNode;
}

export interface ChipContent {
  type:typeof INLINE_WP_TYPE;
  props:{ wpid:string; size:InlineWpSize; displayId:string };
}

/**
 * Resolves the chip's own DOM element to its ProseMirror node and position.
 *
 * `posAtDOM` may return the position directly before the atom node or the
 * position inside its node-view wrapper (off by one), so both candidates are
 * checked and verified by node type.
 */
export function findInlineChipAtDOM(
  editor:AnyEditor,
  chipDom:HTMLElement,
  type:string = INLINE_WP_TYPE,
):FoundInlineChip | null {
  const view = editor.prosemirrorView;
  if (!view) return null;

  let basePosition:number;
  try {
    basePosition = view.posAtDOM(chipDom, 0);
  } catch {
    return null;
  }

  for (const position of [basePosition, basePosition - 1]) {
    if (position < 0) continue;
    const node = view.state.doc.nodeAt(position);
    if (node?.type.name === type) return { position, node };
  }
  return null;
}

/** The inline content one chip is inserted from. */
export function chipContentOf(workPackage:WorkPackage, size:InlineWpSize):ChipContent {
  return {
    type: INLINE_WP_TYPE,
    props: { wpid: String(workPackage.id), size, displayId: workPackage.displayId },
  };
}

function chipAt(editor:AnyEditor, position:number, type:string = INLINE_WP_TYPE):ProsemirrorNode | null {
  return editor.transact((tr) => {
    const node = tr.doc.nodeAt(position);
    return node?.type.name === type ? node : null;
  });
}

export function selectInlineChipAt(editor:AnyEditor, position:number, type:string = INLINE_WP_TYPE):void {
  if (!chipAt(editor, position, type)) return;
  editor.transact((tr) => {
    tr.setSelection(NodeSelection.create(tr.doc, position));
  });
  hideSafariPhantomSelection(editor);
}

export function selectInlineChipAtDOM(editor:AnyEditor, chipDom:HTMLElement, type:string = INLINE_WP_TYPE):void {
  const chip = findInlineChipAtDOM(editor, chipDom, type);
  if (chip) selectInlineChipAt(editor, chip.position, type);
}

export function removeInlineChipAt(editor:AnyEditor, position:number):void {
  const node = chipAt(editor, position);
  if (!node) return;
  editor.transact((tr) => {
    tr.delete(position, position + node.nodeSize);
  });
}

/**
 * Replaces the inline chip at `position` with a block work package card,
 * splitting the surrounding paragraph content around it.
 */
export function promoteInlineChipToBlockAt(
  editor:AnyEditor,
  position:number,
  size:BlockWpSize = 'm'
):void {
  const node = chipAt(editor, position);
  if (!node) return;

  // wpid must be a positive integer
  const wpid = Number(node.attrs.wpid);
  if (Number.isNaN(wpid) || wpid <= 0) return;
  // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
  const displayId = ((node.attrs.displayId || String(node.attrs.wpid)) as string);

  const range = { from: position, to: position + node.nodeSize };
  insertBlockInLine(editor, range, { type: BLOCK_WP_TYPE, props: { wpid, size, displayId } });
}

/**
 * Replaces a block work package card with an inline chip in its own paragraph.
 */
export function convertBlockToInlineChip(
  editor:AnyEditor,
  blockId:string,
  wpid:number,
  size:InlineWpSize
):void {
  const block = editor.getBlock(blockId);
  if (!block) return;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/prefer-nullish-coalescing
  const displayId = (((block?.props as any)?.displayId || String(wpid)) as string);

  const paragraph = {
    type:'paragraph',
    content:[
      {
        type:INLINE_WP_TYPE,
        props:{ wpid:String(wpid), size, displayId },
      },
    ],
  } as Parameters<typeof editor.insertBlocks>[0][number];

  const [insertedParagraph] = editor.insertBlocks(
    [paragraph],
    blockId,
    'before'
  );

  editor.removeBlocks([blockId]);

  requestAnimationFrame(() => {
    if (!insertedParagraph?.id) return;
    editor.focus();
    editor.setTextCursorPosition(insertedParagraph.id, 'end');
  });
}
