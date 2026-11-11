import type { Node as ProsemirrorNode } from 'prosemirror-model';
import type { AnyEditor } from '../editorTypes';
import { isPendingWpid, makePendingWpid } from './pending';
import type { PendingHandlers, PendingRegistry } from './pending';

const SPACER = { type: 'text', text: ' ', styles: {} };

export interface FoundPendingInline {
  position:number;
  node:ProsemirrorNode;
}

interface PendingInlineOptions<Entry> {
  type:string;
  props?:Record<string, unknown>;
  withSpacer?:boolean;
  entry:(pendingWpid:string) => Entry;
}

export function insertPendingInline<Result, Entry extends PendingHandlers<Result>>(
  editor:AnyEditor,
  registry:PendingRegistry<Result, Entry>,
  { type, props = {}, withSpacer = true, entry }:PendingInlineOptions<Entry>,
):void {
  const pendingWpid = makePendingWpid();
  registry.register(pendingWpid, entry(pendingWpid));

  try {
    (editor.insertInlineContent as (content:unknown[]) => void)([
      { type, props: { ...props, wpid: pendingWpid } },
      ...(withSpacer ? [SPACER] : []),
    ]);
  } catch (error) {
    console.error(`[${type}] insertInlineContent failed:`, error);
    registry.unregister(pendingWpid);
  }
}

/**
 * Resolves the placeholder by updating its attributes, which keeps the cursor
 * behind it. Under Yjs, a selection change dispatched after the menu insertion
 * makes the editor drop the next keystroke.
 */
export function inPlaceHandlers<Result>(
  editor:AnyEditor,
  type:string,
  pendingWpid:string,
  attrsOf:(result:Result) => Record<string, unknown>,
):PendingHandlers<Result> {
  return {
    onResolve: (result) => {
      const found = findPendingInline(editor.prosemirrorState.doc, pendingWpid, type);
      if (!found) return;

      editor.focus();
      editor.transact((tr) => {
        tr.setNodeMarkup(found.position, undefined, { ...found.node.attrs, ...attrsOf(result) });
      });
    },
    onCancel: () => {
      editor.focus();
      removePendingInline(editor, pendingWpid, type, { withSpacer: true });
    },
  };
}

export function findPendingInline(doc:ProsemirrorNode, wpid:string, type:string):FoundPendingInline | null {
  if (!isPendingWpid(wpid)) return null;

  let found:FoundPendingInline | null = null;
  doc.descendants((node, position) => {
    if (found) return false;
    if (node.type.name === type && node.attrs.wpid === wpid) {
      found = { position, node };
      return false;
    }
    return true;
  });
  return found;
}

export function removePendingInline(
  editor:AnyEditor,
  wpid:string,
  type:string,
  { withSpacer = false }:{ withSpacer?:boolean } = {},
):boolean {
  return editor.transact((tr) => {
    const found = findPendingInline(tr.doc, wpid, type);
    if (!found) return false;

    const [from, to] = withSpacer
      ? rangeWithSpacer(tr.doc, found)
      : [found.position, found.position + found.node.nodeSize];
    tr.delete(from, to);
    return true;
  });
}

export function rangeWithSpacer(doc:ProsemirrorNode, found:FoundPendingInline):[number, number] {
  const end = found.position + found.node.nodeSize;
  const spacerEnd = end < doc.content.size && doc.textBetween(end, end + 1) === ' ' ? end + 1 : end;
  return [found.position, spacerEnd];
}
