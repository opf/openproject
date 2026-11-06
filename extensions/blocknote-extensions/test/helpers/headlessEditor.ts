import { BlockNoteEditor, BlockNoteSchema } from '@blocknote/core';
import { TextSelection } from 'prosemirror-state';
import {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
} from '../../lib';
import type { AnyEditor } from '../../lib/editorTypes';
import { INLINE_WP_TYPE } from '../../lib/utils/nodeTypes';

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});

export interface InlineNode {
  type:string;
  text?:string;
  props?:Record<string, unknown>;
}

export function createHeadlessEditorWithBlocks(blocks:unknown[]) {
  return BlockNoteEditor.create({ schema, initialContent: blocks as never });
}

export function createHeadlessEditor(content:unknown[] | string) {
  return createHeadlessEditorWithBlocks([{ type: 'paragraph', content }]);
}

export function createHeadlessEditorWithText(text:string) {
  const editor = createHeadlessEditor(text);
  editor.setTextCursorPosition(editor.document[0], 'end');
  return editor;
}

export function chipContent(wpid:string, size = 's') {
  return { type: INLINE_WP_TYPE, props: { wpid, size } };
}

export function textContent(value:string) {
  return { type: 'text', text: value, styles: {} };
}

export function blockContent(editor:AnyEditor, blockIndex = 0):InlineNode[] {
  return (editor.document[blockIndex]?.content ?? []) as InlineNode[];
}

export function blockTypes(editor:AnyEditor):string[] {
  return editor.document.map((block) => block.type as string);
}

export function blockText(editor:AnyEditor, blockIndex = 0):string {
  return blockContent(editor, blockIndex).map((node) => node.text ?? '').join('');
}

export function nthChipPosition(editor:AnyEditor, ordinal = 0):number {
  let seen = -1;
  let found = -1;
  editor.prosemirrorState.doc.descendants((node, position) => {
    if (found !== -1) return false;
    if (node.type.name === INLINE_WP_TYPE) {
      seen += 1;
      if (seen === ordinal) {
        found = position;
        return false;
      }
    }
    return true;
  });
  return found;
}

export function placeCursorAfterText(editor:AnyEditor, marker:string):void {
  let target = -1;
  editor.prosemirrorState.doc.descendants((node, position) => {
    if (target !== -1) return false;
    if (node.isText && node.text?.includes(marker)) {
      target = position + node.text.indexOf(marker) + marker.length;
      return false;
    }
    return true;
  });
  if (target === -1) throw new Error(`"${marker}" is not in the document`);

  editor.transact((tr) => {
    tr.setSelection(TextSelection.create(tr.doc, target));
  });
}
