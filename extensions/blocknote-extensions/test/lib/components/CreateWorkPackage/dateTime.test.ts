import { describe, expect, it } from 'vitest';
import {
  calendarLocaleOf,
  firstDayOfWeek,
  formatDateTime,
  isoDateOf,
  localDateOf,
  isoToWallClockDate,
  luxonFormatOf,
  parseDateTime,
  uses24HourClock,
  wallClockDateToISO,
} from '../../../../lib/components/CreateWorkPackage/dateTime';
import type { DateTimeSettings } from '../../../../lib/components/CreateWorkPackage/dateTime';

const berlin:DateTimeSettings = {
  timeZone: 'Europe/Berlin',
  locale: 'en',
  dateFormat: 'DD.MM.YYYY',
  timeFormat: 'HH:mm',
};

describe('dateTime', () => {
  describe('luxonFormatOf', () => {
    it.each([
      ['YYYY-MM-DD', 'yyyy-MM-dd'],
      ['DD/MM/YYYY', 'dd/MM/yyyy'],
      ['D MMMM YYYY', 'd MMMM yyyy'],
      ['MMM DD, YY', 'MMM dd, yy'],
      ['DDDD', 'ooo'],
      ['HH:mm', 'HH:mm'],
      ['H:mm', 'H:mm'],
      ['hh:mm A', 'hh:mm a'],
      ['h:mm a', 'h:mm a'],
    ])('translates the moment.js format %s', (moment, luxon) => {
      expect(luxonFormatOf(moment)).toBe(luxon);
    });
  });

  describe('wall clock dates', () => {
    it('shows an instant at the time it is in the time zone of the user', () => {
      const date = isoToWallClockDate('2026-10-26T09:30:00Z', 'Asia/Tokyo')!;

      expect([date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes()])
        .toEqual([2026, 9, 26, 18, 30]);
    });

    it('reads what was picked as a time in the time zone of the user', () => {
      expect(wallClockDateToISO(new Date(2026, 9, 26, 18, 30), 'Asia/Tokyo')).toBe('2026-10-26T09:30:00Z');
    });

    it('drops the seconds the calendar never shows', () => {
      expect(wallClockDateToISO(new Date(2026, 9, 26, 18, 30, 0, 999), 'UTC')).toBe('2026-10-26T18:30:00Z');
    });

    it('has no date for what is not an instant', () => {
      expect(isoToWallClockDate('next tuesday', 'UTC')).toBeNull();
    });
  });

  describe('dates', () => {
    it('reads an ISO date as that day in the browser', () => {
      const date = localDateOf('2026-10-26')!;

      expect([date.getFullYear(), date.getMonth(), date.getDate(), date.getHours()]).toEqual([2026, 9, 26, 0]);
    });

    it('writes a day as an ISO date', () => {
      expect(isoDateOf(new Date(2026, 9, 26, 23, 59))).toBe('2026-10-26');
    });

    it('has no date for what is not an ISO date', () => {
      expect(localDateOf('26.10.2026')).toBeNull();
      expect(localDateOf('')).toBeNull();
    });
  });

  describe('formatDateTime', () => {
    it('shows the instant in the formats and time zone of the user', () => {
      expect(formatDateTime('2026-10-26T09:30:00Z', berlin)).toBe('26.10.2026 10:30');
    });

    it('follows daylight saving time', () => {
      expect(formatDateTime('2026-07-01T09:30:00Z', berlin)).toBe('01.07.2026 11:30');
    });

    it('falls back to the formats of the language', () => {
      const unset = { ...berlin, locale: 'en-US', dateFormat: null, timeFormat: null };

      expect(formatDateTime('2026-10-26T09:30:00Z', unset)).toBe('10/26/2026 10:30 AM');
    });

    it('shows nothing for nothing', () => {
      expect(formatDateTime('', berlin)).toBe('');
    });
  });

  describe('parseDateTime', () => {
    it('reads typed text as a time in the time zone of the user', () => {
      expect(parseDateTime('26.10.2026 10:30', berlin)).toBe('2026-10-26T09:30:00Z');
    });

    it('reads a twelve hour clock', () => {
      const twelveHours = { ...berlin, dateFormat: 'MM/DD/YYYY', timeFormat: 'hh:mm A' };

      expect(parseDateTime('10/26/2026 02:15 PM', twelveHours)).toBe('2026-10-26T13:15:00Z');
    });

    it('reads the formats of the language', () => {
      const unset = { ...berlin, locale: 'en-US', dateFormat: null, timeFormat: null };

      expect(parseDateTime('10/26/2026 10:30 AM', unset)).toBe('2026-10-26T09:30:00Z');
    });

    it('rejects what does not match the format', () => {
      expect(parseDateTime('2026-10-26 10:30', berlin)).toBeNull();
      expect(parseDateTime('', berlin)).toBeNull();
    });

    it('reads back what it formatted', () => {
      const iso = '2026-03-29T00:45:00Z';

      expect(parseDateTime(formatDateTime(iso, berlin), berlin)).toBe(iso);
    });
  });

  describe('uses24HourClock', () => {
    it('follows the time format of the user', () => {
      expect(uses24HourClock({ ...berlin, timeFormat: 'HH:mm' })).toBe(true);
      expect(uses24HourClock({ ...berlin, timeFormat: 'hh:mm A' })).toBe(false);
      expect(uses24HourClock({ ...berlin, timeFormat: 'h:mm a' })).toBe(false);
    });

    it('falls back to the clock of the language', () => {
      expect(uses24HourClock({ ...berlin, locale: 'en-US', timeFormat: null })).toBe(false);
      expect(uses24HourClock({ ...berlin, locale: 'de', timeFormat: null })).toBe(true);
    });
  });

  describe('firstDayOfWeek', () => {
    it('counts from Sunday, as the calendar does', () => {
      expect(firstDayOfWeek(1, 'en')).toBe(1);
      expect(firstDayOfWeek(6, 'en')).toBe(6);
      expect(firstDayOfWeek(7, 'en')).toBe(0);
    });

    it('falls back to the first day of the week of the language', () => {
      expect(firstDayOfWeek(null, 'en-US')).toBe(0);
      expect(firstDayOfWeek(null, 'de')).toBe(1);
    });
  });

  describe('calendarLocaleOf', () => {
    it('names the months and days in the language, from Sunday on', () => {
      const locale = calendarLocaleOf('de', 1);

      expect(locale.months.longhand[9]).toBe('Oktober');
      expect(locale.months.shorthand[0]).toBe('Jan');
      expect(locale.weekdays.longhand[0]).toBe('Sonntag');
      expect(locale.weekdays.shorthand[1]).toBe('Mo');
      expect(locale.firstDayOfWeek).toBe(1);
    });
  });
});
