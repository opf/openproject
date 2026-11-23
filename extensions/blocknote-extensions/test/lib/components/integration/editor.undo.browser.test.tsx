import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  editorShortcut,
  insertInlineWorkPackageViaSlashMenu,
  insertBlockWorkPackageViaHash,
  insertInlineWorkPackageViaHash,
  convertToCompactCard,
  openInlineWorkPackageSizeMenu,
  openBlockCardSizeMenu,
} from '../../../helpers/editorHelpers';

describe('Keyboard undo', () => {
  it('undoes typed text', async () => {
    renderEditor();
    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'hello');
    await expect.element(editor).toMatchTextContent('hello');

    await editorShortcut('z');

    await expect.element(editor).not.toMatchTextContent('hello');
  });

  it('multiple undos work sequentially', async () => {
    renderEditor();
    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'first');
    await userEvent.keyboard('{Enter}');
    await userEvent.type(editor, 'second');

    await editorShortcut('z');
    await expect.element(editor).not.toMatchTextContent('second');

    await editorShortcut('z');
    await editorShortcut('z');
    await expect.element(editor).not.toMatchTextContent('first');
  });

  it('undoes chip inserted via slash menu — chip is gone', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();

    await editorShortcut('z');

    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
  });

  it('undoes chip inserted via ### hash — chip is gone', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHash('###');
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();

    await editorShortcut('z');

    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
  });

  it('undoes block card inserted via #### hash — card is gone', async () => {
    renderEditor();
    await insertBlockWorkPackageViaHash();

    await editorShortcut('z');

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
  });

  it('undoes inline -> block conversion — block card is gone, inline chip is restored', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    // ProseMirror's newGroupDelay defaults to 500ms - pause longer to keep insertion and conversion as separate undo steps
    await new Promise(r => setTimeout(r, 600));
    await convertToCompactCard();
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await editorShortcut('z');

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
  });

  it('undoes block -> inline conversion — inline chip is gone, block card is restored', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await convertToCompactCard();
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('menuitemradio', { name: 'Regular', exact: true }));
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();

    await editorShortcut('z');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug', { exact: true })).toBeVisible();
  });

  it('undoes inline size change (S -> XS) — status is visible again', async () => {
    renderEditor();
    await insertInlineWorkPackageViaSlashMenu();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await new Promise(r => setTimeout(r, 600));
    await openInlineWorkPackageSizeMenu();
    await userEvent.click(page.getByRole('menuitemradio', { name: 'Compact', exact: true }));
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();

    await editorShortcut('z');

    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByText('#123')).toBeVisible();
  });

  it('redo works after undo', async () => {
    renderEditor();
    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'hello');

    await editorShortcut('z');
    await expect.element(editor).not.toMatchTextContent('hello');

    await editorShortcut('redo');
    await expect.element(editor).toMatchTextContent('hello');
  });
});
