// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { BlockNoteEditor, BlockNoteSchema } from '@blocknote/core';
import {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
} from '../../../lib';
import {
  findPendingInlineChip,
  removeInlineChipAt,
  promoteInlineChipToBlockAt,
  convertBlockToInlineChip,
} from '../../../lib/utils/inlineChipActions';

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});

 
function createEditorWithContent(content:any[]) {
  return BlockNoteEditor.create({
    schema,
    initialContent: [
      {
        type: 'paragraph',
        content,
         
      } as any,
    ],
  });
}

function chip(wpid:string, size = 's') {
  return { type: 'openProjectWorkPackageInline', props: { wpid, size } };
}

function text(value:string) {
  return { type: 'text', text: value, styles: {} };
}

// Position of the nth (0-based) inline chip in the document.
function nthChipPosition(editor:BlockNoteEditor, ordinal:number):number {
  let seen = -1;
  let found = -1;
  editor.prosemirrorState.doc.descendants((node, position) => {
    if (found !== -1) return false;
    if (node.type.name === 'openProjectWorkPackageInline') {
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

 
function blockContent(editor:BlockNoteEditor, blockIndex = 0):any[] {
   
  return (editor.document[blockIndex]?.content ?? []) as any[];
}

describe('findPendingInlineChip', () => {
  it('finds the chip with the given pending wpid', () => {
    const editor = createEditorWithContent([text('a'), chip('pending:x'), text('b')]);

    const found = findPendingInlineChip(editor.prosemirrorState.doc, 'pending:x');

    expect(found).not.toBeNull();
    expect(found?.node.attrs.wpid).toBe('pending:x');
    expect(found?.position).toBe(nthChipPosition(editor, 0));
  });

  it('returns null when no chip matches', () => {
    const editor = createEditorWithContent([text('a'), chip('1')]);

    expect(findPendingInlineChip(editor.prosemirrorState.doc, 'pending:x')).toBeNull();
  });

  it('returns null when the wpid does not carry the pending prefix, even if a matching chip exists', () => {
    const editor = createEditorWithContent([chip('1')]);

    expect(findPendingInlineChip(editor.prosemirrorState.doc, '1')).toBeNull();
  });
});

describe('removeInlineChipAt', () => {
  it('removes exactly the chip at the given position', () => {
    const editor = createEditorWithContent([chip('1'), text(' between '), chip('1')]);

    removeInlineChipAt(editor, nthChipPosition(editor, 1));

    const content = blockContent(editor);
    const chips = content.filter((n) => n.type === 'openProjectWorkPackageInline');
    expect(chips).toHaveLength(1);
    expect(content[0].type).toBe('openProjectWorkPackageInline');
  });

  it('does nothing when the position does not hold a chip', () => {
    const editor = createEditorWithContent([text('abc'), chip('1')]);
    const before = JSON.stringify(editor.document);

    removeInlineChipAt(editor, 1);

    expect(JSON.stringify(editor.document)).toBe(before);
  });
});

describe('promoteInlineChipToBlockAt', () => {
  it('replaces a lone chip with a block card', () => {
    const editor = createEditorWithContent([chip('7')]);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 0), 'm');

    const blocks = editor.document;
    expect(blocks[0].type).toBe('openProjectWorkPackageBlock');
     
    expect((blocks[0].props as any).wpid).toBe(7);
     
    expect((blocks[0].props as any).size).toBe('m');
  });

  it('keeps content before the chip in the original paragraph', () => {
    const editor = createEditorWithContent([text('before '), chip('7')]);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 0), 'm');

    const blocks = editor.document;
    expect(blocks[0].type).toBe('paragraph');
    expect(blockContent(editor, 0)[0].text).toBe('before ');
    expect(blocks[1].type).toBe('openProjectWorkPackageBlock');
  });

  it('moves content after the chip into a new paragraph below the block', () => {
    const editor = createEditorWithContent([text('before '), chip('7'), text(' after')]);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 0), 'l');

    const blocks = editor.document;
    expect(blocks[0].type).toBe('paragraph');
    expect(blocks[1].type).toBe('openProjectWorkPackageBlock');
    expect(blocks[2].type).toBe('paragraph');
    expect(blockContent(editor, 2)[0].text).toBe(' after');
  });

  it('promotes the correct chip when identical chips share the paragraph', () => {
    const editor = createEditorWithContent([chip('7'), text(' mid '), chip('7'), text(' tail')]);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 1), 'm');

    const blocks = editor.document;
    // First chip stays inline in the first paragraph.
    const firstParagraphChips = blockContent(editor, 0).filter(
      (n) => n.type === 'openProjectWorkPackageInline'
    );
    expect(firstParagraphChips).toHaveLength(1);
    expect(blocks[1].type).toBe('openProjectWorkPackageBlock');
    expect(blockContent(editor, 2)[0].text).toBe(' tail');
  });

  it('does nothing for a pending (non-numeric) wpid', () => {
    const editor = createEditorWithContent([chip('pending:x')]);
    const before = JSON.stringify(editor.document);

    promoteInlineChipToBlockAt(editor, nthChipPosition(editor, 0), 'm');

    expect(JSON.stringify(editor.document)).toBe(before);
  });
});

describe('convertBlockToInlineChip', () => {
  it('replaces the block card with an inline chip paragraph', () => {
    const editor = BlockNoteEditor.create({
      schema,
      initialContent: [
        {
          type: 'openProjectWorkPackageBlock',
          props: { wpid: 7, size: 'm', displayId: '7' },
           
        } as any,
      ],
    });
    const blockId = editor.document[0].id;

    convertBlockToInlineChip(editor, blockId, 7, 'xs');

    const blocks = editor.document;
    expect(blocks[0].type).toBe('paragraph');
    const inserted = blockContent(editor, 0)[0];
    expect(inserted.type).toBe('openProjectWorkPackageInline');
    expect(inserted.props.wpid).toBe('7');
    expect(inserted.props.size).toBe('xs');
  });
});
