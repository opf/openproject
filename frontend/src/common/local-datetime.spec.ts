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
  endOfDayISO,
  isoToWallClockDate,
  startOfDayISO,
  wallClockDateToISO,
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
