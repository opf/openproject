import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertBlockWorkPackageViaSlashMenu } from '../../../helpers/editorHelpers';

const blockIsSelected = () =>
  document.querySelector('[data-testid="block-wp-wrapper"][data-selected]') !== null;

describe('Block WP – blue border on focus (BNE-95)', () => {
  it('shows border when clicked after typing text below the block', async () => {
    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();

    // cursor lands below the block after insertion – press Enter twice then type
    await userEvent.keyboard('{Enter}{Enter}');
    await userEvent.keyboard('some text');

    await userEvent.click(page.getByTestId('block-wp-wrapper'));
    await expect.poll(blockIsSelected).toBe(true);
  });

  it('shows border when clicked after typing text above the block (exact BNE-95 scenario)', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);

    // type text first, then insert WP block below – text is now ABOVE the block
    await userEvent.keyboard('some text{Enter}');
    await insertBlockWorkPackageViaSlashMenu();

    // move cursor to the text above
    await userEvent.click(page.getByText('some text'));

    await userEvent.click(page.getByTestId('block-wp-wrapper'));
    await expect.poll(blockIsSelected).toBe(true);
  });
});

describe('Block WP - no text highlight on selection (BNE-125)', () => {
  it('leaves no card text highlighted when the card is clicked', async () => {
    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();
    await expect.element(page.getByTestId('block-wp-wrapper')).toBeVisible();

    await userEvent.click(page.getByTestId('op-bn-work-package--type'));

    await expect.poll(blockIsSelected).toBe(true);
    await expect.poll(() => window.getSelection()?.toString()).toBe('');
  });

  it('leaves no card text highlighted when a selection already spanned the card', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);
    await userEvent.keyboard('above{Enter}');
    await insertBlockWorkPackageViaSlashMenu();
    await userEvent.keyboard('{Enter}below');

    await userEvent.click(page.getByText('above'));
    await userEvent.keyboard('{Home}');
    await userEvent.keyboard('{Shift>}{ArrowDown}{ArrowDown}{ArrowDown}{/Shift}');
    // The card is already part of the selection, so clicking it node-selects it
    // without the selected flag ever flipping.
    await expect.poll(blockIsSelected).toBe(true);

    await userEvent.click(page.getByTestId('op-bn-work-package--type'));

    await expect.poll(blockIsSelected).toBe(true);
    await expect.poll(() => window.getSelection()?.toString()).toBe('');
  });
});
