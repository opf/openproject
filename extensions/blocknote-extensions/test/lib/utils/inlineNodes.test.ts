// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { removeInlineNodeAt } from '../../../lib/utils/inlineNodes';
import { INLINE_WP_TYPE } from '../../../lib/utils/nodeTypes';
import {
  blockContent,
  createHeadlessEditor,
  nthChipPosition,
} from '../../helpers/headlessEditor';
import { chipContent, textContent } from '../../helpers/content';

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
