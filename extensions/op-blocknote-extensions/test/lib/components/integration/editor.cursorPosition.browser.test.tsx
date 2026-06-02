import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';

async function setupEditorWithSurroundingText() {
  const editor = page.getByRole('textbox');
  await userEvent.click(editor);
  await userEvent.type(editor, 'beforeTAIL');
  await userEvent.keyboard('{Home}{ArrowRight>6}');
  return editor;
}

describe('Cursor position after chip insertion', () => {
  describe('/wp slash command (S chip)', () => {
    it('cursor lands right after the chip, not at end of line', async () => {
      renderEditor();
      const editor = await setupEditorWithSurroundingText();

      await userEvent.keyboard('/');
      await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
      await userEvent.click(page.getByText('Link existing work package').first());

      const searchInput = page.getByPlaceholder('Search by work package ID or subject');
      await userEvent.type(searchInput, 'Fix');
      await expect.element(page.getByText('Fix login bug')).toBeVisible();
      await userEvent.click(page.getByText('Fix login bug'));

      await expect.element(page.getByText('Fix login bug')).toBeVisible();

      await userEvent.keyboard('HERE');

      await expect.element(editor).toHaveTextContent(/before.*#123.*HERE.*TAIL/);
    });
  });

  describe('# hash menu (XXS chip — ID only)', () => {
    it('cursor lands right after the chip, not on the next line', async () => {
      renderEditor();
      const editor = await setupEditorWithSurroundingText();

      await userEvent.keyboard('#Fix');
      await expect.element(page.getByText('Fix login bug')).toBeVisible();
      await userEvent.click(page.getByText('Fix login bug'));
      await expect.element(page.getByText('#123')).toBeVisible();

      await userEvent.keyboard('HERE');

      await expect.element(editor).toHaveTextContent(/before.*#123.*HERE.*TAIL/);
    });
  });

  describe('## hash menu (XS chip — ID + type + subject)', () => {
    it('cursor lands right after the chip, not on the next line', async () => {
      renderEditor();
      const editor = await setupEditorWithSurroundingText();

      await userEvent.keyboard('##Fix');
      await expect.element(page.getByText('Fix login bug')).toBeVisible();
      await userEvent.click(page.getByText('Fix login bug'));
      await expect.element(page.getByText('#123')).toBeVisible();

      await userEvent.keyboard('HERE');

      await expect.element(editor).toHaveTextContent(/before.*#123.*HERE.*TAIL/);
    });
  });

  describe('### hash menu (S chip — ID + type + status + subject)', () => {
    it('cursor lands right after the chip, not on the next line', async () => {
      renderEditor();
      const editor = await setupEditorWithSurroundingText();

      await userEvent.keyboard('###Fix');
      await expect.element(page.getByText('Fix login bug')).toBeVisible();
      await userEvent.click(page.getByText('Fix login bug'));
      await expect.element(page.getByText('#123')).toBeVisible();

      await userEvent.keyboard('HERE');

      await expect.element(editor).toHaveTextContent(/before.*#123.*HERE.*TAIL/);
    });
  });
});
