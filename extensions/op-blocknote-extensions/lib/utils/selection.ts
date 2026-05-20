/**
 * Selection utilities for shadow DOM.
 *
 * Chromium does not surface shadow-tree selections through `window.getSelection()`;
 * it exposes a non-standard `ShadowRoot.getSelection()` instead. Firefox works
 * through `window.getSelection()`.
 */

type ShadowRootWithSelection = ShadowRoot & {
  getSelection: () => Selection | null;
};

function hasShadowGetSelection(root: Node): root is ShadowRootWithSelection {
  return root instanceof ShadowRoot && "getSelection" in root;
}

export function getSelectionForNode(node: Node): Selection | null {
  const root = node.getRootNode();
  return hasShadowGetSelection(root) ? root.getSelection() : window.getSelection();
}

export function isNodeInSelection(node: Node): boolean {
  const selection = getSelectionForNode(node);
  if (!selection || selection.rangeCount === 0) return false;
  return selection.getRangeAt(0).intersectsNode(node);
}