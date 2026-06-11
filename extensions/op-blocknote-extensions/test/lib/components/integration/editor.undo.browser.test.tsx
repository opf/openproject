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

const ctrl_z = () => userEvent.keyboard('{Control>}z{/Control}');

describe('Undo (Ctrl+Z)', () => {
  it('undoes typed text', async () => {
    renderEditor();
    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'hello');
    await expect.element(editor).toHaveTextContent('hello');

    await ctrl_z();

    await expect.element(editor).not.toHaveTextContent('hello');
  });

  it('multiple undos work sequentially', async () => {
    renderEditor();
    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'first');
    await userEvent.keyboard('{Enter}');
    await userEvent.type(editor, 'second');

    await ctrl_z(); 
    await expect.element(editor).not.toHaveTextContent('second');

    await ctrl_z(); 
    await ctrl_z(); 
    await expect.element(editor).not.toHaveTextContent('first');
  });

  it('undoes chip inserted via slash menu — chip is gone', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();

    await ctrl_z();

    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
  });

  it('undoes chip inserted via ### hash — chip is gone', async () => {
    renderEditor();
    await insertInlineChipViaHash('###');
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByTestId('op-bn-work-package--type')).toBeVisible();

    await ctrl_z();

    await expect.element(page.getByText('#123')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('op-bn-work-package--type')).not.toBeInTheDocument();
  });

  it('undoes inline -> block conversion — block card is gone, inline chip is restored', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    // ProseMirror's newGroupDelay defaults to 500ms - pause longer to keep insertion and conversion as separate undo steps
    await new Promise(r => setTimeout(r, 600));
    await convertToCompactCard();
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await ctrl_z();

    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByText('In Progress')).toBeVisible();
  });

  it('undoes block -> inline conversion — inline chip is gone, block card is restored', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await convertToCompactCard();
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await openBlockCardSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Regular', exact: true }));
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();

    await ctrl_z();

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Fix login bug')).toBeVisible();
  });

  it('undoes inline size change (S -> XS) — status is visible again', async () => {
    renderEditor();
    await insertInlineChipViaSlashMenu();
    await expect.element(page.getByText('In Progress')).toBeVisible();
    await new Promise(r => setTimeout(r, 600));
    await openInlineChipSizeMenu();
    await userEvent.click(page.getByRole('button', { name: 'Compact', exact: true }));
    await expect.element(page.getByText('In Progress')).not.toBeInTheDocument();

    await ctrl_z();

    await expect.element(page.getByText('In Progress')).toBeVisible();
    await expect.element(page.getByText('#123')).toBeVisible();
  });

  it('redo works after undo', async () => {
    renderEditor();
    const editor = page.getByRole('textbox');
    await userEvent.click(editor);
    await userEvent.type(editor, 'hello');

    await ctrl_z();
    await expect.element(editor).not.toHaveTextContent('hello');

    await userEvent.keyboard('{Control>}y{/Control}');
    await expect.element(editor).toHaveTextContent('hello');
  });
});
