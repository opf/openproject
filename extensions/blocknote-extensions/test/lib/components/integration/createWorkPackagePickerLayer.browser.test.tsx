import { describe, it, expect } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  fillRequiredFields,
  gapToField,
  modalBody,
  openCreateModal,
  openPicker,
  pickerList,
} from '../../../helpers/createWorkPackageHelpers';

const MOVED_BY = 40;
const fieldRowOf = (field:Element):HTMLElement => {
  const content = modalBody().firstElementChild;
  let row = field.parentElement!;
  while (row.parentElement && row.parentElement !== content) row = row.parentElement;
  return row;
};

const openTheSupervisorList = async () => {
  renderEditor();
  await openCreateModal();
  await fillRequiredFields('Fix the header alignment');
  await openPicker('Supervisor *', 'Anna Kovalenko');

  return page.getByLabelText('Supervisor *').element();
};

describe('Create work package - where the suggestions are drawn', () => {
  it('stays on its field while the form around it is transformed', async () => {
    const field = await openTheSupervisorList();
    const before = pickerList('Supervisor').getBoundingClientRect();

    fieldRowOf(field).style.transform = 'translateY(-4px)';

    await expect.poll(() => Math.round(pickerList('Supervisor').getBoundingClientRect().top))
      .toBe(Math.round(before.top));
    expect(Math.round(pickerList('Supervisor').getBoundingClientRect().left))
      .toBe(Math.round(before.left));
  });

  it('follows its field when the form moves it with no event to go by', async () => {
    const field = await openTheSupervisorList();
    const gap = gapToField('Supervisor', field);
    const movedFrom = field.getBoundingClientRect().top;

    fieldRowOf(field).style.paddingTop = `${MOVED_BY}px`;

    await expect.poll(() => Math.round(field.getBoundingClientRect().top))
      .toBe(Math.round(movedFrom + MOVED_BY));
    await expect.poll(() => gapToField('Supervisor', field)).toBe(gap);
  });
});
