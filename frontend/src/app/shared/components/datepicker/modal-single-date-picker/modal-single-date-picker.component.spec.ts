//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { english } from 'flatpickr/dist/l10n/default';
import { of } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { OpSpotModule } from 'core-app/spot/spot.module';
import { OpDatePickerModule } from '../datepicker.module';
import { OpModalSingleDatePickerComponent } from './modal-single-date-picker.component';

@Component({
  imports: [ReactiveFormsModule, OpDatePickerModule, OpSpotModule],
  template: `
    <op-modal-single-date-picker
      id="date-picker"
      name="date"
      [formControl]="date"
      [opened]="opened()"
      (closed)="opened.set(false)"
    >
      <button slot="trigger" type="button" (click)="opened.set(true)">Choose date</button>
    </op-modal-single-date-picker>
    <opce-spot-drop-modal-portal />
  `,
})
class DatePickerHostComponent {
  readonly date = new FormControl('2026-11-07', { nonNullable: true });
  readonly opened = signal(false);
}

describe('OpModalSingleDatePickerComponent', () => {
  function submittedValue(host:HTMLElement) {
    return host.querySelector<HTMLInputElement>('input[hidden][name="date"]')!;
  }

  async function openCalendar(host:HTMLElement) {
    fireEvent.click(screen.getByRole('button', { name: 'Choose date' }));
    const portal = host.querySelector<HTMLElement>('opce-spot-drop-modal-portal')!;
    const calendar = within(portal);
    await calendar.findByRole('button', { name: 'Apply' });
    // The drop modal installs its document listeners in the next browser task.
    await new Promise<void>((resolve) => setTimeout(resolve));
    return { calendar, portal };
  }

  beforeEach(() => {
    window.I18n.store({
      en: {
        date: {
          abbr_day_names: english.weekdays.shorthand,
          day_names: english.weekdays.longhand,
          abbr_month_names: ['', ...english.months.shorthand],
          month_names: ['', ...english.months.longhand],
          abbr_week: 'Wk',
        },
        js: {
          modals: { button_apply: 'Apply' },
          button_cancel: 'Cancel',
        },
      },
    });
    TestBed.configureTestingModule({
      imports: [DatePickerHostComponent],
      providers: [
        { provide: ConfigurationService, useValue: { startOfWeek: () => 1 } },
        { provide: WeekdayService, useValue: { loadWeekdays: () => of([]), isNonWorkingDay: () => false } },
        { provide: DayResourceService, useValue: { isNonWorkingDay$: () => Promise.resolve(false) } },
      ],
    });
  });

  it('updates the working value from a calendar day and applies it', async () => {
    const fixture = TestBed.createComponent(DatePickerHostComponent);
    await fixture.whenStable();
    const submittedDate = submittedValue(fixture.nativeElement as HTMLElement);
    expect(submittedDate).toHaveValue('2026-11-07');

    const { calendar, portal } = await openCalendar(fixture.nativeElement as HTMLElement);
    const day = await waitFor(() => {
      const day = portal.querySelector<HTMLElement>('.flatpickr-day[aria-label="November 8, 2026"]');
      expect(day).toBeVisible();
      return day!;
    });
    fireEvent.click(day);
    const workingDate = calendar.getByRole('textbox');
    await waitFor(() => expect(workingDate).toHaveValue('2026-11-08'));

    fireEvent.click(calendar.getByRole('button', { name: 'Apply' }));
    await waitFor(() => expect(calendar.queryByRole('textbox')).not.toBeInTheDocument());
    expect(submittedDate).toHaveValue('2026-11-08');
    expect(fixture.componentInstance.date.value).toBe('2026-11-08');
  });

  it('discards a canceled draft', async () => {
    const fixture = TestBed.createComponent(DatePickerHostComponent);
    await fixture.whenStable();
    const host = fixture.nativeElement as HTMLElement;
    const picker = fixture.debugElement.query(By.directive(OpModalSingleDatePickerComponent))
      .injector.get(OpModalSingleDatePickerComponent);
    const { calendar } = await openCalendar(host);
    fireEvent.input(await calendar.findByRole('textbox'), { target: { value: '2026-11-12' } });
    await waitFor(() => expect(picker.workingValue).toBe('2026-11-12'));

    fireEvent.click(calendar.getByRole('button', { name: 'Cancel' }));
    await waitFor(() => expect(calendar.queryByRole('textbox')).not.toBeInTheDocument());
    expect(fixture.componentInstance.date.value).toBe('2026-11-07');
    expect(submittedValue(host)).toHaveValue('2026-11-07');

    const reopened = await openCalendar(host);
    await waitFor(() => expect(reopened.calendar.getByRole('textbox')).toHaveValue('2026-11-07'));
  });

  it('renders a value written to the form control after the picker has mounted', async () => {
    const fixture = TestBed.createComponent(DatePickerHostComponent);
    await fixture.whenStable();
    const submittedDate = submittedValue(fixture.nativeElement as HTMLElement);
    fixture.componentInstance.date.setValue('2026-12-01');
    await waitFor(() => expect(submittedDate).toHaveValue('2026-12-01'));
  });
});
