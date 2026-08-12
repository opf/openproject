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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import { DisplayedDays } from 'core-app/features/calendar/te-calendar/te-calendar.component';
import moment from 'moment-timezone';

@Injectable()
export class TimeEntriesCurrentUserConfigurationModalService {
  /*
  * Get the data of the days in the locale order
  * @param daysCheckedValues: Checked value of all days of the week, starting from Monday.
  *                           Moment's default weekday start is Sunday, so daysCheckedValues have a weekday offset of 1.
  * @param localeWeekDays: week days ordered by locale
  * @param localeOffset: locale offset regarding the default week start day (Sunday (0)).
  */

  getOrderedDaysData(
    daysCheckedValues:boolean[],
    localeWeekDays = moment.weekdays(true),
    localeOffset = moment.localeData().firstDayOfWeek(),
  ):IDayData[] {
    // The daysCheckedValues come with offset 1 (the week start day is Monday (1),
    // so the first element in the array is Monday). We have to subtract 1 to the
    // locale offset to match localeWeekDays with daysCheckedValues. For example:
    // localeWeekDays (with offset 0) = [SundayValue, MondayValue, TuesdayValue, WednesdayValue, ThursdayValue, FridayValue, SaturdayValue]
    // daysCheckedValues (with offset 1) = [MondayValue, TuesdayValue, WednesdayValue, ThursdayValue, FridayValue, SaturdayValue, SundayValue]
    // offsetToApply = -1, so we need to pass the last daysCheckedValues to the start of the array to match the localeWeekDays order
    // In order save the result, we will have to reorder it with offset 1 (getCheckedValuesInOriginalOrder)
    const offsetToApply = localeOffset - 1;
    const checkedValues = Array.from(daysCheckedValues);
    const offsetCheckedValues = offsetToApply >= 0 ? checkedValues.splice(0, offsetToApply) : checkedValues.splice(offsetToApply);
    const orderedDaysCheckedValues = offsetToApply >= 0 ? [...checkedValues, ...offsetCheckedValues] : [...offsetCheckedValues, ...checkedValues];
    const weekDaysWithCheckedValue = orderedDaysCheckedValues
      .map(
        (dayCheckedValue, index) => ({
          weekDay: localeWeekDays[index],
          checked: dayCheckedValue,
          originalIndex: this.getOriginalIndex(offsetToApply, index, orderedDaysCheckedValues.length),
        }),
      );

    return weekDaysWithCheckedValue;
  }

  getOriginalIndex(offsetToApply:number, currentIndex:number, arrayLength:number):number {
    return ((currentIndex + offsetToApply) % arrayLength + arrayLength) % arrayLength;
  }

  getCheckedValuesInOriginalOrder(days:IDayData[]) {
    const configuredDays = days
      .sort((a, b) => a.originalIndex - b.originalIndex)
      .map((localeDayData) => localeDayData.checked);

    return this.validDays(configuredDays as DisplayedDays);
  }

  private validDays(days:DisplayedDays) {
    if (days.every((value) => !value)) {
      return Array.from({ length: 7 }, () => true);
    }
    return days;
  }
}
