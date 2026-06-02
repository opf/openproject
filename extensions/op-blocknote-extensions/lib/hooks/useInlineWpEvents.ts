import { useEffect } from 'react';
import type { BlockNoteEditor, InlineContentFromConfig } from '@blocknote/core';
import { wpBridge, makeInstanceId } from '../../lib';
import type { InlineWpSize, BlockWpSize, WpSize } from '../../lib';
import { moveCursorAfterBlock } from '../utils/cursor';

type AnyEditor = BlockNoteEditor<any, any, any>;
type AnyInlineNode = InlineContentFromConfig<any, any>;

interface InlineWpNode {
  type:'openProjectWorkPackageInline';
  props:{
    wpid:string;
    instanceId:string;
    size:InlineWpSize;
  };
  content: AnyInlineNode[];
}

const VALID_INLINE_SIZES:Set<InlineWpSize> = new Set(['xxs', 'xs', 's']);

function isInlineWpNode(node:unknown): node is InlineWpNode {
  if (typeof node !== 'object' || node === null) return false;

  const n = node as Record<string, unknown>;
  if (n['type'] !== 'openProjectWorkPackageInline') return false;

  const props = n['props'];
  if (typeof props !== 'object' || props === null) return false;

  const p = props as Record<string, unknown>;
  return (
    typeof p['instanceId'] === 'string' &&
    typeof p['wpid'] === 'string' &&
    VALID_INLINE_SIZES.has(p['size'] as InlineWpSize)
  );
}

function asInlineNode(node:InlineWpNode):AnyInlineNode {
  return node as unknown as AnyInlineNode;
}

interface FoundInlineBlock {
  blockId:string;
  content:AnyInlineNode[];
  chip:InlineWpNode;
}

function findInlineChip(editor:AnyEditor, instanceId:string):FoundInlineBlock | null {
  let found: FoundInlineBlock | null = null;

  editor.forEachBlock((block) => {
    if (found) return false;

    if (!Array.isArray(block.content)) return true; 
    
    const content = (block.content ?? []) as AnyInlineNode[];
    const chip = content.find(
      (node) => isInlineWpNode(node) && node.props.instanceId === instanceId
    ) as InlineWpNode | undefined;

    if (chip) {
      found = { blockId:block.id, content, chip };
      return false;
    }

    return true;
  });

  return found;
}

// The updater returns the updated node, or null to remove it.
// Returns found so the caller can use it without a second traversal.
export function updateInlineChip(
  editor:AnyEditor,
  instanceId:string,
  updater:(chip:InlineWpNode) => InlineWpNode | null
): FoundInlineBlock | null {
  const found = findInlineChip(editor, instanceId);
  if (!found) return null;

  const updatedContent = found.content.reduce<AnyInlineNode[]>((acc, node) => {
    if (!isInlineWpNode(node) || node.props.instanceId !== instanceId) {
      acc.push(node);
      return acc;
    }
    const updated = updater(node);
    if (updated !== null) acc.push(asInlineNode(updated));
    return acc;
  }, []);

  editor.updateBlock(found.blockId, { content:updatedContent });
  return found;
}

function handleResize(editor:AnyEditor, instanceId:string, size:WpSize):void {
  const isBlockSize = size === 'm' || size === 'l' || size === 'xl';

  if (isBlockSize) {
    handlePromoteToBlock(editor, instanceId, size as BlockWpSize);
    return;
  }

  updateInlineChip(editor, instanceId, (chip) => ({
    ...chip,
    props:{ ...chip.props, size:size as InlineWpSize },
  }));
}

function handleDelete(editor:AnyEditor, instanceId:string):void {
  updateInlineChip(editor, instanceId, () => null);
}

function handlePromoteToBlock(
  editor:AnyEditor,
  instanceId:string,
  size:BlockWpSize = 'm'
):void {
  const found = findInlineChip(editor, instanceId);
  if (!found) return;

  // wpid must be a positive integer
  const wpid = Number(found.chip.props.wpid);
  if (Number.isNaN(wpid) || wpid <= 0) return;
  const displayId = (found.chip.props as any).displayId || String(found.chip.props.wpid);

  const chipIndex = found.content.findIndex(
    (node) => isInlineWpNode(node) && node.props.instanceId === instanceId
  );
  if (chipIndex === -1) return;

  const contentBefore = found.content.slice(0, chipIndex);
  const contentAfter  = found.content.slice(chipIndex + 1);

  const blockNode = {
    type: 'openProjectWorkPackageBlock',
    props: { wpid, initialized: true, size, displayId },
  } as Parameters<typeof editor.insertBlocks>[0][number];

  if (contentBefore.length > 0) {
    editor.updateBlock(found.blockId, { content: contentBefore });
    const [insertedBlock] = editor.insertBlocks([blockNode], found.blockId, 'after');
    if (!insertedBlock?.id) return;
    placeAfterContent(editor, insertedBlock.id, contentAfter);
  } else {
    const [insertedBlock] = editor.insertBlocks([blockNode], found.blockId, 'before');
    editor.removeBlocks([found.blockId]);
    if (!insertedBlock?.id) return;
    placeAfterContent(editor, insertedBlock.id, contentAfter);
  }
}

function placeAfterContent(
  editor: AnyEditor,
  anchorBlockId: string,
  content: AnyInlineNode[]
): void {
  if (content.length > 0) {
    const [afterParagraph] = editor.insertBlocks(
      [{ type: 'paragraph', content }],
      anchorBlockId,
      'after'
    );
    requestAnimationFrame(() => {
      editor.focus();
      editor.setTextCursorPosition(afterParagraph.id, 'start');
    });
  } else {
    moveCursorAfterBlock(editor, anchorBlockId);
  }
}

function handleConvertToInline(
  editor:AnyEditor,
  wpid:number,
  size:InlineWpSize,
  blockId:string
):void {
  const block = editor.getBlock(blockId);
  if (!block) return;
  const displayId = (block?.props as any)?.displayId || String(wpid);

  const instanceId = makeInstanceId();

  const paragraph = {
    type:'paragraph',
    content:[
      {
        type:'openProjectWorkPackageInline',
        props:{ wpid:String(wpid), instanceId, size, displayId },
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

// editor instance is stable for the lifetime of the component re-subscription only on editor replacement
export function useInlineWpEvents(editor: AnyEditor):void {
  useEffect(() => {
    const offResize = wpBridge.onResize(({ instanceId, size }) =>
      handleResize(editor, instanceId, size)
    );

    const offDelete = wpBridge.onDelete(({ instanceId }) =>
      handleDelete(editor, instanceId)
    );

    const offToInline = wpBridge.onConvertToInline(({ wpid, size, blockId }) =>
      handleConvertToInline(editor, wpid, size, blockId)
    );

    return () => {
      offResize();
      offDelete();
      offToInline();
    };
  }, [editor]);
}