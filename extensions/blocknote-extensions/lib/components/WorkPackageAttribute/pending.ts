import type { AnyEditor } from '../../editorTypes';
import { canBlockWorkPackageReplaceCurrentBlock } from '../../utils/blockContent';
import { findPendingInlineChip, pendingInlineChipRange, removePendingInlineChip } from '../../utils/inlineChipActions';
import { BLOCK_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';
import { makePendingWpid, PENDING_PREFIX } from '../InlineWorkPackage/callbacks';
import { attributeInlineConfig } from './inlineConfig';
import type { AttributeNodeKind } from './externalHtml';
import type { AttributeChoice } from './types';

interface PendingAttribute {
  onInsert:(choice:AttributeChoice, kind:AttributeNodeKind) => void;
  onCancel:() => void;
}

// Bridges the slash menu to the placeholder chip that hosts the insert dialog.
const registry = new Map<string, PendingAttribute>();

export function getPendingAttribute(wpid:string):PendingAttribute | undefined {
  return wpid.startsWith(PENDING_PREFIX) ? registry.get(wpid) : undefined;
}

export function insertPendingAttribute(editor:AnyEditor):void {
  const pendingWpid = makePendingWpid();

  // Resolved in place with setNodeMarkup, for the same collaboration reasons
  // as pending work package chips (see SlashMenu).
  const onInsert = (choice:AttributeChoice, kind:AttributeNodeKind) => {
    registry.delete(pendingWpid);
    const found = findPendingInlineChip(editor.prosemirrorState.doc, pendingWpid, attributeInlineConfig.type);
    if (!found) return;

    editor.focus();
    if (kind === 'inline') {
      editor.transact((tr) => {
        tr.setNodeMarkup(found.position, undefined, { ...found.node.attrs, ...choice });
      });
      return;
    }

    // A long text takes the place of the placeholder's line, or follows it when
    // that line holds more.
    const [from, to] = pendingInlineChipRange(editor.prosemirrorState.doc, found);
    editor.transact(() => {
      editor.transact((tr) => {
        tr.delete(from, to);
      });
      const line = editor.getTextCursorPosition().block;
      const block = { type: BLOCK_ATTRIBUTE_TYPE, props: choice } as Parameters<typeof editor.insertBlocks>[0][number];
      if (canBlockWorkPackageReplaceCurrentBlock(editor)) editor.replaceBlocks([line], [block]);
      else editor.insertBlocks([block], line, 'after');
    });
  };

  const onCancel = () => {
    registry.delete(pendingWpid);
    const found = findPendingInlineChip(editor.prosemirrorState.doc, pendingWpid, attributeInlineConfig.type);
    editor.focus();
    if (found) removePendingInlineChip(editor, found);
  };

  registry.set(pendingWpid, { onInsert, onCancel });

  try {
    (editor.insertInlineContent as (content:unknown[]) => void)([
      { type: attributeInlineConfig.type, props: { wpid: pendingWpid } },
      { type: 'text', text: ' ', styles: {} },
    ]);
  } catch (error) {
    console.error('[wp-attribute] insertInlineContent failed:', error);
    registry.delete(pendingWpid);
  }
}
