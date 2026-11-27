import { afterEach, describe, expect, it } from 'vitest';
import { useState } from 'react';
import { cleanup, render } from 'vitest-browser-react';
import { page, userEvent } from 'vitest/browser';
import { FormFieldControl } from '../../../../lib/components/CreateWorkPackage/FormFieldControl';
import type { FieldKind, FieldValue } from '../../../../lib/components/CreateWorkPackage/formSchema';
import { DESKTOP } from '../../../helpers/createWorkPackageHelpers';

afterEach(() => {
  cleanup();
});

const LABEL = 'Go-live';

const NOON_FOR_THE_USER = '2026-10-14T22:00:00Z';

function renderDateField(kind:FieldKind, initial = '', onKeyDown?:(key:string) => void) {
  const changes:FieldValue[] = [];

  const Harness = () => {
    const [value, setValue] = useState<FieldValue>(initial);
    return (
      <FormFieldControl
        field={{ key: 'customField9', label: LABEL, kind, required: false, isLink: false }}
        value={value}
        onChange={(next) => {
          changes.push(next);
          setValue(next);
        }}
      />
    );
  };

  render(<div onKeyDown={(event) => onKeyDown?.(event.key)}><Harness /></div>);
  return { input: page.getByLabelText(LABEL), lastChange: () => changes[changes.length - 1] };
}

const calendar = () => page.elementLocator(document.body).getByTestId('op-bn-create-wp-customField9-calendar');

const day = (label:string) => page.getByLabelText(label, { exact: true });

async function openCalendar() {
  await expect.element(page.getByLabelText(LABEL)).toBeEnabled();
  await userEvent.click(page.getByLabelText(LABEL));
  await expect.element(calendar()).toBeVisible();
}

describe('the date picker of the create form', () => {
  describe('for a date and time', () => {
    it('shows the value in the formats and time zone of the user', async () => {
      const { input } = renderDateField('datetime', NOON_FOR_THE_USER);

      await expect.element(input).toHaveValue('15.10.2026 12:00');
    });

    it('takes a picked day as a day in the time zone of the user', async () => {
      const { lastChange } = renderDateField('datetime', NOON_FOR_THE_USER);
      await openCalendar();

      await userEvent.click(day('October 20, 2026'));

      await expect.poll(() => lastChange()).toBe('2026-10-19T22:00:00Z');
    });

    it('takes typed text in the formats of the user', async () => {
      const { input, lastChange } = renderDateField('datetime', NOON_FOR_THE_USER);
      await expect.element(input).toBeEnabled();

      await userEvent.fill(input, '21.10.2026 08:15');
      await userEvent.keyboard('{Tab}');

      await expect.poll(() => lastChange()).toBe('2026-10-20T18:15:00Z');
      await expect.element(input).toHaveValue('21.10.2026 08:15');
    });

    it('clears the value with the text', async () => {
      const { input, lastChange } = renderDateField('datetime', NOON_FOR_THE_USER);
      await expect.element(input).toBeEnabled();

      await userEvent.clear(input);
      await userEvent.keyboard('{Tab}');

      await expect.poll(() => lastChange()).toBe('');
    });

    it('offers the time on the clock the user reads', async () => {
      renderDateField('datetime', NOON_FOR_THE_USER);
      await openCalendar();

      await expect.element(calendar().getByLabelText('Hour')).toHaveValue(12);
      expect(calendar().element().querySelector('.flatpickr-am-pm')).toBeNull();
    });
  });

  describe('for a date', () => {
    it('takes a picked day as a date', async () => {
      const { lastChange } = renderDateField('date', '2026-10-15');
      await openCalendar();

      await userEvent.click(day('October 20, 2026'));

      await expect.poll(() => lastChange()).toBe('2026-10-20');
    });

    it('takes a typed date', async () => {
      const { input, lastChange } = renderDateField('date', '2026-10-15');
      await expect.element(input).toBeEnabled();

      await userEvent.fill(input, '2026-10-21');
      await userEvent.keyboard('{Tab}');

      await expect.poll(() => lastChange()).toBe('2026-10-21');
    });

    it('leaves the date to the phone on a narrow screen', async () => {
      await page.viewport(390, 700);

      try {
        const { input, lastChange } = renderDateField('date');

        await expect.element(input).toHaveAttribute('type', 'date');
        await userEvent.fill(input, '2026-10-21');
        await expect.poll(() => lastChange()).toBe('2026-10-21');
      } finally {
        await page.viewport(DESKTOP.width, DESKTOP.height);
      }
    });
  });

  describe('the calendar', () => {
    it('starts the week on the day the user does', async () => {
      renderDateField('date', '2026-10-15');
      await openCalendar();

      const weekdays = calendar().element().querySelectorAll('.flatpickr-weekday');
      expect(weekdays[0].textContent?.trim()).toBe('Mon');
    });

    it('marks the days not worked, but leaves them to be picked', async () => {
      const { lastChange } = renderDateField('date', '2026-10-15');
      await openCalendar();

      await expect.element(day('October 24, 2026')).toHaveClass('flatpickr-non-working-day_enabled');
      await expect.element(day('October 26, 2026')).toHaveClass('flatpickr-non-working-day_enabled');
      await expect.element(day('October 20, 2026')).not.toHaveClass('flatpickr-non-working-day_enabled');

      await userEvent.click(day('October 24, 2026'));
      await expect.poll(() => lastChange()).toBe('2026-10-24');
    });

    it('opens right below the field', async () => {
      const { input } = renderDateField('date', '2026-10-15');
      await openCalendar();

      const fieldBottom = input.element().getBoundingClientRect().bottom;
      const calendarTop = calendar().element().getBoundingClientRect().top;
      expect(calendarTop).toBeGreaterThanOrEqual(fieldBottom);
      expect(calendarTop - fieldBottom).toBeLessThan(8);
    });
  });

  describe('Escape', () => {
    it('is kept from the form while the calendar is open', async () => {
      const keys:string[] = [];
      renderDateField('date', '2026-10-15', (key) => keys.push(key));
      await openCalendar();

      await userEvent.keyboard('{Escape}');
      await expect.element(calendar()).not.toBeVisible();

      await openCalendar();
      day('October 20, 2026').element().focus();
      await userEvent.keyboard('{Escape}');
      await expect.element(calendar()).not.toBeVisible();

      expect(keys).not.toContain('Escape');
    });

    it('reaches the form once the calendar is closed', async () => {
      const keys:string[] = [];
      renderDateField('date', '2026-10-15', (key) => keys.push(key));
      await openCalendar();

      await userEvent.keyboard('{Escape}');
      await expect.element(calendar()).not.toBeVisible();
      await userEvent.keyboard('{Escape}');

      expect(keys).toEqual(['Escape']);
    });
  });
});
