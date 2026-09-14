import { describe, it, expect, afterEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page } from 'vitest/browser';
import { worker } from '../../../mocks/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { openEditorAndType, typeAndSelect } from '../../../helpers/editorHelpers';
import { refreshCreateWorkPackagePermission } from '../../../../lib/services/openProjectApi';

async function withoutCreatePermission() {
  worker.use(
    http.get('http://localhost:3000/api/v3/work_packages/available_projects', () =>
      HttpResponse.json({ message: 'You are not authorized to access this resource.' }, { status: 403 })
    )
  );
  await refreshCreateWorkPackagePermission();
}

async function openSlashMenu() {
  await openEditorAndType('/');
  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
}

describe('Create work package entry points', () => {
  afterEach(async () => {
    worker.resetHandlers();
    await refreshCreateWorkPackagePermission();
  });

  it('keeps the create command out of the slash menu without the permission', async () => {
    await withoutCreatePermission();
    renderEditor();

    await openSlashMenu();

    await expect.element(page.getByText('Create new work package')).not.toBeInTheDocument();
  });

  it('offers the create command to a permitted user', async () => {
    renderEditor();

    await openSlashMenu();

    await expect.element(page.getByText('Create new work package').first()).toBeVisible();
  });

  it('keeps the create button out of the formatting toolbar without the permission', async () => {
    await withoutCreatePermission();
    renderEditor();

    await typeAndSelect('Redesign the landing page');

    await expect.element(page.getByRole('button', { name: 'Bold' })).toBeVisible();
    await expect.element(page.getByRole('button', { name: 'Create work package' })).not.toBeInTheDocument();
  });

  it('offers the create button to a permitted user', async () => {
    renderEditor();

    await typeAndSelect('Redesign the landing page');

    await expect.element(page.getByRole('button', { name: 'Create work package' })).toBeVisible();
  });
});
