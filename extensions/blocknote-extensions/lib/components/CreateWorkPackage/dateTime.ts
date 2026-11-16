import { DateTime } from 'luxon';
import type { Locale } from 'flatpickr/dist/types/locale';

export interface DateTimeSettings {
  timeZone:string;
  locale:string;
  dateFormat:string | null;
  timeFormat:string | null;
}

const LUXON_TOKENS:Record<string, string> = {
  YYYY: 'yyyy',
  YY: 'yy',
  DDDD: 'ooo',
  DD: 'dd',
  D: 'd',
  A: 'a',
};

const MOMENT_TOKEN = /YYYY|YY|DDDD|DD|D|A/g;

const LANGUAGE_DATE_FORMAT = 'D';
const LANGUAGE_TIME_FORMAT = 't';

export function luxonFormatOf(momentFormat:string):string {
  return momentFormat.replace(MOMENT_TOKEN, (token) => LUXON_TOKENS[token]);
}

function dateTimeFormatOf({ dateFormat, timeFormat }:DateTimeSettings):string {
  const date = dateFormat ? luxonFormatOf(dateFormat) : LANGUAGE_DATE_FORMAT;
  const time = timeFormat ? luxonFormatOf(timeFormat) : LANGUAGE_TIME_FORMAT;
  return `${date} ${time}`;
}

const toISO = (dateTime:DateTime):string | null =>
  (dateTime.isValid ? dateTime.toUTC().startOf('second').toISO({ suppressMilliseconds: true }) : null);

export function isoToWallClockDate(iso:string, timeZone:string):Date | null {
  const dateTime = DateTime.fromISO(iso, { zone: timeZone });
  return dateTime.isValid ? dateTime.setZone('local', { keepLocalTime: true }).toJSDate() : null;
}

export function wallClockDateToISO(date:Date, timeZone:string):string | null {
  return toISO(DateTime.fromJSDate(date).setZone(timeZone, { keepLocalTime: true }));
}

export const isoDateOf = (date:Date):string => DateTime.fromJSDate(date).toISODate() ?? '';

export function localDateOf(isoDate:string):Date | null {
  const dateTime = DateTime.fromISO(isoDate.trim());
  return dateTime.isValid ? dateTime.toJSDate() : null;
}

export function formatDateTime(iso:string, settings:DateTimeSettings):string {
  const dateTime = DateTime.fromISO(iso, { zone: settings.timeZone, locale: settings.locale });
  return dateTime.isValid ? dateTime.toFormat(dateTimeFormatOf(settings)) : '';
}

export function parseDateTime(text:string, settings:DateTimeSettings):string | null {
  return toISO(DateTime.fromFormat(text.trim(), dateTimeFormatOf(settings), {
    zone: settings.timeZone,
    locale: settings.locale,
  }));
}

export function uses24HourClock({ timeFormat, locale }:DateTimeSettings):boolean {
  if (timeFormat) return !/[aA]/.test(timeFormat);

  return new Intl.DateTimeFormat(locale, { hour: 'numeric' }).resolvedOptions().hour12 === false;
}

interface WeekInfo {
  firstDay:number;
}

interface LocaleWithWeekInfo extends Intl.Locale {
  getWeekInfo?:() => WeekInfo;
  weekInfo?:WeekInfo;
}

const MONDAY = 1;

export function firstDayOfWeek(startOfWeek:number | null, locale:string):number {
  if (startOfWeek !== null) return startOfWeek % 7;

  const language = new Intl.Locale(locale) as LocaleWithWeekInfo;
  const weekInfo = language.getWeekInfo?.() ?? language.weekInfo;
  return (weekInfo?.firstDay ?? MONDAY) % 7;
}

type CalendarLocale = Pick<Locale, 'weekdays' | 'months' | 'firstDayOfWeek'>;

const namesOf = (count:number, locale:string, options:Intl.DateTimeFormatOptions, timestampOf:(index:number) => number) => {
  const format = new Intl.DateTimeFormat(locale, { ...options, timeZone: 'UTC' });
  return Array.from({ length: count }, (_, index) => format.format(timestampOf(index)));
};

const A_SUNDAY = Date.UTC(2023, 0, 1);
const DAY = 24 * 60 * 60 * 1000;

const weekdayNames = (locale:string, weekday:'short' | 'long') =>
  namesOf(7, locale, { weekday }, (index) => A_SUNDAY + index * DAY) as Locale['weekdays']['longhand'];

const monthNames = (locale:string, month:'short' | 'long') =>
  namesOf(12, locale, { month }, (index) => Date.UTC(2023, index, 1)) as Locale['months']['longhand'];

export function calendarLocaleOf(locale:string, firstDayOfWeek:number):CalendarLocale {
  return {
    weekdays: { shorthand: weekdayNames(locale, 'short'), longhand: weekdayNames(locale, 'long') },
    months: { shorthand: monthNames(locale, 'short'), longhand: monthNames(locale, 'long') },
    firstDayOfWeek,
  };
}
