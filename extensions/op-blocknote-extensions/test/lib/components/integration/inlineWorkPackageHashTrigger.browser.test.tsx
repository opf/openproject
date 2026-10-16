import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { openEditorAndType } from '../../../helpers/editorHelpers';

describe('Inline chip - # trigger with an existing hash in the line', () => {
  it('preserves an earlier # in the line when inserting a chip via the # notation', async () => {
    renderEditor();

    // Pre-existing text that already contains a hash. Typing "#42" opens the hash
    // menu; Escape dismisses it, leaving "#42" as plain text — as if it had been
    // there from a saved document.
    await openEditorAndType('See PR #42');
    await userEvent.keyboard('{Escape}');

    // Insert a work package via the # notation directly after the existing hash.
    const editor = page.getByRole('textbox');
    await userEvent.type(editor, '#Fix');
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await userEvent.click(page.getByText('Fix login bug'));

    // The chip is inserted and the earlier "#42" must be preserved (only the
    // "#Fix" trigger is removed — by BlockNote's suggestion menu).
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(editor).toHaveTextContent('See PR #42');
  });
});
