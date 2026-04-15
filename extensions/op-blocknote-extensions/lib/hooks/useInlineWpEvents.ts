import { useEffect } from 'react';
import type { BlockNoteEditor, InlineContentFromConfig } from '@blocknote/core';
import { wpBridge, makeInstanceId } from '../../lib';
import type { InlineWpSize } from '../../lib';

//Uses `any` generics this hook is schema-agnostic by design.
type AnyEditor = BlockNoteEditor<any, any, any>;
type AnyInlineNode = InlineContentFromConfig<any, any>;

interface InlineWpNode {
  type:'inlineWorkPackage';
  props:{
    wpid:string;
    // instanceId MUST be globally unique per document
    instanceId:string;
    size:InlineWpSize;
  };
  content:unknown[];
}

// Must match InlineWpSize union update both if sizes change
const VALID_SIZES:Set<InlineWpSize> = new Set(['xxs', 'xs', 's', 'm']);

function isInlineWpNode(node:unknown): node is InlineWpNode {
  if (typeof node !== 'object' || node === null) return false;
  const n = node as Record<string, unknown>;
  if (n['type'] !== 'inlineWorkPackage') return false;

  const props = n['props'];
  if (typeof props !== 'object' || props === null) return false;

  const p = props as Record<string, unknown>;
  return (
    typeof p['instanceId'] === 'string' &&
    typeof p['wpid'] === 'string' &&
    typeof p['size'] === 'string' && VALID_SIZES.has(p['size'] as InlineWpSize)
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

    const content = (block.content ?? []) as AnyInlineNode[];
    const chip = content.find(
      (node):node is AnyInlineNode & InlineWpNode =>
        isInlineWpNode(node) && node.props.instanceId === instanceId
    );

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
function updateInlineChip(
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

  editor.updateBlock(found.blockId, { content:updatedContent } as any);
  return found;
}

function moveCursorAfter(editor:AnyEditor, blockId:string):void {
  requestAnimationFrame(() => {
    editor.focus();
    editor.setTextCursorPosition(blockId, 'end');

    const cursor = editor.getTextCursorPosition();
    if (!cursor?.nextBlock && cursor?.block) {
      editor.insertBlocks([{ type: 'paragraph', content:[] }], cursor.block.id, 'after');
    }

    const updated = editor.getTextCursorPosition();
    if (updated?.nextBlock) {
      editor.setTextCursorPosition(updated.nextBlock.id, 'start');
    }
  });
}

function handleResize(editor:AnyEditor, instanceId:string, size:InlineWpSize):void {
  if (size === 'm') {
    handlePromoteToBlock(editor, instanceId);
    return;
  }
  updateInlineChip(editor, instanceId, (chip) => ({
    ...chip,
    props:{ ...chip.props, size },
  }));
}

function handleDelete(editor:AnyEditor, instanceId:string):void {
  updateInlineChip(editor, instanceId, () => null);
}

function handlePromoteToBlock(editor:AnyEditor, instanceId:string):void {
  const found = findInlineChip(editor, instanceId);
  if (!found) return;

  // wpid must be a positive integer
  const wpid = Number(found.chip.props.wpid);
  if (Number.isNaN(wpid) || wpid <= 0) return;

  updateInlineChip(editor, instanceId, () => null);

  const [insertedBlock] = editor.insertBlocks(
    [{ type:'openProjectWorkPackage', props: { wpid, initialized:true } } as any],
    found.blockId,
    'after'
  );

  if (insertedBlock?.id) {
    moveCursorAfter(editor, insertedBlock.id);
  }
}

function handleConvertToInline(editor: AnyEditor, wpid: number, size: InlineWpSize, blockId: string): void {
  const block = editor.getBlock(blockId);
  if (!block) return;

  const instanceId = makeInstanceId();

  const [insertedParagraph] = editor.insertBlocks(
    [
      {
        type: 'paragraph',
        content: [
          { type: 'inlineWorkPackage', props: { wpid: String(wpid), instanceId, size } },
        ],
      } as any,
    ],
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
    const offResize = wpBridge.onResize(({ instanceId, size }) => handleResize(editor, instanceId, size));
    const offDelete = wpBridge.onDelete(({ instanceId }) => handleDelete(editor, instanceId));
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