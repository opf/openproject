import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  computeWorkPackageBlockExternalData,
  buildWorkPackageBlockExternalDOM,
} from '../../../../lib/components/BlockWorkPackage/externalHtml';
import {
  computeWorkPackageInlineExternalData,
  buildWorkPackageInlineExternalDOM,
} from '../../../../lib/components/InlineWorkPackage/externalHtml';

// Simulate a paste from an external source (e.g. Hocuspocus markdown export or
// another editor) by dispatching a ClipboardEvent carrying the serialised HTML.
function pasteHtml(html:string, plain:string) {
  const el = document.querySelector('[contenteditable]');
  if (!(el instanceof HTMLElement)) {
    throw new Error('Could not find a [contenteditable] element to dispatch paste on');
  }
  const dt = new DataTransfer();
  dt.setData('text/html', html);
  dt.setData('text/plain', plain);
  el.dispatchEvent(new ClipboardEvent('paste', { clipboardData: dt, bubbles: true, cancelable: true }));
}

describe('Paste external HTML — block work package', () => {
  it('recreates a block card from serialised HTML', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    const data = computeWorkPackageBlockExternalData({ wpid: 123, size: 'm' })!;
    pasteHtml(buildWorkPackageBlockExternalDOM(data, document).outerHTML, '#123');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });
});

describe('Paste external HTML — inline work package', () => {
  it('recreates an inline chip from serialised HTML', async () => {
    renderEditor();
    await userEvent.click(page.getByRole('textbox'));

    const data = computeWorkPackageInlineExternalData({ wpid: '123', size: 's' })!;
    pasteHtml(buildWorkPackageInlineExternalDOM(data, document).outerHTML, '#123');

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });
});
