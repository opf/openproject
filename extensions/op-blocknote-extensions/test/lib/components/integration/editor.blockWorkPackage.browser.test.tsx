import { describe, it, expect, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaSlashMenu,
  convertToCompactCard,
  openBlockCardPopover,
  openBlockCardSizeMenu,
} from '../../../helpers/editorHelpers';

describe('Block card - resize', () => {
  // it('Compact card -> Regular card: both show title and status', async () => {
  //   renderEditor();
  //   await insertInlineWorkPackageViaSlashMenu();
  //   await convertToCompactCard();

  //   await openBlockCardSizeMenu();
  //   await userEvent.click(page.getByRole('button', { name: 'Regular card', exact: true }));

  //   await expect.element(page.getByTestId('block-card')).toBeVisible();
  //   await expect.element(page.getByText('Fix login bug')).toBeVisible();
  //   await expect.element(page.getByText('In Progress')).toBeVisible();
  // });

  // it('Regular card -> Full card shows extended content', async () => {
  //   renderEditor();
  //   await insertInlineWorkPackageViaSlashMenu();

  //   await openBlockCardSizeMenu();
  //   await userEvent.click(page.getByRole('button', { name: 'Regular card', exact: true }));
  //   await expect.element(page.getByTestId('block-card')).toBeVisible();

  //   await openBlockCardSizeMenu();
  //   await userEvent.click(page.getByRole('button', { name: 'Full card', exact: true }));

  //   await expect.element(page.getByTestId('block-card')).toBeVisible();
  //   await expect.element(page.getByText('Fix login bug')).toBeVisible();
  //   await expect.element(page.getByText('In Progress')).toBeVisible();
  // });

  it('size button label reflects current card size', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardPopover();
    await expect.element(page.getByTitle('Change size')).toHaveTextContent('Compact card');
  });

  it('size menu shows all 4 options for a block card', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardSizeMenu();

    for (const label of [
      'Tiny',
      'Compact',
      'Regular',
      'Compact card',
    ]) {
      await expect.element(page.getByRole('button', { name: label, exact: true })).toBeVisible();
    }
  });

  it('size menu closes after selecting a size', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));

    await expect.element(page.getByTestId('size-menu')).not.toBeInTheDocument();
  });
});

describe('Block card - popover UX', () => {
  it('popover is not visible before clicking the card', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
  });

  it('clicking the card opens the popover', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardPopover();
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
  });

  it('"Open" button opens the work package in a new tab', async () => {
    const openSpy = vi.spyOn(window, 'open').mockReturnValue(null);
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardPopover();
    await userEvent.click(page.getByTitle('Open in new tab'));

    expect(openSpy).toHaveBeenCalledWith(
      expect.stringContaining('/wp/123'),
      '_blank',
      'noopener,noreferrer',
    );
    openSpy.mockRestore();
  });
});

describe('Block card - remove', () => {
  it('removing a block card removes it from the editor', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardPopover();
    await userEvent.click(page.getByTestId('remove-btn'));

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
  });
});

describe('Block card - selection', () => {
  it('the card wrapper is not text-selectable', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    const wrapper = document.querySelector('[data-testid="block-wp-wrapper"]')!;
    // user-select: all made a single click highlight the whole card's text.
    expect(getComputedStyle(wrapper).userSelect).toBe('none');
  });

  // role=button is what makes iOS fire the click on the first tap (a plain div
  // in the contenteditable needs two); see BlockCards.
  it('the clickable card exposes role=button', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    expect(page.getByTestId('block-card').element().getAttribute('role')).toBe('button');
  });
});