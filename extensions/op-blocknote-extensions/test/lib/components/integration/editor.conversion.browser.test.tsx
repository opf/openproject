import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaSlashMenu,
  insertInlineWorkPackageViaHash,
  insertInlineWorkPackageViaHashWithTextBefore,
  convertToCompactCard,
  openInlineWorkPackageSizeMenu,
  openBlockCardSizeMenu,
} from '../../../helpers/editorHelpers';

describe('Inline chip - convert to block card', () => {
  it('inline -> Compact card replaces chip with block card', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

    await convertToCompactCard();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
  });

  // it('inline → Regular card replaces chip with block card', async () => {
  //   renderEditor();
  //   await insertInlineWorkPackageViaSlashMenu();

  //   await openInlineWorkPackageSizeMenu();
  //   await userEvent.click(page.getByRole('button', { name: 'Regular card', exact: true }));

  //   await expect.element(page.getByTestId('block-card')).toBeVisible();
  //   await expect.element(page.getByText('Fix login bug')).toBeVisible();
  //   await expect.element(page.getByText('In Progress')).toBeVisible();
  // });
});

describe('Block card - convert to inline chip', () => {
  it('block -> Tiny replaces card with XXS chip', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
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
    await insertInlineWorkPackageViaSlashMenu();
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
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();

    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Regular', exact: true }));

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
  });
});

describe('Inline chip -> block: surrounding text is split at chip position', () => {
  it('WP - text: text after chip moves to new paragraph below block', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('#');
    await userEvent.keyboard(' World');

    await openInlineWorkPackageSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('World')).toBeVisible();

    const blockCardEl = page.getByTestId('block-card').element();
    const worldEl = page.getByText('World').element();
    // World must follow the block card in the DOM and not be inside it
    expect(blockCardEl.compareDocumentPosition(worldEl) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(blockCardEl.contains(worldEl)).toBe(false);
  });

  it('text - WP - text: surrounding sentence is split into two paragraphs around the block', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHashWithTextBefore('Hello ');
    await userEvent.keyboard(' World');

    await openInlineWorkPackageSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('Hello')).toBeVisible();
    await expect.element(page.getByText('World')).toBeVisible();
    await expect.element(page.getByText('Hello World')).not.toBeInTheDocument();

    const helloEl = page.getByText('Hello').element();
    const blockCardEl = page.getByTestId('block-card').element();
    const worldEl = page.getByText('World').element();
    // DOM order must be: Hello paragraph -> block card -> World paragraph
    expect(helloEl.compareDocumentPosition(blockCardEl) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(blockCardEl.compareDocumentPosition(worldEl) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(blockCardEl.contains(helloEl)).toBe(false);
    expect(blockCardEl.contains(worldEl)).toBe(false);
  });

  it('text - WP: text before chip stays in paragraph above block', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHashWithTextBefore('Hello ');

    await openInlineWorkPackageSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('Hello')).toBeVisible();

    const helloEl = page.getByText('Hello').element();
    const blockCardEl = page.getByTestId('block-card').element();
    // Hello must precede the block card in the DOM and not be inside it
    expect(helloEl.compareDocumentPosition(blockCardEl) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    expect(blockCardEl.contains(helloEl)).toBe(false);
  });
});

describe('Round-trip conversion', () => {
  it('inline chip survives block card round-trip and retains WP data', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();

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
    await insertInlineWorkPackageViaHash('#');

    // block
    await openInlineWorkPackageSizeMenu();
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