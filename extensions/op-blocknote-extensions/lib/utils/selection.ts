import type { Node as ProsemirrorNode } from 'prosemirror-model';
import type { AnyEditor } from '../editorTypes';

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

const WORK_PACKAGE_NODE_TYPES = ['openProjectWorkPackageInline', 'openProjectWorkPackageBlock'];

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
