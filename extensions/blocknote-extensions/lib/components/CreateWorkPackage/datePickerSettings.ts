import { useEffect, useState } from 'react';
import i18n from '../../services/i18n';
import { fetchConfiguration, fetchNonWorkingDays, fetchWeekdays } from '../../services/openProjectApi';
import { firstDayOfWeek, isoDateOf } from './dateTime';
import type { DateTimeSettings } from './dateTime';

export interface DatePickerSettings extends DateTimeSettings {
  firstDayOfWeek:number;
}

let settings:Promise<DatePickerSettings> | undefined;
let loadedSettings:DatePickerSettings | undefined;

let weekdaysOff = new Set<number>();
const daysOff = new Set<string>();
let weekdaysLoading:Promise<void> | undefined;
const yearsLoading = new Map<number, Promise<void>>();

const browserTimeZone = ():string => Intl.DateTimeFormat().resolvedOptions().timeZone;

async function readSettings(locale:string):Promise<DatePickerSettings> {
  const configuration = await fetchConfiguration();
  return {
    timeZone: configuration._embedded?.userPreferences?.timeZone ?? browserTimeZone(),
    locale,
    dateFormat: configuration.dateFormat,
    timeFormat: configuration.timeFormat,
    firstDayOfWeek: firstDayOfWeek(configuration.startOfWeek, locale),
  };
}

const fallbackSettings = (locale:string):DatePickerSettings => ({
  timeZone: browserTimeZone(),
  locale,
  dateFormat: null,
  timeFormat: null,
  firstDayOfWeek: firstDayOfWeek(null, locale),
});

export function loadDatePickerSettings():Promise<DatePickerSettings> {
  const locale = i18n.language;

  settings ??= readSettings(locale).then(
    (read) => {
      loadedSettings = read;
      return read;
    },
    (error:unknown) => {
      console.error('[date picker] Failed to load the configuration:', error);
      settings = undefined;
      return fallbackSettings(locale);
    }
  );
  return settings;
}

export function useDatePickerSettings():DatePickerSettings | null {
  const [known, setKnown] = useState<DatePickerSettings | null>(loadedSettings ?? null);

  useEffect(() => {
    let active = true;
    void loadDatePickerSettings().then((read) => {
      if (active) setKnown(read);
    });
    return () => { active = false; };
  }, []);

  return known;
}

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

export function clearDatePickerSettings():void {
  settings = undefined;
  loadedSettings = undefined;
  weekdaysOff = new Set();
  daysOff.clear();
  weekdaysLoading = undefined;
  yearsLoading.clear();
}
