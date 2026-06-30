import type { BlockNoteEditor } from '@blocknote/core';
import type { InlineWpSize } from '../WorkPackage/types';
import { makeInstanceId } from '../../utils/id.ts';
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
 * Inserts a chip at the cursor and removes the `#query` trigger before it.
 *
 * The chip is inserted on its own (no trailing space): `insertInlineContent`
 * leaves the cursor directly after the chip, which is exactly where we want it.
 * We deliberately avoid placing the cursor with a separate selection
 * transaction — under real-time collaboration (Yjs/Hocuspocus) any selection
 * change dispatched after the menu insertion leaves the editor in a state where
 * the following native keyboard input (e.g. Backspace) is silently dropped.
 * Relying on the natural post-insertion cursor sidesteps that entirely.
 */
export function insertWpChip(editor:AnyEditor, wp:WorkPackage, size:InlineWpSize):void {
  const instanceId = makeInstanceId();

  (editor.insertInlineContent as (content:unknown[]) => void)([
    { type: 'openProjectWorkPackageInline', props: { wpid: String(wp.id), instanceId, size, displayId: wp.displayId } },
  ]);

  removeTriggerBeforeChip(editor, instanceId);
  editor.focus();
}

/**
 * Trims the trailing `#query` trigger from the text node directly before the chip.
 *
 * Implemented with a ProseMirror delete transaction rather than `editor.updateBlock`.
 * updateBlock rebuilds the whole block and moves the cursor to the block end, which
 * would leave the caret in the wrong place after insertion. A delete maps the existing
 * selection through unchanged, so the caret stays directly after the chip — and we
 * never dispatch a separate selection transaction, which under real-time collaboration
 * (Yjs/Hocuspocus) would cause the following keyboard input to be silently dropped.
 */
export function removeTriggerBeforeChip(editor:AnyEditor, instanceId:string):void {
  const { doc } = editor.prosemirrorState;

  let chipStart = -1;
  doc.descendants((node, position) => {
    if (chipStart !== -1) return false;
    if ((node.attrs as Record<string, unknown>)?.instanceId === instanceId) {
      chipStart = position;
      return false;
    }
    return true;
  });
  if (chipStart === -1) return;

  const nodeBeforeChip = doc.resolve(chipStart).nodeBefore;
  if (!nodeBeforeChip?.isText || nodeBeforeChip.text == null) return;

  const match = /#+\S*$/.exec(nodeBeforeChip.text);
  if (!match) return;

  const triggerStart = chipStart - (nodeBeforeChip.text.length - match.index);
  editor.transact((tr) => {
    tr.delete(triggerStart, chipStart);
  });
}
