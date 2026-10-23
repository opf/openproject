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

import { buildTable, TableHarness } from '../../testing/table-harness';

describe('RelationsRenderPass', () => {
  let harness:TableHarness;

  afterEach(() => harness.destroy());

  it('renders an ofType relation row under its source row', async () => {
    harness = buildTable({
      workPackages: [{ id: '1', type: 'Phase' }, { id: '2', type: 'Task' }],
      relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
    });
    harness.expand('1', 'relationsOfTypeFollows');

    await harness.render();

    const relationRow = harness.row('1').nextElementSibling as HTMLTableRowElement;
    expect(relationRow).toHaveClass('wp-table--relations-additional-row');
    expect(relationRow.dataset.workPackageId).toBe('2');
    expect(relationRow.dataset.occurrenceKey).toBe('relation:ofType:1:2');
    expect(relationRow.querySelector('.relation-row--type-label')).toHaveTextContent('Task');
  });

  it('renders a child relation row under its parent row', async () => {
    harness = buildTable({
      workPackages: [{ id: '1', children: [{ id: '3' }] }],
      columns: ['id', 'subject', { id: 'children', children: true }],
    });
    harness.expand('1', 'children');

    await harness.render();

    const childRow = harness.row('1').nextElementSibling as HTMLTableRowElement;
    expect(childRow).toHaveClass('wp-table--relations-additional-row');
    expect(childRow.dataset.workPackageId).toBe('3');
    expect(childRow.dataset.occurrenceKey).toBe('relation:children:1:3');
  });

  it('assigns semantic levels to every occurrence', async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
    });
    harness.expand('1', 'relationsOfTypeFollows');

    await harness.render();

    expect(harness.table.ledger.byKey('wp:1')!.level).toBe(1);
    expect(harness.table.ledger.byKey('relation:ofType:1:2')!.level).toBe(2);
  });

  it('places a relation row one level below its owner in a hierarchy', async () => {
    const parent = { id: '1' };
    harness = buildTable({
      workPackages: [parent, { id: '2', ancestors: [parent] }, { id: '3' }],
      relations: [{ from: '2', to: '3', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      showHierarchies: true,
    });
    harness.expand('2', 'relationsOfTypeFollows');

    await harness.render();

    expect(harness.table.ledger.byKey('wp:2')!.level).toBe(2);
    expect(harness.table.ledger.byKey('relation:ofType:2:3')!.level).toBe(3);
  });
});
