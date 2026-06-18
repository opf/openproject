// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { BlockNoteEditor, BlockNoteSchema } from '@blocknote/core';
import {
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
} from '../../../lib';
import {
  getSizeFromCurrentBlock,
  insertWpChip,
  removeTriggerBeforeChip,
} from '../../../lib/components/HashMenu/editorUtils';

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});

function createTestEditor(text:string) {
  const editor = BlockNoteEditor.create({
    schema,
    initialContent: [{ type: 'paragraph', content: text }],
  });

  const block = editor.document[0];
  editor.setTextCursorPosition(block, 'end');

  return editor;
}

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

describe('getSizeFromCurrentBlock', () => {
  it('returns xxs for #', () => {
    const editor = createTestEditor('#foo');
    expect(getSizeFromCurrentBlock(editor as any)).toBe('xxs');
  });

  it('returns xs for ##', () => {
    const editor = createTestEditor('##foo');
    expect(getSizeFromCurrentBlock(editor as any)).toBe('xs');
  });

  it('returns s for ### or more', () => {
    expect(getSizeFromCurrentBlock(createTestEditor('###foo') as any)).toBe('s');
    expect(getSizeFromCurrentBlock(createTestEditor('####foo') as any)).toBe('s');
  });

  it('returns xxs if no hashes', () => {
    const editor = createTestEditor('foo');
    expect(getSizeFromCurrentBlock(editor as any)).toBe('xxs');
  });

  it('uses the last hash trigger in the block', () => {
    const editor = createTestEditor('#first ##bug');
    expect(getSizeFromCurrentBlock(editor as any)).toBe('xs');
  });
});

describe('removeTriggerBeforeChip', () => {
  it('removes the trailing # before the chip', () => {
    const editor = createEditorWithContent([
      { type: 'text', text: 'Hello #', styles: {} },
      {
        type: 'openProjectWorkPackageInline',
        props: { wpid: '1', instanceId: 'test-iid', size: 'xxs' },
      },
    ]);

    removeTriggerBeforeChip(editor as any, 'test-iid');

    const block = editor.getBlock(editor.document[0].id);
    expect((block?.content as any)[0].text).toBe('Hello ');
  });

  it('removes multiple trailing hashes (##, ###) before the chip', () => {
    const editor = createEditorWithContent([
      { type: 'text', text: 'Hello ###', styles: {} },
      {
        type: 'openProjectWorkPackageInline',
        props: { wpid: '1', instanceId: 'test-iid', size: 's' },
      },
    ]);

    removeTriggerBeforeChip(editor as any, 'test-iid');

    const block = editor.getBlock(editor.document[0].id);
    expect((block?.content as any)[0].text).toBe('Hello ');
  });

  it('leaves earlier # in the line alone — removes only the trigger # nearest to the chip', () => {
    const editor = createEditorWithContent([
      { type: 'text', text: 'Pre #one #two #', styles: {} },
      {
        type: 'openProjectWorkPackageInline',
        props: { wpid: '1', instanceId: 'test-iid', size: 'xxs' },
      },
    ]);

    removeTriggerBeforeChip(editor as any, 'test-iid');

    const block = editor.getBlock(editor.document[0].id);
    expect((block?.content as any)[0].text).toBe('Pre #one #two ');
  });

  it('removes the previous text node entirely when only # remains', () => {
    const editor = createEditorWithContent([
      { type: 'text', text: '#', styles: {} },
      {
        type: 'openProjectWorkPackageInline',
        props: { wpid: '1', instanceId: 'test-iid', size: 'xxs' },
      },
    ]);

    removeTriggerBeforeChip(editor as any, 'test-iid');

    const block = editor.getBlock(editor.document[0].id);
    expect((block?.content as any)[0].type).toBe('openProjectWorkPackageInline');
  });

  it('does nothing if the chip is not found', () => {
    const editor = createTestEditor('Hello #foo');
    const before = JSON.stringify(editor.document);

    removeTriggerBeforeChip(editor as any, 'nonexistent-iid');

    expect(JSON.stringify(editor.document)).toBe(before);
  });

  it('does nothing when there is no preceding text node', () => {
    const editor = createEditorWithContent([
      {
        type: 'openProjectWorkPackageInline',
        props: { wpid: '1', instanceId: 'test-iid', size: 'xxs' },
      },
    ]);

    const before = JSON.stringify(editor.document);
    removeTriggerBeforeChip(editor as any, 'test-iid');

    expect(JSON.stringify(editor.document)).toBe(before);
  });
});

describe('insertWpChip', () => {
  it('inserts a chip with the work package ID and size', () => {
    const editor = createTestEditor('test ');

    insertWpChip(
      editor as any,
      { id: 1, subject: 'Fix bug' } as any,
      'xxs',
    );

    const block = editor.getBlock(editor.document[0].id);
    const chip = (block?.content as any[]).find(
      (n) => n.type === 'openProjectWorkPackageInline',
    );

    expect(chip).toBeDefined();
    expect(chip.props.wpid).toBe('1');
    expect(chip.props.size).toBe('xxs');
    expect(chip.props.instanceId).toEqual(expect.any(String));
  });

  it('inserts a trailing space after the chip', () => {
    const editor = createTestEditor('test ');

    insertWpChip(
      editor as any,
      { id: 1, subject: 'Fix bug' } as any,
      'xxs',
    );

    const block = editor.getBlock(editor.document[0].id);
    const content = block?.content as any[];

    const chipIdx = content.findIndex(
      (n) => n.type === 'openProjectWorkPackageInline',
    );
    const afterChip = content[chipIdx + 1];

    expect(afterChip?.type).toBe('text');
    expect(afterChip?.text).toBe(' ');
  });
});