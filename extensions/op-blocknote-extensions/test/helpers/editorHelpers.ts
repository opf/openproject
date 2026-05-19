import { expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';

// Insert
export async function openEditorAndType(text: string) {
  const editorEl = page.getByRole('textbox');
  await expect.element(editorEl).toBeVisible();
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, text);
}

export async function insertInlineChipViaSlashMenu() {
  await openEditorAndType('/');
  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());

  const searchInput = page.getByPlaceholder('Search by work package ID or subject');
  await expect.element(searchInput).toBeVisible();
  await userEvent.type(searchInput, 'Fix');

  await expect.element(page.getByText('Fix login bug')).toBeVisible();
  await userEvent.click(page.getByText('Fix login bug'));

  // default S chip - status visible
  await expect.element(page.getByText('In Progress')).toBeVisible();
}

export async function insertInlineChipViaHash(hashes: string) {
  await openEditorAndType(`${hashes}Fix`);
  await expect.element(page.getByText('Fix login bug')).toBeVisible();
  await userEvent.click(page.getByText('Fix login bug'));
}

// Inline chip - popover & size menu
export async function openInlineChipPopover(displayId: string = '#123') {
  await userEvent.click(page.getByText(displayId).first());
  await expect.element(page.getByTestId('popover-content')).toBeVisible();
}

export async function insertSemanticInlineChipViaSlashMenu() {
  await openEditorAndType('/');
  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());

  const searchInput = page.getByPlaceholder('Search by work package ID or subject');
  await expect.element(searchInput).toBeVisible();
  await userEvent.type(searchInput, 'Semantic');

  await expect.element(page.getByText('Semantic ID work package')).toBeVisible();
  await userEvent.click(page.getByText('Semantic ID work package'));

  await expect.element(page.getByText('DWPS-1')).toBeVisible();
}

export async function openInlineChipSizeMenu(displayId:string|undefined = '#123') {
  await openInlineChipPopover(displayId);
  await userEvent.click(page.getByTitle('Change size'));
  await expect.element(page.getByTestId('size-menu')).toBeVisible();
}

// Block card - popover & size menu
export async function openBlockCardPopover() {
  await userEvent.click(page.getByTestId('op-bn-work-package--type'));
  await expect.element(page.getByTestId('popover-content')).toBeVisible();
}

export async function openBlockCardSizeMenu() {
  await openBlockCardPopover();
  await userEvent.click(page.getByTitle('Change size'));
  await expect.element(page.getByTestId('size-menu')).toBeVisible();
}

export async function convertToCompactCard(displayId:string|undefined = "#123") {
  await openInlineChipSizeMenu(displayId);
  await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));
  await expect.element(page.getByTestId('block-card')).toBeVisible();
}