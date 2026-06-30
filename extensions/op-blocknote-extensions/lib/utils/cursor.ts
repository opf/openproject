import type { BlockNoteEditor } from '@blocknote/core';
import type { Node as PmNode } from 'prosemirror-model';
import { NodeSelection } from 'prosemirror-state';

const isSafari =
  typeof navigator !== 'undefined' &&
  /^((?!chrome|android).)*safari/i.test(navigator.userAgent);

interface DomObserver { disconnectSelection:() => void; connectSelection:() => void; setCurSelection:() => void }

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyEditor = BlockNoteEditor<any, any, any>;

export function moveCursorAfterBlock(editor:AnyEditor, blockId:string):void {
  editor.focus();
  editor.setTextCursorPosition(blockId, 'end');

  const cursor = editor.getTextCursorPosition();
  if (!cursor?.nextBlock && cursor?.block) {
    editor.insertBlocks([{ type: 'paragraph', content: [] }], cursor.block.id, 'after');
  }

  const updated = editor.getTextCursorPosition();
  if (updated?.nextBlock) {
    editor.setTextCursorPosition(updated.nextBlock.id, 'start');
  }
}

function findInlineNodeRange(doc:PmNode, instanceId:string):{ from:number; to:number } | null {
  let result:{ from:number; to:number } | null = null;
  doc.descendants((node, pos) => {
    if (result) return false;
    if ((node.attrs as Record<string, unknown>)?.instanceId === instanceId) {
      result = { from: pos, to: pos + node.nodeSize };
      return false;
    }
    return true;
  });
  return result;
}

export function selectInlineNode(editor:AnyEditor, instanceId:string):void {
  const range = findInlineNodeRange(editor.prosemirrorState.doc, instanceId);
  if (!range) return;
  editor.transact((tr) => {
    tr.setSelection(NodeSelection.create(tr.doc, range.from));
  });
  if (!isSafari) return;
  // Safari renders a phantom selection on contenteditable=false atoms when PM syncs
  // NodeSelection to the DOM. Collapse the native selection to hide it while keeping
  // PM's NodeSelection intact (so Cmd+C and Delete still work).
  // Uses PM's own disconnect→collapseToEnd→setCurSelection→connect bracket to prevent
  // the selectionchange from being re-read as a state change. collapseToEnd not
  // removeAllRanges — removeAllRanges blurs the editor and breaks Cmd+C in Safari.
  // domObserver is a PM internal — missing it degrades to the visual glitch, not a crash.
  requestAnimationFrame(() => {
    const domObserver = (editor.prosemirrorView as unknown as { domObserver?:DomObserver }).domObserver;
    if (!domObserver) return;
    const nativeSel = window.getSelection();
    if (!nativeSel || nativeSel.rangeCount === 0) return;
    domObserver.disconnectSelection();
    nativeSel.collapseToEnd();
    domObserver.setCurSelection();
    domObserver.connectSelection();
  });
}

