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
