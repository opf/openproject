import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, cleanup } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse } from 'msw';
import { InlineWorkPackageChip } from '../../../../lib/components/InlineWorkPackage/InlineWorkPackageChip';
import { worker } from '../../../mocks/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { insertBlockWorkPackageViaSlashMenu } from '../../../helpers/editorHelpers';

afterEach(() => {
  cleanup();
  worker.resetHandlers();
});

// Insert an inline work package whose detail fetch fails (the search list is
// mocked separately, so the search flow still succeeds).
async function insertUnavailableInlineWorkPackage() {
  const editorEl = page.getByRole('textbox');
  await expect.element(editorEl).toBeVisible();
  await userEvent.click(editorEl);
  await userEvent.type(editorEl, ' /');

  await expect.element(page.getByText('Link existing work package').first()).toBeVisible();
  await userEvent.click(page.getByText('Link existing work package').first());

  const searchInput = page.getByPlaceholder('Search by work package ID or subject');
  await expect.element(searchInput).toBeVisible();
  await userEvent.type(searchInput, 'Fix');
  await expect.element(page.getByText('Fix login bug')).toBeVisible();
  await userEvent.click(page.getByText('Fix login bug'));

  await expect.element(searchInput).not.toBeInTheDocument();
}

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
    expect(
      page.getByText('Unavailable: No permission').element().closest('.op-bn-inline-wp')?.querySelector('.octicon-eye-closed')
    ).not.toBeNull();
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
    expect(
      page.getByText('Unavailable: error').element().closest('.op-bn-inline-wp')?.querySelector('.octicon-alert')
    ).not.toBeNull();
  });

  it('renders only the icon with a tooltip for size xxs', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/999', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    render(
      <InlineWorkPackageChip
        inlineContent={{ props: { wpid: '999', size: 'xxs', instanceId: 'test-xxs' } }}
        contentRef={vi.fn()}
      />
    );

    await vi.waitFor(() => {
      expect(document.querySelector('.op-bn-inline-wp .octicon-eye-closed')).not.toBeNull();
    });
    const chip = document.querySelector('.op-bn-inline-wp');
    expect(chip?.textContent).toBe('');
    expect(chip?.getAttribute('title')).toBe('Unavailable: No permission');
  });

  it('gets the selection outline on click and can be copied and pasted', async () => {
    worker.use(
      http.get('http://localhost:3000/api/v3/work_packages/123', () =>
        HttpResponse.json({ message: 'Not found' }, { status: 404 })
      )
    );

    renderEditor();
    await insertUnavailableInlineWorkPackage();

    await expect.element(page.getByText('Unavailable: No permission')).toBeVisible();
    await userEvent.click(page.getByText('Unavailable: No permission'));

    await expect.poll(() => {
      const base = document.querySelector('.op-bn-inline-wp .op-bn-inline-wp-base');
      return base ? getComputedStyle(base).boxShadow : '';
    }).toContain('inset');

    await userEvent.keyboard('{Control>}c{/Control}');
    await userEvent.keyboard('{Control>}{End}{/Control}');
    await userEvent.keyboard('{Enter}');
    await userEvent.keyboard('{Control>}v{/Control}');

    await vi.waitFor(() => {
      expect(document.querySelectorAll('.op-bn-inline-wp').length).toBe(2);
    });
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
