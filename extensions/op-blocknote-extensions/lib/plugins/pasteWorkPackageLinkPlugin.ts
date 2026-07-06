import { Plugin, PluginKey } from 'prosemirror-state';
import type { BlockNoteEditor } from '@blocknote/core';
import { parseWorkPackageUrl } from '../services/openProjectApi';
import { isCurrentBlockEmpty } from '../utils/blockContent';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

/**
 * Transforms a pasted work package URL of the own OpenProject instance into
 * a rich work package link (BNE-47), reusing the slash-menu context rule:
 * pasting into an empty paragraph yields a card block, pasting into a
 * non-empty paragraph yields a regular inline chip. Any other pasted content
 * falls through to the default paste handling.
 *
 * The handler inspects the pasted slice instead of the ClipboardEvent:
 * BlockNote's pasteFromClipboard extension re-dispatches plain text and
 * markdown pastes through `prosemirrorView.pasteText`/`pasteHTML`, where no
 * clipboard event with usable data is guaranteed to reach the handlePaste
 * prop.
 */
export const pasteWorkPackageLinkPluginKey = new PluginKey(
  'pasteWorkPackageLink'
);

export function pasteWorkPackageLinkPlugin(editor:AnyEditor):Plugin {
  return new Plugin({
    key: pasteWorkPackageLinkPluginKey,

    props: {
      handlePaste(_view, _event, slice) {
        if (slice.content.childCount !== 1) return false;

        let text = '';
        slice.content.forEach((node) => {
          text += node.textContent;
        });
        text = text.trim();
        if (text === '' || /\s/.test(text)) return false;

        const wpid = parseWorkPackageUrl(text);
        if (wpid === null) return false;

        const block = editor.getTextCursorPosition()?.block as { type?:string } | undefined;
        if (!block || block.type === 'codeBlock') return false;

        if (isCurrentBlockEmpty(editor)) {
          insertBlockWorkPackage(editor, wpid);
        } else {
          insertInlineWorkPackage(editor, wpid);
        }
        return true;
      },
    },
  });
}

/**
 * Mirrors insertBlockWorkPackage of SlashMenu.tsx, but with the work package
 * already known from the pasted URL — no pending search popover is needed.
 */
function insertBlockWorkPackage(editor:AnyEditor, wpid:number):void {
  const blockId = editor.getTextCursorPosition()?.block?.id as string | undefined;
  if (!blockId) return;

  const block = {
    type: 'openProjectWorkPackageBlock' as const,
    props: { wpid, size: 'm' },
  } as Parameters<typeof editor.insertBlocks>[0][number];

  const [insertedBlock] = editor.insertBlocks([block], blockId, 'after');
  if (!insertedBlock?.id) return;

  editor.removeBlocks([blockId]);
}

/**
 * Mirrors insertWpChip of HashMenu/editorUtils.ts: chip plus trailing space,
 * leaving the cursor directly after the space.
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
