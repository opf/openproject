import type { AnyEditor } from '../../editorTypes';
import { makePendingWpid, PENDING_PREFIX } from '../InlineWorkPackage/callbacks';
import { findPendingInlineChip, removePendingInlineChip } from '../../utils/inlineChipActions';
import { attributeInlineConfig } from './inlineConfig';
import type { AttributeDisplay } from './externalHtml';

export interface AttributeChoice {
  wpid:string;
  displayId:string;
  attribute:string;
  display:AttributeDisplay;
}

interface PendingAttribute {
  onInsert:(choice:AttributeChoice) => void;
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
  const onInsert = (choice:AttributeChoice) => {
    registry.delete(pendingWpid);
    const found = findPendingInlineChip(editor.prosemirrorState.doc, pendingWpid, attributeInlineConfig.type);
    if (!found) return;

    editor.focus();
    editor.transact((tr) => {
      tr.setNodeMarkup(found.position, undefined, { ...found.node.attrs, ...choice });
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
