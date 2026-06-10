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

    // Verify chip actually moved into the "Last line" block (inline drop splits the text node,
    // so getByText('Last line') won't find it whole - check via the block container instead)
    const chipEl = document.querySelector('.op-bn-inline-wp')!;
    const chipBlock = chipEl.closest('[data-node-type="blockOuter"]');
    expect(chipBlock?.textContent).toContain('Last');
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
