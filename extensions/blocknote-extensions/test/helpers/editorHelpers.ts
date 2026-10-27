import { expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';

export const SEARCH_PLACEHOLDER = 'Search by work package ID or subject';

function touchAt(element:Element) {
  const rect = element.getBoundingClientRect();
  return new Touch({
    identifier: 1,
    target: element,
    clientX: rect.left + rect.width / 2,
    clientY: rect.top + rect.height / 2,
  });
}

export function touchStartElement(element:Element, touch = touchAt(element)) {
  element.dispatchEvent(new TouchEvent('touchstart', {
    bubbles: true, cancelable: true, changedTouches: [touch], touches: [touch],
  }));
}

export function tapElement(element:Element) {
  const touch = touchAt(element);
  touchStartElement(element, touch);
  element.dispatchEvent(new TouchEvent('touchend', {
    bubbles: true, cancelable: true, changedTouches: [touch], touches: [],
  }));
}

// Insert
export async function openEditorAndType(text:string) {
  const editorEl = page.getByRole('textbox');
  await expect.element(editorEl).toBeVisible();
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, text);
}

export async function typeAndSelect(text:string) {
  await openEditorAndType(text);
  await userEvent.keyboard('{Shift>}{Home}{/Shift}');
}

export async function openEditorAndStartBulletList(firstItem = 'First item') {
  await openEditorAndType(`- ${firstItem}`);
  await userEvent.keyboard('{Enter}');
}

export async function insertInlineWorkPackageViaSlashMenu(searchTerm='Fix', resultTerm='Fix login bug') {
  await openEditorAndType(' /');
  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());

  const searchInput = page.getByPlaceholder(SEARCH_PLACEHOLDER);
  await expect.element(searchInput).toBeVisible();
  await userEvent.type(searchInput, searchTerm);

  await expect.element(page.getByText(resultTerm)).toBeVisible();
  await userEvent.click(page.getByText(resultTerm));

  // default S chip - status visible
  await expect.element(searchInput).not.toBeInTheDocument();
  await expect.element(page.getByText(resultTerm)).toBeVisible();
}

export const BLOCK_CARD_HASHES = '####';

async function pickHashMenuResult() {
  await expect.element(page.getByText('Fix login bug')).toBeVisible();
  await userEvent.click(page.getByText('Fix login bug'));
}

async function insertWorkPackageViaHash(trigger:string) {
  await openEditorAndType(`${trigger}Fix`);
  await pickHashMenuResult();
}

export async function insertInlineWorkPackageViaHash(hashes:string) {
  await insertWorkPackageViaHash(hashes);
}

export async function insertBlockWorkPackageViaHash(textBefore = '') {
  await insertWorkPackageViaHash(`${textBefore}${BLOCK_CARD_HASHES}`);
  await expect.element(page.getByTestId('block-card')).toBeVisible();
}

export async function insertBlockWorkPackageViaHashAtCursor() {
  await userEvent.keyboard(`${BLOCK_CARD_HASHES}Fix`);
  await pickHashMenuResult();
  await expect.element(page.getByTestId('block-card')).toBeVisible();
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

export async function openBlockWorkPackageSearch() {
  const editorEl = page.getByRole('textbox');
  await expect.element(editorEl).toBeVisible();
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, '/');

  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());

  const searchInput = page.getByPlaceholder(SEARCH_PLACEHOLDER);
  await expect.element(searchInput).toBeVisible();
  return searchInput;
}

export async function insertBlockWorkPackageViaSlashMenu(searchTerm = 'Fix', resultTerm = 'Fix login bug') {
  const searchInput = await openBlockWorkPackageSearch();

  await userEvent.type(searchInput, searchTerm);
  await expect.element(page.getByText(resultTerm)).toBeVisible();
  await userEvent.click(page.getByText(resultTerm));

  await expect.element(searchInput).not.toBeInTheDocument();
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
  await insertWorkPackageViaHash(`${before}#`);
  await expect.element(page.getByText('#123')).toBeVisible();
}

function caretOffset():number | null {
  const selection = document.getSelection();
  if (selection?.anchorNode == null) return null;
  return selection.anchorOffset;
}

const caretPlacementTimeout = 2000;
const keyPressSettleTimeout = 100;

async function waitForCaret(reached:(at:number | null) => boolean, timeout:number):Promise<boolean> {
  const deadline = Date.now() + timeout;
  for (;;) {
    if (reached(caretOffset())) return true;
    if (Date.now() >= deadline) return false;
    await new Promise((resolve) => { setTimeout(resolve, 10); });
  }
}

// BlockNote 0.54 drops caret keys that arrive before the editor has settled, so a
// batched `{Home}{ArrowRight>N}` loses presses. Each key is repeated until the caret
// has actually moved, and the whole placement is bounded by time, not by a press count.
export async function placeCaretAtOffset(offset:number) {
  const deadline = Date.now() + caretPlacementTimeout;

  while (caretOffset() !== 0) {
    if (Date.now() >= deadline) {
      throw new Error(`Caret did not reach the start of the block: at ${caretOffset()}`);
    }
    await userEvent.keyboard('{Home}');
    await waitForCaret((at) => at === 0, keyPressSettleTimeout);
  }

  for (let at = caretOffset(); at !== offset; at = caretOffset()) {
    if (at === null || at > offset) {
      throw new Error(`Caret overshot while moving to offset ${offset}: now at ${at}`);
    }
    if (Date.now() >= deadline) {
      throw new Error(`Caret did not reach offset ${offset}: at ${at}`);
    }
    await userEvent.keyboard('{ArrowRight}');
    await waitForCaret((now) => now !== null && now > at, keyPressSettleTimeout);
  }
}
