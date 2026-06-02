import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertInlineChipViaSlashMenu, convertToCompactCard } from '../../../helpers/editorHelpers';
import {
  computeWorkPackageBlockExternalData,
  buildWorkPackageBlockExternalDOM,
} from '../../../../lib/components/BlockWorkPackage/externalHtml';

// Paste the serialised external HTML of a block card into the editor.
// Dispatch directly on the contenteditable so we can test paste independence
// without relying on browser clipboard permissions.
function pasteBlockCardHtml(wpid: number) {
  const data = computeWorkPackageBlockExternalData({ wpid, size: 'm' })!;
  const el = document.querySelector('[contenteditable]');
  if (!(el instanceof HTMLElement)) {
    throw new Error('Could not find a [contenteditable] element to dispatch paste on');
  }
  const dt = new DataTransfer();
  dt.setData('text/html', buildWorkPackageBlockExternalDOM(data, document).outerHTML);
  dt.setData('text/plain', `#${wpid}`);
  el.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
}

describe('Block card - copy/paste independence', () => {
  it('removing the pasted copy does not remove the original', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    pasteBlockCardHtml(123);
    await expect.element(page.getByTestId('block-card').nth(1)).toBeVisible();

    // Remove the pasted copy (second card)
    await userEvent.click(page.getByTestId('op-bn-work-package--type').nth(1));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTestId('remove-btn'));

    expect((await page.getByTestId('block-card').all()).length).toBe(1);
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('removing the original does not remove the pasted copy', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    pasteBlockCardHtml(123);
    await expect.element(page.getByTestId('block-card').nth(1)).toBeVisible();

    // Remove the original (first card)
    await userEvent.click(page.getByTestId('op-bn-work-package--type').nth(0));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTestId('remove-btn'));

    expect((await page.getByTestId('block-card').all()).length).toBe(1);
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('resizing the original does not affect the pasted copy', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    pasteBlockCardHtml(123);
    await expect.element(page.getByTestId('block-card').nth(1)).toBeVisible();

    // Resize the original (first card) to Tiny — status badge disappears for it
    await userEvent.click(page.getByTestId('op-bn-work-package--type').nth(0));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTitle('Change size'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    // The pasted copy still shows the status
    expect((await page.getByText('In Progress').all()).length).toBe(1);
  });

  it('resizing the pasted copy does not affect the original', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    pasteBlockCardHtml(123);
    await expect.element(page.getByTestId('block-card').nth(1)).toBeVisible();

    // Resize the pasted copy (second card) to Tiny
    await userEvent.click(page.getByTestId('op-bn-work-package--type').nth(1));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTitle('Change size'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    // The original still shows the status
    expect((await page.getByText('In Progress').all()).length).toBe(1);
  });
});
