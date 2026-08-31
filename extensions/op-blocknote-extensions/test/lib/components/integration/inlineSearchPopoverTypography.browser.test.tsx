import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';

const SEARCH_PLACEHOLDER = 'Search by work package ID or subject';

async function openInlineSearch(text:string) {
  renderEditor();
  const editorEl = page.getByRole('textbox');
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, text);
  await userEvent.type(editorEl, '/');

  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());
  await expect.element(page.getByPlaceholder(SEARCH_PLACEHOLDER)).toBeVisible();

  return document.querySelector('.op-bn-search')!;
}

describe('Inline work package search popover', () => {
  it('keeps the editor typography when opened inside a heading', async () => {
    const popover = await openInlineSearch('# Heading ');

    const heading = document.querySelector('[data-content-type="heading"]')!;
    expect(getComputedStyle(heading).fontSize).not.toBe(getComputedStyle(document.body).fontSize);
    expect(heading.contains(popover)).toBe(false);

    const editorStyle = getComputedStyle(document.querySelector('.bn-editor')!);
    const popoverStyle = getComputedStyle(popover);
    expect(popoverStyle.fontSize).toBe(editorStyle.fontSize);
    expect(popoverStyle.fontWeight).toBe(editorStyle.fontWeight);
  });

  it('links a work package picked from inside a heading', async () => {
    await openInlineSearch('# Heading ');

    await userEvent.type(page.getByPlaceholder(SEARCH_PLACEHOLDER), 'Fix');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await userEvent.click(page.getByText('Fix login bug'));

    await expect.element(page.getByPlaceholder(SEARCH_PLACEHOLDER)).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    expect(document.querySelector('[data-content-type="heading"] .op-bn-inline-wp')).not.toBeNull();
  });
});
