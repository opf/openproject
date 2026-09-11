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
const MULTI_FIELD = 'Rooms *';
const LIST = 'op-bn-create-wp-customField5-list';
const MULTI_LIST = 'op-bn-create-wp-customField6-list';
const ITEMS_HREF = '/api/v3/custom_fields/5/items';

const roomSchema = {
  type: 'CustomField::Hierarchy::Item', name: 'Room', required: true, hasDefault: false, writable: true,
  location: '_links',
  _links: { allowedValues: { href: ITEMS_HREF } },
};

const roomsSchema = { ...roomSchema, type: '[]CustomField::Hierarchy::Item', name: 'Rooms' };

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
      if (schema.status) Object.assign(schema, { customField5: roomSchema, customField6: roomsSchema });

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

async function openPicker(field = FIELD) {
  serveHierarchyField();
  renderEditor();
  await openCreateModal();
  await pickProject();
  await selectOptionNamed('Type *', 'Task');

  await expect.element(page.getByLabelText(field)).toBeVisible();
  await userEvent.click(page.getByLabelText(field));
  await expect.element(page.getByRole('treeitem', { name: 'room 1 (R1)' })).toBeVisible();
}

const optionLabels = (list = LIST) =>
  Array.from(document.querySelectorAll(`[data-testid="${list}-popover"] [role="treeitem"]`))
    .map((option) => option.textContent?.trim());

describe('create work package: hierarchy custom field picker', () => {
  it('names every item and leaves the nameless root out', async () => {
    await openPicker();

    expect(optionLabels()).toEqual(['room 1 (R1)', 'room 2 (R2)']);
  });

  it('unfolds an item into its children, and folds it back', async () => {
    await openPicker();

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));

    await expect.element(page.getByRole('treeitem', { name: 'room 1a' })).toBeVisible();
    expect(optionLabels()).toEqual(['room 1 (R1)', 'room 1a', 'room 2 (R2)']);

    await userEvent.click(page.getByTestId(`${LIST}-twisty-0`));
    await expect.element(page.getByRole('treeitem', { name: 'room 1a' })).not.toBeInTheDocument();
  });

  it('says it opens a tree, so the rows and the field agree', async () => {
    await openPicker();

    await expect.element(page.getByLabelText(FIELD)).toHaveAttribute('aria-haspopup', 'tree');
  });

  it('unfolds and picks a branch with the arrow keys alone', async () => {
    await openPicker();

    await userEvent.keyboard('{ArrowRight}');
    await expect.element(page.getByRole('treeitem', { name: 'room 1a' })).toBeVisible();

    await userEvent.keyboard('{ArrowDown}{Enter}');

    await expect.element(page.getByLabelText(FIELD)).toHaveValue('room 1a');
  });

  it('picks a child the search unfolded', async () => {
    await openPicker();
    await userEvent.fill(page.getByLabelText(FIELD), 'room 1a');

    const child = page.getByRole('treeitem', { name: 'room 1a' });
    await expect.element(child).toBeVisible();
    await userEvent.click(child);

    await expect.element(page.getByLabelText(FIELD)).toHaveValue('room 1a');
  });

  it('takes on a child of a field holding several values', async () => {
    await openPicker(MULTI_FIELD);

    await expect.element(page.getByLabelText(MULTI_FIELD)).toHaveAttribute('aria-haspopup', 'tree');
    expect(optionLabels(MULTI_LIST)).toEqual(['room 1 (R1)', 'room 2 (R2)']);

    await userEvent.click(page.getByTestId(`${MULTI_LIST}-twisty-0`));
    await userEvent.click(page.getByRole('treeitem', { name: 'room 1a' }));

    await expect.element(page.getByRole('button', { name: 'Remove room 1a' })).toBeVisible();
  });
});
