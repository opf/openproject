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

import { displayDuration } from './duration-helpers';

describe('displayDuration', () => {
  it('shows only hours for whole hours', () => {
    expect(displayDuration(0)).toBe('0h');
    expect(displayDuration(8)).toBe('8h');
  });

  it('shows only minutes below an hour', () => {
    expect(displayDuration(0.25)).toBe('15m');
    expect(displayDuration(2 / 3)).toBe('40m');
  });

  it('shows hours and minutes for mixed durations', () => {
    expect(displayDuration(1.5)).toBe('1h 30m');
    expect(displayDuration(6 + 2 / 3)).toBe('6h 40m');
  });

  it('carries minutes that round up to a full hour into the hours', () => {
    expect(displayDuration(7.999999999999999)).toBe('8h');
    expect(displayDuration(59.9999 / 60)).toBe('1h');
  });
});
