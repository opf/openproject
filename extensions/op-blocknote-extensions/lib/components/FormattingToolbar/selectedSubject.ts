import type { AnyEditor } from '../../editorTypes';
import { WORK_PACKAGE_NODE_TYPES } from '../../utils/nodeTypes';

export function subjectOf(text:string):string {
  return text.replace(/\s+/g, ' ').trim();
}

function selectionHoldsWorkPackage(editor:AnyEditor):boolean {
  const { doc, selection } = editor.prosemirrorState;
  let held = false;

  doc.nodesBetween(selection.from, selection.to, (node) => {
    if (WORK_PACKAGE_NODE_TYPES.includes(node.type.name)) held = true;
    return !held;
  });

  return held;
}

export function selectedSubject(editor:AnyEditor):string {
  if (selectionHoldsWorkPackage(editor)) return '';

  const { doc, selection } = editor.prosemirrorState;
  // Not `editor.getSelectedText()`: it runs the blocks of a selection together
  // without the separator that keeps their words apart.
  return subjectOf(doc.textBetween(selection.from, selection.to, ' '));
}
