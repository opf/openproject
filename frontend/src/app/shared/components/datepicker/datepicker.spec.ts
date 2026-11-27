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
import { Injector } from '@angular/core';
import { Observable, of, Subject } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { IWeekday } from 'core-app/core/state/days/weekday.model';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { DatePicker } from './datepicker';

describe('DatePicker', () => {
  let weekdays$:Subject<IWeekday[]>;
  let loadWeekdays:() => Observable<IWeekday[]>;
  let input:HTMLInputElement;

  beforeEach(() => {
    weekdays$ = new Subject<IWeekday[]>();
    loadWeekdays = () => weekdays$;
    input = document.createElement('input');
    document.body.appendChild(input);

    TestBed.configureTestingModule({
      providers: [
        { provide: WeekdayService, useValue: { loadWeekdays: () => loadWeekdays() } },
        { provide: ConfigurationService, useValue: { startOfWeek: () => 1 } },
        { provide: I18nService, useValue: { t: () => [] } },
        { provide: DayResourceService, useValue: {} },
      ],
    });
  });

  afterEach(() => {
    input.remove();
    vi.restoreAllMocks();
  });

  async function finishLoadingWeekdays() {
    weekdays$.next([]);
    weekdays$.complete();
    await Promise.resolve();
  }

  function createDatePicker() {
    return new DatePicker(TestBed.inject(Injector), '', '2026-11-21', {}, input);
  }

  it('redraws once the weekdays have loaded', async () => {
    const datePicker = createDatePicker();
    const redraw = vi.spyOn(datePicker.datepickerInstance, 'redraw');

    await finishLoadingWeekdays();

    expect(redraw).toHaveBeenCalledOnce();
    datePicker.destroy();
  });

  it('redraws after construction when the weekdays are cached', async () => {
    loadWeekdays = () => of([]);
    const pickerAssigned:boolean[] = [];
    const caller:{ datePicker?:DatePicker } = {};

    caller.datePicker = new DatePicker(TestBed.inject(Injector), '', '2026-11-21', {
      onDayCreate: () => { pickerAssigned.push(caller.datePicker !== undefined); },
    }, input);
    await new Promise((resolve) => { setTimeout(resolve); });

    expect(pickerAssigned.at(-1)).toBe(true);
    caller.datePicker.destroy();
  });

  it('does not redraw when destroyed before the weekdays have loaded', async () => {
    const datePicker = createDatePicker();
    const redraw = vi.spyOn(datePicker.datepickerInstance, 'redraw');

    datePicker.destroy();
    await finishLoadingWeekdays();

    expect(redraw).not.toHaveBeenCalled();
  });
});
