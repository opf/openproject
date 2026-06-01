import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineChipViaSlashMenu,
  insertInlineChipViaHash,
  convertToCompactCard,
  openInlineChipSizeMenu,
  openBlockCardSizeMenu,
} from '../../../helpers/editorHelpers';

describe('Inline chip - convert to block card', () => {
  it('inline -> Compact card replaces chip with block card', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();

    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
  });

  // it('inline → Regular card replaces chip with block card', async () => {
  //   renderEditor();
  //   await insertInlineChipViaSlashMenu();

  //   await openInlineChipSizeMenu();
  //   await userEvent.click(page.getByRole('button', { name: 'Regular card', exact: true }));

  //   await expect.element(page.getByTestId('block-card')).toBeVisible();
  //   await expect.element(page.getByText('Fix login bug')).toBeVisible();
  //   await expect.element(page.getByText('In Progress')).toBeVisible();
  // });
});

describe('Block card - convert to inline chip', () => {
  it('block -> Tiny replaces card with XXS chip', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
  });

  it('block -> Compact (inline) replaces card with XS chip', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact', exact: true }));

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();
  });

  it('block -> Regular (inline) replaces card with S chip', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Regular', exact: true }));

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
  });
});

describe('Round-trip conversion', () => {
  it('inline chip survives block card round-trip and retains WP data', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();

    // block
    await convertToCompactCard();
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    // back to inline S
    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Regular', exact: true }));

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('XXS chip inserted via # survives block card round-trip', async () => {
    renderEditor();
    await insertInlineChipViaHash('#');

    // block
    await openInlineChipSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    // back to XXS inline
    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Tiny', exact: true }));

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
  });
});