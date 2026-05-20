import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertInlineChipViaSlashMenu, convertToCompactCard } from '../../../helpers/editorHelpers';

describe('Drag and drop - inline chip', () => {
  it('chip has data-drag-handle and is not independently draggable', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'Before ');
    await insertInlineChipViaSlashMenu();

    await expect.element(page.getByText('#123')).toBeVisible();

    const chipEl = page.getByText('#123').element().closest('.op-bn-inline-wp') as HTMLElement;
    expect(chipEl).not.toBeNull();
    expect(chipEl.hasAttribute('data-drag-handle')).toBe(true);
    expect(chipEl.getAttribute('draggable')).not.toBe('true');
  });

  it('dragging chip block does not create a duplicate', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'First line');
    await userEvent.keyboard('{Enter}');
    await insertInlineChipViaSlashMenu();
    await userEvent.keyboard('{Enter}');
    await userEvent.type(editor, 'Last line');

    await expect.element(page.getByText('#123')).toBeVisible();
    expect(document.querySelectorAll('.op-bn-inline-wp')).toHaveLength(1);

    await userEvent.dragAndDrop(
      document.querySelector('.op-bn-inline-wp')!,
      page.getByText('Last line'),
    );

    await expect.element(page.getByText('#123')).toBeVisible();
    expect(document.querySelectorAll('.op-bn-inline-wp')).toHaveLength(1);

    // Verify chip actually moved below "Last line" (not just that count is 1)
    const chipEl = document.querySelector('.op-bn-inline-wp')!;
    const lastLineEl = page.getByText('Last line').element();
    expect(lastLineEl.compareDocumentPosition(chipEl) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });
});

describe('Drag and drop - block card', () => {
  it('block card container is draggable', async () => {
    renderEditor();

    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();

    const blockContainer = page.getByTestId('block-card').element().closest('.op-bn-extensions') as HTMLElement;
    expect(blockContainer).not.toBeNull();
    expect(blockContainer.getAttribute('draggable')).toBe('true');
  });
});
