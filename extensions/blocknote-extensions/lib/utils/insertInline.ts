import type { AnyEditor } from '../editorTypes';

// insertInlineContent is typed against the editor's own schema; callers here hold an AnyEditor.
export function insertInline(editor:AnyEditor, content:unknown[]):void {
  (editor.insertInlineContent as (content:unknown[]) => void)(content);
}

/** Puts back what the suggestion menu removed when its placeholder item is picked. */
export function restoreTypedQuery(editor:AnyEditor, trigger:string, query:string):void {
  insertInline(editor, [{ type: 'text', text: `${trigger}${query}`, styles: {} }]);
}
