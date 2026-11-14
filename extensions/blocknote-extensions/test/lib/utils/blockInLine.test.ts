// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { NodeSelection, TextSelection } from 'prosemirror-state';
import { insertBlockInLine, placeBlockInLine } from '../../../lib/utils/blockInLine';
import { BLOCK_WP_TYPE } from '../../../lib/utils/nodeTypes';
import type { AnyEditor } from '../../../lib/editorTypes';
import {
  blockText,
  blockTypes,
  createHeadlessEditorWithBlocks,
  placeCursorAfterText,
} from '../../helpers/headlessEditor';

const card = { wpid: 7, size: 'm', displayId: '7' };

function insertCardAtCursor(editor:AnyEditor):void {
  const range = editor.transact(({ selection }) => ({ from: selection.from, to: selection.to }));
  insertBlockInLine(editor, range, { type: BLOCK_WP_TYPE, props: card });
}

function positionAfter(editor:AnyEditor, marker:string):number {
  placeCursorAfterText(editor, marker);
  return editor.transact(({ selection }) => selection.from);
}

function selectRange(editor:AnyEditor, from:number, to:number):void {
  editor.transact((tr) => {
    tr.setSelection(TextSelection.create(tr.doc, from, to));
  });
}

function cursorBlockIndex(editor:AnyEditor):number {
  const cursorBlockId = editor.getTextCursorPosition().block.id;
  return editor.document.findIndex((block) => block.id === cursorBlockId);
}

describe('insertBlockInLine', () => {
  it('splits the line around the block', () => {
    const editor = createHeadlessEditorWithBlocks([{ type: 'paragraph', content: 'Before after' }]);
    placeCursorAfterText(editor, 'Before ');

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual(['paragraph', BLOCK_WP_TYPE, 'paragraph']);
    expect(blockText(editor, 0)).toBe('Before ');
    expect(blockText(editor, 2)).toBe('after');
    expect(editor.document[1].props).toMatchObject(card);
    expect(cursorBlockIndex(editor)).toBe(2);
  });

  it('keeps the type of the line on both sides', () => {
    const editor = createHeadlessEditorWithBlocks([{ type: 'heading', props: { level: 2 }, content: 'Before after' }]);
    placeCursorAfterText(editor, 'Before ');

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual(['heading', BLOCK_WP_TYPE, 'heading']);
    expect(editor.document[2].props).toMatchObject({ level: 2 });
  });

  it('follows a line it is inserted at the end of, with the cursor on a new line', () => {
    const editor = createHeadlessEditorWithBlocks([{ type: 'paragraph', content: 'Before' }]);
    placeCursorAfterText(editor, 'Before');

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual(['paragraph', BLOCK_WP_TYPE, 'paragraph']);
    expect(blockText(editor, 0)).toBe('Before');
    expect(blockText(editor, 2)).toBe('');
    expect(cursorBlockIndex(editor)).toBe(2);
  });

  it('precedes a line it is inserted at the start of', () => {
    const editor = createHeadlessEditorWithBlocks([{ type: 'paragraph', content: 'after' }]);
    editor.setTextCursorPosition(editor.document[0], 'start');

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual([BLOCK_WP_TYPE, 'paragraph']);
    expect(blockText(editor, 1)).toBe('after');
    expect(cursorBlockIndex(editor)).toBe(1);
  });

  it('takes the place of an empty line and keeps the blocks nested in it', () => {
    const editor = createHeadlessEditorWithBlocks([
      { type: 'paragraph', content: [], children: [{ type: 'paragraph', content: 'Nested' }] },
    ]);
    editor.setTextCursorPosition(editor.document[0], 'start');

    insertCardAtCursor(editor);

    expect(editor.document[0].type).toBe(BLOCK_WP_TYPE);
    expect(editor.document[0].children.map((child) => child.content)).toEqual([
      [{ type: 'text', text: 'Nested', styles: {} }],
    ]);
  });

  it('moves the blocks nested in a split line along with its last part', () => {
    const editor = createHeadlessEditorWithBlocks([
      { type: 'paragraph', content: 'Before after', children: [{ type: 'paragraph', content: 'Nested' }] },
    ]);
    placeCursorAfterText(editor, 'Before ');

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual(['paragraph', BLOCK_WP_TYPE, 'paragraph']);
    expect(editor.document[0].children).toEqual([]);
    expect(editor.document[2].children.map((child) => child.content)).toEqual([
      [{ type: 'text', text: 'Nested', styles: {} }],
    ]);
  });

  it('moves the blocks nested in a line it ends along with the block', () => {
    const editor = createHeadlessEditorWithBlocks([
      { type: 'paragraph', content: 'Before', children: [{ type: 'paragraph', content: 'Nested' }] },
    ]);
    placeCursorAfterText(editor, 'Before');

    insertCardAtCursor(editor);

    expect(editor.document[0].children).toEqual([]);
    expect(editor.document[1].type).toBe(BLOCK_WP_TYPE);
    expect(editor.document[1].children).toHaveLength(1);
  });

  it('replaces a selection across lines, keeping what is not selected', () => {
    const editor = createHeadlessEditorWithBlocks([
      { type: 'paragraph', content: 'One two' },
      { type: 'paragraph', content: 'three four' },
    ]);
    selectRange(editor, positionAfter(editor, 'One '), positionAfter(editor, 'three'));

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual(['paragraph', BLOCK_WP_TYPE, 'paragraph']);
    expect(blockText(editor, 0)).toBe('One ');
    expect(blockText(editor, 2)).toBe(' four');
  });

  it('follows a block selected as a whole', () => {
    const editor = createHeadlessEditorWithBlocks([
      { type: 'paragraph', content: 'One' },
      { type: 'paragraph', content: 'Two' },
    ]);
    editor.transact((tr) => {
      tr.setSelection(NodeSelection.create(tr.doc, 1));
    });

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual(['paragraph', BLOCK_WP_TYPE, 'paragraph']);
    expect(blockText(editor, 0)).toBe('One');
  });

  it('follows a selected block instead of replacing it', () => {
    const editor = createHeadlessEditorWithBlocks([
      { type: BLOCK_WP_TYPE, props: { wpid: 1, size: 'm', displayId: '1' } },
      { type: 'paragraph', content: 'Below' },
    ]);
    editor.transact((tr) => {
      tr.setSelection(NodeSelection.create(tr.doc, 1 + 1));
    });

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual([BLOCK_WP_TYPE, BLOCK_WP_TYPE, 'paragraph']);
    expect(editor.document[0].props).toMatchObject({ wpid: 1 });
    expect(editor.document[1].props).toMatchObject(card);
  });

  it('follows a table it is inserted into', () => {
    const editor = createHeadlessEditorWithBlocks([
      { type: 'table', content: { type: 'tableContent', rows: [{ cells: ['Cell'] }] } },
    ]);
    placeCursorAfterText(editor, 'Cell');

    insertCardAtCursor(editor);

    expect(blockTypes(editor)).toEqual(['table', BLOCK_WP_TYPE, 'paragraph']);
    expect(cursorBlockIndex(editor)).toBe(2);
  });

  it('works within an outer transaction', () => {
    const editor = createHeadlessEditorWithBlocks([{ type: 'paragraph', content: 'Before after' }]);
    placeCursorAfterText(editor, 'Before ');

    editor.transact(() => insertCardAtCursor(editor));

    expect(blockTypes(editor)).toEqual(['paragraph', BLOCK_WP_TYPE, 'paragraph']);
  });
});

describe('placeBlockInLine', () => {
  it('keeps the caret in the text after the block', () => {
    const editor = createHeadlessEditorWithBlocks([{ type: 'paragraph', content: 'Before MACRO after' }]);
    const from = positionAfter(editor, 'Before ');
    placeCursorAfterText(editor, 'af');

    placeBlockInLine(editor, { from, to: from + 'MACRO'.length }, { type: BLOCK_WP_TYPE, props: card });

    expect(cursorBlockIndex(editor)).toBe(2);
    expect(editor.transact(({ selection }) => selection.$from.parentOffset)).toBe(' af'.length);
  });

  it('keeps the caret in the text before the block', () => {
    const editor = createHeadlessEditorWithBlocks([{ type: 'paragraph', content: 'Before MACRO after' }]);
    const from = positionAfter(editor, 'Before ');
    placeCursorAfterText(editor, 'Bef');

    placeBlockInLine(editor, { from, to: from + 'MACRO'.length }, { type: BLOCK_WP_TYPE, props: card });

    expect(cursorBlockIndex(editor)).toBe(0);
    expect(editor.transact(({ selection }) => selection.$from.parentOffset)).toBe('Bef'.length);
  });
});
