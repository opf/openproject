import { Plugin, PluginKey } from 'prosemirror-state';
import type { Fragment, Node } from 'prosemirror-model';
import { contentNodeToInlineContent, isLinkInlineContent, isStyledTextInlineContent } from '@blocknote/core';
import type { BlockNoteEditor, InlineContent, StyleSchema, StyledText } from '@blocknote/core';
import { fetchWorkPackage, parseWorkPackageUrl } from '../services/openProjectApi';
import { isCurrentBlockEmpty } from '../utils/blockContent';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyInline = InlineContent<any, StyleSchema>;

interface Reference { wp:string; href:string }

// `href` is kept so an unresolvable reference can fall back to a plain link.
type PastePart = Reference | { keep:AnyInline };

function isReference(part:PastePart):part is Reference {
  return 'wp' in part;
}

/**
 * Turns pasted work package references of this OpenProject instance into card
 * blocks (empty paragraph, reference only) or inline chips (otherwise);
 * surrounding text and non-work-package links are kept untouched.
 *
 * Inspects the pasted slice, not the ClipboardEvent: BlockNote's
 * pasteFromClipboard re-dispatches text/markdown through `pasteText`/`pasteHTML`,
 * so no usable clipboard event reaches handlePaste.
 */
export const pasteWorkPackageLinkPluginKey = new PluginKey(
  'pasteWorkPackageLink'
);

export function pasteWorkPackageLinkPlugin(editor:AnyEditor):Plugin {
  return new Plugin({
    key: pasteWorkPackageLinkPluginKey,

    props: {
      handlePaste(_view, _event, slice) {
        const pasted = singlePastedTextblock(slice.content);
        if (!pasted) return false;

        const parts = pasteParts(editor, pasted);
        if (!parts.some(isReference)) return false;

        const block = editor.getTextCursorPosition()?.block;
        if (!block || block.type === 'codeBlock') return false;

        const sole = soleReference(parts);
        if (sole && isCurrentBlockEmpty(editor)) {
          void insertBlockWorkPackage(editor, sole, block.id);
          return true;
        }

        if (!canInsertInlineWorkPackage(editor)) return false;

        void insertInlineWorkPackages(editor, parts);
        return true;
      },
    },
  });
}

/**
 * Unwraps BlockNote's single-child paste wrappers (blockGroup/blockContainer)
 * to the sole pasted textblock; null when the paste spans multiple blocks.
 */
function singlePastedTextblock(fragment:Fragment):Node | null {
  if (fragment.childCount !== 1) return null;
  const child = fragment.child(0);
  if (child.isText || child.isTextblock) return child;
  return singlePastedTextblock(child.content);
}

/**
 * Reuses BlockNote's own node conversion so styles and non-work-package links
 * survive. References are matched by href, so a markdown `[label](url)` keeps
 * only the url and drops the label.
 */
function pasteParts(editor:AnyEditor, node:Node):PastePart[] {
  const inline:AnyInline[] = node.isTextblock
    ? contentNodeToInlineContent(node, editor.schema.inlineContentSchema, editor.schema.styleSchema)
    : bareTextInlineContent(node);

  const parts:PastePart[] = [];
  for (const item of inline) {
    if (isLinkInlineContent(item)) {
      const wp = parseWorkPackageUrl(item.href);
      parts.push(wp !== null ? { wp, href: item.href } : { keep: item });
    }
    else if (isStyledTextInlineContent(item)) {
      pushTextParts(parts, item);
    }
    else {
      parts.push({ keep: item });
    }
  }
  return parts;
}

// Fallback for a lone pasted text node with no wrapping textblock.
function bareTextInlineContent(node:Node):AnyInline[] {
  const link = node.marks.find((mark) => mark.type.name === 'link');
  if (link) {
    return [{ type: 'link', href: (link.attrs as { href:string }).href, content: [{ type: 'text', text: node.text ?? '', styles: {} }] }];
  }
  return [{ type: 'text', text: node.text ?? '', styles: {} }];
}

// Splits a plain text run around any bare work package URLs, keeping the
// surrounding text (with its styles) intact.
function pushTextParts(parts:PastePart[], item:StyledText<StyleSchema>):void {
  const text = item.text;
  const urls = /https?:\/\/[^\s]+/g;

  let last = 0;
  let match:RegExpExecArray | null;
  while ((match = urls.exec(text)) !== null) {
    const token = match[0].replace(/[.,;:!?)\]}'"]+$/, '');
    const wp = parseWorkPackageUrl(token);
    if (wp === null) continue;

    const before = text.slice(last, match.index);
    if (before) parts.push({ keep: { ...item, text: before } });
    parts.push({ wp, href: token });
    last = match.index + token.length;
    urls.lastIndex = last;
  }

  const rest = text.slice(last);
  if (rest) parts.push({ keep: { ...item, text: rest } });
}

/**
 * The single reference eligible for a card: exactly one reference and no
 * visible surrounding content (whitespace-only text does not count), else null.
 */
function soleReference(parts:PastePart[]):Reference | null {
  const references = parts.filter(isReference);
  const hasVisibleKeep = parts.some((part) =>
    'keep' in part && !(isStyledTextInlineContent(part.keep) && part.keep.text.trim() === '')
  );
  return references.length === 1 && !hasVisibleKeep ? references[0] : null;
}

/**
 * Numeric ids need no request; semantic ones (`PROJ-42`) resolve via the API,
 * returning null when the work package cannot be reached.
 */
async function resolveReference(identifier:string):Promise<{ wpid:number; displayId:string } | null> {
  if (/^\d+$/.test(identifier)) return { wpid: Number(identifier), displayId: identifier };
  try {
    const wp = await fetchWorkPackage(identifier);
    return { wpid: wp.id, displayId: wp.displayId };
  }
  catch {
    return null;
  }
}

// A plain link inline node, used as the fallback for a reference that cannot be resolved.
function plainLink(href:string) {
  return { type: 'link', href, content: [{ type: 'text', text: href, styles: {} }] };
}

async function insertBlockWorkPackage(editor:AnyEditor, reference:Reference, blockId:string):Promise<void> {
  const resolved = await resolveReference(reference.wp);
  if (!resolved) {
    const fallback = [{ type: 'paragraph', content: [plainLink(reference.href)] }];
    editor.replaceBlocks([blockId], fallback as Parameters<typeof editor.replaceBlocks>[1]);
    return;
  }
  editor.replaceBlocks([blockId], [{
    type: 'openProjectWorkPackageBlock',
    props: { wpid: resolved.wpid, displayId: resolved.displayId },
  } as Parameters<typeof editor.replaceBlocks>[1][number]]);
}

function canInsertInlineWorkPackage(editor:AnyEditor):boolean {
  return 'openProjectWorkPackageInline' in editor.schema.inlineContentSpecs;
}

/**
 * Swaps every resolved reference for a chip and keeps the surrounding content;
 * unresolvable references fall back to a plain link. A trailing space is added
 * when a chip ends the run so the cursor lands after it. Deliberately does not
 * reuse insertWpChip of HashMenu/editorUtils.ts: that helper strips a `#`
 * trigger, which on the paste path would delete a legitimate character.
 */
async function insertInlineWorkPackages(editor:AnyEditor, parts:PastePart[]):Promise<void> {
  const resolved = await Promise.all(
    parts.map((part) => (isReference(part) ? resolveReference(part.wp) : Promise.resolve(null)))
  );

  const content:unknown[] = [];
  let lastIsChip = false;
  parts.forEach((part, index) => {
    if (!isReference(part)) {
      content.push(part.keep);
      lastIsChip = false;
      return;
    }
    const wp = resolved[index];
    if (wp) {
      content.push({ type: 'openProjectWorkPackageInline', props: { wpid: String(wp.wpid), size: 's', displayId: wp.displayId } });
      lastIsChip = true;
    }
    else {
      content.push(plainLink(part.href));
      lastIsChip = false;
    }
  });

  if (content.length === 0) return;
  if (lastIsChip) content.push({ type: 'text', text: ' ', styles: {} });

  (editor.insertInlineContent as (content:unknown[]) => void)(content);
}
