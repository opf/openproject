import { describe, expect, it } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor, renderEditorWithHandle } from '../../../helpers/renderEditor';
import { mentionContent, paragraphWith } from '../../../helpers/content';
import { mentionsIn } from '../../../helpers/headlessEditor';
import { withNavigationPrevented } from '../../../helpers/editorHelpers';

const anna = mentionContent('7', 'Anna Kovalenko');

describe('User mention', () => {
  it('shows the avatar and the name, linking to the user in a new tab', async () => {
    renderEditor({ initialContent: [paragraphWith('Thanks ', anna)] });

    const link = page.getByRole('link', { name: 'Anna Kovalenko' });
    await expect.element(link).toHaveAttribute('href', 'http://localhost:3000/users/7');
    await expect.element(link).toHaveAttribute('target', '_blank');
    await expect.element(link).toHaveAttribute('rel', 'noopener noreferrer');
  });

  it('lets the browser follow the name link on click', async () => {
    renderEditor({ initialContent: [paragraphWith('Thanks ', anna)] });
    const link = page.getByRole('link', { name: 'Anna Kovalenko' });
    await expect.element(link).toBeVisible();

    const clicks = await withNavigationPrevented(() => userEvent.click(link));

    expect(clicks).toEqual([{ defaultPrevented: false, href: 'http://localhost:3000/users/7' }]);
  });

  it('serialises to a mention element and parses it back', async () => {
    const editor = await renderEditorWithHandle({ initialContent: [paragraphWith(anna)] });
    await expect.element(page.getByRole('link', { name: 'Anna Kovalenko' })).toBeVisible();

    const html = await editor.blocksToHTMLLossy(editor.document);
    expect(html).toContain('<mention class="mention" data-id="7" data-type="user" data-text="@Anna Kovalenko">@Anna Kovalenko</mention>');

    editor.setTextCursorPosition(editor.document[0], 'end');
    editor.pasteHTML(html);
    expect(mentionsIn(editor)).toEqual([anna.props, anna.props]);
  });

  it('pastes a CKEditor mention as a mention', async () => {
    const editor = await renderEditorWithHandle({ initialContent: [paragraphWith('Hello')] });
    await expect.element(page.getByText('Hello')).toBeVisible();

    editor.setTextCursorPosition(editor.document[0], 'end');
    editor.pasteHTML('<p><mention class="mention" data-id="8" data-type="user" data-text="@Peter Lang">@Peter Lang</mention></p>');
    expect(mentionsIn(editor)).toEqual([{ userId: '8', name: 'Peter Lang' }]);
  });
});
