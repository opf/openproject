import { describe, it, expect } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  openEditorAndType,
  insertBlockWorkPackageViaSlashMenu,
  insertInlineWorkPackageViaHash,
  tapElement,
} from '../../../helpers/editorHelpers';

async function settled(selector:string):Promise<Element> {
  await expect.poll(() => document.querySelector(selector)).not.toBeNull();
  return document.querySelector(selector)!;
}

const chip = () => settled('.op-bn-inline-wp[role="button"]');
const blockCard = () => settled('[data-testid="block-card"]');

describe('Single tap activation', () => {
  it('inserts a work package from one tap on a hash menu row', async () => {
    renderEditor();
    await openEditorAndType('#Fix');
    await expect.element(page.getByText('Add dark mode')).toBeVisible();

    tapElement(document.querySelectorAll('.op-bn-hash-menu-item')[1]);

    await expect.element(page.getByText('#456')).toBeVisible();
    expect(document.querySelectorAll('.op-bn-inline-wp').length).toBe(1);
  });

  it('opens the options popover from one tap on a chip', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    tapElement(await chip());

    await expect.element(page.getByTestId('popover-content')).toBeVisible();
  });

  it('opens the size menu and picks a size, one tap each', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');
    tapElement(await chip());

    tapElement(await settled('button[title="Change size"]'));
    await expect.element(page.getByTestId('size-menu')).toBeVisible();

    tapElement(page.getByLabelText('Compact', { exact: true }).element());

    // Compact (xs) is the first size that spells the subject out on the chip.
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('opens the options popover from one tap on a block card', async () => {
    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();

    tapElement(await blockCard());

    await expect.element(page.getByTestId('remove-btn')).toBeVisible();
    await expect
      .poll(() => document.querySelector('[data-testid="block-wp-wrapper"]')?.getAttribute('data-selected'))
      .toBe('true');
  });

  it('closes the block popover when the next tap opens a chip', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');
    const inlineChip = await chip();
    await insertBlockWorkPackageViaSlashMenu();

    tapElement(await blockCard());
    await expect.element(page.getByTestId('remove-btn')).toBeVisible();
    tapElement(inlineChip);

    await expect.poll(() => document.querySelectorAll('[data-testid="popover-content"]').length).toBe(1);
  });
});
