import type { BlockNoteEditor, InlineContentFromConfig } from '@blocknote/core';
import type { Node as ProsemirrorNode } from 'prosemirror-model';
import { LinkIcon } from '@primer/octicons-react';
import i18n from '../services/i18n.ts';
import { getAliases } from '../services/slashMenuAliases';
import { registerInlineWpCallbacks, clearInlineWpCallbacks, makePendingWpid } from './InlineWorkPackage/callbacks';
import { makeInstanceId } from '../utils/id.ts';
import { pendingBlockRegistry } from './BlockWorkPackage/pendingBlockRegistry';
import { isCurrentBlockEmpty } from '../utils/blockContent.ts';
import type { AnyEditor } from './HashMenu/editorUtils';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyInlineNode = InlineContentFromConfig<any, any>;

function getBlockContent(
  editor:AnyEditor,
  blockId:string
):{ blockId:string; content:AnyInlineNode[] } | null {
  const block = editor.getBlock(blockId) as { id:string; content:AnyInlineNode[] } | null;
  if (!block) return null;
  return { blockId: block.id, content: block.content ?? [] };
}

function buildOnSelect(
  editor:AnyEditor,
  instanceId:string
):(wpid:number, displayId:string) => void {
  return (wpid:number, displayId:string) => {
    // Resolve the placeholder chip to its real work package by updating the node's
    // props in place. We use a ProseMirror `setNodeMarkup` transaction rather than
    // `editor.updateBlock` because updateBlock rebuilds the block and moves the
    // cursor to the block end, whereas setNodeMarkup maps the existing selection
    // through unchanged — leaving the cursor directly after the chip (where the
    // placeholder insertion left it). Crucially we do NOT dispatch a separate
    // selection transaction to reposition the cursor: under real-time
    // collaboration (Yjs/Hocuspocus) a selection change issued after the menu
    // insertion leaves the editor in a state where the next native keyboard input
    // (e.g. Backspace) is silently dropped. Relying on the preserved selection
    // avoids that entirely.
    const view = editor.prosemirrorView;
    let chipPosition:number | null = null;
    let chipNode:ProsemirrorNode | null = null;
    view.state.doc.descendants((node, position) => {
      if (chipPosition !== null) return false;
      if ((node.attrs as Record<string, unknown>)?.instanceId === instanceId) {
        chipPosition = position;
        chipNode = node;
        return false;
      }
      return true;
    });
    if (chipPosition === null || chipNode === null) return;

    const position:number = chipPosition;
    const existingAttributes = (chipNode as ProsemirrorNode).attrs;
    editor.focus();
    editor.transact((tr) => {
      tr.setNodeMarkup(position, undefined, { ...existingAttributes, wpid: String(wpid), displayId });
    });
  };
}

function buildOnCancel(
  editor:AnyEditor,
  blockId:string,
  pendingWpid:string,
  instanceId:string
):() => void {
  return () => {
    const current = getBlockContent(editor, blockId);
    if (!current) return;

    const updatedContent = current.content.filter((node) => {
      const n = node as { type:string; props?:{ wpid?:string } };
      return !(n.type === 'openProjectWorkPackageInline' && n.props?.wpid === pendingWpid);
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-argument
    editor.updateBlock(current.blockId, { content: updatedContent } as any);
    clearInlineWpCallbacks(instanceId);
  };
}

function insertBlockWorkPackage(editor:AnyEditor):void {
  const blockId = editor.getTextCursorPosition()?.block?.id as string | undefined;
  if (!blockId) return;

  const block = {
    type: 'openProjectWorkPackageBlock' as const,
    props: {},
  } as Parameters<typeof editor.insertBlocks>[0][number];

  const [insertedBlock] = editor.insertBlocks([block], blockId, 'after');
  if (!insertedBlock?.id) return;

  pendingBlockRegistry.add(insertedBlock.id);
  editor.removeBlocks([blockId]);
}

function insertInlineWorkPackage(editor:AnyEditor):void {
  const instanceId = makeInstanceId();
  const pendingWpid = makePendingWpid(instanceId);

  const blockId = editor.getTextCursorPosition()?.block?.id as string | undefined;
  if (!blockId) return;

  const onSelect = buildOnSelect(editor, instanceId);
  const onCancel = buildOnCancel(editor, blockId, pendingWpid, instanceId);

  registerInlineWpCallbacks(instanceId, onSelect, onCancel);

  try {
    (editor.insertInlineContent as (content:unknown[]) => void)([
      { type: 'openProjectWorkPackageInline', props: { wpid: pendingWpid, instanceId, size: 's' } },
    ]);
  } catch (error) {
    console.error('[inline-wp] insertInlineContent failed:', error);
    clearInlineWpCallbacks(instanceId);
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const workPackageSlashMenu = (editor:BlockNoteEditor<any>) => ({
  title: i18n.t('slashMenu.title'),
  onItemClick: () => {
    if (isCurrentBlockEmpty(editor)) {
      insertBlockWorkPackage(editor);
    } else {
      insertInlineWorkPackage(editor);
    }
  },
  aliases: [...getAliases()],
  group: 'OpenProject',
  icon: <LinkIcon size={18} />,
  subtext: i18n.t('slashMenu.subtext'),
});