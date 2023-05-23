import { DEFAULT_TIMESTAMP } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import * as moment from 'moment-timezone';

export type BaselineOption = 'oneDayAgo'|'lastWorkingDay'|'oneWeekAgo'|'oneMonthAgo'|'aSpecificDate'|'betweenTwoSpecificDates';

export interface BaselineTimestamp {
  date:string;
  time:string;
  offset:string;
}

const BASELINE_OPTIONS = ['oneDayAgo', 'lastWorkingDay', 'oneWeekAgo', 'oneMonthAgo', 'aSpecificDate', 'betweenTwoSpecificDates'];

export function baselineFilterFromValue(selectedDates:string[]):BaselineOption|null {
  if (selectedDates.length < 2) {
    return null;
  }

  const first = selectedDates[0].split('@')[0];
  if (BASELINE_OPTIONS.includes(first)) {
    return first as BaselineOption;
  }

  if (selectedDates[1] === DEFAULT_TIMESTAMP) {
    return 'aSpecificDate';
  }

  return 'betweenTwoSpecificDates';
}

export function getPartsFromTimestamp(value:string):BaselineTimestamp|null {
  if (value.includes('@')) {
    const [date, timeWithZone] = value.split(/[@]/);
    const [time, offset] = timeWithZone.split(/(?=[+-])/);
    return { date, time, offset };
  }

  if (value !== 'PT0S') {
    const dateObj = moment.parseZone(value);
    const date = dateObj.format('YYYY-MM-DD');
    const time = dateObj.format('HH:mm');
    const offset = dateObj.format('Z');

    return { date, time, offset };
  }

  return null;
}
