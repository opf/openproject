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

import { remainingAllocations, remainingHours, type ResourceAllocationEvent } from './resource-allocation-event';

describe('remainingHours', () => {
  const allocation = {
    start: '2026-10-05',
    hours: 6,
    workPackageId: '42',
  } as ResourceAllocationEvent;

  function timeEntry(overrides:Partial<{ start:string, hours:number, ongoing:boolean, workPackageId:string }> = {}) {
    return {
      start: '2026-10-05T09:00:00+02:00',
      hours: 2,
      ongoing: false,
      workPackageId: '42',
      ...overrides,
    };
  }

  it('is the planned time when nothing was logged', () => {
    expect(remainingHours(allocation, [])).toBe(6);
  });

  it('subtracts the time logged on the work package that day', () => {
    expect(remainingHours(allocation, [timeEntry(), timeEntry({ hours: 1.5 })])).toBe(2.5);
  });

  it('ignores time logged on other work packages', () => {
    expect(remainingHours(allocation, [timeEntry({ workPackageId: '43' })])).toBe(6);
  });

  it('ignores time logged on other days', () => {
    expect(remainingHours(allocation, [timeEntry({ start: '2026-10-06T09:00:00+02:00' })])).toBe(6);
  });

  it('ignores a running timer', () => {
    expect(remainingHours(allocation, [timeEntry({ ongoing: true })])).toBe(6);
  });

  it('does not go below zero when more was logged than planned', () => {
    expect(remainingHours(allocation, [timeEntry({ hours: 8 })])).toBe(0);
  });

  it('subtracts nothing for a work package the user cannot see', () => {
    const hidden = { ...allocation, workPackageId: undefined };

    expect(remainingHours(hidden, [timeEntry()])).toBe(6);
  });
});

describe('remainingAllocations', () => {
  const allocation = (id:string, workPackageId:string) => ({
    id,
    start: '2026-10-05',
    hours: 2,
    workPackageId,
  }) as ResourceAllocationEvent;

  const timeEntry = {
    start: '2026-10-05T09:00:00+02:00',
    hours: 2,
    ongoing: false,
    workPackageId: '42',
  };

  it('drops the allocations whose plan has been logged in full', () => {
    const remaining = remainingAllocations([allocation('done', '42'), allocation('open', '43')], [timeEntry]);

    expect(remaining.map(({ id, hours }) => [id, hours])).toEqual([['open', 2]]);
  });
});
