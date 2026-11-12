import type { BlockNoteEditor } from '@blocknote/core';
import { CodeSquareIcon, LinkIcon, PlusIcon } from '@primer/octicons-react';
import i18n from '../services/i18n.ts';
import { getAliases } from '../services/slashMenuAliases';
import { insertPendingInlineWorkPackage } from './InlineWorkPackage/pending';
import { insertPendingAttribute } from './WorkPackageAttribute/pending';
import { pendingBlockRegistry } from './BlockWorkPackage/pendingBlockRegistry';
import { canBlockWorkPackageReplaceCurrentBlock } from '../utils/blockContent.ts';
import { canCreateWorkPackages } from '../services/openProjectApi.ts';
import type { AnyEditor } from '../editorTypes';
import type { PendingMode } from './WorkPackage/types';

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

function insertPendingWorkPackage(editor:AnyEditor, mode:PendingMode):void {
  if (canBlockWorkPackageReplaceCurrentBlock(editor)) {
    insertBlockWorkPackage(editor, mode);
  } else {
    insertPendingInlineWorkPackage(editor, mode);
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
const workPackageAttributeSlashMenu = (editor:BlockNoteEditor<any>) => ({
  title: i18n.t('slashMenu.attribute.title'),
  onItemClick: () => insertPendingAttribute(editor),
  aliases: [...getAliases('attribute')],
  group: 'OpenProject',
  icon: <CodeSquareIcon size={18} />,
  subtext: i18n.t('slashMenu.attribute.subtext'),
});

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getOpenProjectSlashMenuItems = (editor:BlockNoteEditor<any>) => [
  workPackageSlashMenu(editor),
  ...(canCreateWorkPackages() ? [createWorkPackageSlashMenu(editor)] : []),
  workPackageAttributeSlashMenu(editor),
];
