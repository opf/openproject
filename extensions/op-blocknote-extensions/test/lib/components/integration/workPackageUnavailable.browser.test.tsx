import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, cleanup } from 'vitest-browser-react';
import { page } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { InlineWorkPackageChip } from '../../../../lib/components/InlineWorkPackage/InlineWorkPackageChip';
import { worker } from '../../../mocks/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertBlockWorkPackageViaSlashMenu } from '../../../helpers/editorHelpers';

afterEach(() => {
  cleanup();
  worker.resetHandlers();
});

describe('Inline chip - unavailable work package', () => {
  it('shows eye-closed icon and "Unavailable: No permission" on 404', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/999', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    render(
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: '999', size: 's', instanceId: 'test-unauth' } }}
        contentRef={vi.fn()}
      />
    );

    await expect.element(page.getByText('Unavailable: No permission')).toBeVisible();
    expect(document.querySelector('.octicon-eye-closed')).not.toBeNull();
  });

  it('shows alert icon and "Unavailable: error" on server error', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/999', () =>
        HttpResponse.json({ message: 'Internal Server Error' }, { status: 500 })
      )
    );

    render(
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: '999', size: 's', instanceId: 'test-err' } }}
        contentRef={vi.fn()}
      />
    );

    await expect.element(page.getByText('Unavailable: error')).toBeVisible();
    expect(document.querySelector('.octicon-alert')).not.toBeNull();
  });
});

describe('Block card - unavailable work package', () => {
  it('shows eye-closed icon and "Linked work package unavailable" on 404', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/123', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();

    await expect.element(page.getByText('Linked work package unavailable')).toBeVisible();
    await expect.element(page.getByText('You do not have permission to see this')).toBeVisible();
    expect(document.querySelector('.op-bn-unavailable-message--header .octicon-eye-closed')).not.toBeNull();
  });

  it('shows alert icon and "Error" on server error', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/123', () =>
        HttpResponse.json({ message: 'Internal Server Error' }, { status: 500 })
      )
    );

    renderEditor();
    await insertBlockWorkPackageViaSlashMenu();

    await expect.element(page.getByText('Error', { exact: true })).toBeVisible();
    await expect.element(page.getByText('Could not load work package')).toBeVisible();
    expect(document.querySelector('.op-bn-unavailable-message--header .octicon-alert')).not.toBeNull();
  });
});
