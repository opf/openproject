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

import {
  calendarDate,
  calendarDaysSpanned,
  endOfDayISO,
  isoToWallClockDate,
  startOfDayISO,
  wallClockDateToISO,
  weekStartDate,
} from './local-datetime';

describe('startOfDayISO', () => {
  it('returns the start of the day in the time zone as UTC', () => {
    expect(startOfDayISO('2026-01-01', 'Europe/Berlin')).toBe('2025-12-31T23:00:00Z');
  });

  it('returns null for an invalid date', () => {
    expect(startOfDayISO('not a date', 'Europe/Berlin')).toBeNull();
  });
});

describe('endOfDayISO', () => {
  it('returns the last second of the day in the time zone as UTC', () => {
    expect(endOfDayISO('2026-10-30', 'Europe/Berlin')).toBe('2026-10-30T22:59:59Z');
  });

  it('returns null for an invalid date', () => {
    expect(endOfDayISO('not a date', 'Europe/Berlin')).toBeNull();
  });
});

describe('isoToWallClockDate', () => {
  it('returns a Date showing the wall-clock time of the time zone', () => {
    const date = isoToWallClockDate('2026-10-01T12:30:00Z', 'Europe/Berlin')!;

    expect([date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes()])
      .toEqual([2026, 9, 1, 14, 30]);
  });

  it('returns null for an invalid value', () => {
    expect(isoToWallClockDate('not a date', 'Europe/Berlin')).toBeNull();
  });
});

describe('wallClockDateToISO', () => {
  it('reads the wall-clock time of the Date in the time zone and returns UTC', () => {
    expect(wallClockDateToISO(new Date(2026, 9, 1, 14, 30), 'Europe/Berlin')).toBe('2026-10-01T12:30:00Z');
  });

  it('applies the winter offset', () => {
    expect(wallClockDateToISO(new Date(2026, 0, 15, 14, 30), 'Europe/Berlin')).toBe('2026-01-15T13:30:00Z');
  });
});

describe('calendarDate', () => {
  // Havana repeats 00:00 on 2026-11-01, so both instants fall on that date.
  it('names the date of an instant in the time zone across a repeated midnight', () => {
    expect(calendarDate('2026-11-01T04:59:59.999Z', 'America/Havana')).toBe('2026-11-01');
    expect(calendarDate('2026-11-01T05:59:59.999Z', 'America/Havana')).toBe('2026-11-01');
  });

  it('names the earlier date west of UTC', () => {
    expect(calendarDate('2026-11-02T03:00:00.000Z', 'America/New_York')).toBe('2026-11-01');
  });

  it('returns null for an invalid instant', () => {
    expect(calendarDate('nonsense', 'UTC')).toBeNull();
  });
});

describe('weekStartDate', () => {
  it('steps back to the configured first day of the week', () => {
    expect(weekStartDate('2026-03-08', 1)).toBe('2026-03-02');
    expect(weekStartDate('2026-11-04', 0)).toBe('2026-11-01');
    expect(weekStartDate('2026-11-01', 6)).toBe('2026-10-31');
  });

  it('treats 0 and 7 alike as Sunday', () => {
    expect(weekStartDate('2026-11-01', 0)).toBe('2026-11-01');
    expect(weekStartDate('2026-11-01', 7)).toBe('2026-11-01');
  });

  it('returns null for an invalid date', () => {
    expect(weekStartDate('nonsense', 1)).toBeNull();
  });
});

describe('calendarDaysSpanned', () => {
  it('counts both ends', () => {
    expect(calendarDaysSpanned('2026-03-08', '2026-04-08')).toBe(32);
    expect(calendarDaysSpanned('2026-10-01', '2026-10-31')).toBe(31);
    expect(calendarDaysSpanned('2026-10-01', '2026-10-01')).toBe(1);
  });

  it('returns null for an invalid date', () => {
    expect(calendarDaysSpanned('nonsense', '2026-10-01')).toBeNull();
  });
});
