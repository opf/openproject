import type { InlineContentFromConfig } from '@blocknote/core';
import type { Node as ProsemirrorNode } from 'prosemirror-model';
import type { AnyEditor } from '../editorTypes';
import type { WorkPackage } from '../openProjectTypes';
import type { InlineWpSize, BlockWpSize } from '../components/WorkPackage/types';
import { moveCursorAfterBlock } from './cursor';
import { BLOCK_WP_TYPE, INLINE_WP_TYPE } from './nodeTypes';
import { inlineNodeAt } from './inlineNodes';
import type { FoundInlineNode } from './inlineNodes';
import { PENDING_PREFIX } from '../components/InlineWorkPackage/callbacks';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyInlineNode = InlineContentFromConfig<any, any>;

export interface ChipContent {
  type:typeof INLINE_WP_TYPE;
  props:{ wpid:string; size:InlineWpSize; displayId:string };
}

/**
 * Finds a pending chip by its wpid. Only `pending:<uuid>` placeholder wpids
 * are unique in the document, so only those can be found reliably.
 */
export function findPendingInlineChip(doc:ProsemirrorNode, wpid:string):FoundInlineNode | null {
  if (!wpid.startsWith(PENDING_PREFIX)) return null;

  let found:FoundInlineNode | null = null;
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

/**
 * Replaces the inline chip at `position` with a block work package card,
 * splitting the surrounding paragraph content around it.
 */
export function promoteInlineChipToBlockAt(
  editor:AnyEditor,
  position:number,
  size:BlockWpSize = 'm'
):void {
  const node = inlineNodeAt(editor, position, INLINE_WP_TYPE);
  if (!node) return;

  // wpid must be a positive integer
  const wpid = Number(node.attrs.wpid);
  if (Number.isNaN(wpid) || wpid <= 0) return;
  // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
  const displayId = ((node.attrs.displayId || String(node.attrs.wpid)) as string);

  const $position = editor.transact((tr) => tr.doc.resolve(position));

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

  // One transaction, or undo strands the document half-converted: chip gone, no card.
  const containerBlockId = blockId;
  editor.transact(() => {
    if (contentBefore.length > 0) {
      editor.updateBlock(containerBlockId, { content: contentBefore });
      const [insertedBlock] = editor.insertBlocks([blockNode], containerBlockId, 'after');
      if (!insertedBlock?.id) return;
      placeAfterContent(editor, insertedBlock.id, contentAfter);
    } else {
      const [insertedBlock] = editor.insertBlocks([blockNode], containerBlockId, 'before');
      editor.removeBlocks([containerBlockId]);
      if (!insertedBlock?.id) return;
      placeAfterContent(editor, insertedBlock.id, contentAfter);
    }
  });
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
