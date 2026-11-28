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

import { TestBed } from '@angular/core/testing';
import { vi } from 'vitest';
import { of } from 'rxjs';
import moment from 'moment-timezone';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';
import { OpWpDatePickerInstanceComponent } from './wp-date-picker-instance.component';

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
  return TestBed.configureTestingModule({
    providers: [
      TimezoneService,
      { provide: I18nService, useValue: { t: translate } },
      { provide: DeviceService, useValue: { isMobile: false } },
      { provide: ApiV3Service, useValue: {} },
      { provide: PathHelperService, useValue: {} },
      { provide: ConfigurationService, useValue: { isTimezoneSet: () => false, startOfWeek: () => 1 } },
      {
        provide: WeekdayService,
        useValue: { loadWeekdays: () => of([]), isNonWorkingDay: (day:Date) => day.getDay() === 6 },
      },
      { provide: DayResourceService, useValue: { isNonWorkingDay$: () => Promise.resolve(false) } },
    ],
  }).compileComponents();
}

function day(element:HTMLElement, label:string):HTMLElement {
  return element.querySelector<HTMLElement>(`.flatpickr-day[aria-label="${label}"]`)!;
}

async function expectDayClass(element:HTMLElement, label:string, cssClass:string, present = true) {
  await vi.waitFor(() => expect(day(element, label).classList.contains(cssClass)).toBe(present));
}

describe('OpWpDatePickerInstanceComponent as a custom element', () => {
  beforeEach(() => configure());

  afterEach(() => document.body.replaceChildren());

  it('selects the dates and range mode from the attributes', async () => {
    const custom = await defineTestCustomElement(OpWpDatePickerInstanceComponent, {
      'start-date': '2026-12-10',
      'due-date': '2026-12-24',
      'date-mode': 'range',
    });

    expect(day(custom.element, 'December 10, 2026')).toHaveClass('selected');
    expect(day(custom.element, 'December 24, 2026')).toHaveClass('selected');
    expect(day(custom.element, 'December 17, 2026')).toHaveClass('inRange');
  });

  it('selects a single date in single mode', async () => {
    const custom = await defineTestCustomElement(OpWpDatePickerInstanceComponent, {
      'start-date': '2026-12-10',
      'date-mode': 'single',
    });

    expect(day(custom.element, 'December 10, 2026')).toHaveClass('selected');
    expect(custom.element.querySelectorAll('.flatpickr-day.selected')).toHaveLength(1);
  });

  it('disables days before min-date', async () => {
    const custom = await defineTestCustomElement(OpWpDatePickerInstanceComponent, {
      'date-mode': 'range',
      'min-date': '2026-12-05',
    });

    expect(day(custom.element, 'December 4, 2026')).toHaveClass('flatpickr-disabled');
    expect(day(custom.element, 'December 5, 2026')).not.toHaveClass('flatpickr-disabled');
  });

  it('disables all days when is-schedulable is false', async () => {
    const custom = await defineTestCustomElement(OpWpDatePickerInstanceComponent, {
      'date-mode': 'range',
      'is-schedulable': 'false',
    });

    await expectDayClass(custom.element, 'December 10, 2026', 'flatpickr-disabled');
    expect(custom.element.querySelectorAll('.flatpickr-day:not(.flatpickr-disabled)')).toHaveLength(0);
  });

  it('keeps days enabled by default', async () => {
    const custom = await defineTestCustomElement(OpWpDatePickerInstanceComponent, { 'date-mode': 'range' });

    await expectDayClass(custom.element, 'December 11, 2026', 'flatpickr-non-working-day', false);
    await expectDayClass(custom.element, 'December 12, 2026', 'flatpickr-non-working-day');
    expect(day(custom.element, 'December 10, 2026')).not.toHaveClass('flatpickr-disabled');
  });

  it('disables days before the start date unless schedule-manually is set', async () => {
    const automatic = await defineTestCustomElement(OpWpDatePickerInstanceComponent, {
      'start-date': '2026-12-10',
      'date-mode': 'range',
    });
    await expectDayClass(automatic.element, 'December 9, 2026', 'flatpickr-disabled');

    const manual = await defineTestCustomElement(OpWpDatePickerInstanceComponent, {
      'start-date': '2026-12-10',
      'date-mode': 'range',
      'schedule-manually': '',
    });
    await expectDayClass(manual.element, 'December 12, 2026', 'flatpickr-non-working-day');
    expect(day(manual.element, 'December 9, 2026')).not.toHaveClass('flatpickr-disabled');
  });

  it('enables non-working days with ignore-non-working-days', async () => {
    const custom = await defineTestCustomElement(OpWpDatePickerInstanceComponent, {
      'date-mode': 'range',
      'ignore-non-working-days': '',
    });

    await expectDayClass(custom.element, 'December 12, 2026', 'flatpickr-non-working-day_enabled');
    expect(day(custom.element, 'December 12, 2026')).not.toHaveClass('flatpickr-non-working-day');
  });

  it('follows the set-values event for ignoring non-working days', async () => {
    const custom = await defineTestCustomElement(OpWpDatePickerInstanceComponent, { 'date-mode': 'range' });
    await expectDayClass(custom.element, 'December 12, 2026', 'flatpickr-non-working-day');

    document.dispatchEvent(new CustomEvent('date-picker:flatpickr-set-values', {
      detail: { dates: [new Date(Date.UTC(2026, 11, 10))], ignoreNonWorkingDays: true, mode: 'range' },
    }));

    await expectDayClass(custom.element, 'December 12, 2026', 'flatpickr-non-working-day_enabled');
    expect(day(custom.element, 'December 10, 2026')).toHaveClass('selected');
  });

  it('dispatches the dates-changed event when a day is picked', async () => {
    const custom = await defineTestCustomElement(OpWpDatePickerInstanceComponent, { 'date-mode': 'range' });
    const listener = vi.fn();
    document.addEventListener('date-picker:flatpickr-dates-changed', listener);

    day(custom.element, 'December 10, 2026').click();
    document.removeEventListener('date-picker:flatpickr-dates-changed', listener);

    const event = listener.mock.calls[0][0] as CustomEvent<{ dates:Date[] }>;
    expect(event.detail.dates).toEqual([new Date(Date.UTC(2026, 11, 10))]);
  });
});
