import { afterEach, describe, it, expect } from 'vitest';
import { delay, http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  clearProject,
  openCreateModal,
  openCreateModalAtCursor,
  pickProject,
  pickValues,
  selectOptionNamed,
} from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';
import { rememberSelection } from '../../../../lib/components/CreateWorkPackage/lastSelection';
import { initEditorContext } from '../../../../lib/services/editorContext';
import { initializeOpBlockNoteExtensions } from '../../../../lib';

afterEach(() => {
  worker.resetHandlers();
  initEditorContext({});
});

function remember(selection:Record<string, { href:string; label:string }>) {
  rememberSelection(selection);
}

function holdBackFormLoads(ms:number) {
  worker.use(http.post('http://localhost:3000/api/v3/work_packages/form', async () => { await delay(ms); }));
}

function heldFormLoad():() => void {
  let release = () => {};
  worker.use(http.post('http://localhost:3000/api/v3/work_packages/form', async () => {
    await new Promise<void>((resolve) => { release = resolve; });
  }));

  return () => release();
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
  await pickValues('Labels *', 'Accessibility');

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

  it('carries the project, the type and the assignee over to the next work package in the document', async () => {
    renderEditor();
    await openCreateModal();
    await createBugAssignedToElif('The one that sets the tone');

    await openCreateModalAtCursor();

    await expect.element(page.getByLabelText('Project *')).toHaveValue('Demo project');
    await expect.element(page.getByLabelText('Type *')).toHaveValue('/api/v3/types/2');
    await expect.element(page.getByLabelText('Assignee')).toHaveValue('Elif Yildiz');
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('');
  });

  it('opens on the project the editor is rendered in, and asks for what it brings', async () => {
    initializeOpBlockNoteExtensions({ baseUrl: 'http://localhost:3000', locale: 'en', projectId: 2 });

    renderEditor();
    await openCreateModal();

    await expect.element(page.getByLabelText('Project *')).toHaveValue('Scrum project');
    await expect.element(page.getByLabelText('Type *')).toHaveValue('/api/v3/types/1');
    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
  });

  it('opens on the project last created in rather than the one it is rendered in', async () => {
    remember({ project: { href: '/api/v3/projects/1', label: 'Demo project' } });
    initEditorContext({ projectId: 2 });

    renderEditor();
    await openCreateModal();

    await expect.element(page.getByLabelText('Project *')).toHaveValue('Demo project');
  });

  it('starts from scratch in another document', async () => {
    remember({ project: { href: '/api/v3/projects/1', label: 'Demo project' } });
    const wasAt = window.location.pathname;
    history.pushState({}, '', '/projects/demo/documents/2');

    try {
      renderEditor();
      await openCreateModal();

      await expect.element(page.getByLabelText('Project *')).toHaveValue('');
    } finally {
      history.replaceState({}, '', wasAt);
    }
  });

  it('brings what the type asks for in one piece rather than a field group at a time', async () => {
    holdBackFormLoads(400);
    initEditorContext({ projectId: 1 });

    renderEditor();
    await openCreateModal();

    await expect.element(page.getByTestId('create-wp-loading')).toBeVisible();
    await expect.element(page.getByLabelText('Type *')).not.toBeInTheDocument();
    await expect.element(page.getByLabelText('Subject *')).toBeVisible();

    await expect.element(page.getByLabelText('Type *')).toBeVisible();
    expect(page.getByLabelText('Assignee').element()).toBeInTheDocument();
    expect(page.getByLabelText('Supervisor *').element()).toBeInTheDocument();
  });

  it('answers Escape before a single field has loaded', async () => {
    const release = heldFormLoad();
    initEditorContext({ projectId: 1 });

    try {
      renderEditor();
      await openCreateModal();
      await expect.element(page.getByTestId('create-wp-loading')).toBeVisible();

      await userEvent.keyboard('nothing of this belongs in the document{Escape}');

      await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
      await expect.element(page.getByRole('textbox')).not.toHaveTextContent('belongs in the document');
    } finally {
      release();
    }
  });

  it('leaves the fields already shown where they are when the rest arrives', async () => {
    holdBackFormLoads(400);
    initEditorContext({ projectId: 1 });

    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Subject *')).toBeVisible();
    const panelTop = page.getByTestId('create-wp-modal').element().getBoundingClientRect().top;

    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();

    expect(page.getByTestId('create-wp-modal').element().getBoundingClientRect().top).toBe(panelTop);
  });

  it('takes the subject while the fields the project brings still load', async () => {
    holdBackFormLoads(400);
    initEditorContext({ projectId: 1 });

    renderEditor();
    await openCreateModal();
    await expect.element(page.getByTestId('create-wp-loading')).toBeVisible();

    await userEvent.fill(page.getByLabelText('Subject *'), 'Typed while loading');

    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('Typed while loading');
  });

  it('asks for the project where work packages cannot be created in the one it is rendered in', async () => {
    initEditorContext({ projectId: 99 });

    renderEditor();
    await openCreateModal();

    await expect.element(page.getByLabelText('Project *')).toHaveValue('');
    await expect.element(page.getByLabelText('Type *')).not.toBeInTheDocument();
  });

  it('drops a form nothing was answered in, prefilled or not', async () => {
    initEditorContext({ projectId: 1 });

    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Project *')).toHaveValue('Demo project');

    await userEvent.click(page.getByTestId('create-wp-overlay'), { position: { x: 5, y: 5 } });

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
  });

  it('drops a fully prefilled form nothing was answered in on Escape', async () => {
    initEditorContext({ projectId: 1 });

    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Supervisor *')).toBeVisible();

    await userEvent.keyboard('{Escape}');

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
  });

  it('keeps a form an answer was given in when the overlay is clicked', async () => {
    initEditorContext({ projectId: 1 });

    renderEditor();
    await openCreateModal();
    await userEvent.fill(page.getByLabelText('Subject *'), 'Worth keeping');

    await userEvent.click(page.getByTestId('create-wp-overlay'), { position: { x: 5, y: 5 } });

    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('Worth keeping');
  });

  it('keeps a form a checkbox was ticked in', async () => {
    initEditorContext({ projectId: 1 });

    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Needs documentation')).toBeVisible();
    await userEvent.click(page.getByLabelText('Needs documentation'));

    await userEvent.keyboard('{Escape}');
    await userEvent.click(page.getByTestId('create-wp-overlay'), { position: { x: 5, y: 5 } });

    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
    await expect.element(page.getByLabelText('Needs documentation')).toBeChecked();
  });

  it('keeps a form an answer was given in when Escape is pressed', async () => {
    initEditorContext({ projectId: 1 });

    renderEditor();
    await openCreateModal();
    await userEvent.fill(page.getByLabelText('Subject *'), 'Worth keeping');

    await userEvent.keyboard('{Escape}');

    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
    await expect.element(page.getByLabelText('Subject *')).toHaveValue('Worth keeping');
  });

  it('asks for the project again once it is cleared', async () => {
    remember({ project: { href: '/api/v3/projects/1', label: 'Demo project' } });

    renderEditor();
    await openCreateModal();
    await expect.element(page.getByLabelText('Type *')).toBeVisible();

    await clearProject();

    await expect.element(page.getByLabelText('Type *')).not.toBeInTheDocument();
    await expect.element(page.getByLabelText('Project *')).toHaveValue('');
  });

  it('prefills from what an earlier creation in the document left behind', async () => {
    remember({
      project: { href: '/api/v3/projects/1', label: 'Demo project' },
      type: { href: '/api/v3/types/2', label: 'Bug' },
      assignee: { href: '/api/v3/users/6', label: 'Bianca Fuchs' },
    });

    renderEditor();
    await openCreateModal();

    await expect.element(page.getByLabelText('Project *')).toHaveValue('Demo project');

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
    await pickValues('Labels *', 'Accessibility');
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('create-wp-modal')).not.toBeInTheDocument();
    expect(body._links).toMatchObject({
      type: { href: '/api/v3/types/2' },
      assignee: { href: '/api/v3/users/5' },
    });
  });
});
