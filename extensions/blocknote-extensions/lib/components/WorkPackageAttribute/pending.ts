import type { AnyEditor } from '../../editorTypes';
import { createPendingRegistry } from '../../utils/pending';
import { insertPendingInline, inPlaceHandlers } from '../../utils/pendingInline';
import { attributeInlineConfig } from './inlineConfig';
import type { AttributeDisplay } from './externalHtml';

export interface AttributeChoice {
  wpid:string;
  displayId:string;
  attribute:string;
  display:AttributeDisplay;
}

export const pendingAttributes = createPendingRegistry<AttributeChoice>();

export function insertPendingAttribute(editor:AnyEditor):void {
  const { type } = attributeInlineConfig;

  insertPendingInline(editor, pendingAttributes, {
    type,
    entry: (pendingWpid) => inPlaceHandlers(editor, type, pendingWpid, (choice:AttributeChoice) => ({ ...choice })),
  });
}
