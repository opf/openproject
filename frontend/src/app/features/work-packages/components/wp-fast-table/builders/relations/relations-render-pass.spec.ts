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

import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { States } from 'core-app/core/states/states.service';
import { within } from '@testing-library/dom';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { buildWorkPackage } from '../../testing/work-package-fixture';

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

  describe('relation expander buttons', () => {
    const translations = { 'js.work_packages.table.relations_button': 'Relations in %{column} for %{work_package}' };
    const columns = [
      'id',
      'subject',
      { id: 'follows', relationType: 'follows' },
      { id: 'blocks', relationType: 'blocks' },
    ];
    const relations = [
      { from: '1', to: '2', type: 'follows', reverseType: 'precedes' },
      { from: '1', to: '3', type: 'blocks', reverseType: 'blocked' },
    ];
    const expanders = (row:HTMLElement) => within(row).queryAllByRole('button', { name: /^Relations in / });

    it('names each available expander and reads the expansion state', async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
        relations,
        columns,
        translations,
        configuration: { keyboardNavigationEnabled: true },
      });
      harness.expand('1', 'follows');

      await harness.render();

      const row = within(harness.row('1'));
      expect(row.getByRole('button', { name: 'Relations in follows for #1' })).toHaveAttribute('aria-expanded', 'true');
      expect(row.getByRole('button', { name: 'Relations in blocks for #1' })).toHaveAttribute('aria-expanded', 'false');
    });

    it('moves the expanded state when another column is expanded', async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
        relations,
        columns,
        translations,
        configuration: { keyboardNavigationEnabled: true },
      });
      harness.expand('1', 'follows');
      await harness.render();

      const redrawn = harness.nextRender();
      harness.expand('1', 'blocks');
      await redrawn;

      const row = within(harness.row('1'));
      expect(row.getByRole('button', { name: 'Relations in follows for #1' })).toHaveAttribute('aria-expanded', 'false');
      expect(row.getByRole('button', { name: 'Relations in blocks for #1' })).toHaveAttribute('aria-expanded', 'true');
    });

    it('exposes the expanded state only on the primary occurrence of a repeated work package', async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
        relations: [
          { from: '1', to: '2', type: 'follows', reverseType: 'precedes' },
          { from: '2', to: '3', type: 'follows', reverseType: 'precedes' },
        ],
        columns: ['id', 'subject', { id: 'follows', relationType: 'follows' }],
        translations,
        configuration: { keyboardNavigationEnabled: true },
      });
      harness.expand('1', 'follows');
      harness.expand('2', 'follows');

      await harness.render();

      const buttons = expanders(harness.row('2'));
      expect(buttons).toHaveLength(1);
      expect(buttons[0]).toHaveAttribute('aria-expanded', 'true');
      expect(expanders(harness.relationRow('1', '2'))).toHaveLength(0);
    });

    it('renders no button for zero counts or in relation-label cells', async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }, { id: '2' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'follows', relationType: 'follows' }, { id: 'blocks', relationType: 'blocks' }],
        translations,
        configuration: { keyboardNavigationEnabled: true },
      });
      harness.expand('1', 'follows');

      await harness.render();

      expect(expanders(harness.row('1'))).toHaveLength(1);
      expect(within(harness.row('1')).getByRole('button', { name: /^Relations in / })).toBeEmptyDOMElement();
      expect(harness.row('1').querySelector('.wp-table--relation-count')).toHaveTextContent('1');
      expect(expanders(harness.relationRow('1', '2'))).toHaveLength(0);
      expect(harness.row('1')).not.toHaveAttribute('aria-expanded');
    });

    it('leaves hierarchy expansion independent of relation expansion', async () => {
      const parent = { id: '1' };
      harness = buildTable({
        workPackages: [parent, { id: '2', ancestors: [parent] }, { id: '3' }],
        relations: [{ from: '1', to: '3', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'follows', relationType: 'follows' }],
        showHierarchies: true,
        translations,
        configuration: { keyboardNavigationEnabled: true },
      });
      harness.injector.get(WorkPackageViewHierarchiesService).collapse('1');
      harness.expand('1', 'follows');

      await harness.render();

      expect(within(harness.row('1')).getByRole('button', { name: 'Relations in follows for #1' })).toHaveAttribute('aria-expanded', 'true');
      expect(harness.row('1')).toHaveAttribute('aria-expanded', 'false');
    });

    it('keeps the span indicator when keyboard navigation is off', async () => {
      harness = buildTable({
        workPackages: [{ id: '1' }, { id: '2' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'follows', relationType: 'follows' }],
        translations,
      });

      await harness.render();

      const indicator = harness.row('1').querySelector('.wp-table--relation-indicator')!;
      expect(indicator.tagName).toBe('SPAN');
      expect(indicator).toHaveAttribute('aria-hidden', 'true');
    });

    it('redraws the expanded state once asynchronous child loading completes', async () => {
      let resolveLoad!:() => void;
      const loaded = new Promise<void>((resolve) => { resolveLoad = resolve; });
      harness = buildTable({
        workPackages: [{ id: '1', children: [{ id: '3' }] }],
        columns: ['id', 'subject', { id: 'children', children: true }],
        loadChildren: false,
        translations,
        configuration: { keyboardNavigationEnabled: true },
        requireAll: async (ids) => {
          await loaded;
          return ids.map((id) => {
            const child = buildWorkPackage({ id });
            harness.injector.get(States).workPackages.get(id).putValue(child);
            return child;
          });
        },
      });
      harness.expand('1', 'children');

      await harness.render();

      const name = 'Relations in children for #1';
      expect(within(harness.row('1')).getByRole('button', { name })).toHaveAttribute('aria-expanded', 'true');
      expect(harness.rows()).toHaveLength(1);

      const redrawn = harness.nextRender();
      resolveLoad();
      await redrawn;

      expect(harness.rows()).toHaveLength(2);
      expect(within(harness.row('1')).getByRole('button', { name })).toHaveAttribute('aria-expanded', 'true');
    });
  });
});
