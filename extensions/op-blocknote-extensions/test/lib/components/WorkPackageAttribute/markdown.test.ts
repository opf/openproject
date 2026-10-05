// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { BlockNoteEditor, BlockNoteSchema } from '@blocknote/core';
import { openProjectWorkPackageAttributeStaticInlineSpec } from '../../../../lib/server';

const schema = BlockNoteSchema.create().extend({
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
      'The designer is workPackageValue:PROJ-57:Designer, '
      + 'workPackageLabel:PROJ-57:"Content owner": workPackageValue:PROJ-57:"Content owner" '
      + 'and workPackageLabel:PROJ-57:dueDate',
    );
  });
});
