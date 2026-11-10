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

import { bodyRowPositions, draftAgrees, PositionWindow } from './body-row-positions';

const groups = [
  { headerKey: 'G', sumsKey: 'G-sum', count: 4, hasSums: true },
  { headerKey: 'H', sumsKey: 'H-sum', count: 1, hasSums: true },
];

function window(overrides:Partial<PositionWindow> = {}):PositionWindow {
  return { pageNumber: 1, pageSize: 20, total: 100, primaryKeys: [], groups: [], ...overrides };
}

describe('bodyRowPositions', () => {
  it('retains global ordinals on the second flat page', () => {
    const primaryKeys = Array.from({ length: 20 }, (_, index) => String(index));
    const result = bodyRowPositions(window({ pageNumber: 2, primaryKeys }));
    expect(result?.count).toBe(100);
    expect(result?.ordinals.get('0')).toBe(21);
    expect(result?.ordinals.get('19')).toBe(40);
  });

  it('includes every group boundary while preserving unloaded member gaps', () => {
    const result = bodyRowPositions(window({ pageNumber: 2, pageSize: 2, total: 5, primaryKeys: ['C', 'D'], groups }));
    expect(result?.count).toBe(9);
    expect(Array.from(result?.ordinals ?? [])).toEqual([
      ['G', 1], ['G-sum', 6], ['H', 7], ['H-sum', 9], ['C', 4], ['D', 5],
    ]);
  });

  it('maps a window crossing a group boundary', () => {
    const result = bodyRowPositions(window({ pageNumber: 2, pageSize: 3, total: 5, primaryKeys: ['D', 'E'], groups }));
    expect(result?.ordinals.get('D')).toBe(5);
    expect(result?.ordinals.get('E')).toBe(8);
  });

  it('omits boundaries for zero count groups', () => {
    const result = bodyRowPositions(window({ total: 1, primaryKeys: ['A'], groups: [
      { headerKey: 'empty', sumsKey: 'empty-sum', count: 0, hasSums: true },
      { headerKey: 'G', sumsKey: 'unused-sum', count: 1, hasSums: false },
    ] }));
    expect(result?.count).toBe(2);
    expect(Array.from(result?.ordinals ?? [])).toEqual([['G', 1], ['A', 2]]);
  });

  it('accepts empty exact collections and out-of-range empty pages', () => {
    expect(bodyRowPositions(window({ total: 0 }))?.count).toBe(0);
    expect(bodyRowPositions(window({ pageNumber: 100, total: 0 }))?.ordinals.size).toBe(0);
    expect(bodyRowPositions(window({ pageNumber: 100, total: 5, groups }))?.count).toBe(9);
  });

  const invalid:Partial<PositionWindow>[] = [
    { pageNumber: 0 }, { pageNumber: -1 }, { pageNumber: 1.5 }, { pageNumber: NaN },
    { pageSize: 0 }, { pageSize: Infinity }, { pageSize: undefined },
    { total: -1 }, { total: 1.5 }, { total: undefined },
    { pageSize: 1, primaryKeys: ['A', 'B'] },
    { primaryKeys: ['A', 'A'] },
    { total: 0, primaryKeys: ['A'] },
    { pageNumber: 6, pageSize: 20, primaryKeys: ['A'] },
    { pageNumber: Number.MAX_SAFE_INTEGER, pageSize: 20 },
    { total: -1, groups }, { total: 6, groups },
    { total: 0, groups: [{ ...groups[0], count: -1 }] },
    { total: 0, groups: [{ ...groups[0], count: 0.5 }] },
    { total: 5, groups, primaryKeys: ['G'] },
    { total: 5, groups: [groups[0], { ...groups[1], headerKey: 'G' }] },
    { total: Number.MAX_SAFE_INTEGER, groups: [{ ...groups[0], count: Number.MAX_SAFE_INTEGER }] },
    { total: -1, pageNumber: Number.MAX_SAFE_INTEGER, pageSize: 1, primaryKeys: ['A', 'B'] },
  ];

  it.each(invalid)('rejects contradictory or unsafe metadata %o', (overrides) => {
    expect(bodyRowPositions(window(overrides))).toBeNull();
  });
});

describe('draftAgrees', () => {
  const member = (key:string) => ({ key, member: true });
  const structural = (key:string) => ({ key, member: false });
  const flat = () => bodyRowPositions(window({ primaryKeys: ['A', 'B'] }))!;
  const grouped = () => bodyRowPositions(window({ pageNumber: 2, pageSize: 2, total: 5, primaryKeys: ['C', 'D'], groups }))!;

  it('accepts increasing flat ordinals', () => {
    expect(draftAgrees(flat(), [member('A'), member('B')], [])).toBe(true);
  });

  it('rejects flat rows out of rank order', () => {
    expect(draftAgrees(flat(), [member('B'), member('A')], [])).toBe(false);
  });

  it('accepts headers, members and sums in group order', () => {
    const rows = [structural('G'), member('C'), member('D'), structural('G-sum'), structural('H'), structural('H-sum')];
    expect(draftAgrees(grouped(), rows, groups)).toBe(true);
  });

  it('rejects a member rendered under another group header', () => {
    expect(draftAgrees(grouped(), [structural('H'), member('C')], groups)).toBe(false);
  });

  it('rejects a sums row before its members', () => {
    expect(draftAgrees(grouped(), [structural('G'), structural('G-sum'), member('C')], groups)).toBe(false);
  });

  it('rejects a structural row that is not the active sums row', () => {
    expect(draftAgrees(grouped(), [structural('G'), structural('H-sum')], groups)).toBe(false);
  });

  it('rejects unknown keys', () => {
    expect(draftAgrees(grouped(), [structural('G'), member('X')], groups)).toBe(false);
  });
});
