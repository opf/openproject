import { describe, it, expect, vi, afterEach } from 'vitest';
import { render, cleanup } from 'vitest-browser-react';
import { page } from 'vitest/browser';
import { FormFieldControl } from '../../../../lib/components/CreateWorkPackage/FormFieldControl';
import type { FormField } from '../../../../lib/components/CreateWorkPackage/formSchema';

afterEach(() => {
  cleanup();
});

function renderField(field:FormField) {
  render(
    <FormFieldControl
      field={field}
      value={undefined}
      onChange={vi.fn()}
    />
  );
  return page.getByLabelText(field.label);
}

// A browser suggesting past values makes sense for a plain custom-field text
// input, but not for the Subject line, a date, or a number - those are
// suppressed explicitly rather than through the shared text-input default.
describe('FormFieldControl autocomplete', () => {
  it('turns off autocomplete on the Subject field', async () => {
    const control = renderField({
      key: 'subject',
      label: 'Subject',
      kind: 'text',
      required: true,
      isLink: false,
    });

    await expect.element(control).toHaveAttribute('autocomplete', 'off');
  });

  it('leaves autocomplete on for other plain text fields', async () => {
    const control = renderField({
      key: 'customText',
      label: 'Custom text',
      kind: 'text',
      required: false,
      isLink: false,
    });

    await expect.element(control).not.toHaveAttribute('autocomplete');
  });

  it('turns off autocomplete on date fields', async () => {
    const control = renderField({
      key: 'startDate',
      label: 'Start date',
      kind: 'date',
      required: false,
      isLink: false,
    });

    await expect.element(control).toHaveAttribute('autocomplete', 'off');
  });

  it('turns off autocomplete on number fields', async () => {
    const control = renderField({
      key: 'estimatedHours',
      label: 'Estimated hours',
      kind: 'number',
      required: false,
      isLink: false,
      integer: true,
    });

    await expect.element(control).toHaveAttribute('autocomplete', 'off');
  });

  it('turns off autocomplete on textarea fields', async () => {
    const control = renderField({
      key: 'description',
      label: 'Description',
      kind: 'textarea',
      required: false,
      isLink: false,
    });

    await expect.element(control).toHaveAttribute('autocomplete', 'off');
  });
});
