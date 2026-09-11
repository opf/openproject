import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { openCreateModal, pickProject, selectOptionNamed } from '../../../helpers/createWorkPackageHelpers';
import { createFormFor } from '../../../mocks/handlers';
import type { FormRequestBody } from '../../../mocks/handlers';
import { worker } from '../../../mocks/browser';

afterEach(() => worker.resetHandlers());

const FIELD = 'Room *';
const LIST = 'op-bn-create-wp-customField5-list';
const ITEMS_HREF = '/api/v3/custom_fields/5/items';

const roomSchema = {
  type: 'CustomField::Hierarchy::Item', name: 'Room', required: true, hasDefault: false, writable: true,
  location: '_links',
  _links: { allowedValues: { href: ITEMS_HREF } },
};

const items = [
  { id: 1, label: null, short: null, depth: null, _links: { self: { href: '/api/v3/custom_field_items/1' } } },
  {
    id: 2, label: 'room 1', short: 'R1', depth: 0,
    _links: {
      self: { href: '/api/v3/custom_field_items/2', title: 'room 1 (R1)' },
      parent: { href: '/api/v3/custom_field_items/1' },
    },
  },
  {
    id: 3, label: 'room 1a', short: null, depth: 1,
    _links: {
      self: { href: '/api/v3/custom_field_items/3', title: 'room 1a' },
      parent: { href: '/api/v3/custom_field_items/2', title: 'room 1 (R1)' },
    },
  },
  {
    id: 4, label: 'room 2', short: 'R2', depth: 0,
    _links: {
      self: { href: '/api/v3/custom_field_items/4', title: 'room 2 (R2)' },
      parent: { href: '/api/v3/custom_field_items/1' },
    },
  },
];

function serveHierarchyField() {
  worker.use(
    http.post('http://localhost:3000/api/v3/work_packages/form', async ({ request }) => {
      const form = createFormFor(await request.json() as FormRequestBody);
      // A custom field of a type is offered once the type is picked.
      const schema = form._embedded.schema;
      if (schema.status) schema.customField5 = roomSchema;

      return HttpResponse.json(form);
    }),

    http.get(`http://localhost:3000${ITEMS_HREF}`, ({ request }) => {
      if (new URL(request.url).searchParams.has('filters')) {
        return HttpResponse.json({ message: 'Filters is invalid.' }, { status: 400 });
      }
      return HttpResponse.json({ _embedded: { elements: items } });
    })
  );
}

async function openRoomPicker() {
  serveHierarchyField();
  renderEditor();
  await openCreateModal();
  await pickProject();
  await selectOptionNamed('Type *', 'Task');

  await expect.element(page.getByLabelText(FIELD)).toBeVisible();
  await userEvent.click(page.getByLabelText(FIELD));
  await expect.element(page.getByRole('treeitem', { name: 'room 1 (R1)' })).toBeVisible();
}

const optionLabels = () =>
  Array.from(document.querySelectorAll(`[data-testid="${LIST}-popover"] [role="treeitem"]`))
    .map((option) => option.textContent?.trim());

describe('create work package: hierarchy custom field picker', () => {
  it('names every item and leaves the nameless root out', async () => {
    await openRoomPicker();

    expect(optionLabels()).toEqual(['room 1 (R1)', 'room 2 (R2)']);
  });

  it('unfolds an item into its children, and folds it back', async () => {
    await openRoomPicker();

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));

    await expect.element(page.getByRole('treeitem', { name: 'room 1a' })).toBeVisible();
    expect(optionLabels()).toEqual(['room 1 (R1)', 'room 1a', 'room 2 (R2)']);

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'room 1a' })).not.toBeInTheDocument();
  });

  it('picks a child the search unfolded', async () => {
    await openRoomPicker();
    await userEvent.fill(page.getByLabelText(FIELD), 'room 1a');

    const child = page.getByRole('treeitem', { name: 'room 1a' });
    await expect.element(child).toBeVisible();
    await userEvent.click(child);

    await expect.element(page.getByLabelText(FIELD)).toHaveValue('room 1a');
  });
});
