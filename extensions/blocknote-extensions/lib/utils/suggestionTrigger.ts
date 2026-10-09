import type { Node as ProsemirrorNode, ResolvedPos } from 'prosemirror-model';

// An atom node (an inline chip, a mention) reads as one object character, so
// the text on either side of it stays apart.
const leafText = (leaf:ProsemirrorNode) => (leaf.type.name === 'hardBreak' ? '\n' : '￼');

/** Up to `maxLength` characters of the textblock before `position`; null outside a textblock. */
export function textBefore(position:ResolvedPos, maxLength = Number.POSITIVE_INFINITY):string | null {
  if (!position.parent.isTextblock) return null;
  const end = position.parentOffset;
  return position.parent.textBetween(Math.max(0, end - maxLength), end, undefined, leafText);
}
