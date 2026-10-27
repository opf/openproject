import { NodeSelection } from 'prosemirror-state';
import type { Node as ProsemirrorNode } from 'prosemirror-model';
import type { AnyEditor } from '../editorTypes';
import { WORK_PACKAGE_NODE_TYPES } from './nodeTypes';

/**
 * Selection utilities.
 *
 * Shadow DOM: Chromium does not surface shadow-tree selections through
 * `window.getSelection()`; it exposes a non-standard `ShadowRoot.getSelection()`
 * instead. Firefox works through `window.getSelection()`.
 */

type ShadowRootWithSelection = ShadowRoot & {
  getSelection:() => Selection | null;
};

function hasShadowGetSelection(root:Node):root is ShadowRootWithSelection {
  return root instanceof ShadowRoot && 'getSelection' in root;
}

export function getSelectionForNode(node:Node):Selection | null {
  const root = node.getRootNode();
  return hasShadowGetSelection(root) ? root.getSelection() : window.getSelection();
}

export function isNodeInSelection(node:Node):boolean {
  const selection = getSelectionForNode(node);
  if (!selection || selection.rangeCount === 0) return false;
  return selection.getRangeAt(0).intersectsNode(node);
}

// A function, not a module-level const, so a stubbed user agent still takes effect.
function isSafari():boolean {
  return typeof navigator !== 'undefined' &&
    /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
}

interface DomObserver { disconnectSelection:() => void; connectSelection:() => void; setCurSelection:() => void }

/** Safari paints a phantom selection over node-selected atoms; collapse it, leaving PM's NodeSelection intact. */
export function hideSafariPhantomSelection(editor:AnyEditor):void {
  if (!isSafari()) return;
  requestAnimationFrame(() => {
    const view = editor.prosemirrorView;
    if (!view) return;

    const selectedNode = (view.state.selection as { node?:ProsemirrorNode }).node;
    if (!selectedNode || !WORK_PACKAGE_NODE_TYPES.includes(selectedNode.type.name)) return;

    const domObserver = (view as unknown as { domObserver?:DomObserver }).domObserver;
    if (!domObserver) return;
    const nativeSelection = getSelectionForNode(view.dom);
    if (!nativeSelection || nativeSelection.rangeCount === 0) return;

    domObserver.disconnectSelection();
    // Not removeAllRanges — it blurs the editor and kills Cmd+C in Safari.
    nativeSelection.collapseToEnd();
    domObserver.setCurSelection();
    domObserver.connectSelection();
  });
}

/**
 * Node-selects a block by id. A click reaches ProseMirror and it selects the
 * block itself; a tap we answered ourselves never does, and the block would
 * stay unmarked while its popover is open. BlockNote's `setSelection` cannot
 * express this - it rejects a range that starts and ends on the same block.
 */
export function selectBlockNode(editor:AnyEditor, blockId:string):void {
  editor.transact((tr) => {
    let position:number | null = null;

    tr.doc.descendants((node, pos) => {
      if (position !== null) return false;
      if ((node.attrs as { id?:string }).id !== blockId) return true;

      const content = node.firstChild;
      position = content && WORK_PACKAGE_NODE_TYPES.includes(content.type.name) ? pos + 1 : pos;
      return false;
    });

    if (position !== null) tr.setSelection(NodeSelection.create(tr.doc, position));
  });
  hideSafariPhantomSelection(editor);
}
