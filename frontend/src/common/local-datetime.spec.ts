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

import { isoToLocalDatetime, localDatetimeToISO } from './local-datetime';

describe('localDatetimeToISO', () => {
  it('adds the offset of the time zone in summer', () => {
    expect(localDatetimeToISO('2026-07-01T14:30', 'Europe/Berlin')).toBe('2026-07-01T14:30:00+02:00');
  });

  it('adds the offset of the time zone in winter', () => {
    expect(localDatetimeToISO('2026-01-15T14:30', 'Europe/Berlin')).toBe('2026-01-15T14:30:00+01:00');
  });

  it('returns null for an empty value', () => {
    expect(localDatetimeToISO('', 'Europe/Berlin')).toBeNull();
  });

  it('returns null for an invalid value', () => {
    expect(localDatetimeToISO('not a date', 'Europe/Berlin')).toBeNull();
  });
});

describe('isoToLocalDatetime', () => {
  it('converts a UTC value into the local time of the time zone', () => {
    expect(isoToLocalDatetime('2026-07-01T12:30:00.000Z', 'Europe/Berlin')).toBe('2026-07-01T14:30');
  });

  it('returns an empty string for a missing value', () => {
    expect(isoToLocalDatetime(null, 'Europe/Berlin')).toBe('');
  });

  it('returns an empty string for an invalid value', () => {
    expect(isoToLocalDatetime('not a date', 'Europe/Berlin')).toBe('');
  });
});
