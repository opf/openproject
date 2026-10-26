import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertInlineWorkPackageViaHash, openEditorAndType } from '../../../helpers/editorHelpers';

describe('Inline chip - keyboard deletion', () => {
  it('Backspace removes the chip without affecting other text in the document', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await userEvent.keyboard('{Enter}');
    await openEditorAndType('keep this text');

    await userEvent.click(page.getByText('#123').first());
    await expect.element(page.getByTestId('popover-content')).toBeVisible();

    await userEvent.keyboard('{Backspace}');

    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
    await expect.element(page.getByText('keep this text')).toBeVisible();
  });

  it('Delete removes the chip without affecting other text in the document', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await userEvent.keyboard('{Enter}');
    await openEditorAndType('keep this text');

    await userEvent.click(page.getByText('#123').first());
    await expect.element(page.getByTestId('popover-content')).toBeVisible();

    await userEvent.keyboard('{Delete}');

    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
    await expect.element(page.getByText('keep this text')).toBeVisible();
  });
});
