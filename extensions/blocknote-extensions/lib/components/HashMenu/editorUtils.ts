import type { AnyEditor } from '../../editorTypes';
import type { WorkPackage } from '../../openProjectTypes';
import {
  chipContentOf,
  promoteInlineChipToBlockAt,
  removePendingInlineChip,
} from '../../utils/inlineChipActions';
import { INLINE_WP_TYPE } from '../../utils/nodeTypes';
import { subjectOf } from '../../utils/subject';
import { makePendingWpid, registerInlineWpCallbacks } from '../InlineWorkPackage/callbacks';
import type { BlockWpSize, InlineWpSize } from '../WorkPackage/types';
import type { HashTarget } from './hashTrigger';

// Discarded right away, so the cheapest chip to render will do.
const SPLIT_MARKER_SIZE:InlineWpSize = 'xxs';

export function insertWpForTarget(
  editor:AnyEditor,
  workPackage:WorkPackage,
  target:HashTarget
):void {
  if (target.kind === 'inline') insertWpChip(editor, workPackage, target.size);
  else if (target.kind === 'block') insertWpBlockCard(editor, workPackage, target.size);
}

export function createWpForTarget(
  editor:AnyEditor,
  query:string,
  target:HashTarget
):void {
  const pendingWpid = makePendingWpid();

  registerInlineWpCallbacks(
    pendingWpid,
    (workPackage) => replacePendingChip(editor, pendingWpid, () => insertWpForTarget(editor, workPackage, target)),
    () => replacePendingChip(editor, pendingWpid, () => restoreHashQuery(editor, query)),
    { mode: 'create', initialSubject: subjectOf(query) }
  );

  (editor.insertInlineContent as (content:unknown[]) => void)([
    { type: INLINE_WP_TYPE, props: { wpid: pendingWpid } },
  ]);
}

// The cursor stays right behind the pending chip while the form is open, so
// removing the chip leaves it where the replacement belongs.
function replacePendingChip(editor:AnyEditor, pendingWpid:string, insertReplacement:() => void):void {
  editor.focus();
  editor.transact(() => {
    if (removePendingInlineChip(editor, pendingWpid)) insertReplacement();
  });
}

/**
 * Inserts a chip followed by a trailing space at the cursor, then removes any
 * leftover trigger hashes immediately before it.
 *
 * `insertInlineContent` leaves the cursor directly after the space, which is
 * exactly where we want it. We deliberately avoid placing the cursor with a
 * separate selection transaction — under real-time collaboration
 * (Yjs/Hocuspocus) any selection change dispatched after the menu insertion
 * leaves the editor in a state where the following native keyboard input
 * (e.g. Backspace) is silently dropped.
 */
export function insertWpChip(
  editor:AnyEditor,
  workPackage:WorkPackage,
  size:InlineWpSize
):void {
  insertChipAtCursor(editor, workPackage, size, { withTrailingSpace: true });
  editor.focus();
}

function insertWpBlockCard(
  editor:AnyEditor,
  workPackage:WorkPackage,
  size:BlockWpSize
):void {
  editor.transact(() => {
    const chipPosition = insertChipAtCursor(editor, workPackage, SPLIT_MARKER_SIZE, {
      withTrailingSpace: false,
    });
    promoteInlineChipToBlockAt(editor, chipPosition, size);
  });
}

function insertChipAtCursor(
  editor:AnyEditor,
  workPackage:WorkPackage,
  size:InlineWpSize,
  { withTrailingSpace }:{ withTrailingSpace:boolean }
):number {
  const content:unknown[] = [chipContentOf(workPackage, size)];
  if (withTrailingSpace) content.push({ type: 'text', text: ' ', styles: {} });

  const chipPosition = editor.transact((tr) => tr.selection.from);
  (editor.insertInlineContent as (content:unknown[]) => void)(content);

  return removeTriggerBeforeChip(editor, chipPosition);
}

export function restoreHashQuery(editor:AnyEditor, query:string):void {
  (editor.insertInlineContent as (content:unknown[]) => void)([
    { type: 'text', text: `#${query}`, styles: {} },
  ]);
}

/**
 * Removes the leftover trigger hashes (`#`/`##`/`###`) that BlockNote's
 * suggestion menu leaves directly before the chip for `##`-and-longer triggers,
 * and returns the chip's position afterwards.
 */
export function removeTriggerBeforeChip(editor:AnyEditor, chipPosition:number):number {
  return editor.transact((tr) => {
    const chipNode = tr.doc.nodeAt(chipPosition);
    if (chipNode?.type.name !== INLINE_WP_TYPE) return chipPosition;

    const nodeBeforeChip = tr.doc.resolve(chipPosition).nodeBefore;
    if (!nodeBeforeChip?.isText || nodeBeforeChip.text == null) return chipPosition;

    const match = /#+$/.exec(nodeBeforeChip.text);
    if (!match) return chipPosition;

    const triggerStart = chipPosition - (nodeBeforeChip.text.length - match.index);
    tr.delete(triggerStart, chipPosition);
    return triggerStart;
  });
}
