import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  BLOCK_CARD_HASHES,
  insertBlockWorkPackageViaHash,
  insertBlockWorkPackageViaHashAtCursor,
  openEditorAndType,
} from '../../../helpers/editorHelpers';

const inlineChip = () =>
  document.querySelector('[data-inline-content-type="openProjectWorkPackageInline"]');

describe('Block card - #### trigger', () => {
  it('#### inserts a block card instead of an inline chip', async () => {
    renderEditor();

    await insertBlockWorkPackageViaHash();

    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();
    expect(inlineChip()).toBeNull();
  });

  it('leaves no trigger hashes behind', async () => {
    renderEditor();

    await insertBlockWorkPackageViaHash();

    await expect.element(page.getByRole('textbox')).not.toHaveTextContent('###');
  });

  it('moves the card onto its own line when invoked after text', async () => {
    renderEditor();

    await insertBlockWorkPackageViaHash('Hello ');

    await expect.element(page.getByText('Hello')).toBeVisible();
    const helloEl = page.getByText('Hello').element();
    const blockCardEl = page.getByTestId('block-card').element();
    expect(blockCardEl.contains(helloEl)).toBe(false);
    expect(helloEl.compareDocumentPosition(blockCardEl) & Node.DOCUMENT_POSITION_FOLLOWING)
      .toBeTruthy();
  });

  it('splits the sentence it is invoked in around the card', async () => {
    renderEditor();

    await openEditorAndType('Hello World');
    await userEvent.keyboard('{ArrowLeft>6/}');
    await insertBlockWorkPackageViaHashAtCursor();

    await expect.element(page.getByText('Hello', { exact: true })).toBeVisible();
    await expect.element(page.getByText('World', { exact: true })).toBeVisible();
    await expect.element(page.getByText('Hello World')).not.toBeInTheDocument();

    const helloEl = page.getByText('Hello', { exact: true }).element();
    const blockCardEl = page.getByTestId('block-card').element();
    const worldEl = page.getByText('World', { exact: true }).element();
    expect(helloEl.compareDocumentPosition(blockCardEl) & Node.DOCUMENT_POSITION_FOLLOWING)
      .toBeTruthy();
    expect(blockCardEl.compareDocumentPosition(worldEl) & Node.DOCUMENT_POSITION_FOLLOWING)
      .toBeTruthy();
  });

  it('stops searching past #### and leaves the hashes as typed', async () => {
    renderEditor();

    await openEditorAndType(BLOCK_CARD_HASHES);
    await expect.element(page.getByTestId('hash-menu')).toBeVisible();

    await userEvent.keyboard('#');
    await expect.element(page.getByTestId('hash-menu')).not.toBeInTheDocument();

    await userEvent.keyboard('Fix');

    await expect.element(page.getByTestId('hash-menu')).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveTextContent('#####Fix');
    expect(inlineChip()).toBeNull();
    expect(document.querySelector('[data-testid="block-card"]')).toBeNull();
  });
});
