import { DEFAULT_TIMESTAMP } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import * as moment from 'moment-timezone';

export type BaselineOption = 'oneDayAgo'|'lastWorkingDay'|'oneWeekAgo'|'oneMonthAgo'|'aSpecificDate'|'betweenTwoSpecificDates';

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

export function getOffsetFromBaseline(value:string):string|null {
  if (value.includes('@')) {
    const [, timeWithZone] = value.split(/[@]/);
    const [, offset] = timeWithZone.split(/\s+/)[0];
    return offset;
  }

  if (value !== 'PT0S') {
    const date = moment(value);
    return date.format('Z');
  }

  return null;
}
