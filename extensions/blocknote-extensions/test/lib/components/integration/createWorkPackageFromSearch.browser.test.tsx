import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  BLOCK_CARD_HASHES,
  openBlockWorkPackageSearch,
  openEditorAndType,
  SEARCH_PLACEHOLDER,
} from '../../../helpers/editorHelpers';
import {
  chooseCreateFromSearch,
  fillRequiredFieldsBesidesSubject,
} from '../../../helpers/createWorkPackageHelpers';
import { mockCreatedWorkPackage } from '../../../mocks/handlers';

async function createWithFilledForm(expectedSubject:string) {
  await expect.element(page.getByLabelText('Subject *')).toHaveValue(expectedSubject);
  await fillRequiredFieldsBesidesSubject();
  await userEvent.click(page.getByTestId('create-wp-submit'));
  await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
}

describe('Create work package from the search of the slash command', () => {
  it('names the work package after the query and links it where the search was opened', async () => {
    renderEditor();
    const searchInput = await openBlockWorkPackageSearch();
    await userEvent.type(searchInput, 'Redesign the landing page');

    await chooseCreateFromSearch();
    await createWithFilledForm('Redesign the landing page');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText(mockCreatedWorkPackage.subject)).toBeVisible();
  });

  it('links the work package inline where the search was opened within a line', async () => {
    renderEditor();
    await openEditorAndType('See /');
    await userEvent.click(page.getByText('Link existing work package').first());
    await userEvent.type(page.getByPlaceholder(SEARCH_PLACEHOLDER), 'Redesign the landing page');

    await chooseCreateFromSearch();
    await createWithFilledForm('Redesign the landing page');

    await expect.element(page.getByText('#999')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).not.toHaveTextContent('Redesign the landing page');
  });

  it('leaves nothing behind when the form is cancelled', async () => {
    renderEditor();
    const searchInput = await openBlockWorkPackageSearch();
    await userEvent.type(searchInput, 'Redesign the landing page');

    await chooseCreateFromSearch();
    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('block-wp-wrapper')).not.toBeInTheDocument();
  });
});

describe('Create work package from the hash menu', () => {
  it('names the work package after the query and puts it in the place of what was typed', async () => {
    renderEditor();
    await openEditorAndType('See ##Redesign the landing page');

    await chooseCreateFromSearch();
    await createWithFilledForm('Redesign the landing page');

    await expect.element(page.getByText(mockCreatedWorkPackage.subject)).toBeVisible();
    await expect.element(page.getByRole('textbox')).not.toHaveTextContent('##');
    await expect.element(page.getByRole('textbox')).not.toHaveTextContent('Redesign the landing page');
  });

  it('puts a block card in the place of a block trigger', async () => {
    renderEditor();
    await openEditorAndType(`${BLOCK_CARD_HASHES}Redesign the landing page`);

    await chooseCreateFromSearch();
    await createWithFilledForm('Redesign the landing page');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
  });

  it('gives the typed text back when the form is cancelled', async () => {
    renderEditor();
    await openEditorAndType('See ##Redesign the landing page');

    await chooseCreateFromSearch();
    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveTextContent('See ##Redesign the landing page');
  });
});
