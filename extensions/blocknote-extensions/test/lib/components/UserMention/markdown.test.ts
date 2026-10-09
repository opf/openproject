// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { BlockNoteEditor, BlockNoteSchema } from '@blocknote/core';
import { openProjectUserMentionStaticSpec } from '../../../../lib/server';
import { mentionContent, paragraphWith } from '../../../helpers/content';

// Not the shared headless editor: that one uses the React specs, while the stored markdown comes from the server-side static spec.
const schema = BlockNoteSchema.create().extend({
  inlineContentSpecs: { openProjectUserMention: openProjectUserMentionStaticSpec },
});

async function markdownOf(blocks:unknown[]) {
  const editor = BlockNoteEditor.create({ schema, initialContent: blocks as never });
  return (await editor.blocksToMarkdownLossy()).trim();
}

const judith = '<mention class="mention" data-id="5" data-type="user" data-text="@Judith Roth">@Judith Roth</mention>';

describe('user mention markdown export', () => {
  it('writes the OpenProject mention tag into a paragraph', async () => {
    expect(await markdownOf([paragraphWith('Thanks ', mentionContent('5', 'Judith Roth'), ' for the review')]))
      .toBe(`Thanks ${judith} for the review`);
  });

  it('keeps the tag in a list item and after bold text', async () => {
    expect(await markdownOf([
      { type: 'bulletListItem', content: [mentionContent('5', 'Judith Roth')] },
      paragraphWith({ type: 'text', text: 'Owner ', styles: { bold: true } }, mentionContent('5', 'Judith Roth')),
    ])).toBe(`* ${judith}\n\n**Owner** ${judith}`);
  });

  it('escapes a name so OpenProject reads the same name back', async () => {
    expect(await markdownOf([paragraphWith(mentionContent('9', 'Ann "A&B" <Lee>'))]))
      .toBe('<mention class="mention" data-id="9" data-type="user" data-text="@Ann &quot;A&amp;B&quot; &lt;Lee&gt;">@Ann "A&amp;B" &lt;Lee&gt;</mention>');
  });

  it('writes nothing for a mention without a user', async () => {
    expect(await markdownOf([paragraphWith('Hi ', mentionContent('', ''), 'there')]))
      .toBe('Hi there');
  });
});
