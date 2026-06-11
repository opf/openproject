import { describe, it, expect, vi } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaSlashMenu,
  insertInlineWorkPackageViaHash,
  openInlineWorkPackagePopover,
  openInlineWorkPackageSizeMenu,
} from '../../../helpers/editorHelpers';

describe('Inline chip - insert', () => {
  it('inserts S chip via slash menu - shows ID, type, status, subject', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('inserts XXS chip via # - shows only ID', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
  });

  it('inserts XS chip via ## - shows ID, type, subject but no status', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('##');

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
  });

  it('inserts S chip via ### — shows ID, type, status, subject', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('###');

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
  });
});

describe('Inline chip - resize', () => {
  it('S -> XXS: hides type, status, subject - shows only ID', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await openInlineWorkPackageSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
  });

  it('S -> XS: hides status - shows ID, type, subject', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await openInlineWorkPackageSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact', exact: true }));

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('XS -> XXS: hides type, subject and status - shows only ID', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('##');

    await openInlineWorkPackageSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
    await expect.element(page.getByText('Fix login bug')).not.toBeInTheDocument();
  });
});

describe('Inline chip - popover UX', () => {
  it('popover is not visible before clicking the chip', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await expect.element(page.getByTestId('popover-content')).not.toBeInTheDocument();
  });

  it('clicking the chip opens the popover', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await openInlineWorkPackagePopover();
    await expect.element(page.getByTestId('popover-content')).toBeVisible();
  });

  it('"Open" button opens the work package in a new tab', async () => {
    const openSpy = vi.spyOn(window, 'open').mockReturnValue(null);
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await openInlineWorkPackagePopover();
    await userEvent.click(page.getByTitle('Open in new tab'));

    expect(openSpy).toHaveBeenCalledWith(
      expect.stringContaining('/wp/123'),
      '_blank',
      'noopener,noreferrer',
    );
    openSpy.mockRestore();
  });
});

describe('Inline chip - remove', () => {
  it('removing an inline chip removes it from the editor', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await openInlineWorkPackagePopover();
    await userEvent.click(page.getByTestId('remove-btn'));

    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
  });
});