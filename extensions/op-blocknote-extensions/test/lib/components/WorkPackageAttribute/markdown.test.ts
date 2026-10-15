// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { BlockNoteEditor, BlockNoteSchema } from '@blocknote/core';
import {
  openProjectWorkPackageAttributeStaticBlockSpec,
  openProjectWorkPackageAttributeStaticInlineSpec,
} from '../../../../lib/server';

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageAttributeBlock: openProjectWorkPackageAttributeStaticBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageAttribute: openProjectWorkPackageAttributeStaticInlineSpec,
  },
});

function attribute(attribute:string, display:string) {
  return { type: 'openProjectWorkPackageAttribute', props: { wpid: '57', displayId: 'PROJ-57', attribute, display } };
}

describe('work package attribute markdown export', () => {
  it('writes the attribute macros into the paragraph', async () => {
    const editor = BlockNoteEditor.create({
      schema,
      initialContent: [{
        type: 'paragraph',
        content: [
          'The designer is ',
          attribute('Designer', 'value'),
          ', ',
          attribute('Content owner', 'both'),
          ' and ',
          attribute('dueDate', 'label'),
        ],
      }] as never,
    });

    expect((await editor.blocksToMarkdownLossy()).trim()).toBe(
      'The designer is workPackageValue:PROJ-57:"Designer", '
      + 'workPackageLabel:PROJ-57:"Content owner": workPackageValue:PROJ-57:"Content owner" '
      + 'and workPackageLabel:PROJ-57:"dueDate"',
    );
  });

  it('writes a long text block as a paragraph of its own', async () => {
    const editor = BlockNoteEditor.create({
      schema,
      initialContent: [
        { type: 'paragraph', content: 'Before' },
        { type: 'openProjectWorkPackageAttributeBlock', props: { wpid: '57', displayId: 'PROJ-57', attribute: 'description', display: 'value' } },
        { type: 'paragraph', content: 'After' },
      ] as never,
    });

    expect((await editor.blocksToMarkdownLossy()).trim())
      .toBe('Before\n\nworkPackageValue:PROJ-57:"description"\n\nAfter');
  });

  it('keeps the paragraph as the block a new document starts with', async () => {
    const editor = BlockNoteEditor.create({ schema });
    const filled:string[] = [];
    editor.pmSchema.topNodeType.createAndFill()!.descendants((node) => {
      if (node.type.isInGroup('blockContent')) filled.push(node.type.name);
    });
    expect(filled).toEqual(['paragraph']);

    const blocks = await editor.tryParseHTMLToBlocks('<p>Plain text</p>');
    expect(blocks.map((block) => block.type)).toEqual(['paragraph']);
  });

  it('turns its own external HTML back into the block', async () => {
    const editor = BlockNoteEditor.create({ schema });
    const html = await editor.blocksToHTMLLossy([
      { type: 'openProjectWorkPackageAttributeBlock', props: { wpid: '57', displayId: 'PROJ-57', attribute: 'description', display: 'both' } },
    ] as never);

    const [block] = await editor.tryParseHTMLToBlocks(html);
    expect(block).toMatchObject({
      type: 'openProjectWorkPackageAttributeBlock',
      props: { wpid: '57', displayId: 'PROJ-57', attribute: 'description', display: 'both' },
    });
  });
});
