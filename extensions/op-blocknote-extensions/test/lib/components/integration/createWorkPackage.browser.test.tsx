import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { fillRequiredFields, openCreateModal, pickProject, selectOptionNamed } from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';
import { mockCreatedWorkPackage } from '../../../mocks/handlers';

afterEach(() => worker.resetHandlers());

function colorChannelsOf(element:Element):string[] {
  const styles = getComputedStyle(element);
  return ['--color-r', '--color-g', '--color-b'].map((channel) => styles.getPropertyValue(channel).trim());
}

describe('Create work package', () => {
  it('creates a card when invoked on an empty line', async () => {
    renderEditor();
    await openCreateModal();

    await fillRequiredFields('Fix the header alignment');

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

  it('only asks for attributes the API does not default, required or not', async () => {
    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');

    await expect.element(page.getByLabelText('Status *')).not.toBeInTheDocument();
    await expect.element(page.getByLabelText('Priority *')).not.toBeInTheDocument();
    await expect.element(page.getByLabelText('Start date')).not.toBeInTheDocument();
  });

  it('submits the defaults of what it did not ask for', async () => {
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
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    expect(body._links).toMatchObject({
      status: { href: '/api/v3/statuses/1' },
      priority: { href: '/api/v3/priorities/8' },
    });
  });

  it('sets the attributes of the chosen type apart from the generic ones', async () => {
    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Subject *')).toBeVisible();
    await expect.element(page.getByTestId('create-wp-divider')).not.toBeInTheDocument();

    await fillRequiredFields('Fix the header alignment');

    const divider = page.getByTestId('create-wp-divider').element();
    expect(divider.compareDocumentPosition(page.getByLabelText('Type *').element()))
      .toBe(Node.DOCUMENT_POSITION_PRECEDING);
    expect(divider.compareDocumentPosition(page.getByLabelText('Supervisor *').element()))
      .toBe(Node.DOCUMENT_POSITION_FOLLOWING);
  });

  it('points at every required field left empty, starting at the first one', async () => {
    renderEditor();
    await openCreateModal();
    await pickProject();
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await selectOptionNamed('Type *', 'Task');
    await expect.element(page.getByLabelText('Department *')).toBeVisible();

    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
    await expect.element(page.getByTestId('block-card')).not.toBeInTheDocument();

    const subject = page.getByLabelText('Subject *');
    await expect.element(subject).toHaveFocus();
    await expect.element(subject).toHaveAccessibleDescription('This field is required.');
    await expect.element(page.getByLabelText('Supervisor *')).toHaveAttribute('aria-invalid', 'true');
    await expect.element(page.getByLabelText('Department *')).toHaveAttribute('aria-invalid', 'true');
    await expect.element(page.getByLabelText('Needs documentation')).not.toHaveAttribute('aria-invalid');

    await userEvent.fill(subject, 'Fix the header alignment');
    await expect.element(subject).not.toHaveAttribute('aria-invalid');

    await userEvent.click(page.getByTestId('create-wp-submit'));
    await expect.element(page.getByLabelText('Supervisor *')).toHaveFocus();
  });

  it('starts over with the complaints when the form is reshaped', async () => {
    renderEditor();
    await openCreateModal();
    await pickProject();
    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    await selectOptionNamed('Type *', 'Task');
    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();

    await userEvent.click(page.getByTestId('create-wp-submit'));
    await expect.element(page.getByLabelText('Supervisor *')).toHaveAttribute('aria-invalid', 'true');

    await selectOptionNamed('Type *', 'Bug');

    await expect.element(page.getByLabelText('Supervisor *')).not.toHaveAttribute('aria-invalid');
    await expect.element(page.getByLabelText('Subject *')).not.toHaveAttribute('aria-invalid');
  });

  it('shows the color of the chosen type', async () => {
    renderEditor();
    await openCreateModal();

    await expect.element(page.getByTestId('create-wp-type-color')).not.toBeInTheDocument();
    await pickProject();

    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    const dot = page.getByTestId('create-wp-type-color');
    await expect.element(dot).toBeVisible();
    await expect.poll(() => colorChannelsOf(dot.element())).toEqual(['211', '84', '0']);

    const { width, height } = getComputedStyle(dot.element());
    expect([width, height]).toEqual(['12px', '12px']);

    await selectOptionNamed('Type *', 'Bug');
    await expect.poll(() => colorChannelsOf(dot.element())).toEqual(['39', '174', '96']);
  });

  it('narrows the project typeahead through the API', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.fill(page.getByLabelText('Project *'), 'Scrum');
    await expect.element(page.getByRole('option', { name: 'Scrum project' })).toBeVisible();
    await expect.element(page.getByRole('option', { name: 'Demo project' })).not.toBeInTheDocument();
  });

  it('keeps a match the API made on something the option does not read as', async () => {
    worker.use(
      // As the API does: a person is matched on their e-mail as well as their name.
      http.get('http://localhost:3000/api/v3/projects/:id/available_assignees', ({ request }) => {
        const filters = new URL(request.url).searchParams.get('filters') ?? '';
        const elements = filters.includes('elif@example.com')
          ? [{ id: 5, name: 'Elif Yildiz', _links: { self: { href: '/api/v3/users/5' } } }]
          : [];
        return HttpResponse.json({ _embedded: { elements } });
      })
    );

    renderEditor();
    await openCreateModal();
    await pickProject();

    await userEvent.fill(page.getByLabelText('Assignee'), 'elif@example.com');

    await expect.element(page.getByRole('option', { name: 'Elif Yildiz' })).toBeVisible();
  });

  it('keeps what is filled in when the new type asks for the same fields', async () => {
    renderEditor();
    await openCreateModal();
    // "Bug" asks for the very same attributes as "Task".
    await fillRequiredFields('Fix the header alignment');
    await userEvent.click(page.getByLabelText('Needs documentation'));

    await selectOptionNamed('Type *', 'Bug');

    await expect.element(page.getByLabelText('Supervisor *')).toHaveValue('Anna Kovalenko');
    await expect.element(page.getByLabelText('Department *')).toHaveValue('/api/v3/custom_options/7');
    await expect.element(page.getByLabelText('Needs documentation')).toBeChecked();

    // Nothing left to answer a second time.
    await userEvent.click(page.getByTestId('create-wp-submit'));
    await expect.element(page.getByTestId('block-card')).toBeVisible();
  });

  it('asks again for what the new type does not carry over', async () => {
    renderEditor();
    await openCreateModal();
    // "Milestone" is the type the fixture offers without a department.
    await fillRequiredFields('Fix the header alignment');

    await selectOptionNamed('Type *', 'Milestone');

    await expect.element(page.getByLabelText('Supervisor *')).toHaveValue('Anna Kovalenko');
    await expect.element(page.getByLabelText('Department *')).not.toBeInTheDocument();

    await selectOptionNamed('Type *', 'Task');

    await expect.element(page.getByLabelText('Department *')).toHaveValue('');
    await expect.element(page.getByLabelText('Supervisor *')).toHaveValue('Anna Kovalenko');
  });

  it('keeps the assignee it was given when the type changes', async () => {
    renderEditor();
    await openCreateModal();
    await pickProject();

    await userEvent.click(page.getByLabelText('Assignee'));
    await userEvent.click(page.getByRole('option', { name: 'Elif Yildiz' }));
    await selectOptionNamed('Type *', 'Bug');

    await expect.element(page.getByLabelText('Assignee')).toHaveValue('Elif Yildiz');
  });

  it('asks for every required custom field the type brings, whatever its kind', async () => {
    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');

    await expect.element(page.getByLabelText('Supervisor *')).toHaveValue('Anna Kovalenko');
    await expect.element(page.getByLabelText('Needs documentation')).not.toBeChecked();

    // Every kind of them answered, so nothing is held against the form.
    await userEvent.click(page.getByTestId('create-wp-submit'));
    await expect.element(page.getByTestId('block-card')).toBeVisible();
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

  it('removes the placeholder again when the modal is dismissed, and takes the cursor back', async () => {
    renderEditor();
    await openCreateModal();

    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('block-wp-wrapper')).not.toBeInTheDocument();

    await userEvent.keyboard('after cancel');
    expect(document.querySelector('.bn-editor')?.textContent).toContain('after cancel');
  });

  it('removes a dismissed inline chip and leaves the cursor in the line it was in', async () => {
    renderEditor();
    await openCreateModal('Some text ');

    await userEvent.click(page.getByRole('button', { name: 'Cancel' }));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    expect(document.querySelector('[data-inline-content-type="openProjectWorkPackageInline"]')).toBeNull();

    await userEvent.keyboard('goes on');
    expect(document.querySelector('.bn-editor')?.textContent).toContain('Some text');
    expect(document.querySelector('.bn-editor')?.textContent).toContain('goes on');
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

  it('shows a refused attribute at its own field and points to it from the top', async () => {
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages', () =>
        HttpResponse.json({
          message: 'Multiple field constraints have been violated.',
          _embedded: {
            errors: [
              { message: 'Subject is too long.', _embedded: { details: { attribute: 'subject' } } },
              { message: 'Start date is not in this century.', _embedded: { details: { attribute: 'startDate' } } },
            ],
          },
        }, { status: 422 })
      )
    );

    renderEditor();
    await openCreateModal();
    await fillRequiredFields('Fix the header alignment');
    await userEvent.click(page.getByTestId('create-wp-submit'));

    const subject = page.getByLabelText('Subject *');
    await expect.element(subject).toHaveAttribute('aria-invalid', 'true');
    await expect.element(page.getByText('Subject is too long.')).toBeVisible();
    await expect.element(subject).toHaveAccessibleDescription('Subject is too long.');

    // What no field of this form can carry stays in the message on top.
    await expect.element(page.getByTestId('create-wp-error'))
      .toHaveTextContent('Please correct the highlighted fields below. Start date is not in this century.');

    // Correcting the field takes its own complaint away, and only that one.
    await userEvent.fill(subject, 'Fix the header');
    await expect.element(page.getByText('Subject is too long.')).not.toBeInTheDocument();
    await expect.element(subject).not.toHaveAttribute('aria-invalid');
  });
});
