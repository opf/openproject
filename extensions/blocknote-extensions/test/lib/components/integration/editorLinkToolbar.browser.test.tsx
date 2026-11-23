import { assert, expect, it } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditorInShadowDom } from '../../../helpers/renderEditor';

it('keeps the create form open when the URL is empty', async () => {
  const { shadowRoot } = await renderEditorInShadowDom({
    initialContent: [{ type: 'paragraph', content: 'handbook' }],
  });
  await userEvent.dblClick(page.getByText('handbook', { exact: true }));
  await userEvent.click(page.getByRole('button', { name: /^Create link/ }));
  const dialog = page.getByRole('dialog', { name: 'Create link' });
  const url = dialog.getByRole('textbox', { name: 'URL' });
  await userEvent.click(url);
  await userEvent.keyboard('{Enter}');
  await expect.element(dialog).toBeVisible();
  const input = url.element();
  assert.instanceOf(input, HTMLInputElement);
  expect(input.validity.valueMissing).toBe(true);
  expect(shadowRoot.querySelector('.bn-editor a')).toBeNull();

  await userEvent.fill(url, '   ');
  await userEvent.click(dialog.getByRole('button', { name: 'Save' }));
  expect(input.validity.patternMismatch).toBe(true);
  expect(shadowRoot.querySelector('.bn-editor a')).toBeNull();

  await userEvent.fill(url, 'https://example.org/handbook');
  await userEvent.click(dialog.getByRole('button', { name: 'Save' }));
  await expect.element(page.getByRole('link', { name: 'handbook' })).toHaveAttribute('href', 'https://example.org/handbook');
});

it('reopens the link toolbar on hover after Escape and after editing with the caret inside the link', async () => {
  await renderEditorInShadowDom({
    initialContent: [{ type: 'paragraph', content: [
      { type: 'link', href: 'https://example.org/old', content: 'handbook' }, ' appendix',
    ] }, { type: 'paragraph', content: 'Other paragraph' }],
  });
  const link = page.getByRole('link', { name: 'handbook' });
  const edit = page.getByRole('button', { name: 'Edit link', exact: true });
  await userEvent.click(page.getByText('appendix'));
  await userEvent.keyboard('{Home}{ArrowRight}');
  await expect.element(edit).toBeVisible();
  await userEvent.keyboard('{Escape}');
  await expect.element(edit).not.toBeInTheDocument();
  await userEvent.hover(page.getByText('Other paragraph'));
  await userEvent.hover(link);
  await expect.element(edit).toBeVisible();
  await userEvent.click(edit);

  const dialog = page.getByRole('dialog', { name: 'Edit link' });
  const url = dialog.getByRole('textbox', { name: 'URL' });
  await userEvent.fill(url, 'https://example.org/new');
  await userEvent.keyboard('{Enter}');
  await expect.element(link).toHaveAttribute('href', 'https://example.org/new');
  await expect.element(edit).not.toBeInTheDocument();
  await userEvent.hover(page.getByText('Other paragraph'));
  await userEvent.hover(link);
  await expect.element(edit).toBeVisible();
});
