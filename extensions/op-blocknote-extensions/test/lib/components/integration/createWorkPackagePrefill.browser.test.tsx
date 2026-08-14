import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  openCreateModal,
  openCreateModalAtCursor,
  pickProject,
  selectOptionNamed,
} from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';
import { LAST_SELECTION_STORAGE_KEY } from '../../../../lib/components/CreateWorkPackage/lastSelection';

afterEach(() => worker.resetHandlers());

function remember(selection:Record<string, { href:string; label:string }>) {
  sessionStorage.setItem(LAST_SELECTION_STORAGE_KEY, JSON.stringify(selection));
}

async function pickAssignee(name:string) {
  await userEvent.click(page.getByLabelText('Assignee'));
  await expect.element(page.getByRole('option', { name })).toBeVisible();
  await userEvent.click(page.getByRole('option', { name }));
}

async function createBugAssignedToElif(subject:string) {
  await userEvent.fill(page.getByLabelText('Subject *'), subject);
  await pickProject();

  await expect.element(page.getByLabelText('Type *')).toBeVisible();
  await selectOptionNamed('Type *', 'Bug');
  await pickAssignee('Elif Yildiz');

  await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
  await userEvent.click(page.getByLabelText('Supervisor *'));
  await userEvent.click(page.getByRole('option', { name: 'Anna Kovalenko' }));
  await selectOptionNamed('Department *', 'Design');

  await userEvent.click(page.getByTestId('create-wp-submit'));
  await expect.element(page.getByTestId('block-card')).toBeVisible();
}

describe('Create work package - prefilled from previous selections', () => {
  it('opens the type the project defaults to and asks for what it brings', async () => {
    renderEditor();
    await openCreateModal();
    await pickProject();

    await expect.element(page.getByLabelText('Type *')).toHaveValue('/api/v3/types/1');
    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
    await expect.element(page.getByLabelText('Assignee')).toHaveValue('');
  });

  it('carries the type and the assignee over to the next work package of the session', async () => {
    renderEditor();
    await openCreateModal();
    await createBugAssignedToElif('The one that sets the tone');

    await openCreateModalAtCursor();
    await pickProject();

    await expect.element(page.getByLabelText('Type *')).toHaveValue('/api/v3/types/2');
    await expect.element(page.getByLabelText('Assignee')).toHaveValue('Elif Yildiz');
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('');
  });

  it('prefills from what an earlier page of the session left behind', async () => {
    remember({
      type: { href: '/api/v3/types/2', label: 'Bug' },
      assignee: { href: '/api/v3/users/6', label: 'Bianca Fuchs' },
    });

    renderEditor();
    await openCreateModal();
    await pickProject();

    await expect.element(page.getByLabelText('Type *')).toHaveValue('/api/v3/types/2');
    await expect.element(page.getByLabelText('Assignee')).toHaveValue('Bianca Fuchs');
  });

  it('leaves the assignee empty where the remembered person cannot be assigned', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/projects/:id/available_assignees', () =>
        HttpResponse.json({
          _embedded: { elements: [{ id: 6, name: 'Bianca Fuchs', _links: { self: { href: '/api/v3/users/6' } } }] },
        })
      )
    );
    remember({ assignee: { href: '/api/v3/users/5', label: 'Elif Yildiz' } });

    renderEditor();
    await openCreateModal();
    await pickProject();

    await expect.element(page.getByLabelText('Type *')).toHaveValue('/api/v3/types/1');
    await expect.element(page.getByLabelText('Assignee')).toHaveValue('');
  });

  it('submits what it prefilled without the form being touched again', async () => {
    let body:Record<string, unknown> = {};
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages', async ({ request }) => {
        body = await request.json() as Record<string, unknown>;
        return HttpResponse.json({ id: 999, displayId: '999', subject: 'Prefilled', _links: {} }, { status: 201 });
      })
    );
    remember({
      type: { href: '/api/v3/types/2', label: 'Bug' },
      assignee: { href: '/api/v3/users/5', label: 'Elif Yildiz' },
    });

    renderEditor();
    await openCreateModal();
    await userEvent.fill(page.getByLabelText('Subject *'), 'Prefilled');
    await pickProject();
    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();

    await userEvent.click(page.getByLabelText('Supervisor *'));
    await userEvent.click(page.getByRole('option', { name: 'Anna Kovalenko' }));
    await selectOptionNamed('Department *', 'Design');
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    expect(body._links).toMatchObject({
      type: { href: '/api/v3/types/2' },
      assignee: { href: '/api/v3/users/5' },
    });
  });
});
