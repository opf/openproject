// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import {
  findPendingInlineChip,
  removeInlineChipAt,
  promoteInlineChipToBlockAt,
  convertBlockToInlineChip,
} from '../../../lib/utils/inlineChipActions';
import { BLOCK_WP_TYPE, INLINE_WP_TYPE } from '../../../lib/utils/nodeTypes';
import {
  blockContent,
  chipContent,
  createHeadlessEditor,
  createHeadlessEditorWithBlocks,
  nthChipPosition,
  textContent,
} from '../../helpers/headlessEditor';

describe('findPendingInlineChip', () => {
  it('finds the chip with the given pending wpid', () => {
    const editor = createHeadlessEditor([textContent('a'), chipContent('pending:x'), textContent('b')]);

    const found = findPendingInlineChip(editor.prosemirrorState.doc, 'pending:x');

    expect(found).not.toBeNull();
    expect(found?.node.attrs.wpid).toBe('pending:x');
    expect(found?.position).toBe(nthChipPosition(editor, 0));
  });

  it('returns null when no chip matches', () => {
    const editor = createHeadlessEditor([textContent('a'), chipContent('1')]);

    expect(findPendingInlineChip(editor.prosemirrorState.doc, 'pending:x')).toBeNull();
  });

  it('returns null when the wpid does not carry the pending prefix, even if a matching chip exists', () => {
    const editor = createHeadlessEditor([chipContent('1')]);

    expect(findPendingInlineChip(editor.prosemirrorState.doc, '1')).toBeNull();
  });
});

describe('removeInlineChipAt', () => {
  it('removes exactly the chip at the given position', () => {
    const editor = createHeadlessEditor([chipContent('1'), textContent(' between '), chipContent('1')]);

    removeInlineChipAt(editor, nthChipPosition(editor, 1));

    const content = blockContent(editor);
    const chips = content.filter((n) => n.type === INLINE_WP_TYPE);
    expect(chips).toHaveLength(1);
    expect(content[0].type).toBe(INLINE_WP_TYPE);
  });

  it('does nothing when the position does not hold a chip', () => {
    const editor = createHeadlessEditor([textContent('abc'), chipContent('1')]);
    const before = JSON.stringify(editor.document);

    removeInlineChipAt(editor, 1);

    expect(JSON.stringify(editor.document)).toBe(before);
  });
});

describe('promoteInlineChipToBlockAt', () => {
  it('replaces a lone chip with a block card', () => {
    const editor = createHeadlessEditor([chipContent('7')]);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 0), 'm');

    const blocks = editor.document;
    expect(blocks[0].type).toBe(BLOCK_WP_TYPE);
    expect(blocks[0].props).toMatchObject({ wpid: 7, size: 'm' });
  });

  it('keeps content before the chip in the original paragraph', () => {
    const editor = createHeadlessEditor([textContent('before '), chipContent('7')]);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 0), 'm');

    const blocks = editor.document;
    expect(blocks[0].type).toBe('paragraph');
    expect(blockContent(editor, 0)[0].text).toBe('before ');
    expect(blocks[1].type).toBe(BLOCK_WP_TYPE);
  });

  it('moves content after the chip into a new paragraph below the block', () => {
    const editor = createHeadlessEditor([textContent('before '), chipContent('7'), textContent(' after')]);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 0), 'l');

    const blocks = editor.document;
    expect(blocks[0].type).toBe('paragraph');
    expect(blocks[1].type).toBe(BLOCK_WP_TYPE);
    expect(blocks[2].type).toBe('paragraph');
    expect(blockContent(editor, 2)[0].text).toBe(' after');
  });

  it('promotes the correct chip when identical chips share the paragraph', () => {
    const editor = createHeadlessEditor([chipContent('7'), textContent(' mid '), chipContent('7'), textContent(' tail')]);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 1), 'm');

    const blocks = editor.document;
    // First chip stays inline in the first paragraph.
    const firstParagraphChips = blockContent(editor, 0).filter(
      (n) => n.type === INLINE_WP_TYPE
    );
    expect(firstParagraphChips).toHaveLength(1);
    expect(blocks[1].type).toBe(BLOCK_WP_TYPE);
    expect(blockContent(editor, 2)[0].text).toBe(' tail');
  });

  it('does nothing for a pending (non-numeric) wpid', () => {
    const editor = createHeadlessEditor([chipContent('pending:x')]);
    const before = JSON.stringify(editor.document);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 0), 'm');

    expect(JSON.stringify(editor.document)).toBe(before);
  });
});

describe('convertBlockToInlineChip', () => {
  it('replaces the block card with an inline chip paragraph', () => {
    const editor = createHeadlessEditorWithBlocks([
      { type: BLOCK_WP_TYPE, props: { wpid: 7, size: 'm', displayId: '7' } },
    ]);
    const blockId = editor.document[0].id;

    convertBlockToInlineChip(editor, blockId, 7, 'xs');

    const blocks = editor.document;
    expect(blocks[0].type).toBe('paragraph');
    expect(blockContent(editor, 0)[0]).toMatchObject({
      type: INLINE_WP_TYPE,
      props: { wpid: '7', size: 'xs' },
    });
  });
});
