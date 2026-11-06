import { describe, it, expect } from 'vitest';
import { page } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  fillRequiredFields,
  gapToField,
  modalBody,
  onAPhone,
  openCreateModal,
  openPicker,
  pickerList,
} from '../../../helpers/createWorkPackageHelpers';
import { standInVisualViewport } from '../../../helpers/visualViewport';

const SCREEN_HEIGHT = 640;
const KEYBOARD_HEIGHT = 300;
const ROOM_BELOW_FIELD = 30;
const REPORTED_OFFSET = 400;
const PANNED_BY = 200;
const MAX_GAP_TO_FIELD = 4;
const PINCHED_IN = 3;

const supervisorList = () => pickerList('Supervisor').getBoundingClientRect();

const scrollFieldJustAboveTheKeyboard = (field:Element, panned = 0) => {
  const keyboardTop = panned + SCREEN_HEIGHT - KEYBOARD_HEIGHT;
  modalBody().scrollTop += field.getBoundingClientRect().bottom - (keyboardTop - ROOM_BELOW_FIELD);
};

const openTheFormOnAPhone = async () => {
  await onAPhone(SCREEN_HEIGHT);
  const viewport = standInVisualViewport();

  renderEditor();
  await openCreateModal();
  await fillRequiredFields('Fix the header alignment');

  const field = page.getByLabelText('Supervisor *').element();
  scrollFieldJustAboveTheKeyboard(field);

  return { viewport, field };
};

const openTheSupervisorList = () => openPicker('Supervisor *', 'Anna Kovalenko');

describe('Create work package - suggestions and the visual viewport', () => {
  it('flips the suggestions above the field once the keyboard covers the room below it', async () => {
    const { viewport, field } = await openTheFormOnAPhone();
    await openTheSupervisorList();

    expect(supervisorList().top).toBeGreaterThanOrEqual(field.getBoundingClientRect().bottom);

    viewport.raiseKeyboard(KEYBOARD_HEIGHT);

    await expect.poll(() => Math.round(supervisorList().bottom))
      .toBeLessThanOrEqual(Math.round(field.getBoundingClientRect().top));
    expect(supervisorList().top).toBeGreaterThanOrEqual(0);
  });

  it('brings the suggestions back below the field when the keyboard goes away', async () => {
    const { viewport, field } = await openTheFormOnAPhone();
    viewport.raiseKeyboard(KEYBOARD_HEIGHT);
    await openTheSupervisorList();

    await expect.poll(() => Math.round(supervisorList().bottom))
      .toBeLessThanOrEqual(Math.round(field.getBoundingClientRect().top));

    viewport.lowerKeyboard();

    await expect.poll(() => Math.round(supervisorList().top))
      .toBeGreaterThanOrEqual(Math.round(field.getBoundingClientRect().bottom));
  });

  it('keeps the suggestions on the field when the visual viewport pans down the layout one', async () => {
    const { viewport, field } = await openTheFormOnAPhone();
    viewport.raiseKeyboard(KEYBOARD_HEIGHT);
    viewport.scrollTo(PANNED_BY);
    scrollFieldJustAboveTheKeyboard(field, PANNED_BY);

    await openTheSupervisorList();

    await expect.poll(() => gapToField('Supervisor', field)).toBeLessThanOrEqual(MAX_GAP_TO_FIELD);
    expect(supervisorList().top).toBeGreaterThanOrEqual(PANNED_BY);
  });

  it('ignores the offset where client rects are read off the visual viewport', async () => {
    const { viewport, field } = await openTheFormOnAPhone();
    viewport.readClientRectsOffTheVisualViewport();
    viewport.raiseKeyboard(KEYBOARD_HEIGHT);
    viewport.scrollTo(REPORTED_OFFSET);

    await openTheSupervisorList();

    await expect.poll(() => gapToField('Supervisor', field)).toBeLessThanOrEqual(MAX_GAP_TO_FIELD);
  });

  it('keeps the suggestions on the field when the reader pinches in', async () => {
    const { viewport, field } = await openTheFormOnAPhone();
    await openTheSupervisorList();

    viewport.pinchTo(PINCHED_IN);

    await expect.poll(() => gapToField('Supervisor', field)).toBeLessThanOrEqual(MAX_GAP_TO_FIELD);
  });
});
