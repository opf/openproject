import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';

describe('Hash trigger - data loss regression', () => {
  it('preserves text before and after the # trigger', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'Hello world example');

    await userEvent.keyboard('{Home}{ArrowRight>5}');
    await userEvent.keyboard('#bug');

    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await userEvent.keyboard('{Enter}');

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(editor).toHaveTextContent(/Hello.*world example/);
  });

  it('preserves surrounding text when inserting an S-size chip via ###', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'before after');

    await userEvent.keyboard('{Home}{ArrowRight>6}');
    await userEvent.keyboard('###bug');

    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await userEvent.keyboard('{Enter}');

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(editor).toHaveTextContent(/before.*after/);
    await expect.element(editor).not.toHaveTextContent('##');
  });
});