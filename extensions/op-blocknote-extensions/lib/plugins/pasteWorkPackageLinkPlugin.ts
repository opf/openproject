import { Plugin, PluginKey } from 'prosemirror-state';
import type { Fragment, Node } from 'prosemirror-model';
import type { BlockNoteEditor } from '@blocknote/core';
import { parseWorkPackageUrl } from '../services/openProjectApi';
import { isCurrentBlockEmpty } from '../utils/blockContent';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

/**
 * Turns a pasted work package URL (or markdown link) of this OpenProject
 * instance into a card block (empty paragraph) or inline chip (non-empty);
 * anything else falls through to the default paste.
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

        const text = pasted.textContent.trim();
        const url = singleLinkHref(pasted) ?? (text !== '' && !/\s/.test(text) ? text : null);
        const wpid = url === null ? null : parseWorkPackageUrl(url);
        if (wpid === null) return false;

        const block = editor.getTextCursorPosition()?.block;
        if (!block || block.type === 'codeBlock') return false;

        if (isCurrentBlockEmpty(editor)) {
          insertBlockWorkPackage(editor, wpid, block.id);
        } else if (canInsertInlineWorkPackage(editor)) {
          insertInlineWorkPackage(editor, wpid);
        } else {
          return false;
        }
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
 * The link href when the textblock is solely link-marked text sharing one
 * href, else null. Matching on href drops markdown `[label](url)` markup.
 */
function singleLinkHref(node:Node):string | null {
  const inline:Node[] = [];
  if (node.isText) {
    inline.push(node);
  } else {
    node.content.forEach((part) => inline.push(part));
  }

  let href:string | null = null;
  for (const part of inline) {
    if (part.isText && part.textContent.trim() === '') continue;
    const mark = part.marks.find((m) => m.type.name === 'link');
    const target = mark ? (mark.attrs as { href?:string }).href : undefined;
    if (!target || (href !== null && target !== href)) return null;
    href = target;
  }
  return href;
}

function insertBlockWorkPackage(editor:AnyEditor, wpid:number, blockId:string):void {
  editor.replaceBlocks([blockId], [{
    type: 'openProjectWorkPackageBlock',
    props: { wpid },
  } as Parameters<typeof editor.replaceBlocks>[1][number]]);
}

function canInsertInlineWorkPackage(editor:AnyEditor):boolean {
  return 'openProjectWorkPackageInline' in editor.schema.inlineContentSpecs;
}

/**
 * Inserts a resolved chip plus a trailing space, leaving the cursor after it.
 * Deliberately does not reuse insertWpChip of HashMenu/editorUtils.ts: that
 * helper strips a `#` trigger before the chip, which on the paste path would
 * delete a legitimate character rather than a trigger.
 */
function insertInlineWorkPackage(editor:AnyEditor, wpid:number):void {
  (editor.insertInlineContent as (content:unknown[]) => void)([
    {
      type: 'openProjectWorkPackageInline',
      props: { wpid: String(wpid), size: 's', displayId: String(wpid) },
    },
    { type: 'text', text: ' ', styles: {} },
  ]);
}
