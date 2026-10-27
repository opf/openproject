import { describe, it, expect } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaSlashMenu,
  convertToCompactCard,
} from '../../../helpers/editorHelpers';

describe('displayId - classic (numeric)', () => {
  it('inline chip shows #123 for numeric displayId', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu('123');

    await expect.element(page.getByText('#123')).toBeVisible();
  });

  it('block card shows #123 for numeric displayId', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu('123');
    await convertToCompactCard();

    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).toBeVisible();
  });
});

describe('displayId - semantic (alphanumeric)', () => {
  it('inline chip shows DWPS-1 without # for semantic displayId', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu('DWPS-1', 'Semantic');

    await expect.element(page.getByText('DWPS-1')).toBeVisible();
    await expect.element(page.getByText('#DWPS-1')).not.toBeInTheDocument();
    await expect.element(page.getByText('#789')).not.toBeInTheDocument();
  });

  it('block card shows DWPS-1 without # for semantic displayId', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu('DWPS-1', 'Semantic');
    await convertToCompactCard('DWPS-1');

    await expect.element(page.getByText('DWPS-1')).toBeVisible();
    await expect.element(page.getByText('#DWPS-1')).not.toBeInTheDocument();
    await expect.element(page.getByText('#789')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('block-card')).toBeVisible();
  });
});
