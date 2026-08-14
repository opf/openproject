import type { BlockNoteEditor } from '@blocknote/core';
import { LinkIcon, PlusIcon } from '@primer/octicons-react';
import i18n from '../services/i18n.ts';
import { getAliases } from '../services/slashMenuAliases';
import { registerInlineWpCallbacks, clearInlineWpCallbacks, makePendingWpid } from './InlineWorkPackage/callbacks';
import { findPendingInlineChip } from '../utils/inlineChipActions';
import { pendingBlockRegistry } from './BlockWorkPackage/pendingBlockRegistry';
import { isCurrentBlockEmpty } from '../utils/blockContent.ts';
import type { AnyEditor } from '../editorTypes';
import type { PendingMode } from './WorkPackage/types';

function buildOnSelect(
  editor:AnyEditor,
  pendingWpid:string
):(wpid:number, displayId:string) => void {
  return (wpid:number, displayId:string) => {
    // Resolve the placeholder chip to its real work package by updating the node's
    // props in place. We use a ProseMirror `setNodeMarkup` transaction rather than
    // `editor.updateBlock` because updateBlock rebuilds the block and moves the
    // cursor to the block end, whereas setNodeMarkup maps the existing selection
    // through unchanged — leaving the cursor directly after the chip's trailing
    // space (where the placeholder insertion left it). Crucially we do NOT dispatch a separate
    // selection transaction to reposition the cursor: under real-time
    // collaboration (Yjs/Hocuspocus) a selection change issued after the menu
    // insertion leaves the editor in a state where the next native keyboard input
    // (e.g. Backspace) is silently dropped. Relying on the preserved selection
    // avoids that entirely.
    const found = findPendingInlineChip(editor.prosemirrorState.doc, pendingWpid);
    if (!found) return;

    editor.focus();
    editor.transact((tr) => {
      tr.setNodeMarkup(found.position, undefined, { ...found.node.attrs, wpid: String(wpid), displayId });
    });
  };
}

function buildOnCancel(
  editor:AnyEditor,
  pendingWpid:string
):() => void {
  return () => {
    const found = findPendingInlineChip(editor.prosemirrorState.doc, pendingWpid);
    if (found) {
      editor.focus();
      editor.transact((tr) => {
        tr.delete(found.position, found.position + found.node.nodeSize);
      });
    }
    clearInlineWpCallbacks(pendingWpid);
  };
}

function insertBlockWorkPackage(editor:AnyEditor, mode:PendingMode):void {
  const blockId = editor.getTextCursorPosition()?.block?.id as string | undefined;
  if (!blockId) return;

  const block = {
    type: 'openProjectWorkPackageBlock' as const,
    props: {},
  } as Parameters<typeof editor.insertBlocks>[0][number];

  const [insertedBlock] = editor.insertBlocks([block], blockId, 'after');
  if (!insertedBlock?.id) return;

  pendingBlockRegistry.add(insertedBlock.id, mode);
  editor.removeBlocks([blockId]);
}

function insertInlineWorkPackage(editor:AnyEditor, mode:PendingMode):void {
  const pendingWpid = makePendingWpid();

  const onSelect = buildOnSelect(editor, pendingWpid);
  const onCancel = buildOnCancel(editor, pendingWpid);

  registerInlineWpCallbacks(pendingWpid, onSelect, onCancel, mode);

  try {
    (editor.insertInlineContent as (content:unknown[]) => void)([
      { type: 'openProjectWorkPackageInline', props: { wpid: pendingWpid, size: 's' } },
      { type: 'text', text: ' ', styles: {} },
    ]);
  } catch (error) {
    console.error('[inline-wp] insertInlineContent failed:', error);
    clearInlineWpCallbacks(pendingWpid);
  }
}

function insertPendingWorkPackage(editor:AnyEditor, mode:PendingMode):void {
  if (isCurrentBlockEmpty(editor)) {
    insertBlockWorkPackage(editor, mode);
  } else {
    insertInlineWorkPackage(editor, mode);
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const workPackageSlashMenu = (editor:BlockNoteEditor<any>) => ({
  title: i18n.t('slashMenu.title'),
  onItemClick: () => insertPendingWorkPackage(editor, 'link'),
  aliases: [...getAliases('link')],
  group: 'OpenProject',
  icon: <LinkIcon size={18} />,
  subtext: i18n.t('slashMenu.subtext'),
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const createWorkPackageSlashMenu = (editor:BlockNoteEditor<any>) => ({
  title: i18n.t('slashMenu.create.title'),
  onItemClick: () => insertPendingWorkPackage(editor, 'create'),
  aliases: [...getAliases('create')],
  group: 'OpenProject',
  icon: <PlusIcon size={18} />,
  subtext: i18n.t('slashMenu.create.subtext'),
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getOpenProjectSlashMenuItems = (editor:BlockNoteEditor<any>) => [
  workPackageSlashMenu(editor),
  createWorkPackageSlashMenu(editor),
];
