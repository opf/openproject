import type { Fragment, Node } from 'prosemirror-model';
import { contentNodeToInlineContent, isStyledTextInlineContent } from '@blocknote/core';
import type { InlineContent, StyleSchema } from '@blocknote/core';
import type { AnyEditor } from '../editorTypes';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type AnyInline = InlineContent<any, StyleSchema>;

/**
 * Unwraps BlockNote's single-child paste wrappers (blockGroup/blockContainer)
 * to the sole pasted textblock; null when the paste spans multiple blocks.
 */
export function singlePastedTextblock(fragment:Fragment):Node | null {
  if (fragment.childCount !== 1) return null;
  const child = fragment.child(0);
  if (child.isText || child.isTextblock) return child;
  return singlePastedTextblock(child.content);
}

/**
 * Reuses BlockNote's own node conversion so styles, links and other inline
 * content survive.
 */
export function pastedInlineContent(editor:AnyEditor, node:Node):AnyInline[] {
  return node.isTextblock
    ? contentNodeToInlineContent(node, editor.schema.inlineContentSchema, editor.schema.styleSchema)
    : bareTextInlineContent(node);
}

// Fallback for a lone pasted text node with no wrapping textblock.
function bareTextInlineContent(node:Node):AnyInline[] {
  const link = node.marks.find((mark) => mark.type.name === 'link');
  if (link) {
    return [{ type: 'link', href: (link.attrs as { href:string }).href, content: [{ type: 'text', text: node.text ?? '', styles: {} }] }];
  }
  return [{ type: 'text', text: node.text ?? '', styles: {} }];
}

export function isBlankText(item:AnyInline):boolean {
  return isStyledTextInlineContent(item) && item.text.trim() === '';
}
