import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertInlineWorkPackageViaHash, openEditorAndType } from '../../../helpers/editorHelpers';

describe('Inline chip - formatting toolbar suppression', () => {
  it('clicking a chip does not open the formatting toolbar', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await userEvent.click(page.getByText('#123').first());
    await expect.element(page.getByTestId('popover-content')).toBeVisible();

    await expect.element(page.getByRole('toolbar')).not.toBeInTheDocument();
  });

  it('clicking a chip hides the formatting toolbar when it was already open', async () => {
    renderEditor();
    await openEditorAndType('select me');
    await userEvent.keyboard('{Enter}');
    await insertInlineWorkPackageViaHash('#');

    // Select the text to open the formatting toolbar
    await userEvent.tripleClick(page.getByText('select me'));
    await expect.element(page.getByRole('toolbar')).toBeVisible();

    // Clicking the chip should close the toolbar
    await userEvent.click(page.getByText('#123').first());
    await expect.element(page.getByRole('toolbar')).not.toBeInTheDocument();
  });
});
