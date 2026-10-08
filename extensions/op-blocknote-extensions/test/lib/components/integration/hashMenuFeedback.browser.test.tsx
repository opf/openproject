import { describe, it, expect, afterEach } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { http, HttpResponse, delay } from 'msw';
import { renderEditor } from '../../../helpers/renderEditor';
import { openEditorAndType } from '../../../helpers/editorHelpers';
import { mockWorkPackage } from '../../../mocks/handlers';
import { worker } from '../../../mocks/browser';

const WORK_PACKAGES_ENDPOINT = 'http://localhost:3000/api/v3/work_packages';

const settle = () => new Promise((resolve) => setTimeout(resolve, 500));

describe('Hash menu - search feedback', () => {
  afterEach(() => {
    worker.resetHandlers();
  });

  it('shows a spinner in the hint box while the search is running', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, async () => {
        await delay(300);
        return HttpResponse.json({ _embedded: { elements: [mockWorkPackage] } });
      })
    );

    renderEditor();
    await openEditorAndType('#Fix');

    const spinner = page.getByRole('img', { name: 'Loading' });
    await expect.element(page.getByText('Type to search work packages…')).toBeVisible();
    await expect.element(spinner).toBeVisible();

    await expect.element(page.getByText('Fix login bug')).toBeVisible();
    await expect.element(spinner).not.toBeInTheDocument();
  });

  it('shows "No results" when the search returns nothing', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () =>
        HttpResponse.json({ _embedded: { elements: [] } })
      )
    );

    renderEditor();
    await openEditorAndType('#zzz');

    await expect.element(page.getByText('No results')).toBeVisible();
  });

  it('keeps showing "No results" for a six character query', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () =>
        HttpResponse.json({ _embedded: { elements: [] } })
      )
    );

    renderEditor();
    await openEditorAndType('#zzzzzz');

    await expect.element(page.getByText('No results')).toBeVisible();
    await settle();
    await expect.element(page.getByText('No results')).toBeVisible();
  });

  it('keeps the typed query when the menu is dismissed with Enter', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () =>
        HttpResponse.json({ _embedded: { elements: [] } })
      )
    );

    renderEditor();
    await openEditorAndType('#zzz');

    await expect.element(page.getByText('No results')).toBeVisible();
    await userEvent.keyboard('{Enter}');

    await expect.element(page.getByText('No results')).not.toBeInTheDocument();
    await expect.element(page.getByRole('textbox')).toHaveTextContent('#zzz');
  });

  it('shows an error message when the search request fails', async () => {
    worker.use(
      http.get(WORK_PACKAGES_ENDPOINT, () => HttpResponse.error())
    );

    renderEditor();
    await openEditorAndType('#zzz');

    await expect.element(page.getByText('Error. Unable to load content.')).toBeVisible();
  });
});
