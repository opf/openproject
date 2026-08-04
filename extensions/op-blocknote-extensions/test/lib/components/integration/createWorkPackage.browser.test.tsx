import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { fillRequiredFields, openCreateModal, pickProject } from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';
import { mockCreatedWorkPackage } from '../../../mocks/handlers';

afterEach(() => worker.resetHandlers());

describe('Create work package', () => {
  it('creates a card when invoked on an empty line', async () => {
    renderEditor();
    await openCreateModal();

    await expect.element(page.getByTestId('create-wp-submit')).toBeDisabled();
    await fillRequiredFields('Fix the header alignment');

    await expect.element(page.getByLabelText('Status *')).toHaveValue('/api/v3/statuses/1');

    await expect.element(page.getByTestId('create-wp-submit')).toBeEnabled();
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('block-card')).toBeVisible();
    await expect.element(page.getByText('Freshly created work package')).toBeVisible();
  });

  it('creates an inline chip when invoked within a line of text', async () => {
    renderEditor();
    await openCreateModal('Some text ');

    await fillRequiredFields('Fix the header alignment');
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByText('#999')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();
  });

  it('only asks for attributes the API does not default', async () => {
    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');

    await expect.element(page.getByLabelText('Priority *')).not.toBeInTheDocument();
    await expect.element(page.getByLabelText('Start date')).not.toBeInTheDocument();
  });

  it('narrows the project typeahead through the API', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.fill(page.getByLabelText('Project *'), 'Scrum');
    await expect.element(page.getByRole('option', { name: 'Scrum project' })).toBeVisible();
    await expect.element(page.getByRole('option', { name: 'Demo project' })).not.toBeInTheDocument();
  });

  it('re-asks for the type dependent fields when the type changes', async () => {
    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');
    await expect.element(page.getByTestId('create-wp-submit')).toBeEnabled();

    await userEvent.selectOptions(page.getByLabelText('Type *'), '/api/v3/types/2');

    await expect.element(page.getByLabelText('Supervisor *')).toHaveValue('');
    await expect.element(page.getByTestId('create-wp-submit')).toBeDisabled();
  });

  it('keeps the assignee it was given when the type changes', async () => {
    renderEditor();
    await openCreateModal();
    await pickProject();

    await userEvent.click(page.getByLabelText('Assignee'));
    await userEvent.click(page.getByRole('option', { name: 'Elif Yildiz' }));
    await userEvent.selectOptions(page.getByLabelText('Type *'), '/api/v3/types/1');

    await expect.element(page.getByLabelText('Assignee')).toHaveValue('Elif Yildiz');
  });

  it('asks for every required custom field the type brings, whatever its kind', async () => {
    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');

    await expect.element(page.getByLabelText('Supervisor *')).toHaveValue('Anna Kovalenko');
    await expect.element(page.getByLabelText('Needs documentation')).not.toBeChecked();
    await expect.element(page.getByTestId('create-wp-submit')).toBeEnabled();
  });

  it('submits the custom fields under the keys the schema named them by', async () => {
    let body:Record<string, unknown> = {};
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages', async ({ request }) => {
        body = await request.json() as Record<string, unknown>;
        return HttpResponse.json(mockCreatedWorkPackage, { status: 201 });
      })
    );

    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');
    await userEvent.click(page.getByLabelText('Needs documentation'));
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    expect(body.customField2).toBe(true);
    expect(body._links).toMatchObject({
      customField1: { href: '/api/v3/users/7' },
      customField3: { href: '/api/v3/custom_options/7' },
    });
  });

  it('removes the placeholder again when the modal is dismissed', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('block-wp-wrapper')).not.toBeInTheDocument();
  });

  it('keeps the form open and shows why the API refused', async () => {
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages', () =>
        HttpResponse.json({ message: 'Department is not set to one of the allowed values.' }, { status: 422 })
      )
    );

    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('create-wp-error')).toBeVisible();
    await expect.element(page.getByText('Department is not set to one of the allowed values.')).toBeVisible();
    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
  });
});
