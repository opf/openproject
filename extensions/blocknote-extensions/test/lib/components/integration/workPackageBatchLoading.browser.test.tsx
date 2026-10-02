import { afterEach, describe, expect, it } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { breakWorkPackages, hideWorkPackages, requestsDuring } from '../../../helpers/requestHelpers';
import { worker } from '../../../mocks/browser';

const card = (wpid:number) => ({ type: 'openProjectWorkPackageBlock', props: { wpid, displayId: String(wpid), size: 'm' } });
const chip = (wpid:number) => ({
  type: 'openProjectWorkPackageInline',
  props: { wpid: String(wpid), displayId: String(wpid), size: 's' },
});

const documentWithManyWorkPackages = [
  card(123),
  card(456),
  { type: 'paragraph', content: [chip(789), ' and ', chip(999), ' and ', chip(456)] },
  card(321),
];

function requestedIds(url:string):string[] {
  const filters = JSON.parse(new URL(url).searchParams.get('filters')!) as { id:{ values:string[] } }[];
  return filters[0].id.values;
}

describe('Loading the work packages of a document', () => {
  afterEach(() => worker.resetHandlers());

  it('loads all linked work packages with a single request', async () => {
    const requests = await requestsDuring('/api/v3/work_packages', async () => {
      renderEditor({ initialContent: documentWithManyWorkPackages });

      await expect.element(page.getByText('#123')).toBeVisible();
      await expect.element(page.getByText('Add dark mode').first()).toBeVisible();
      await expect.element(page.getByText('Semantic ID work package')).toBeVisible();
      await expect.element(page.getByText('Freshly created work package')).toBeVisible();
      await expect.element(page.getByText('#321')).toBeVisible();
    });

    expect(requests).toHaveLength(1);
    expect(requestedIds(requests[0]).sort()).toEqual(['123', '321', '456', '789', '999']);
  });

  it('shows the work packages the user cannot see as unavailable and still loads the others together', async () => {
    hideWorkPackages(456);

    const requests = await requestsDuring('/api/v3/work_packages', async () => {
      renderEditor({ initialContent: documentWithManyWorkPackages });

      await expect.element(page.getByText('#123')).toBeVisible();
      await expect.element(page.getByText('Linked work package unavailable')).toBeVisible();
      await expect.element(page.getByText('Work package unavailable: no permission')).toBeVisible();
      await expect.element(page.getByText('Semantic ID work package')).toBeVisible();
    });

    expect(requests).toHaveLength(1);
  });

  it('shows a link with an invalid id as unavailable without failing the others', async () => {
    renderEditor({ initialContent: [{ type: 'paragraph', content: [chip(-5), ' and ', chip(456)] }] });

    await expect.element(page.getByText('Work package unavailable: no permission')).toBeVisible();
    await expect.element(page.getByText('Add dark mode')).toBeVisible();
  });

  it('shows the error only on the work package that breaks the batch load', async () => {
    breakWorkPackages(456);

    renderEditor({ initialContent: documentWithManyWorkPackages });

    await expect.element(page.getByText('Could not load work package')).toBeVisible();
    await expect.element(page.getByText('Unavailable: error')).toBeVisible();
    await expect.element(page.getByText('#123')).toBeVisible();
    await expect.element(page.getByText('Semantic ID work package')).toBeVisible();
    await expect.element(page.getByText('Freshly created work package')).toBeVisible();
    await expect.element(page.getByText('#321')).toBeVisible();
  });
});
