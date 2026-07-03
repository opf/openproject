import type { BlockNoteEditor } from '@blocknote/core';
import type { InlineWpSize } from '../WorkPackage/types';
import type { WorkPackage } from '../../openProjectTypes';
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type AnyEditor = BlockNoteEditor<any, any, any>;

interface RawNode {
  type:string;
  text?:string;
  props?:Record<string, string | undefined>;
  [key:string]:unknown;
}

/**
 * Determines the inline chip size based on how many `#` characters
 * the user typed before the search query in the current block.
 *
 *   #query -> "xxs" (ID only)
 *   ##query -> "xs" (ID + Type + Subject)
 *   ###query -> "s" (ID + Type + Status + Subject)
 */
export function getSizeFromCurrentBlock(editor:AnyEditor):InlineWpSize {
  const block = editor.getTextCursorPosition()?.block;
  if (!block) return 'xxs';

  const content = (block.content ?? []) as RawNode[];
  let lastHashCount:number | null = null;

  for (const node of content) {
    if (node.type !== 'text') continue;
    const text = node.text ?? '';
    const matches = [...text.matchAll(/#+/g)];
    if (matches.length > 0) {
      lastHashCount = matches[matches.length - 1][0].length;
    }
  }

  if (lastHashCount === null) return 'xxs';
  if (lastHashCount >= 3) return 's';
  if (lastHashCount === 2) return 'xs';
  return 'xxs';
}

/**
 * Inserts a chip followed by a trailing space at the cursor, then removes any
 * leftover trigger hashes immediately before it.
 *
 * The chip and its trailing space are inserted together; `insertInlineContent`
 * leaves the cursor directly after the space, which is exactly where we want it.
 * We deliberately avoid placing the cursor with a separate selection
 * transaction — under real-time collaboration (Yjs/Hocuspocus) any selection
 * change dispatched after the menu insertion leaves the editor in a state where
 * the following native keyboard input (e.g. Backspace) is silently dropped.
 * Relying on the natural post-insertion cursor sidesteps that entirely.
 */
export function insertWpChip(editor:AnyEditor, wp:WorkPackage, size:InlineWpSize):void {
  (editor.insertInlineContent as (content:unknown[]) => void)([
    { type: 'openProjectWorkPackageInline', props: { wpid: String(wp.id), size, displayId: wp.displayId } },
    { type: 'text', text: ' ', styles: {} },
  ]);

  // The chip (nodeSize 1) and its trailing space (length 1) were just inserted;
  // insertInlineContent leaves the cursor right after the space.
  const chipPosition = editor.prosemirrorState.selection.from - 2;
  removeTriggerBeforeChip(editor, chipPosition);
  editor.focus();
}

/**
 * Removes the leftover trigger hashes (`#`/`##`) that BlockNote's suggestion menu
 * leaves directly before the chip for `##`/`###` triggers.
 */
export function removeTriggerBeforeChip(editor:AnyEditor, chipPosition:number):void {
  const { doc } = editor.prosemirrorState;

  const chipNode = doc.nodeAt(chipPosition);
  if (chipNode?.type.name !== 'openProjectWorkPackageInline') return;

  const nodeBeforeChip = doc.resolve(chipPosition).nodeBefore;
  if (!nodeBeforeChip?.isText || nodeBeforeChip.text == null) return;

  const match = /#+$/.exec(nodeBeforeChip.text);
  if (!match) return;

  const triggerStart = chipPosition - (nodeBeforeChip.text.length - match.index);
  editor.transact((tr) => {
    tr.delete(triggerStart, chipPosition);
  });
}
