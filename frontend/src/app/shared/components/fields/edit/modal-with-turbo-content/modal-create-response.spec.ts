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

import { isDatePickerCreateResponse, isProgressCreateResponse } from './modal-create-response';
import { DatePickerEditFieldComponent } from '../field-types/date-picker-edit-field.component';
import { ProgressPopoverEditFieldComponent } from '../field-types/progress-popover-edit-field.component';

describe('Turbo modal create payloads', () => {
  const dates = { duration: 3, startDate: '2026-10-29', dueDate: '2026-11-02', includeNonWorkingDays: false, scheduleManually: true };
  const progress = { estimatedTime: 'PT3H', remainingTime: 'PT1H', percentageDone: 67 };

  it('accepts the JSON values from both Rails create endpoints', () => {
    expect(isDatePickerCreateResponse(dates)).toBe(true);
    expect(isProgressCreateResponse(progress)).toBe(true);
    expect(isDatePickerCreateResponse({ ...dates, duration: null, startDate: null, dueDate: null })).toBe(true);
    expect(isProgressCreateResponse({ estimatedTime: null, remainingTime: null, percentageDone: null })).toBe(true);
  });

  it.each([null, undefined, {}, new Event('create'), { ...dates, duration: '3' }, { ...dates, startDate: new Date() }])(
    'rejects non-date JSON %j', (value) => expect(isDatePickerCreateResponse(value)).toBe(false),
  );

  it.each([null, undefined, {}, { ...progress, percentageDone: '67' }, { ...progress, remainingTime: 1 }])(
    'rejects non-progress JSON %j', (value) => expect(isProgressCreateResponse(value)).toBe(false),
  );

  function dateField() {
    const field = Object.create(DatePickerEditFieldComponent.prototype) as DatePickerEditFieldComponent;
    const onModalClosed = vi.fn();
    Object.assign(field, {
      resource: {},
      change: { schema: { isMilestone: false } },
      timezoneService: { toISODuration: vi.fn(() => 'P3D') },
      onModalClosed,
    });
    return { field, onModalClosed };
  }

  it('applies string dates, nullable duration and schedule flags without Date conversion', () => {
    const { field, onModalClosed } = dateField();
    field.handleSuccessfulCreate(new CustomEvent('date-picker-modal:create', { detail: dates }));
    expect(field.resource).toEqual({ duration: 'P3D', startDate: dates.startDate, dueDate: dates.dueDate, ignoreNonWorkingDays: false, scheduleManually: true });
    expect(onModalClosed).toHaveBeenCalledOnce();
    field.handleSuccessfulCreate(new CustomEvent('date-picker-modal:create', { detail: { ...dates, duration: null, startDate: null, dueDate: null } }));
    expect(field.resource.duration).toBeNull();
    expect(field.resource.startDate).toBeNull();
  });

  it('ignores ordinary DOM events and unrelated custom-event detail', () => {
    const { field, onModalClosed } = dateField();
    const onCreate:EventListener = field.handleSuccessfulCreate.bind(field);
    onCreate(new Event('date-picker-modal:create'));
    field.handleSuccessfulCreate(new CustomEvent('date-picker-modal:create', { detail: progress }));
    expect(field.resource).toEqual({});
    expect(onModalClosed).not.toHaveBeenCalled();
  });

  it('applies nullable progress values and numeric percentages', () => {
    const field = Object.create(ProgressPopoverEditFieldComponent.prototype) as ProgressPopoverEditFieldComponent;
    const onModalClosed = vi.fn();
    Object.assign(field, { resource: {}, onModalClosed });
    field.handleSuccessfulCreate(progress);
    expect(field.resource).toEqual(progress);
    field.handleSuccessfulCreate({ estimatedTime: null, remainingTime: null, percentageDone: null });
    expect(field.resource).toEqual({ estimatedTime: null, remainingTime: null, percentageDone: null });
    field.handleSuccessfulCreate(dates);
    expect(onModalClosed).toHaveBeenCalledTimes(2);
  });
});
