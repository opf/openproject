import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { http, HttpResponse } from 'msw';
import { worker } from '../../../mocks/browser';
import { requestedWorkPackageIds } from '../../../mocks/handlers';
import { mockAttributeWorkPackage } from '../../../mocks/workPackageAttributes';
import { page, userEvent } from 'vitest/browser';
import { enablePrimerDialogs } from '../../../../lib/primer';
import { setPrimerDialogs } from '../../../../lib/services/dialogComponents';
import { renderEditor } from '../../../helpers/renderEditor';
import { openEditorAndType, openWorkPackageAttributeDialog } from '../../../helpers/editorHelpers';

describe('Primer work package dialogs', () => {
  beforeEach(() => {
    enablePrimerDialogs();
    renderEditor();
  });
  afterEach(() => {
    setPrimerDialogs();
    worker.resetHandlers();
  });

  it('keeps a changed subject on Escape and closes on Cancel', async () => {
    await openEditorAndType('/');
    await page.getByText('Create new work package').first().click();
    const dialog = page.getByRole('dialog', { name: 'Create new work package' });
    await expect.element(dialog).toHaveAttribute('data-component', 'Dialog');
    await expect.element(dialog.getByRole('textbox', { name: /Subject/ })).toBeRequired();
    await userEvent.fill(dialog.getByRole('textbox', { name: /Subject/ }), 'Keep this subject');
    await userEvent.keyboard('{Escape}');
    await expect.element(dialog.getByRole('textbox', { name: /Subject/ })).toHaveValue('Keep this subject');
    await dialog.getByRole('button', { name: 'Cancel' }).click();
    await expect.element(dialog).not.toBeInTheDocument();
  });

  it('filters work packages and attributes before inserting a live preview', async () => {
    worker.use(http.get('http://localhost:3000/api/v3/work_packages', ({ request }) => (
      requestedWorkPackageIds(request) ? undefined : HttpResponse.json({ _embedded: { elements: [mockAttributeWorkPackage] } })
    )));
    await openWorkPackageAttributeDialog();
    const dialog = page.getByRole('dialog', { name: 'Insert work package attribute' });
    await userEvent.fill(dialog.getByRole('combobox', { name: 'Work package' }), 'Redesign');
    await page.getByRole('option', { name: /Redesign onboarding flow/ }).click();
    await dialog.getByRole('button', { name: 'Attribute' }).click();
    await userEvent.fill(page.getByRole('combobox', { name: 'Attribute' }), 'suBj');
    await expect.element(page.getByRole('option', { name: 'Subject' })).toBeVisible();
    await expect.element(page.getByRole('option', { name: 'Status' })).not.toBeInTheDocument();
    await userEvent.keyboard('{ArrowDown}{Enter}');
    await expect.element(page.getByTestId('insert-attribute-preview')).toHaveTextContent('Redesign onboarding flow');
    await dialog.getByRole('button', { name: 'Insert', exact: true }).click();
    await expect.element(dialog).not.toBeInTheDocument();
  });

  it('opens the attribute preview and allows dismissal before editing', async () => {
    await openWorkPackageAttributeDialog();
    const dialog = page.getByRole('dialog', { name: 'Insert work package attribute' });
    await expect.element(dialog).toHaveAttribute('data-component', 'Dialog');
    await expect.element(dialog.getByRole('button', { name: 'Insert', exact: true })).toBeDisabled();
    await userEvent.keyboard('{Escape}');
    await expect.element(dialog).not.toBeInTheDocument();
  });
});
