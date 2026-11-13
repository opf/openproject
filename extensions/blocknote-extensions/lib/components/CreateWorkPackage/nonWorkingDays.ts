import { fetchNonWorkingDays, fetchWeekdays } from '../../services/openProjectApi';
import { isoDateOf } from '../../utils/dateTime';

let weekdaysOff = new Set<number>();
const daysOff = new Set<string>();
let weekdaysLoading:Promise<void> | undefined;
const yearsLoading = new Map<number, Promise<void>>();

async function readNonWorkingDays<T>(read:() => Promise<T[]>):Promise<T[]> {
  try {
    return await read();
  } catch (error) {
    console.error('[date picker] Failed to load the non working days:', error);
    return [];
  }
}

const isoWeekdayOf = (date:Date):number => date.getDay() || 7;

export async function loadNonWorkingDays(year:number):Promise<void> {
  weekdaysLoading ??= readNonWorkingDays(fetchWeekdays).then((weekdays) => {
    weekdaysOff = new Set(weekdays.filter((weekday) => !weekday.working).map((weekday) => weekday.day));
  });

  let yearLoading = yearsLoading.get(year);
  if (!yearLoading) {
    yearLoading = readNonWorkingDays(() => fetchNonWorkingDays(year)).then((dates) => {
      dates.forEach((date) => daysOff.add(date));
    });
    yearsLoading.set(year, yearLoading);
  }

  await Promise.all([weekdaysLoading, yearLoading]);
}

export function isNonWorkingDay(date:Date):boolean {
  return weekdaysOff.has(isoWeekdayOf(date)) || daysOff.has(isoDateOf(date));
}

export function clearNonWorkingDays():void {
  weekdaysOff = new Set();
  daysOff.clear();
  weekdaysLoading = undefined;
  yearsLoading.clear();
}
