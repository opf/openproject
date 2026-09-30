// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import {
  insertWpChip,
  insertWpForTarget,
  removeTriggerBeforeChip,
} from '../../../../lib/components/HashMenu/editorUtils';
import { INLINE_WP_TYPE, BLOCK_WP_TYPE } from '../../../../lib/utils/nodeTypes';
import type { WorkPackage } from '../../../../lib/openProjectTypes';
import {
  blockContent,
  blockText,
  blockTypes,
  chipContent,
  createHeadlessEditor,
  createHeadlessEditorWithText,
  nthChipPosition,
  placeCursorAfterText,
  textContent,
} from '../../../helpers/headlessEditor';

const workPackage = { id: 1, displayId: '1', subject: 'Fix bug' } as unknown as WorkPackage;

describe('removeTriggerBeforeChip', () => {
  it('removes a single leftover # before the chip', () => {
    const editor = createHeadlessEditor([textContent('Hello #'), chipContent('1', 'xxs')]);

    removeTriggerBeforeChip(editor, nthChipPosition(editor));

    expect(blockText(editor)).toBe('Hello ');
  });

  it('removes multiple leftover hashes (##, ###) before the chip', () => {
    const editor = createHeadlessEditor([textContent('Hello ###'), chipContent('1')]);

    removeTriggerBeforeChip(editor, nthChipPosition(editor));

    expect(blockText(editor)).toBe('Hello ');
  });

  it('returns the position the chip moved to', () => {
    const editor = createHeadlessEditor([textContent('Hello ###'), chipContent('1')]);
    const positionBefore = nthChipPosition(editor);

    const positionAfter = removeTriggerBeforeChip(editor, positionBefore);

    expect(positionAfter).toBe(positionBefore - 3);
    expect(positionAfter).toBe(nthChipPosition(editor));
  });

  it('leaves an earlier # in the line alone — removes only the trailing hashes', () => {
    const editor = createHeadlessEditor([
      textContent('Pre #one #two #'),
      chipContent('1', 'xxs'),
    ]);

    removeTriggerBeforeChip(editor, nthChipPosition(editor));

    expect(blockText(editor)).toBe('Pre #one #two ');
  });

  it('preserves a preceding #word — does not over-delete an existing hash like "#42"', () => {
    const editor = createHeadlessEditor([textContent('See PR #42'), chipContent('1', 'xxs')]);

    removeTriggerBeforeChip(editor, nthChipPosition(editor));

    expect(blockText(editor)).toBe('See PR #42');
  });

  it('removes the previous text node entirely when only # remains', () => {
    const editor = createHeadlessEditor([textContent('#'), chipContent('1', 'xxs')]);

    removeTriggerBeforeChip(editor, nthChipPosition(editor));

    expect(blockContent(editor)[0].type).toBe(INLINE_WP_TYPE);
  });

  it('does nothing if the given position is not a chip', () => {
    const editor = createHeadlessEditorWithText('Hello #foo');
    const before = JSON.stringify(editor.document);

    expect(removeTriggerBeforeChip(editor, 0)).toBe(0);
    expect(JSON.stringify(editor.document)).toBe(before);
  });

  it('does nothing when there is no preceding text node', () => {
    const editor = createHeadlessEditor([chipContent('1', 'xxs')]);
    const before = JSON.stringify(editor.document);

    removeTriggerBeforeChip(editor, nthChipPosition(editor));

    expect(JSON.stringify(editor.document)).toBe(before);
  });
});

describe('insertWpChip', () => {
  it('inserts a chip with the work package ID and size, followed by a space', () => {
    const editor = createHeadlessEditorWithText('test ');

    insertWpChip(editor, workPackage, 'xxs');

    expect(blockContent(editor)).toMatchObject([
      { type: 'text', text: 'test ' },
      { type: INLINE_WP_TYPE, props: { wpid: '1', size: 'xxs' } },
      { type: 'text', text: ' ' },
    ]);
  });
});

describe('insertWpForTarget', () => {
  it('inserts an inline chip of the target size, replacing the trigger hashes', () => {
    const editor = createHeadlessEditorWithText('##');

    insertWpForTarget(editor, workPackage, { kind: 'inline', size: 'xs' });

    expect(blockTypes(editor)).toEqual(['paragraph']);
    expect(blockContent(editor)).toMatchObject([
      { type: INLINE_WP_TYPE, props: { wpid: '1', size: 'xs' } },
      { type: 'text', text: ' ' },
    ]);
  });

  it('inserts a block card, replacing the trigger hashes and leaving no chip', () => {
    const editor = createHeadlessEditorWithText('###');

    insertWpForTarget(editor, workPackage, { kind: 'block', size: 'm' });

    expect(blockTypes(editor)).toEqual([BLOCK_WP_TYPE, 'paragraph']);
    expect(editor.document[0].props).toMatchObject({ wpid: 1, size: 'm', displayId: '1' });
    expect(nthChipPosition(editor)).toBe(-1);
  });

  it('moves text that follows the trigger below the card', () => {
    const editor = createHeadlessEditor('### World');
    placeCursorAfterText(editor, '###');

    insertWpForTarget(editor, workPackage, { kind: 'block', size: 'm' });

    expect(blockTypes(editor)).toEqual([BLOCK_WP_TYPE, 'paragraph']);
    expect(blockText(editor, 1)).toBe(' World');
  });

  it('splits the line, keeping the text before and after the trigger around the card', () => {
    const editor = createHeadlessEditor('Hello ### World');
    placeCursorAfterText(editor, '###');

    insertWpForTarget(editor, workPackage, { kind: 'block', size: 'm' });

    expect(blockTypes(editor)).toEqual(['paragraph', BLOCK_WP_TYPE, 'paragraph']);
    expect(blockText(editor, 0)).toBe('Hello ');
    expect(blockText(editor, 2)).toBe(' World');
  });
});
