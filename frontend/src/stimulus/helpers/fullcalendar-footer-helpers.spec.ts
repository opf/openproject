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

import { renderDayTotal } from './fullcalendar-footer-helpers';

describe('renderDayTotal', () => {
  function text(node:Node):string {
    return (node.textContent ?? '').replace(/\s+/g, ' ').trim();
  }

  it('shows the logged and allocated time and how much of the day they cover', () => {
    expect(text(renderDayTotal(6, 2, 8))).toBe('6h 2h - 8h/8h');
  });

  it('leaves the logged time out of a day with only allocations', () => {
    expect(text(renderDayTotal(0, 5, 8))).toBe('5h - 5h/8h');
  });

  it('leaves the allocated time out of a day with only logged time', () => {
    expect(text(renderDayTotal(8, 0, 8))).toBe('8h - 8h/8h');
  });

  it('shows zero logged time for an empty day', () => {
    expect(text(renderDayTotal(0, 0, 8))).toBe('0h - 0h/8h');
  });

  it('marks a day that is covered beyond its working hours', () => {
    expect((renderDayTotal(5, 5, 8) as HTMLElement).querySelector('.te-day-total--over')).not.toBeNull();
    expect((renderDayTotal(4, 4, 8) as HTMLElement).querySelector('.te-day-total--over')).toBeNull();
  });

  it('leaves the coverage out of a day the user does not work', () => {
    expect(text(renderDayTotal(2, 0, 0))).toBe('2h');
  });
});
