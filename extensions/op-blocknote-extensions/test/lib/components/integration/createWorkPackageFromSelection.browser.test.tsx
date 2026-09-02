import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  fillRequiredFieldsBesidesSubject,
  openCreateModalFromToolbar,
} from '../../../helpers/createWorkPackageHelpers';

async function typeAndSelect(text:string) {
  const editorEl = page.getByRole('textbox');
  await expect.element(editorEl).toBeVisible();
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, text);
  await userEvent.keyboard('{Shift>}{Home}{/Shift}');
}

describe('Create work package from a text selection', () => {
  it('names the work package after the selected text and puts it in its place', async () => {
    renderEditor();
    await typeAndSelect('Redesign the landing page');

    await openCreateModalFromToolbar();
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('Redesign the landing page');

    await fillRequiredFieldsBesidesSubject();
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByText('#999')).toBeVisible();
    await expect.element(page.getByText('Redesign the landing page')).not.toBeInTheDocument();
  });

  it('gives the text back on a single undo', async () => {
    renderEditor();
    await typeAndSelect('Redesign the landing page');

    await openCreateModalFromToolbar();
    await fillRequiredFieldsBesidesSubject();
    await userEvent.click(page.getByTestId('create-wp-submit'));
    await expect.element(page.getByText('#999')).toBeVisible();

    await userEvent.keyboard('{Control>}z{/Control}');

    await expect.element(page.getByText('Redesign the landing page')).toBeVisible();
    await expect.element(page.getByText('#999')).not.toBeInTheDocument();
  });

  it('leaves the document as it was when the form is dismissed', async () => {
    renderEditor();
    await typeAndSelect('Redesign the landing page');

    await openCreateModalFromToolbar();
    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByText('Redesign the landing page')).toBeVisible();
    await expect.element(page.getByText('#999')).not.toBeInTheDocument();
  });

  it('takes a selection that spans lines as a single line of subject', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);
    await userEvent.type(editorEl, 'Redesign the landing page{Enter}and the footer');
    await userEvent.keyboard('{Control>}a{/Control}');

    await openCreateModalFromToolbar();
    await expect.element(page.getByLabelText('Subject *'))
      .toHaveValue('Redesign the landing page and the footer');
  });

  it('leaves the text around a chip that lands in the middle of a line spaced as it was', async () => {
    let editor:any;
    renderEditor({ onEditor: (created) => { editor = created; } });
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);
    await userEvent.type(editorEl, 'Before selected after');
    // Back over " after", then over "selected" with the selection held.
    await userEvent.keyboard('{ArrowLeft>6/}{Shift>}{ArrowLeft>8/}{/Shift}');

    await openCreateModalFromToolbar();
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('selected');

    await fillRequiredFieldsBesidesSubject();
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByText('#999')).toBeVisible();
    expect(editor.document[0].content.map((item:{ type:string; text?:string }) => item.text ?? item.type))
      .toEqual(['Before ', 'openProjectWorkPackageInline', ' after']);
  });

  it('offers nothing in a document that is only open for reading', async () => {
    renderEditor({
      editable: false,
      initialContent: [{ type: 'paragraph', content: 'Redesign the landing page' }],
    });

    await expect.element(page.getByText('Redesign the landing page')).toBeVisible();
    await userEvent.dblClick(page.getByText('Redesign the landing page'));

    await expect.element(page.getByRole('button', { name: 'Create work package' })).not.toBeInTheDocument();
  });

  it('offers nothing where nothing is selected', async () => {
    renderEditor();
    const editorEl = page.getByRole('textbox');
    await userEvent.click(editorEl);
    await userEvent.type(editorEl, 'Redesign the landing page');

    await expect.element(page.getByRole('button', { name: 'Create work package' })).not.toBeInTheDocument();
  });
});
