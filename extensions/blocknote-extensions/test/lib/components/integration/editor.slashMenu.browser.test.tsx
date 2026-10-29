import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor, renderEditorInShadowDom } from '../../../helpers/renderEditor';
import { openEditorAndStartBulletList } from '../../../helpers/editorHelpers';

async function openSlashMenuAndSelectWp() {
  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());

  const searchInput = page.getByPlaceholder('Search by work package ID or subject');
  await expect.element(searchInput).toBeVisible();
  await userEvent.type(searchInput, 'Fix');
  await expect.element(page.getByText('Fix login bug')).toBeVisible();
  await userEvent.click(page.getByText('Fix login bug'));
  await expect.element(searchInput).not.toBeInTheDocument();
}

describe('Slash menu - block vs inline routing', () => {
  it('inserts a block card when triggered on an empty line', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);
    await userEvent.type(editorEl, '/');

    await openSlashMenuAndSelectWp();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
  });

  it('inserts an inline chip when triggered on an empty list item', async () => {
    renderEditor();
    await openEditorAndStartBulletList();
    await userEvent.type(page.getByRole('textbox'), '/');

    await openSlashMenuAndSelectWp();

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    expect(document.querySelectorAll('[data-content-type="bulletListItem"]')).toHaveLength(2);
    expect(document.querySelector('[data-content-type="bulletListItem"] .op-bn-inline-wp')).not.toBeNull();
  });

  it('inserts an inline chip when triggered on a non-empty line', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);
    await userEvent.type(editorEl, 'Some text ');
    await userEvent.type(editorEl, '/');

    await openSlashMenuAndSelectWp();

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
  });
});

describe('Slash menu - pending block between cards (BNE-179)', () => {
  const card = { type: 'openProjectWorkPackageBlock', props: { wpid: 123 } };

  it('selects only the pending block, not the cards around it', async () => {
    const { shadowRoot } = await renderEditorInShadowDom({
      initialContent: [card, { type: 'paragraph' }, card],
    });
    await expect.poll(() => shadowRoot.querySelectorAll('[data-testid="block-card"]').length).toBe(2);

    const emptyParagraph = shadowRoot.querySelector('[data-content-type="paragraph"]')!;
    await userEvent.click(emptyParagraph);
    await userEvent.keyboard('/');
    await userEvent.click(page.getByText('Link existing work package').first());
    await expect.poll(() => shadowRoot.activeElement?.id).toBe('op-bn-wp-search-input');

    const selectedFlags = [...shadowRoot.querySelectorAll('[data-testid="block-wp-wrapper"]')]
      .map((wrapper) => wrapper.hasAttribute('data-selected'));
    expect(selectedFlags).toEqual([false, true, false]);
  });
});
