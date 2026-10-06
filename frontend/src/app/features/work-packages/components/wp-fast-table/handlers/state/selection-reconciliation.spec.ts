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

import { fireEvent, waitFor } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { usePlatform } from 'core-common/testing/platform';
import { nextFrame } from 'core-common/testing/timing';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { buildGroup, buildWorkPackage } from '../../testing/work-package-fixture';

describe('Selection reconciliation with the rendered scope', () => {
  usePlatform('Linux');
  let harness:TableHarness;

  afterEach(() => harness?.destroy());

  describe('across the table lifecycle', () => {
    it('ignores a predecessor snapshot until its own first commit', async () => {
      const predecessor = [{ classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false }];
      harness = buildTable({
        workPackages: [{ id: '2', ancestors: [{ id: '1' }] }, { id: '3' }],
        showHierarchies: true,
        beforeAttach: (injector) => {
          injector.get(IsolatedQuerySpace).tableRendered.putValue(predecessor);
          injector.get(WorkPackageViewSelectionService).initializeSelection(['1', '2', '9']);
        },
      });
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '9']);

      await harness.render();

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
      expect(harness.row('1')).toHaveClass('-checked');
    });

    it('reconciles on a first render that is genuinely empty', async () => {
      harness = buildTable({
        workPackages: [],
        beforeAttach: (injector) => injector.get(WorkPackageViewSelectionService).initializeSelection(['7']),
      });
      await harness.render();
      expect(harness.selection.isEmpty).toBe(true);
    });

    it('never prunes from a table destroyed with a pending render', async () => {
      harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }] });
      await harness.render();
      harness.click('2');
      const frames:FrameRequestCallback[] = [];
      const frameSpy = vi.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => frames.push(callback));
      try {
        harness.querySpace.results.putValue({ elements: [buildWorkPackage({ id: '1' })] } as WorkPackageCollectionResource);
        harness.querySpace.initialized.putValue(null);
        expect(frames).toHaveLength(1);
        harness.table.destroy();
        frames.forEach((frame) => frame(0));
        expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      } finally {
        frameSpy.mockRestore();
      }
    });
  });

  describe('on re-render', () => {
    beforeEach(async () => {
      harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }] });
      await harness.render();
      harness.click('1');
      harness.click('3', { ctrlKey: true });
    });

    it('prunes exactly the work packages that left the page', async () => {
      await harness.render([{ id: '1' }, { id: '2' }]);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
      expect(harness.row('1')).toHaveClass('-checked');
    });

    it('keeps the selection across a reorder', async () => {
      await harness.render([{ id: '3' }, { id: '2' }, { id: '1' }]);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);
    });

    it('never selects a newly rendered work package', async () => {
      await harness.render([{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }]);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);
      expect(harness.row('4')).not.toHaveClass('-checked');
    });

    it('publishes no selection change when the scope is unchanged', async () => {
      const emitted = vi.fn();
      const subscription = harness.selection.live$().subscribe(emitted);
      emitted.mockClear();
      await harness.render([{ id: '1' }, { id: '2' }, { id: '3' }]);
      expect(emitted).not.toHaveBeenCalled();
      subscription.unsubscribe();
    });

    it('clears everything on a settled empty page', async () => {
      await harness.render([]);
      expect(harness.selection.isEmpty).toBe(true);
    });

    it('prunes nothing while the rendered state is cleared', async () => {
      harness.querySpace.tableRendered.clear('loading');
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);
      await harness.render([{ id: '1' }, { id: '2' }, { id: '3' }]);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);
    });
  });

  describe('with groups', () => {
    const newStatus = { href: '/api/v3/statuses/1' };
    const inProgressStatus = { href: '/api/v3/statuses/2' };
    const groupFixtures = [
      { value: 'New', href: newStatus.href, count: 2 },
      { value: 'In progress', href: inProgressStatus.href, count: 2 },
    ];
    const workPackages = [
      { id: '1', attributes: { status: newStatus } },
      { id: '2', attributes: { status: newStatus } },
      { id: '3', attributes: { status: inProgressStatus } },
      { id: '4', attributes: { status: inProgressStatus } },
    ];
    const groups = () => groupFixtures.map((group, index) => buildGroup(group, 'status', index));

    beforeEach(async () => {
      harness = buildTable({ workPackages, groups: groupFixtures });
      await harness.render();
      harness.click('1');
      harness.click('3', { ctrlKey: true });
    });

    it('keeps members inside a collapsed group', async () => {
      fireEvent.click(harness.groupHeader(0).querySelector('.expander')!);
      await waitFor(() => expect(harness.row('1')).not.toBeVisible());
      expect(harness.renderedState()).toEqual([['1', true], ['2', true], ['3', false], ['4', false]]);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);
    });

    it('keeps the selection when grouping is removed and restored', async () => {
      harness.querySpace.groups.putValue([]);
      await harness.render();
      expect(harness.groupHeaderOf(harness.row('1'))).toBeNull();
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);

      harness.querySpace.groups.putValue(groups());
      await harness.render();
      expect(harness.groupHeaderOf(harness.row('1'))).not.toBeNull();
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);
    });
  });

  describe('with hierarchies', () => {
    const parent = { id: '1' };

    beforeEach(async () => {
      harness = buildTable({
        workPackages: [{ id: '2', ancestors: [parent] }, { id: '3', ancestors: [parent] }, { id: '4' }],
        showHierarchies: true,
      });
      await harness.render();
    });

    it('keeps selected children under a collapsed parent', async () => {
      harness.click('2');
      harness.click('3', { ctrlKey: true });
      harness.injector.get(WorkPackageViewHierarchiesService).collapse('1');
      await waitFor(() => expect(harness.row('2')).not.toBeVisible());
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2', '3']);
    });

    it('prunes the contextual ancestor when the flat view no longer shows it (OP-17663)', async () => {
      expect(fireEvent.keyDown(harness.row('2'), { key: 'a', ctrlKey: true })).toBe(false);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '3', '4']);

      const flat = harness.nextRender();
      harness.injector.get(WorkPackageViewHierarchiesService).setEnabled(false);
      await flat;

      expect(harness.rowIds()).toEqual(['2', '3', '4']);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2', '3', '4']);
    });
  });

  describe('with relation rows', () => {
    beforeEach(async () => {
      harness = buildTable({
        workPackages: [{ id: '1', type: 'Phase' }, { id: '2', type: 'Task' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      });
      harness.expand('1', 'relationsOfTypeFollows');
      await harness.render();
    });

    it('retains a member that survives only as a relation row', async () => {
      fireEvent.click(harness.relationRow('1', '2'));
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);

      await harness.render([{ id: '1', type: 'Phase' }]);

      expect(harness.rowIds()).toEqual(['1', '2']);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(harness.relationRow('1', '2')).toHaveClass('-checked');
    });
  });

  describe('around creation', () => {
    beforeEach(async () => {
      harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }] });
      await harness.render();
    });

    it('keeps a work package created into an empty selection while it is rendered', async () => {
      harness.focus.initializeSelectionAndFocus('3');
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3']);
      await harness.render([{ id: '1' }, { id: '2' }, { id: '3' }]);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3']);
      expect(harness.row('3')).toHaveClass('-checked');
    });

    it('prunes a work package created outside the rendered scope', async () => {
      harness.focus.initializeSelectionAndFocus('3');
      await harness.render([{ id: '1' }, { id: '2' }]);
      expect(harness.selection.isEmpty).toBe(true);
      expect(harness.focus.focusedWorkPackage).toBe('3');
    });

    it('leaves an existing batch alone when a work package is created', async () => {
      harness.click('1');
      harness.focus.initializeSelectionAndFocus('3');
      await harness.render([{ id: '1' }, { id: '2' }, { id: '3' }]);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    });
  });

  describe('around loading', () => {
    const newStatus = { href: '/api/v3/statuses/1' };
    const inProgressStatus = { href: '/api/v3/statuses/2' };

    it('treats an old-ledger collapse publication as settled', async () => {
      harness = buildTable({
        workPackages: [
          { id: '1', attributes: { status: newStatus } },
          { id: '2', attributes: { status: inProgressStatus } },
        ],
        groups: [
          { value: 'New', href: newStatus.href, count: 1 },
          { value: 'In progress', href: inProgressStatus.href, count: 1 },
        ],
      });
      await harness.render();
      harness.click('1');
      harness.selection.initializeSelection(['1', '5']);
      harness.querySpace.tableRendered.clear('loading the next query');

      fireEvent.click(harness.groupHeader(0).querySelector('.expander')!);
      await waitFor(() => expect(harness.row('1')).not.toBeVisible());

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
      await harness.render([
        { id: '1', attributes: { status: newStatus } },
        { id: '5', attributes: { status: inProgressStatus } },
      ]);
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    });

    it('prunes a member present only as a child that loads after the first commit', async () => {
      let resolveChildren!:(children:WorkPackageResource[]) => void;
      const loaded = new Promise<WorkPackageResource[]>((resolve) => { resolveChildren = resolve; });
      harness = buildTable({
        workPackages: [{ id: '1', children: [{ id: '2' }] }],
        columns: ['id', 'subject', { id: 'children', children: true }],
        loadChildren: false,
        requireAll: () => loaded,
        beforeAttach: (injector) => injector.get(WorkPackageViewSelectionService).initializeSelection(['2']),
      });
      harness.expand('1', 'children');
      await harness.render();
      expect(harness.selection.isEmpty).toBe(true);

      const child = buildWorkPackage({ id: '2' });
      harness.injector.get(States).workPackages.get('2').putValue(child);
      const redrawn = harness.nextRender();
      resolveChildren([child]);
      await redrawn;
      await nextFrame();

      expect(harness.relationRow('1', '2', 'children')).toBeInTheDocument();
      expect(harness.selection.isEmpty).toBe(true);
    });
  });

  describe('with two tables sharing the resource cache', () => {
    let other:TableHarness;

    beforeEach(async () => {
      const states = new States();
      harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }], states });
      other = buildTable({ workPackages: [{ id: '1' }, { id: '2' }], states });
      await harness.render();
      await other.render();
    });

    afterEach(() => other.destroy());

    it('prunes only its own query space', async () => {
      harness.click('2');
      other.click('2');
      await harness.render([{ id: '1' }]);
      expect(harness.selection.isEmpty).toBe(true);
      expect(other.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(other.row('2')).toHaveClass('-checked');
    });
  });

  describe('pointer and keyboard parity', () => {
    const fixtures = [{ id: '1' }, { id: '2' }, { id: '3' }];
    const reduced = [{ id: '1' }, { id: '3' }];

    it('reconciles the same membership to the same result', async () => {
      harness = buildTable({ workPackages: fixtures });
      await harness.render();
      harness.click('1');
      harness.click('3', { shiftKey: true });
      await harness.render(reduced);
      const byPointer = harness.selection.getSelectedWorkPackageIds();
      await harness.destroy();

      harness = buildTable({ workPackages: fixtures });
      await harness.render();
      fireEvent.keyDown(harness.row('1'), { key: 'a', ctrlKey: true });
      await harness.render(reduced);

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(byPointer);
      expect(byPointer).toEqual(['1', '3']);
    });
  });

  describe('and the focused work package', () => {
    it('leaves focus state untouched when the focused member is pruned', async () => {
      harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }] });
      await harness.render();
      harness.click('2');
      harness.focus.updateFocus('2');
      await harness.render([{ id: '1' }]);
      expect(harness.selection.isEmpty).toBe(true);
      expect(harness.focus.focusedWorkPackage).toBe('2');
    });
  });
});
