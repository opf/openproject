import { expect, it } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditorInShadowDom } from '../../../helpers/renderEditor';
import { editorShortcut } from '../../../helpers/editorHelpers';

it('applies a text colour with Enter without replacing the selected word', async () => {
  const { shadowRoot } = await renderEditorInShadowDom({
    initialContent: [{ type: 'paragraph', content: 'review' }],
  });
  await userEvent.dblClick(page.getByText('review', { exact: true }));
  await userEvent.click(page.getByRole('button', { name: 'Colors', exact: true }));
  await userEvent.keyboard('{ArrowDown}');
  const gray = page.getByRole('group', { name: 'Text', exact: true }).getByRole('menuitemradio', { name: 'Gray' });
  await expect.element(gray).toHaveFocus();
  await userEvent.keyboard('{Enter}');

  await expect.element(page.getByRole('menu')).not.toBeInTheDocument();
  expect(shadowRoot.querySelector('[data-style-type="textColor"][data-value="gray"]')?.textContent).toBe('review');
  expect(shadowRoot.querySelectorAll('.bn-block-content')).toHaveLength(1);
  await editorShortcut('z');
  expect(shadowRoot.querySelector('[data-style-type="textColor"]')).toBeNull();
  expect(shadowRoot.querySelector('.bn-editor')?.textContent).toBe('review');
});

async function openTableMenu(name:string) {
  const { shadowRoot } = await renderEditorInShadowDom({
    tables: { cellTextColor: true },
    initialContent: [{ type: 'table', content: { type: 'tableContent', rows: [{ cells: ['One', 'Two'] }] } }],
  });
  const cell = page.getByRole('cell', { name: 'One' });
  await userEvent.click(cell);
  await userEvent.hover(cell);
  await userEvent.click(page.getByRole('button', { name, exact: true }));
  const menu = page.getByRole('menu', { name, exact: true });
  await expect.element(menu).toBeVisible();
  return { menu, shadowRoot };
}

it.each(['Row actions', 'Column actions', 'Cell actions'])('dismisses %s with Escape and returns focus to the editor', async (name) => {
  const { menu, shadowRoot } = await openTableMenu(name);
  await userEvent.keyboard('{Escape}');
  await expect.element(menu).not.toBeInTheDocument();
  expect(shadowRoot.activeElement).toBe(shadowRoot.querySelector('.bn-editor'));
});

it('still dismisses the anchored table menu with Tab at narrow widths', async () => {
  await page.viewport(500, 700);
  const { menu } = await openTableMenu('Row actions');
  await userEvent.keyboard('{Tab}');
  await expect.element(menu).not.toBeInTheDocument();
});

it('dismisses the table colour submenu before the column menu', async () => {
  const { menu } = await openTableMenu('Column actions');
  const colors = menu.getByRole('menuitem', { name: 'Colors' });
  colors.element().focus();
  await userEvent.keyboard('{ArrowRight}');
  const gray = page.getByRole('menuitemradio', { name: 'Gray' }).first();
  await expect.element(gray).toBeVisible();
  await userEvent.keyboard('{Escape}');
  await expect.element(gray).not.toBeInTheDocument();
  await expect.element(menu).toBeVisible();
  await expect.element(colors).toHaveFocus();
  await userEvent.keyboard('{Escape}');
  await expect.element(menu).not.toBeInTheDocument();
});
