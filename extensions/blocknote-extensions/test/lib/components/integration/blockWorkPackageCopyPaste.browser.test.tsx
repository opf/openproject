import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertInlineWorkPackageViaSlashMenu, convertToCompactCard } from '../../../helpers/editorHelpers';
import {
  computeWorkPackageBlockExternalData,
  buildWorkPackageBlockExternalDOM,
} from '../../../../lib/components/BlockWorkPackage/externalHtml';

// Paste the serialised external HTML of a block card into the editor.
// Dispatch directly on the contenteditable so we can test paste independence
// without relying on browser clipboard permissions.
function pasteBlockCardHtml(wpid:number, size = 'm') {
  const data = computeWorkPackageBlockExternalData({ wpid, size })!;
  const el = document.querySelector('[contenteditable]');
  if (!(el instanceof HTMLElement)) {
    throw new Error('Could not find a [contenteditable] element to dispatch paste on');
  }
  const dt = new DataTransfer();
  dt.setData('text/html', buildWorkPackageBlockExternalDOM(data, document).outerHTML);
  dt.setData('text/plain', `#${wpid}`);
  el.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
}

describe('Block card - paste placement', () => {
  // Left to the default paste, the card ends up indented under the line it was pasted
  // into, with no caret: the next keystroke is swallowed.
  it('pastes below a line with text and leaves the cursor after the card', async () => {
    let editor!:{ document:{ type:string; children:unknown[] }[] };
    renderEditor({ onEditor: (e) => { editor = e; } });
    const textbox = page.getByRole('textbox');
    await userEvent.click(textbox);
    await userEvent.keyboard('before');

    pasteBlockCardHtml(123);
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await userEvent.keyboard('HERE');

    await expect.element(textbox).toHaveTextContent(/before[\s\S]*#123[\s\S]*HERE/);
    expect(editor.document.map((block) => block.type)).toEqual([
      'paragraph',
      'openProjectWorkPackageBlock',
      'paragraph',
    ]);
    // Not nested under the line it was pasted into.
    expect(editor.document[0].children).toEqual([]);
  });

  it('pastes into an empty line and leaves the cursor after the card', async () => {
    renderEditor();
    const textbox = page.getByRole('textbox');
    await userEvent.click(textbox);
    await userEvent.keyboard('before{Enter}');

    pasteBlockCardHtml(123);
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await userEvent.keyboard('HERE');

    await expect.element(textbox).toHaveTextContent(/before[\s\S]*#123[\s\S]*HERE/);
  });

  it('keeps the size of the copied card', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    pasteBlockCardHtml(123, 'xl');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    expect(document.querySelector('[data-testid="block-card"]')?.className)
      .toContain('op-bn-work-package--xl');
  });
});

describe('Block card - copy/paste independence', () => {
  it('removing the pasted copy does not remove the original', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    pasteBlockCardHtml(123);
    await expect.element(page.getByTestId('block-card').nth(1)).toBeVisible();

    // Remove the pasted copy (second card)
    await userEvent.click(page.getByTestId('op-bn-work-package--type').nth(1));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTestId('remove-btn'));

    await expect.element(page.getByTestId('block-card').nth(0)).toBeVisible();
    await expect.element(page.getByTestId('block-card').nth(1)).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('removing the original does not remove the pasted copy', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    pasteBlockCardHtml(123);
    await expect.element(page.getByTestId('block-card').nth(1)).toBeVisible();

    // Remove the original (first card)
    await userEvent.click(page.getByTestId('op-bn-work-package--type').nth(0));
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
    await userEvent.click(page.getByTestId('remove-btn'));

    await expect.element(page.getByTestId('block-card').nth(0)).toBeVisible();
    await expect.element(page.getByTestId('block-card').nth(1)).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('resizing the original does not affect the pasted copy', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
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
    await expect.element(page.getByText('In Progress').nth(0)).toBeVisible();
    await expect.element(page.getByText('In Progress').nth(1)).not.toBeInTheDocument();
  });

  it('resizing the pasted copy does not affect the original', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
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
    await expect.element(page.getByText('In Progress').nth(0)).toBeVisible();
    await expect.element(page.getByText('In Progress').nth(1)).not.toBeInTheDocument();
  });
});
