import { Injectable } from '@angular/core';
import { DisplayedDays } from 'core-app/features/calendar/te-calendar/te-calendar.component';

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
    const offsetCheckedValues = offsetToApply >= 0 ? daysCheckedValues.splice(0, offsetToApply) : daysCheckedValues.splice(offsetToApply);
    const orderedDaysCheckedValues = offsetToApply >= 0 ? [...daysCheckedValues, ...offsetCheckedValues] : [...offsetCheckedValues, ...daysCheckedValues];
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
    let originalIndex = currentIndex + offsetToApply;

    if (originalIndex < 0) {
      originalIndex = arrayLength - 1;
    } else if (originalIndex >= arrayLength) {
      originalIndex = 0;
    }

    return originalIndex;
  }

  getCheckedValuesInOriginalOrder(days:IDayData[]) {
    const configuredDays = days
      .sort((a, b) => (a.originalIndex < b.originalIndex ? -1 : 1))
      .map((localeDayData) => localeDayData.checked);

    return this.validDays(configuredDays as DisplayedDays);
  }

  private validDays(days:DisplayedDays) {
    if (days.every((value) => !value)) {
      return Array.apply(null, Array(7)).map(() => true);
    }
    return days;
  }
}
