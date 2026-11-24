import type { AnyEditor } from '../../editorTypes';
import { BLOCK_WP_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';
import { createPendingRegistry } from '../../utils/pending';
import { insertBlockInLine } from '../../utils/blockInLine';
import { findPendingInline, inPlaceHandlers, insertPendingInline, rangeWithSpacer } from '../../utils/pendingInline';
import { attributeInlineConfig } from './inlineConfig';
import type { AttributeNodeKind } from './externalHtml';
import type { AttributeChoice } from './types';

export interface AttributeInsertion {
  choice:AttributeChoice;
  kind:AttributeNodeKind;
}

export const pendingAttributes = createPendingRegistry<AttributeInsertion>();

export function insertPendingAttribute(editor:AnyEditor):void {
  const { type } = attributeInlineConfig;

  insertPendingInline(editor, pendingAttributes, {
    type,
    entry: (pendingWpid) => {
      const inline = inPlaceHandlers(editor, type, pendingWpid, ({ choice }:AttributeInsertion) => ({ ...choice }));
      return {
        onResolve: (insertion) => {
          if (insertion.kind === 'inline') inline.onResolve(insertion);
          else replaceWithBlock(editor, pendingWpid, insertion.choice);
        },
        onCancel: inline.onCancel,
      };
    },
  });
}

function replaceWithBlock(editor:AnyEditor, pendingWpid:string, choice:AttributeChoice):void {
  const found = findPendingInline(editor.prosemirrorState.doc, pendingWpid, attributeInlineConfig.type);
  if (!found) return;

  editor.focus();
  const [from, to] = rangeWithSpacer(editor.prosemirrorState.doc, found);
  insertBlockInLine(editor, { from, to }, { type: BLOCK_WP_ATTRIBUTE_TYPE, props: { ...choice } });
}
