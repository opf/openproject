import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  insertInlineWorkPackageViaHashWithTextBefore,
  openEditorAndType,
} from '../../../helpers/editorHelpers';
import {
  fillRequiredFieldsBesidesSubject,
  openCreateModalFromToolbar,
} from '../../../helpers/createWorkPackageHelpers';
import { SUBJECT_MAX_LENGTH } from '../../../mocks/handlers';

async function typeAndSelect(text:string) {
  await openEditorAndType(text);
  await userEvent.keyboard('{Shift>}{Home}{/Shift}');
}

interface EditorUnderTest {
  document:{ type:string; content:{ type:string; text?:string }[] }[];
  prosemirrorState:{
    doc:{ textBetween:(from:number, to:number, separator:string) => string };
    selection:{ from:number; to:number };
  };
  prosemirrorView?:{ hasFocus:() => boolean };
}

function selectedTextOf(editor:EditorUnderTest):string {
  const { doc, selection } = editor.prosemirrorState;
  return doc.textBetween(selection.from, selection.to, ' ');
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
    await expect.element(page.getByText('Freshly created work package')).toBeVisible();
    await expect.element(page.getByText('Redesign the landing page')).not.toBeInTheDocument();
  });

  it('gives the text back on a single undo', async () => {
    renderEditor();
    await typeAndSelect('Redesign the landing page');

    await openCreateModalFromToolbar();
    await fillRequiredFieldsBesidesSubject();
    await userEvent.click(page.getByTestId('create-wp-submit'));
    await expect.element(page.getByTestId('block-card')).toBeVisible();

    await userEvent.keyboard('{Control>}z{/Control}');

    await expect.element(page.getByText('Redesign the landing page')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
  });

  it('hands over a whole paragraph as a card, as the slash command does', async () => {
    let editor!:EditorUnderTest;
    renderEditor({ onEditor: (created) => { editor = created as EditorUnderTest; } });
    await typeAndSelect('Redesign the landing page');

    await openCreateModalFromToolbar();
    await fillRequiredFieldsBesidesSubject();
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    expect(editor.document[0].type).toBe('openProjectWorkPackageBlock');
  });

  it('leaves the text around a chip that lands in the middle of a line spaced as it was', async () => {
    let editor!:EditorUnderTest;
    renderEditor({ onEditor: (created) => { editor = created as EditorUnderTest; } });
    await openEditorAndType('Before selected after');
    // Back over " after", then over "selected" with the selection held.
    await userEvent.keyboard('{ArrowLeft>6/}{Shift>}{ArrowLeft>8/}{/Shift}');

    await openCreateModalFromToolbar();
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('selected');

    await fillRequiredFieldsBesidesSubject();
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByText('#999')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    expect(editor.document[0].content.map((item) => item.text ?? item.type))
      .toEqual(['Before ', 'openProjectWorkPackageInline', ' after']);
  });

  it('stays inline where the selection covers a block a work package cannot stand in for', async () => {
    let editor!:EditorUnderTest;
    renderEditor({ onEditor: (created) => { editor = created as EditorUnderTest; } });
    await openEditorAndType('# Redesign the landing page');
    await userEvent.keyboard('{Control>}a{/Control}');

    await openCreateModalFromToolbar();
    await fillRequiredFieldsBesidesSubject();
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByText('#999')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    expect(editor.document[0].type).toBe('heading');
  });

  it('takes a selection that spans lines as a single line of subject', async () => {
    renderEditor();
    await openEditorAndType('Redesign the landing page{Enter}and the footer');
    await userEvent.keyboard('{Control>}a{/Control}');

    await openCreateModalFromToolbar();
    await expect.element(page.getByLabelText('Subject *'))
      .toHaveValue('Redesign the landing page and the footer');
  });

  it('says so when the selection was too long to name the work package in full', async () => {
    const tooLong = 'Redesign the landing page '.repeat(12).trim();
    expect(tooLong.length).toBeGreaterThan(SUBJECT_MAX_LENGTH);

    let editor!:EditorUnderTest;
    renderEditor({
      onEditor: (created) => { editor = created as EditorUnderTest; },
      initialContent: [{ type: 'paragraph', content: tooLong }],
    });
    await userEvent.click(page.getByText(tooLong));
    await userEvent.keyboard('{Control>}a{/Control}');

    await openCreateModalFromToolbar();
    await expect.element(page.getByTestId('op-bn-create-wp-subject-hint')).toBeVisible();
    await expect.element(page.getByLabelText('Subject *'))
      .toHaveValue(tooLong.slice(0, SUBJECT_MAX_LENGTH));

    await fillRequiredFieldsBesidesSubject();
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    expect(editor.document[0].type).toBe('openProjectWorkPackageBlock');
  });

  it('says nothing about a selection the subject holds in full', async () => {
    renderEditor();
    await typeAndSelect('Redesign the landing page');

    await openCreateModalFromToolbar();
    await expect.element(page.getByTestId('op-bn-create-wp-subject-hint')).not.toBeInTheDocument();
  });

  it('leaves the document and the selection as they were when the form is dismissed', async () => {
    let editor!:EditorUnderTest;
    renderEditor({ onEditor: (created) => { editor = created as EditorUnderTest; } });
    await typeAndSelect('Redesign the landing page');

    await openCreateModalFromToolbar();
    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByText('Redesign the landing page')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();

    expect(selectedTextOf(editor)).toBe('Redesign the landing page');
    await expect.poll(() => editor.prosemirrorView?.hasFocus()).toBe(true);
  });

  it('offers nothing for a selection that already holds a work package', async () => {
    renderEditor();
    await insertInlineWorkPackageViaHashWithTextBefore('Ship ');
    await userEvent.keyboard('today{Shift>}{Home}{/Shift}');

    await expect.element(page.getByRole('toolbar')).toBeVisible();
    await expect.element(page.getByRole('button', { name: 'Create work package' })).not.toBeInTheDocument();
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
    await openEditorAndType('Redesign the landing page');

    await expect.element(page.getByRole('button', { name: 'Create work package' })).not.toBeInTheDocument();
  });
});
