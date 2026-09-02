import type { AnyEditor } from '../../editorTypes';

export function subjectOf(text:string):string {
  return text.replace(/\s+/g, ' ').trim();
}

export function selectedSubject(editor:AnyEditor):string {
  const { doc, selection } = editor.prosemirrorState;
  // Not `editor.getSelectedText()`: it runs the blocks of a selection together
  // without the separator that keeps their words apart.
  return subjectOf(doc.textBetween(selection.from, selection.to, ' '));
}
