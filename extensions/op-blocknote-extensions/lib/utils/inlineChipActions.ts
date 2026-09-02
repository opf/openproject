import type { InlineContentFromConfig } from '@blocknote/core';
import type { Node as ProsemirrorNode } from 'prosemirror-model';
import { NodeSelection } from 'prosemirror-state';
import type { AnyEditor } from '../editorTypes';
import type { WorkPackage } from '../openProjectTypes';
import type { InlineWpSize, BlockWpSize } from '../components/WorkPackage/types';
import { moveCursorAfterBlock } from './cursor';
import { hideSafariPhantomSelection } from './selection';
import { PENDING_PREFIX } from '../components/InlineWorkPackage/callbacks';

// Direct, position-based operations on inline work package chips.
//
// The chip's React component locates its own ProseMirror node via its DOM
// element (`findInlineChipAtDOM`) and mutates the document directly. This
// replaces the former event bridge (`wpBridge`) that addressed chips by a
// persisted `instanceId` prop — which leaked into clipboard HTML and required
// paste-time deduplication. A position uniquely identifies one node instance,
// so copies are independent by construction.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyInlineNode = InlineContentFromConfig<any, any>;

const INLINE_WP_TYPE = 'openProjectWorkPackageInline';
const BLOCK_WP_TYPE = 'openProjectWorkPackageBlock';

export interface FoundInlineChip {
  position:number;
  node:ProsemirrorNode;
}

export interface ChipContent {
  type:typeof INLINE_WP_TYPE;
  props:{ wpid:string; size:InlineWpSize; displayId:string };
}

interface TextContent {
  type:'text';
  text:string;
  styles:Record<string, unknown>;
}

/**
 * Resolves the chip's own DOM element to its ProseMirror node and position.
 *
 * `posAtDOM` may return the position directly before the atom node or the
 * position inside its node-view wrapper (off by one), so both candidates are
 * checked and verified by node type.
 */
export function findInlineChipAtDOM(editor:AnyEditor, chipDom:HTMLElement):FoundInlineChip | null {
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
    if (node?.type.name === INLINE_WP_TYPE) return { position, node };
  }
  return null;
}

/**
 * Finds a pending chip by its wpid. Only `pending:<uuid>` placeholder wpids
 * are unique in the document, so only those can be found reliably.
 */
export function findPendingInlineChip(doc:ProsemirrorNode, wpid:string):FoundInlineChip | null {
  if (!wpid.startsWith(PENDING_PREFIX)) return null;

  let found:FoundInlineChip | null = null;
  doc.descendants((node, position) => {
    if (found) return false;
    if (node.type.name === INLINE_WP_TYPE && node.attrs.wpid === wpid) {
      found = { position, node };
      return false;
    }
    return true;
  });
  return found;
}

/** The inline content one chip is inserted from. */
export function chipContentOf(workPackage:WorkPackage, size:InlineWpSize):ChipContent {
  return {
    type: INLINE_WP_TYPE,
    props: { wpid: String(workPackage.id), size, displayId: workPackage.displayId },
  };
}

function spaceFollowsSelection(editor:AnyEditor):boolean {
  const { doc, selection } = editor.prosemirrorState;
  return doc.textBetween(selection.to, Math.min(selection.to + 1, doc.content.size)) === ' ';
}

export function insertWorkPackageChipOverSelection(
  editor:AnyEditor,
  workPackage:WorkPackage,
  size:InlineWpSize = 's'
):void {
  const content:(ChipContent | TextContent)[] = [chipContentOf(workPackage, size)];
  if (!spaceFollowsSelection(editor)) content.push({ type: 'text', text: ' ', styles: {} });

  (editor.insertInlineContent as (content:unknown[]) => void)(content);
  editor.focus();
}

function chipAt(editor:AnyEditor, position:number):ProsemirrorNode | null {
  const node = editor.prosemirrorState.doc.nodeAt(position);
  return node?.type.name === INLINE_WP_TYPE ? node : null;
}

export function selectInlineChipAt(editor:AnyEditor, position:number):void {
  if (!chipAt(editor, position)) return;
  editor.transact((tr) => {
    tr.setSelection(NodeSelection.create(tr.doc, position));
  });
  hideSafariPhantomSelection(editor);
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

  const $position = editor.prosemirrorState.doc.resolve(position);

  let blockId:string | undefined;
  for (let depth = $position.depth; depth > 0; depth--) {
    const ancestor = $position.node(depth);
    if (ancestor.type.name === 'blockContainer') {
      blockId = ancestor.attrs.id as string;
      break;
    }
  }
  if (!blockId) return;

  // The chip's ordinal among the inline chips of its paragraph. Chips are
  // atoms, so the nth chip in the ProseMirror children is the nth chip item
  // in the block's content array, regardless of how text runs are grouped.
  const parent = $position.parent;
  let ordinal = 0;
  for (let childIndex = 0; childIndex < $position.index(); childIndex += 1) {
    if (parent.child(childIndex).type.name === INLINE_WP_TYPE) ordinal += 1;
  }

  const block = editor.getBlock(blockId) as { id:string; content?:AnyInlineNode[] } | null;
  if (!block || !Array.isArray(block.content)) return;
  const content = block.content;

  let chipsSeen = -1;
  const chipIndex = content.findIndex((item) => {
    if ((item as { type:string }).type !== INLINE_WP_TYPE) return false;
    chipsSeen += 1;
    return chipsSeen === ordinal;
  });
  if (chipIndex === -1) return;

  const contentBefore = content.slice(0, chipIndex);
  const contentAfter = content.slice(chipIndex + 1);

  const blockNode = {
    type: BLOCK_WP_TYPE,
    props: { wpid, size, displayId },
  } as Parameters<typeof editor.insertBlocks>[0][number];

  if (contentBefore.length > 0) {
    editor.updateBlock(blockId, { content: contentBefore });
    const [insertedBlock] = editor.insertBlocks([blockNode], blockId, 'after');
    if (!insertedBlock?.id) return;
    placeAfterContent(editor, insertedBlock.id, contentAfter);
  } else {
    const [insertedBlock] = editor.insertBlocks([blockNode], blockId, 'before');
    editor.removeBlocks([blockId]);
    if (!insertedBlock?.id) return;
    placeAfterContent(editor, insertedBlock.id, contentAfter);
  }
}

function placeAfterContent(
  editor:AnyEditor,
  anchorBlockId:string,
  content:AnyInlineNode[]
):void {
  if (content.length > 0) {
    const [afterParagraph] = editor.insertBlocks(
      [{ type: 'paragraph', content }],
      anchorBlockId,
      'after'
    );
    requestAnimationFrame(() => {
      if (!afterParagraph?.id) return;
      editor.focus();
      editor.setTextCursorPosition(afterParagraph.id, 'start');
    });
  } else {
    moveCursorAfterBlock(editor, anchorBlockId);
  }
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
