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
import { FormsModule } from '@angular/forms';
import { fireEvent } from '@testing-library/dom';
import { of } from 'rxjs';
import moment from 'moment-timezone';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';
import { OpBasicDatePickerModule } from '../basic-datepicker.module';
import { OpBasicSingleDatePickerComponent } from './basic-single-date-picker.component';

@Component({
  template: '<op-basic-single-date-picker [(ngModel)]="date" inputId="due" name="due" />',
  imports: [FormsModule, OpBasicDatePickerModule],
})
class NgModelHostComponent {
  readonly date = signal('2026-01-01');
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

function configure(isMobile = false) {
  TestBed.overrideProvider(I18nService, { useValue: { t: translate } });
  return TestBed.configureTestingModule({
    imports: [OpBasicDatePickerModule, NgModelHostComponent],
    providers: [
      TimezoneService,
      { provide: DeviceService, useValue: { isMobile } },
      { provide: ConfigurationService, useValue: { isTimezoneSet: () => false, startOfWeek: () => 1 } },
      { provide: WeekdayService, useValue: { loadWeekdays: () => of([]), isNonWorkingDay: () => false } },
      { provide: DayResourceService, useValue: { isNonWorkingDay$: () => Promise.resolve(false) } },
    ],
  }).compileComponents();
}

describe('OpBasicSingleDatePickerComponent as a custom element', () => {
  beforeEach(() => configure());

  afterEach(() => document.body.replaceChildren());

  it('sets the inner input from the attributes', async () => {
    const custom = await defineTestCustomElement(OpBasicSingleDatePickerComponent, {
      'input-id': 'work_package_due_date',
      name: 'work_package[due_date]',
      value: '2026-12-24',
      required: 'required',
      disabled: 'disabled',
      placeholder: 'Pick a date',
      'input-class-names': 'remote-field--input',
      'remote-field-key': 'due_date',
      'input-attrs': JSON.stringify({ 'data-action': 'change->form#preview', 'data-filter-name': 'dueDate' }),
    });
    const input = custom.element.querySelector('input')!;

    expect(custom.element).not.toHaveAttribute('id');
    expect(input).toHaveAttribute('id', 'work_package_due_date');
    expect(input).toHaveAttribute('name', 'work_package[due_date]');
    expect(input).toHaveValue('2026-12-24');
    expect(input).toBeRequired();
    expect(input).toHaveProperty('disabled', true);
    expect(input).toHaveAttribute('placeholder', 'Pick a date');
    expect(input).toHaveClass('remote-field--input');
    expect(input).toHaveAttribute('data-remote-field-key', 'due_date');
    expect(input).toHaveAttribute('data-action', 'change->form#preview');
    expect(input).toHaveAttribute('data-filter-name', 'dueDate');
  });

  it('leaves the input empty and optional without the attributes', async () => {
    const custom = await defineTestCustomElement(OpBasicSingleDatePickerComponent, { 'input-id': 'start' });
    const input = custom.element.querySelector('input')!;

    expect(input).toHaveValue('');
    expect(input).not.toBeRequired();
    expect(input).toBeEnabled();
    expect(input).not.toHaveAttribute('data-remote-field-key');
  });

  it('follows the disabled attribute toggled after connecting', async () => {
    const custom = await defineTestCustomElement(OpBasicSingleDatePickerComponent, { 'input-id': 'start' });
    const input = custom.element.querySelector('input')!;

    await custom.set('disabled', 'disabled');

    expect(input).toHaveProperty('disabled', true);

    await custom.remove('disabled');

    expect(input).toBeEnabled();
  });

  it('attaches the calendar to the dialog given by in-dialog', async () => {
    const dialog = document.createElement('div');
    dialog.id = 'my-dialog';
    document.body.appendChild(dialog);

    await defineTestCustomElement(OpBasicSingleDatePickerComponent, { 'input-id': 'start', 'in-dialog': 'my-dialog' });

    expect(dialog.querySelector('.flatpickr-calendar')).toBeInTheDocument();
  });
});

describe('OpBasicSingleDatePickerComponent as a custom element on mobile', () => {
  beforeEach(() => configure(true));

  afterEach(() => document.body.replaceChildren());

  it('renders a native date input with the id, name and value', async () => {
    const custom = await defineTestCustomElement(OpBasicSingleDatePickerComponent, {
      'input-id': 'start',
      name: 'start_date',
      value: '2026-12-24',
    });
    const input = custom.element.querySelector('input')!;

    expect(input).toHaveAttribute('type', 'date');
    expect(input).toHaveAttribute('id', 'start');
    expect(input).toHaveAttribute('name', 'start_date');
    expect(input).toHaveValue('2026-12-24');
  });
});

describe('OpBasicSingleDatePickerComponent with ngModel', () => {
  beforeEach(() => configure());

  it('binds the value both ways', async () => {
    const fixture = TestBed.createComponent(NgModelHostComponent);
    await fixture.whenStable();
    const input = (fixture.nativeElement as HTMLElement).querySelector('input')!;

    expect(input).toHaveAttribute('id', 'due');
    expect(input).toHaveValue('2026-01-01');

    fireEvent.input(input, { target: { value: '2026-02-02' } });

    expect(fixture.componentInstance.date()).toBe('2026-02-02');

    fixture.componentInstance.date.set('2026-03-03');
    await fixture.whenStable();

    expect(input).toHaveValue('2026-03-03');
  });
});
