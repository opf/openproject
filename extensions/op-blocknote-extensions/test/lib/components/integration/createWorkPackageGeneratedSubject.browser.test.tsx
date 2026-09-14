import { afterEach, describe, it, expect } from 'vitest';
import { http, HttpResponse } from 'msw';
import { page, userEvent } from 'vitest/browser';
import { renderEditor } from '../../../helpers/renderEditor';
import {
  fillRequiredFieldsBesidesSubject,
  openCreateModal,
  selectOptionNamed,
} from '../../../helpers/createWorkPackageHelpers';
import { worker } from '../../../mocks/browser';
import { GENERATED_SUBJECT_HINT, mockCreatedWorkPackage } from '../../../mocks/handlers';

afterEach(() => worker.resetHandlers());

const TYPED_SUBJECT = 'Typed by hand';

async function pickTheGeneratingType(subject = TYPED_SUBJECT) {
  renderEditor();
  await openCreateModal();
  await userEvent.fill(page.getByLabelText('Subject *'), subject);

  await fillRequiredFieldsBesidesSubject('Phase');
}

describe('Create work package - a type that generates the subject', () => {
  it('tells what the type will generate instead of asking for a subject', async () => {
    await pickTheGeneratingType();

    await expect.element(page.getByLabelText('Subject')).toHaveValue(GENERATED_SUBJECT_HINT);
    await expect.element(page.getByLabelText('Subject')).toHaveAttribute('readonly');
    await expect.element(page.getByLabelText('Subject *')).not.toBeInTheDocument();
  });

  it('leaves the subject to the API rather than sending what was typed', async () => {
    let body:Record<string, unknown> = {};
    worker.use(
      http.post('http://localhost:3000/api/v3/work_packages', async ({ request }) => {
        body = await request.json() as Record<string, unknown>;
        return HttpResponse.json(mockCreatedWorkPackage, { status: 201 });
      })
    );

    await pickTheGeneratingType();

    await userEvent.click(page.getByTestId('create-wp-submit'));

    await expect.element(page.getByTestId('block-card')).toBeVisible();
    expect(body).not.toHaveProperty('subject');
  });

  it('hands the typed subject back when a type that asks for one takes over', async () => {
    await pickTheGeneratingType();

    await selectOptionNamed('Type *', 'Task');

    await expect.element(page.getByLabelText('Subject *')).toHaveValue(TYPED_SUBJECT);
  });
});
