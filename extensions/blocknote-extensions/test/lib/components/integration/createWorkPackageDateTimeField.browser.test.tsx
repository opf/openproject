import { afterEach, describe, expect, it } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import { fillRequiredFields, modalPanel, openCreateModal } from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';
import { createFormFor, mockCreatedWorkPackage } from '../../../mocks/handlers';
import type { FormRequestBody } from '../../../mocks/handlers';

afterEach(() => worker.resetHandlers());

const GO_LIVE = 'Go-live *';

const TYPED = '21.10.2026 08:15';
const TYPED_INSTANT = '2026-10-20T18:15:00Z';

function withRequiredDateTimeField() {
  worker.use(
    http.post('http://localhost:3000/api/v3/work_packages/form', async ({ request }) => {
      const form = createFormFor(await request.json() as FormRequestBody);
      const { schema } = form._embedded;
      if (schema.status) {
        schema.customField9 = { type: 'DateTime', name: 'Go-live', required: true, hasDefault: false, writable: true };
      }
      return HttpResponse.json(form);
    })
  );
}

function capturingCreation():{ body:Record<string, unknown> | null } {
  const captured:{ body:Record<string, unknown> | null } = { body: null };
  worker.use(
    http.post('http://localhost:3000/api/v3/work_packages', async ({ request }) => {
      captured.body = await request.json() as Record<string, unknown>;
      return HttpResponse.json(mockCreatedWorkPackage, { status: 201 });
    })
  );
  return captured;
}

async function openFormWithDateTimeField() {
  withRequiredDateTimeField();
  renderEditor();
  await openCreateModal();
  await fillRequiredFields('Launch the new pricing page');
  await expect.element(page.getByLabelText(GO_LIVE)).toBeEnabled();
}

const calendar = () => modalPanel().querySelector<HTMLElement>('.flatpickr-calendar')!;

describe('a required date and time in the create form', () => {
  it('is asked for, rather than sending the user to OpenProject', async () => {
    await openFormWithDateTimeField();

    await expect.element(page.getByText('cannot be set here')).not.toBeInTheDocument();
    await expect.element(page.getByTestId('create-wp-submit')).toBeEnabled();
  });

  it('is submitted as the instant the user meant', async () => {
    const creation = capturingCreation();
    await openFormWithDateTimeField();

    await userEvent.fill(page.getByLabelText(GO_LIVE), TYPED);
    await userEvent.keyboard('{Tab}');
    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    expect(creation.body?.customField9).toBe(TYPED_INSTANT);
  });

  it('is taken over from the text when Enter submits the form', async () => {
    const creation = capturingCreation();
    await openFormWithDateTimeField();

    await userEvent.fill(page.getByLabelText(GO_LIVE), TYPED);
    await userEvent.keyboard('{Enter}');

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    expect(creation.body?.customField9).toBe(TYPED_INSTANT);
  });

  it('holds the form back while it is empty', async () => {
    await openFormWithDateTimeField();

    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByText('This field is required.')).toBeVisible();
    await expect.element(page.getByLabelText(GO_LIVE)).toHaveFocus();
  });

  it('opens its calendar over the form, which a picked day leaves open', async () => {
    await openFormWithDateTimeField();

    await userEvent.click(page.getByLabelText(GO_LIVE));
    await expect.element(calendar()).toBeVisible();

    const { left, top, width, height } = calendar().getBoundingClientRect();
    expect(calendar().contains(document.elementFromPoint(left + width / 2, top + height / 2))).toBe(true);
    expect(getComputedStyle(calendar()).backgroundColor).toBe(getComputedStyle(modalPanel()).backgroundColor);

    const today = calendar().querySelector<HTMLElement>('.flatpickr-day.today')!;
    await userEvent.click(today);

    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
    await expect.element(page.getByLabelText(GO_LIVE)).not.toHaveValue('');
  });

  it('closes only its calendar on Escape', async () => {
    await openFormWithDateTimeField();
    await userEvent.click(page.getByLabelText(GO_LIVE));
    await expect.element(calendar()).toBeVisible();

    await userEvent.keyboard('{Escape}');

    await expect.element(calendar()).not.toBeVisible();
    await expect.element(page.getByTestId('create-wp-modal')).toBeVisible();
  });
});
