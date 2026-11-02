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
import {
  createFormFor,
  GENERATED_SUBJECT_HINT,
  mockCreatedWorkPackage,
  type FormRequestBody,
} from '../../../mocks/handlers';

afterEach(() => worker.resetHandlers());

const TYPED_SUBJECT = 'Typed by hand';
const UNBROKEN_TYPE_HINT = `Automatically generated through type ${'Phase'.repeat(40)}`;

async function pickTheGeneratingType(subject = TYPED_SUBJECT) {
  renderEditor();
  await openCreateModal();
  await userEvent.fill(page.getByLabelText('Subject *'), subject);

  await fillRequiredFieldsBesidesSubject('Phase');
}

function generatingHint(hint:string) {
  worker.use(
    http.post('http://localhost:3000/api/v3/work_packages/form', async ({ request }) => {
      const form = createFormFor(await request.json() as FormRequestBody);
      const { schema } = form._embedded;
      const subject = schema.subject as { hasDefault:boolean };
      if (subject.hasDefault) schema.subject = { ...subject, placeholder: hint };
      return HttpResponse.json(form);
    })
  );
}

function subjectAndProjectFields() {
  return {
    subject: page.getByLabelText('Subject').element() as HTMLElement,
    project: page.getByLabelText('Project *').element() as HTMLElement,
  };
}

describe('Create work package - a type that generates the subject', () => {
  it('tells what the type will generate instead of asking for a subject', async () => {
    await pickTheGeneratingType();

    await expect.element(page.getByLabelText('Subject')).toHaveValue(GENERATED_SUBJECT_HINT);
    await expect.element(page.getByLabelText('Subject')).toHaveAttribute('readonly');
    await expect.element(page.getByLabelText('Subject *')).not.toBeInTheDocument();
  });

  it('stays one line high while what the type will generate fits', async () => {
    const openProjectStyles = document.createElement('style');
    openProjectStyles.textContent = 'textarea { height: auto; min-height: 50px; }';
    document.head.append(openProjectStyles);

    try {
      await pickTheGeneratingType();

      const { subject, project } = subjectAndProjectFields();

      expect(subject.offsetHeight).toBe(project.offsetHeight);
    } finally {
      openProjectStyles.remove();
    }
  });

  it.each([
    ['a hint of several words', GENERATED_SUBJECT_HINT],
    ['a type name without spaces', UNBROKEN_TYPE_HINT],
  ])('wraps %s instead of cutting it off on a phone', async (_, hint) => {
    generatingHint(hint);
    await page.viewport(320, 600);

    try {
      await pickTheGeneratingType();

      await expect.element(page.getByLabelText('Subject')).toHaveValue(hint);

      const { subject, project } = subjectAndProjectFields();

      expect(subject.scrollWidth).toBeLessThanOrEqual(subject.clientWidth);
      expect(subject.scrollHeight).toBeLessThanOrEqual(subject.clientHeight);
      expect(subject.offsetHeight).toBeGreaterThan(project.offsetHeight);
    } finally {
      await page.viewport(800, 600);
    }
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
