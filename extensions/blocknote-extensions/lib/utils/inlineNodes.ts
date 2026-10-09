import type { Node as ProsemirrorNode } from 'prosemirror-model';
import { NodeSelection } from 'prosemirror-state';
import type { AnyEditor } from '../editorTypes';
import { hideSafariPhantomSelection } from './selection';

// Position-based operations on atom inline nodes (work package chips, user
// mentions). A node's React component finds its own position from its DOM
// element, and a position names exactly one node instance, so copies of a node
// stay independent without an id prop that would leak into clipboard HTML.

export interface FoundInlineNode {
  position:number;
  node:ProsemirrorNode;
}

/**
 * Resolves a node's own DOM element to its ProseMirror node and position.
 *
 * `posAtDOM` may return the position directly before the atom node or the
 * position inside its node-view wrapper (off by one), so both candidates are
 * checked and verified by node type.
 */
export function findInlineNodeAtDOM(
  editor:AnyEditor,
  dom:HTMLElement,
  nodeType:string,
):FoundInlineNode | null {
  const view = editor.prosemirrorView;
  if (!view) return null;

  let basePosition:number;
  try {
    basePosition = view.posAtDOM(dom, 0);
  } catch {
    return null;
  }

  for (const position of [basePosition, basePosition - 1]) {
    if (position < 0) continue;
    const node = view.state.doc.nodeAt(position);
    if (node?.type.name === nodeType) return { position, node };
  }
  return null;
}

export function inlineNodeAt(editor:AnyEditor, position:number, nodeType:string):ProsemirrorNode | null {
  return editor.transact((tr) => {
    const node = tr.doc.nodeAt(position);
    return node?.type.name === nodeType ? node : null;
  });
}

export function selectInlineNodeAt(editor:AnyEditor, position:number, nodeType:string):void {
  if (!inlineNodeAt(editor, position, nodeType)) return;
  editor.transact((tr) => {
    tr.setSelection(NodeSelection.create(tr.doc, position));
  });
  hideSafariPhantomSelection(editor);
}

export function removeInlineNodeAt(editor:AnyEditor, position:number, nodeType:string):void {
  const node = inlineNodeAt(editor, position, nodeType);
  if (!node) return;
  editor.transact((tr) => {
    tr.delete(position, position + node.nodeSize);
  });
}
