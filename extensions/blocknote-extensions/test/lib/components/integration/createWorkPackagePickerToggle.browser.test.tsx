import { describe, it, expect } from 'vitest';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { openCreateModal, pickProject, selectOptionNamed } from '../../../helpers/createWorkPackageHelpers';

const TYPE_FIELD = 'Type *';

interface Picker {
  field:string;
  key:string;
  option:string;
}

// One of every picker a fixed set of values, a searched listing and several
// values are picked from; the project picker is covered by its own suite.
const PICKERS:Picker[] = [
  { field: TYPE_FIELD, key: 'type', option: 'Task' },
  { field: 'Supervisor *', key: 'customField1', option: 'Anna Kovalenko' },
  { field: 'Department *', key: 'customField3', option: 'Design' },
  { field: 'Labels *', key: 'customField4', option: 'Accessibility' },
];

const handleOf = (picker:Picker) => page.getByTestId(`op-bn-create-wp-${picker.key}-toggle`);
const fieldOf = (picker:Picker) => page.getByLabelText(picker.field);

const PRESSED = [
  { part: 'handle', press: handleOf },
  { part: 'field itself', press: fieldOf },
];

async function openPicker(picker:Picker) {
  renderEditor();
  await openCreateModal();
  await pickProject();

  // Every field beyond the type is only offered once the type answers for it.
  if (picker.field !== TYPE_FIELD) await selectOptionNamed(TYPE_FIELD, 'Task');

  await userEvent.click(fieldOf(picker));
  await expect.element(page.getByRole('option', { name: picker.option })).toBeVisible();
}

describe('create work package: shutting a picker list without leaving the field', () => {
  describe.each(PRESSED)('on the $part', ({ press }) => {
    it.each(PICKERS)('shuts and reopens the list of $field', async (picker) => {
      await openPicker(picker);

      await userEvent.click(press(picker));
      await expect.element(page.getByRole('option', { name: picker.option })).not.toBeInTheDocument();

      await userEvent.click(press(picker));
      await expect.element(page.getByRole('option', { name: picker.option })).toBeVisible();
    });
  });

  it.each(PICKERS)('says on the handle of $field what pressing it does next', async (picker) => {
    await openPicker(picker);

    await expect.element(handleOf(picker)).toHaveAccessibleName('Hide options');

    await userEvent.click(handleOf(picker));
    await expect.element(handleOf(picker)).toHaveAccessibleName('Show options');
  });
});
