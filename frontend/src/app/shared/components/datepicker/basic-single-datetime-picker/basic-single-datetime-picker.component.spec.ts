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
import { By } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { of } from 'rxjs';
import moment from 'moment-timezone';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';
import { OpBasicDatePickerModule } from '../basic-datepicker.module';
import { OpBasicSingleDatetimePickerComponent } from './basic-single-datetime-picker.component';

@Component({
  template: '<op-basic-single-datetime-picker [(ngModel)]="startsAt" [disabled]="inFlight()" inputId="starts" name="starts" />',
  imports: [FormsModule, OpBasicDatePickerModule],
})
class NgModelHostComponent {
  readonly startsAt = signal('2026-10-01T12:30:00Z');

  readonly inFlight = signal(false);
}

function translate(key:string):unknown {
  switch (key) {
    case 'date.abbr_day_names': return moment.weekdaysShort();
    case 'date.day_names': return moment.weekdays();
    case 'date.abbr_month_names': return ['', ...moment.monthsShort()];
    case 'date.month_names': return ['', ...moment.months()];
    default: return key;
  }
}

function configure() {
  TestBed.overrideProvider(I18nService, { useValue: { t: translate } });
  return TestBed.configureTestingModule({
    imports: [OpBasicDatePickerModule, NgModelHostComponent],
    providers: [
      TimezoneService,
      { provide: ConfigurationService, useValue: {
        isTimezoneSet: () => true, timezone: () => 'Etc/UTC',
        dateFormatPresent: () => true, dateFormat: () => 'YYYY-MM-DD',
        timeFormatPresent: () => true, timeFormat: () => 'HH:mm', startOfWeek: () => 1,
      } },
      { provide: WeekdayService, useValue: { loadWeekdays: () => of([]), isNonWorkingDay: () => false } },
      { provide: DayResourceService, useValue: { isNonWorkingDay$: () => Promise.resolve(false) } },
    ],
  }).compileComponents();
}

describe('OpBasicSingleDatetimePickerComponent as a custom element', () => {
  beforeEach(() => configure());

  afterEach(() => document.body.replaceChildren());

  const submittedInput = (element:HTMLElement) => element.querySelector<HTMLInputElement>('input[type="hidden"]')!;
  const visibleInput = (element:HTMLElement) => element.querySelector<HTMLInputElement>('input:not([type="hidden"])')!;

  it('sets the submitted and the visible input from the attributes', async () => {
    const custom = await defineTestCustomElement(OpBasicSingleDatetimePickerComponent, {
      'input-id': 'meeting_starts_at',
      name: 'meeting[starts_at]',
      value: '2026-10-01T12:30:00Z',
      required: 'required',
      'input-class-names': 'extra-class',
      'input-attrs': JSON.stringify({ 'data-action': 'change->form#preview', 'data-filter-name': 'startsAt' }),
    });
    const submitted = submittedInput(custom.element);
    const visible = visibleInput(custom.element);

    expect(custom.element).not.toHaveAttribute('id');
    expect(submitted).toHaveAttribute('id', 'meeting_starts_at-value');
    expect(submitted).toHaveAttribute('name', 'meeting[starts_at]');
    expect(submitted).toHaveValue('2026-10-01T12:30:00Z');
    expect(submitted).toHaveAttribute('required');
    expect(submitted).toHaveAttribute('data-action', 'change->form#preview');
    expect(submitted).toHaveAttribute('data-filter-name', 'startsAt');
    expect(visible).toHaveAttribute('id', 'meeting_starts_at');
    expect(visible).toHaveClass('extra-class');
    expect(visible).toHaveValue('2026-10-01 12:30');
    expect(visible).toBeRequired();
    expect(visible).toBeEnabled();
  });

  it('leaves the value empty without a value attribute', async () => {
    const custom = await defineTestCustomElement(OpBasicSingleDatetimePickerComponent, { 'input-id': 'starts' });

    expect(submittedInput(custom.element)).toHaveValue('');
    expect(visibleInput(custom.element)).toHaveValue('');
  });

  it('disables the visible input with the disabled attribute', async () => {
    const custom = await defineTestCustomElement(OpBasicSingleDatetimePickerComponent, { 'input-id': 'starts', disabled: 'disabled' });

    expect(visibleInput(custom.element)).toHaveProperty('disabled', true);
  });

  it('follows the disabled attribute toggled after connecting', async () => {
    const custom = await defineTestCustomElement(OpBasicSingleDatetimePickerComponent, { 'input-id': 'starts' });

    await custom.set('disabled', 'disabled');

    expect(visibleInput(custom.element)).toHaveProperty('disabled', true);

    await custom.remove('disabled');

    expect(visibleInput(custom.element)).toBeEnabled();
  });
});

describe('OpBasicSingleDatetimePickerComponent with ngModel', () => {
  beforeEach(() => configure());

  it('writes the model value into both inputs', async () => {
    const fixture = TestBed.createComponent(NgModelHostComponent);
    await fixture.whenStable();
    const host = fixture.nativeElement as HTMLElement;

    expect(host.querySelector('#starts-value')).toHaveValue('2026-10-01T12:30:00Z');

    fixture.componentInstance.startsAt.set('2026-11-02T08:00:00Z');
    await fixture.whenStable();

    expect(host.querySelector('#starts-value')).toHaveValue('2026-11-02T08:00:00Z');
    expect(host.querySelector('#starts')).toHaveValue('2026-11-02 08:00');
  });

  it('writes a date picked in the calendar back to the model', async () => {
    const fixture = TestBed.createComponent(NgModelHostComponent);
    await fixture.whenStable();
    const picker = fixture.debugElement.query(By.directive(OpBasicSingleDatetimePickerComponent))
      .componentInstance as OpBasicSingleDatetimePickerComponent;

    picker.datePickerInstance.datepickerInstance.setDate(new Date(2026, 10, 2, 8, 0), true);
    await fixture.whenStable();

    expect(fixture.componentInstance.startsAt()).toBe('2026-11-02T08:00:00Z');
  });

  it('disables the visible input with the disabled state', async () => {
    const fixture = TestBed.createComponent(NgModelHostComponent);
    await fixture.whenStable();
    const visible = (fixture.nativeElement as HTMLElement).querySelector<HTMLInputElement>('#starts')!;

    expect(visible).toBeEnabled();

    fixture.componentInstance.inFlight.set(true);
    await fixture.whenStable();

    expect(visible).toBeDisabled();
  });
});
