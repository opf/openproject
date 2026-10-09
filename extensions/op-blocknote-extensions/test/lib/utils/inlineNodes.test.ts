// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { removeInlineNodeAt, selectInlineNodeAt } from '../../../lib/utils/inlineNodes';
import { INLINE_WP_TYPE, USER_MENTION_TYPE } from '../../../lib/utils/nodeTypes';
import {
  blockContent,
  blockText,
  createHeadlessEditor,
  nthChipPosition,
  nthInlineNodePosition,
  selectedNodeType,
} from '../../helpers/headlessEditor';
import { chipContent, mentionContent, textContent } from '../../helpers/content';

describe('removeInlineNodeAt', () => {
  it('removes exactly the chip at the given position', () => {
    const editor = createHeadlessEditor([chipContent('1'), textContent(' between '), chipContent('1')]);

    removeInlineNodeAt(editor, nthChipPosition(editor, 1), INLINE_WP_TYPE);

    const content = blockContent(editor);
    const chips = content.filter((n) => n.type === INLINE_WP_TYPE);
    expect(chips).toHaveLength(1);
    expect(content[0].type).toBe(INLINE_WP_TYPE);
  });

  it('does nothing when the position does not hold a chip', () => {
    const editor = createHeadlessEditor([textContent('abc'), chipContent('1')]);
    const before = JSON.stringify(editor.document);

    removeInlineNodeAt(editor, 1, INLINE_WP_TYPE);

    expect(JSON.stringify(editor.document)).toBe(before);
  });
});

describe('inline node actions for a user mention', () => {
  it('removes a mention when given its node type', () => {
    const editor = createHeadlessEditor([textContent('a '), mentionContent('7', 'Anna'), textContent(' b')]);

    removeInlineNodeAt(editor, nthInlineNodePosition(editor, USER_MENTION_TYPE), USER_MENTION_TYPE);

    expect(blockContent(editor).map((node) => node.type)).toEqual(['text']);
    expect(blockText(editor)).toBe('a  b');
  });

  it('node-selects a mention when given its node type', () => {
    const editor = createHeadlessEditor([textContent('a '), mentionContent('7', 'Anna')]);
    const position = nthInlineNodePosition(editor, USER_MENTION_TYPE);

    selectInlineNodeAt(editor, position, USER_MENTION_TYPE);

    expect(editor.prosemirrorState.selection.from).toBe(position);
    expect(selectedNodeType(editor)).toBe(USER_MENTION_TYPE);
  });

  it('leaves a mention alone when called for work package chips', () => {
    const editor = createHeadlessEditor([mentionContent('7', 'Anna')]);
    const before = JSON.stringify(editor.document);

    removeInlineNodeAt(editor, nthInlineNodePosition(editor, USER_MENTION_TYPE), INLINE_WP_TYPE);

    expect(JSON.stringify(editor.document)).toBe(before);
  });
});
