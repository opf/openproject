import { expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';

// Insert
export async function openEditorAndType(text:string) {
  const editorEl = page.getByRole('textbox');
  await expect.element(editorEl).toBeVisible();
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, text);
}

export async function insertInlineWorkPackageViaSlashMenu(searchTerm='Fix', resultTerm='Fix login bug') {
  await openEditorAndType(' /');
  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());

  const searchInput = page.getByPlaceholder('Search by work package ID or subject');
  await expect.element(searchInput).toBeVisible();
  await userEvent.type(searchInput, searchTerm);

  await expect.element(page.getByText(resultTerm)).toBeVisible();
  await userEvent.click(page.getByText(resultTerm));

  // default S chip - status visible
  await expect.element(searchInput).not.toBeInTheDocument();
  await expect.element(page.getByText(resultTerm)).toBeVisible();
}

export async function insertInlineWorkPackageViaHash(hashes:string) {
  await openEditorAndType(`${hashes}Fix`);
  await expect.element(page.getByText('Fix login bug')).toBeVisible();
  await userEvent.click(page.getByText('Fix login bug'));
}

// Inline chip - popover & size menu
export async function openInlineWorkPackagePopover(displayId = '#123') {
  await userEvent.click(page.getByText(displayId).first());
  await expect.element(page.getByTestId('popover-content')).toBeVisible();
}

export async function openInlineWorkPackageSizeMenu(displayId = '#123') {
  await openInlineWorkPackagePopover(displayId);
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

export async function convertToCompactCard(displayId = '#123') {
  await openInlineWorkPackageSizeMenu(displayId);
  await userEvent.click(page.getByRole('button', { name: 'Compact card', exact: true }));
  await expect.element(page.getByTestId('block-card')).toBeVisible();
}

export async function insertInlineWorkPackageViaHashWithTextBefore(before:string) {
  const editorEl = page.getByRole('textbox');
  await expect.element(editorEl).toBeVisible();
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, `${before}#Fix`);
  await expect.element(page.getByText('Fix login bug')).toBeVisible();
  await userEvent.click(page.getByText('Fix login bug'));
  await expect.element(page.getByText('#123')).toBeVisible();
}