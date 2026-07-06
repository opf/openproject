import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';

// Simulate pasting a plain text URL by dispatching a ClipboardEvent carrying
// only text/plain data, as a browser does when copying from the address bar.
function pastePlainText(plain:string) {
  const el = document.querySelector('[contenteditable]');
  if (!(el instanceof HTMLElement)) {
    throw new Error('Could not find a [contenteditable] element to dispatch paste on');
  }
  const dt = new DataTransfer();
  dt.setData('text/plain', plain);
  el.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
}

describe('Paste work package URL', () => {
  it('creates a block card when pasting into an empty paragraph', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('http://localhost:3000/wp/123');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('creates an inline chip when pasting into a non-empty paragraph', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));
    await userEvent.type(page.getByRole('textbox'), 'See ');

    pastePlainText('http://localhost:3000/work_packages/456');

    await expect.element(page.getByText('#456')).toBeVisible();
    await expect.element(page.getByText('Add dark mode')).toBeVisible();
  });

  it('keeps foreign URLs as plain text', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pastePlainText('https://example.com/wp/123');

    await expect.element(page.getByText('https://example.com/wp/123')).toBeVisible();
  });
});
