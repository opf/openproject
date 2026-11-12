import type { Node } from 'prosemirror-model';
import type { AnyEditor } from '../../editorTypes';
import type { WorkPackage } from '../../openProjectTypes';
import { chipContentOf } from '../../utils/inlineChipActions';
import { insertBlockInLine } from '../../utils/blockInLine';
import { insertPendingInline, removePendingInline } from '../../utils/pendingInline';
import { BLOCK_WP_TYPE, INLINE_WP_TYPE } from '../../utils/nodeTypes';
import { subjectOf } from '../../utils/subject';
import { pendingWorkPackages } from '../InlineWorkPackage/pending';
import type { PendingWorkPackage } from '../InlineWorkPackage/pending';
import type { BlockWpSize, InlineWpSize } from '../WorkPackage/types';
import type { HashTarget } from './hashTrigger';

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
  insertPendingInline(editor, pendingWorkPackages, {
    type: INLINE_WP_TYPE,
    withSpacer: false,
    entry: (pendingWpid):PendingWorkPackage => ({
      onResolve: (workPackage) => replacePendingChip(editor, pendingWpid, () => insertWpForTarget(editor, workPackage, target)),
      onCancel: () => replacePendingChip(editor, pendingWpid, () => restoreHashQuery(editor, query)),
      mode: 'create',
      initialSubject: subjectOf(query),
    }),
  });
}

// The cursor stays right behind the pending chip while the form is open, so
// removing the chip leaves it where the replacement belongs.
function replacePendingChip(editor:AnyEditor, pendingWpid:string, insertReplacement:() => void):void {
  editor.focus();
  editor.transact(() => {
    if (removePendingInline(editor, pendingWpid, INLINE_WP_TYPE)) insertReplacement();
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
  const range = editor.transact((tr) => {
    const to = tr.selection.from;
    return { from: triggerStartBefore(tr.doc, to), to };
  });
  const props = { wpid: workPackage.id, size, displayId: workPackage.displayId };
  insertBlockInLine(editor, range, { type: BLOCK_WP_TYPE, props });
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
    if (tr.doc.nodeAt(chipPosition)?.type.name !== INLINE_WP_TYPE) return chipPosition;

    const triggerStart = triggerStartBefore(tr.doc, chipPosition);
    if (triggerStart < chipPosition) tr.delete(triggerStart, chipPosition);
    return triggerStart;
  });
}

function triggerStartBefore(doc:Node, position:number):number {
  const textBefore = doc.resolve(position).nodeBefore?.text ?? '';
  const trigger = /#+$/.exec(textBefore);
  return trigger ? position - trigger[0].length : position;
}
