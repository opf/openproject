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
  FocusPosition,
  initialPosition,
  NavigableRow,
  computeNextPosition,
  reconcilePosition,
} from './focus-position';

function buildRows():NavigableRow[] {
  return [
    { key: 'header', kind: 'header', hidden: false, cellCount: 3, expanded: null },
    { key: 'A', kind: 'workPackage', hidden: false, cellCount: 3, expanded: null },
    { key: '0:header', kind: 'groupHeader', hidden: false, cellCount: 1, expanded: true, groupIdentifier: 'g' },
    { key: 'B', kind: 'workPackage', hidden: true, cellCount: 3, expanded: null },
    { key: 'C', kind: 'workPackage', hidden: false, cellCount: 3, expanded: false },
    { key: '0:sums', kind: 'sums', hidden: false, cellCount: 3, expanded: null, groupIdentifier: 'g' },
    { key: 'totals', kind: 'totals', hidden: false, cellCount: 3, expanded: null },
  ];
}

function groupOf(key:string) {
  return ['0:header', '0:sums'].includes(key) ? { groupIdentifier: 'g' } : {};
}

function row(key:string):FocusPosition {
  return { key, cell: null, desiredColumn: null, ...groupOf(key) };
}

function cell(key:string, index:number, desiredColumn:number = index):FocusPosition {
  return { key, cell: index, desiredColumn, ...groupOf(key) };
}

function move(position:FocusPosition) {
  return { type: 'move', position };
}

describe('focus position model', () => {
  it('ArrowDown in row focus skips hidden rows', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, row('A'), 'ArrowDown', 5)).toEqual(move(row('0:header')));
    expect(computeNextPosition(rows, row('0:header'), 'ArrowDown', 5)).toEqual(move(row('C')));
  });

  it('ArrowUp from first body row lands on the header row', () => {
    expect(computeNextPosition(buildRows(), row('A'), 'ArrowUp', 5)).toEqual(move(row('header')));
  });

  it('ArrowUp and ArrowDown at the edges are none', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, row('header'), 'ArrowUp', 5)).toEqual({ type: 'none' });
    expect(computeNextPosition(rows, row('totals'), 'ArrowDown', 5)).toEqual({ type: 'none' });
  });

  it('Home/End go to first/last visible row in row focus', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, row('C'), 'Home', 5)).toEqual(move(row('header')));
    expect(computeNextPosition(rows, row('C'), 'End', 5)).toEqual(move(row('totals')));
  });

  it('Home/End in cell focus go to the first/last cell of the row', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, cell('A', 1), 'Home', 5)).toEqual(move(cell('A', 0)));
    expect(computeNextPosition(rows, cell('A', 1), 'End', 5)).toEqual(move(cell('A', 2)));
  });

  it('ArrowRight on an expanded or leaf row enters cell 0', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, row('A'), 'ArrowRight', 5)).toEqual(move(cell('A', 0)));
    expect(computeNextPosition(rows, row('0:header'), 'ArrowRight', 5)).toEqual(move(cell('0:header', 0)));
  });

  it('ArrowRight on a collapsed parent returns expand', () => {
    expect(computeNextPosition(buildRows(), row('C'), 'ArrowRight', 5)).toEqual({ type: 'expand', key: 'C' });
  });

  it('ArrowLeft on an expanded group header returns collapse', () => {
    expect(computeNextPosition(buildRows(), row('0:header'), 'ArrowLeft', 5)).toEqual({ type: 'collapse', key: '0:header' });
  });

  it('ArrowLeft on a non-expanded row is none', () => {
    expect(computeNextPosition(buildRows(), row('A'), 'ArrowLeft', 5)).toEqual({ type: 'none' });
  });

  it('ArrowLeft on cell 0 returns to the row', () => {
    expect(computeNextPosition(buildRows(), cell('A', 0), 'ArrowLeft', 5))
      .toEqual(move({ key: 'A', cell: null, desiredColumn: 0 }));
  });

  it('ArrowRight on the last cell is none', () => {
    expect(computeNextPosition(buildRows(), cell('A', 2), 'ArrowRight', 5)).toEqual({ type: 'none' });
  });

  it('ArrowDown keeps the desired column and clamps on a shorter row', () => {
    const rows = buildRows();

    const toGroup = computeNextPosition(rows, cell('A', 2), 'ArrowDown', 5);
    expect(toGroup).toEqual(move({ ...cell('0:header', 0, 2) }));

    const toC = computeNextPosition(rows, (toGroup as { position:FocusPosition }).position, 'ArrowDown', 5);
    expect(toC).toEqual(move({ key: 'C', cell: 2, desiredColumn: 2 }));
  });

  it('ArrowLeft/Right set the desired column to the landing cell', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, cell('A', 0, 2), 'ArrowRight', 5)).toEqual(move(cell('A', 1)));
    expect(computeNextPosition(rows, cell('A', 2, 0), 'ArrowLeft', 5)).toEqual(move(cell('A', 1)));
  });

  it('CtrlHome/CtrlEnd go to the grid corners in cell focus and first/last row in row focus', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, cell('C', 1), 'CtrlHome', 5)).toEqual(move(cell('header', 0)));
    expect(computeNextPosition(rows, cell('C', 1), 'CtrlEnd', 5)).toEqual(move(cell('totals', 2)));
    expect(computeNextPosition(rows, row('C'), 'CtrlHome', 5)).toEqual(move(row('header')));
    expect(computeNextPosition(rows, row('C'), 'CtrlEnd', 5)).toEqual(move(row('totals')));
  });

  it('PageDown moves pageSize visible rows and stops at the end', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, row('header'), 'PageDown', 2)).toEqual(move(row('0:header')));
    expect(computeNextPosition(rows, row('0:header'), 'PageDown', 10)).toEqual(move(row('totals')));
    expect(computeNextPosition(rows, row('totals'), 'PageDown', 2)).toEqual({ type: 'none' });
  });

  it('PageUp moves pageSize visible rows and stops at the start', () => {
    const rows = buildRows();

    expect(computeNextPosition(rows, row('0:sums'), 'PageUp', 2)).toEqual(move(row('0:header')));
    expect(computeNextPosition(rows, row('A'), 'PageUp', 10)).toEqual(move(row('header')));
  });

  it('PageDown in cell focus keeps cell focus with the desired column', () => {
    expect(computeNextPosition(buildRows(), cell('A', 2), 'PageDown', 2))
      .toEqual(move({ key: 'C', cell: 2, desiredColumn: 2 }));
  });

  it('initialPosition prefers the first visible work package row', () => {
    const rows = buildRows();

    expect(initialPosition(rows)).toEqual(row('A'));
    expect(initialPosition(rows.filter((r) => r.kind !== 'workPackage'))).toEqual(row('header'));
    expect(initialPosition(rows.map((r) => ({ ...r, hidden: true })))).toBeNull();
  });

  it('reconcilePosition keeps the same row, else the row that hides it, else the nearest visible row, else null', () => {
    const rows = buildRows();

    expect(reconcilePosition(rows, cell('A', 2), 1)).toEqual(cell('A', 2));
    expect(reconcilePosition(rows, cell('0:header', 2), 2)).toEqual(cell('0:header', 0, 2));
    expect(reconcilePosition(rows, cell('B', 1), 3)).toEqual(row('0:header'));
    expect(reconcilePosition(rows, row('gone'), 40)).toEqual(row('totals'));
    expect(reconcilePosition(rows.map((r) => ({ ...r, hidden: true })), row('A'), 1)).toBeNull();
  });

  it('reconcilePosition keeps a sums position on the sums row, not the header, after rebinding', () => {
    const rows = buildRows().map((r) => (r.groupIdentifier ? { ...r, key: r.key.replace('0:', '1:') } : r));

    expect(reconcilePosition(rows, cell('0:sums', 1), 5)).toEqual({ ...cell('0:sums', 1), key: '1:sums' });
  });

  it('reconcilePosition rebinds a group header by identifier when its ordinal key changed', () => {
    const rows = buildRows().map((r) => (r.key === '0:header' ? { ...r, key: '1:header' } : r));

    expect(reconcilePosition(rows, row('0:header'), 2)).toEqual({ ...row('0:header'), key: '1:header' });
  });

  it('reconcilePosition does not rebind a removed group to another group at the same ordinal', () => {
    const rows = buildRows().filter((r) => !r.groupIdentifier);
    rows.splice(rows.length - 1, 0, { key: '0:header', kind: 'groupHeader', hidden: false, cellCount: 1, expanded: true, groupIdentifier: 'h' });

    expect(reconcilePosition(rows, row('0:header'), 2)).toEqual(row('A'));
  });

  it('reconcilePosition falls back to row focus when the row has no cells', () => {
    const rows = buildRows().map((r) => (r.key === 'A' ? { ...r, cellCount: 0 } : r));

    expect(reconcilePosition(rows, cell('A', 1), 1)).toEqual({ key: 'A', cell: null, desiredColumn: 1 });
  });

  it('computeNextPosition on a hidden current row is none for every key', () => {
    const keys = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Home', 'End', 'PageUp', 'PageDown', 'CtrlHome', 'CtrlEnd'] as const;

    keys.forEach((key) => {
      expect(computeNextPosition(buildRows(), row('B'), key, 5)).toEqual({ type: 'none' });
      expect(computeNextPosition(buildRows(), cell('B', 1), key, 5)).toEqual({ type: 'none' });
    });
  });
});
