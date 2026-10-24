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

import { States } from 'core-app/core/states/states.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { nextFrame } from 'core-common/testing/timing';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { SingleRowBuilder } from './single-row-builder';

describe('SingleRowBuilder with two tables showing the same work package', () => {
  const harnesses:TableHarness[] = [];
  let first:TableHarness;
  let second:TableHarness;

  const mount = async (states:States) => {
    const table = buildTable({ workPackages: [{ id: '1' }, { id: '2' }], states });
    harnesses.push(table);
    await table.render();
    return table;
  };

  const subjectCell = (table:TableHarness) => table.row('1').querySelector('td.subject');

  beforeEach(async () => {
    const states = new States();
    first = await mount(states);
    second = await mount(states);
  });

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  it('keeps the changed cells in the table that is editing', async () => {
    const openChange = { isEmpty: () => false, changedAttributes: ['subject'] };
    vi.spyOn(second.injector.get(HalResourceEditingService), 'typedState').mockImplementation(
      (resource:HalResource) => ({
        hasValue: () => false,
        value: resource.id === '1' ? openChange : undefined,
      }) as unknown as ReturnType<HalResourceEditingService['typedState']>,
    );
    const editedCell = subjectCell(second);
    const otherCell = subjectCell(first);

    second.table.redrawTable();
    await nextFrame();

    expect(subjectCell(second)).toBe(editedCell);
    expect(subjectCell(first)).toBe(otherCell);
  });
});

describe('SingleRowBuilder physical columns', () => {
  let harness:TableHarness;

  afterEach(() => harness.destroy());

  const spannedColumns = (row:HTMLTableRowElement) => Array.from(row.cells)
    .reduce((total, cell) => total + cell.colSpan, 0);

  const mount = async (configuration:Record<string, boolean>, baseline:boolean) => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      configuration,
      baseline,
    });
    harness.expand('1', 'relationsOfTypeFollows');
    await harness.render();
  };

  describe.each([true, false])('on an enabled table with drag and drop %s', (drag) => {
    describe.each([true, false])('and baseline %s', (baseline) => {
      it.each([true, false])('spans the same columns in every row with a trailing column %s', async (trailing) => {
        await mount({
          keyboardNavigationEnabled: true,
          dragAndDropEnabled: drag,
          columnMenuEnabled: trailing,
        }, baseline);
        const expected = 3 + Number(drag) + Number(baseline) + Number(trailing);

        expect(spannedColumns(harness.row('1'))).toBe(expected);
        expect(spannedColumns(harness.row('2'))).toBe(expected);
        expect(spannedColumns(harness.relationRow('1', '2'))).toBe(expected);
        expect(new SingleRowBuilder(harness.injector, harness.table).placeholderRow.cells[0].colSpan).toBe(expected);
      });
    });
  });

  it('keeps the augmented columns of a capability-off table', async () => {
    await mount({ dragAndDropEnabled: true, columnMenuEnabled: false, actionsColumnEnabled: false }, true);

    expect(harness.row('1').cells).toHaveLength(3 + 1 + 1);
    expect(new SingleRowBuilder(harness.injector, harness.table).placeholderRow.cells[0].colSpan).toBe(3 + 1 + 1 + 1);
  });
});
