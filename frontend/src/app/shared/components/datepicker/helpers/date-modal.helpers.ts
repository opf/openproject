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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { DatePicker } from 'core-app/shared/components/datepicker/datepicker';
import { DateOption } from 'flatpickr/dist/types/options';
import { DayElement } from 'flatpickr/dist/types/instance';
import * as moment from 'moment-timezone';

/**
 * Map the date to the internal format,
 * setting to null if it's empty.
 * @param date
 */
// eslint-disable-next-line class-methods-use-this
export function mappedDate(date:string|null):string|null {
  return (date === '') ? null : date;
}

// eslint-disable-next-line class-methods-use-this
export function parseDate(date:Date|string):Date|'' {
  if (date instanceof Date) {
    return new Date(date.setHours(0, 0, 0, 0));
  }
  if (date === '') {
    return '';
  }
  return new Date(moment(date).toDate().setHours(0, 0, 0, 0));
}

export function validDate(date:Date|string):boolean {
  return (date instanceof Date)
    || (date === '')
    || !!/^\d{4}-\d{2}-\d{2}$/.exec(date);
}

export function areDatesEqual(firstDate:Date|string, secondDate:Date|string):boolean {
  const parsedDate1 = parseDate(firstDate);
  const parsedDate2 = parseDate(secondDate);

  if ((typeof (parsedDate1) === 'string') || (typeof (parsedDate2) === 'string')) {
    return false;
  }
  return parsedDate1.getTime() === parsedDate2.getTime();
}

export function keepCurrentlyActiveMonth(datePicker:DatePicker, currentMonth:number, currentYear:number):void {
  // Keep currently active month and avoid jump because of two-month layout
  datePicker.datepickerInstance.currentMonth = currentMonth;
  datePicker.datepickerInstance.currentYear = currentYear;
}

export function comparableDate(date?:DateOption):number|null {
  if (!date || typeof date === 'string') {
    return null;
  }

  if (typeof date === 'number') {
    return date;
  }

  return date.getTime();
}

export function setDates(dates:DateOption|DateOption[], datePicker:DatePicker, enforceDate?:Date):void {
  const { currentMonth, currentYear, selectedDates } = datePicker.datepickerInstance;

  const [newStart, newEnd] = _.castArray(dates);
  const [selectedStart, selectedEnd] = selectedDates;

  // In case the new times match the current times, do not try to update
  // the current selected months (Regression #46488)
  if (selectedDates.length > 0
    && comparableDate(newStart) === comparableDate(selectedStart)
    && comparableDate(newEnd) === comparableDate(selectedEnd)
  ) {
    return;
  }

  datePicker.setDates(dates);

  if (enforceDate) {
    const enforcedMonth = enforceDate.getMonth();
    const enforcedYear = enforceDate.getFullYear();
    const monthDiff = enforcedMonth - currentMonth + 12 * (enforcedYear - currentYear);

    // Because of the two-month layout we only have to update the calendar
    // if the month is further in the past/future than the one additional month that is shown anyway
    if (Math.abs(monthDiff) > 1) {
      datePicker.datepickerInstance.currentMonth = enforcedMonth;
      datePicker.datepickerInstance.currentYear = enforcedYear;
    } else {
      keepCurrentlyActiveMonth(datePicker, currentMonth, currentYear);
    }
  } else {
    keepCurrentlyActiveMonth(datePicker, currentMonth, currentYear);
  }

  datePicker.datepickerInstance.redraw();
}

export function onDayCreate(
  dayElem:DayElement,
  ignoreNonWorkingDays:boolean,
  isNonWorkingDay:boolean,
  isDayDisabled:boolean,
):void {
  dayElem.setAttribute('data-iso-date', dayElem.dateObj.toISOString());

  if (isDayDisabled) {
    dayElem.classList.add('flatpickr-disabled');
    return;
  }

  if (ignoreNonWorkingDays && isNonWorkingDay) {
    dayElem.classList.add('flatpickr-non-working-day_enabled');
  } else if (!ignoreNonWorkingDays && isNonWorkingDay) {
    dayElem.classList.add('flatpickr-non-working-day');
  }
}
