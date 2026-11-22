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

import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { LiveRegionElement } from '@primer/live-region-element';
import { type MockInstance } from 'vitest';
import { firstValueFrom, from } from 'rxjs';
import { States } from 'core-app/core/states/states.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QUERY_SORT_BY_DESC } from 'core-app/features/hal/resources/query-sort-by-resource';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import {
  buildTable, FakeDragAndDropService, TableHarness, TableHarnessOptions,
} from '../../testing/table-harness';

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };
const groups = [
  { value: 'New', href: newStatus.href, count: 2 },
  { value: 'In progress', href: inProgressStatus.href, count: 2 },
];

const groupedWorkPackages = [
  { id: '1', attributes: { status: newStatus } },
  { id: '2', attributes: { status: newStatus } },
  { id: '3', attributes: { status: inProgressStatus } },
  { id: '4', attributes: { status: inProgressStatus } },
];

interface DropSnapshot {
  group:string|null;
  previous:string|undefined;
  next:string|undefined;
}

function snapshot(table:TableHarness, el:HTMLElement):DropSnapshot {
  const header = table.groupHeaderOf(el);
  return {
    group: header ? groups[Number(header.dataset.groupIndex)].value : null,
    previous: (el.previousElementSibling as HTMLElement|null)?.dataset.workPackageId,
    next: (el.nextElementSibling as HTMLElement|null)?.dataset.workPackageId,
  };
}

describe('DragAndDropTransformer', () => {
  let harness:TableHarness;
  let drops:DropSnapshot[];
  let dropAction:() => Promise<unknown>;

  beforeEach(async () => {
    drops = [];
    dropAction = () => Promise.resolve();
    harness = buildTable({
      workPackages: groupedWorkPackages,
      groups,
      dragAction: {
        prepareDrop: (_workPackage, el) => {
          drops.push(snapshot(harness, el));
          return Promise.resolve({ persist: async () => { await dropAction(); } });
        },
      },
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  const rowIds = () => harness.rows().map((row) => row.dataset.workPackageId);

  it('renders the groups with their header rows', () => {
    expect(rowIds()).toEqual(['1', '2', '3', '4']);
    expect(snapshot(harness, harness.row('2'))).toEqual({ group: 'New', previous: '1', next: undefined });
    expect(snapshot(harness, harness.row('3'))).toEqual({ group: 'In progress', previous: undefined, next: '4' });
  });

  it('keeps a bottom-edge drop on the last row of a group inside that group', async () => {
    const success = await harness.drop('1', '2', 'bottom');

    expect(success).toBe(true);
    expect(drops).toEqual([{ group: 'New', previous: '2', next: undefined }]);
  });

  it('moves a top-edge drop on the first row of a group into that group', async () => {
    await harness.drop('1', '3', 'top');

    expect(drops).toEqual([{ group: 'In progress', previous: undefined, next: '3' }]);
  });

  it('appends a drop past the last row to the last group', async () => {
    await harness.drop('1', null, null);

    expect(drops).toEqual([{ group: 'In progress', previous: '4', next: undefined }]);
  });

  it('rebuilds the table from the persisted order', async () => {
    const rendered = harness.nextRender();
    await harness.drop('1', '2', 'bottom');
    await rendered;

    expect(rowIds()).toEqual(['2', '1', '3', '4']);
    expect(snapshot(harness, harness.row('1'))).toEqual({ group: 'New', previous: '2', next: undefined });
  });

  it('completes without a drop action when the order does not change', async () => {
    const success = await harness.drop('1', '1', 'bottom');

    expect(success).toBe(true);
    expect(drops).toEqual([]);
  });

  it('anchors a following shift-click at the picked-up row when group headers precede it', async () => {
    harness.click('1');
    harness.click('3', { ctrlKey: true });

    harness.dragStart('3');
    await harness.drop('3', '3', 'bottom');
    harness.click('4', { shiftKey: true });

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3', '4']);
    expect(harness.row('2')).not.toHaveClass('-checked');
  });

  it('puts the row back and reports the error when the drop action fails', async () => {
    const error = new Error('drop failed');
    dropAction = () => Promise.reject(error);
    const notification = harness.injector.get(HalResourceNotificationService);
    const handleRawError = vi.spyOn(notification, 'handleRawError');

    const mutate = vi.spyOn(harness.table, 'mutate');

    const success = await harness.drop('1', '2', 'bottom');

    expect(success).toBe(false);
    expect(rowIds()).toEqual(['1', '2', '3', '4']);
    expect(mutate.mock.calls.map(([scope]) => scope)).toEqual(['positions', 'positions']);
    expect(snapshot(harness, harness.row('1'))).toEqual({ group: 'New', previous: undefined, next: '2' });
    expect(handleRawError).toHaveBeenCalledExactlyOnceWith(error, harness.injector.get(States).workPackages.get('1').value);
  });
});

describe('DragAndDropTransformer with two tables showing the same work packages', () => {
  const parent = { id: '1' };
  const hierarchy = {
    parent,
    first: { id: '2', ancestors: [parent] },
    last: { id: '3', ancestors: [parent] },
    unrelated: { id: '4' },
  };
  const harnesses:TableHarness[] = [];
  let states:States;
  let dropped:HTMLElement[];
  let drops:DropSnapshot[];

  const mount = async (options:TableHarnessOptions) => {
    const table = buildTable({ ...options, states });
    harnesses.push(table);
    await table.render();
    return table;
  };

  const mountDragging = async (options:TableHarnessOptions) => {
    const table:TableHarness = await mount({
      ...options,
      dragAction: {
        prepareDrop: (_workPackage, el) => {
          dropped.push(el);
          drops.push(snapshot(table, el));
          return Promise.resolve({ persist: () => Promise.resolve() });
        },
      },
    });
    return table;
  };

  beforeEach(() => {
    states = new States();
    dropped = [];
    drops = [];
  });

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  it('moves and hands over the dragging table\'s own row', async () => {
    const other = await mount({ workPackages: [{ id: '4' }, { id: '3' }, { id: '2' }, { id: '1' }] });
    const dragging = await mountDragging({ workPackages: groupedWorkPackages, groups });
    const source = dragging.row('1');

    const success = await dragging.drop('1', '3', 'top');

    expect(success).toBe(true);
    expect(dropped).toHaveLength(1);
    expect(dropped[0]).toBe(source);
    expect(drops).toEqual([{ group: 'In progress', previous: undefined, next: '3' }]);
    expect(other.rowIds()).toEqual(['4', '3', '2', '1']);
  });

  it('redirects a drop onto a hierarchy collapsed only in the dragging table', async () => {
    const other = await mount({
      workPackages: [hierarchy.parent, hierarchy.first, hierarchy.last, hierarchy.unrelated],
      showHierarchies: true,
    });
    const dragging = await mountDragging({
      workPackages: [hierarchy.unrelated, hierarchy.parent, hierarchy.first, hierarchy.last],
      showHierarchies: true,
    });
    expect(dragging.rowIds()).toEqual(['4', '1', '2', '3']);
    fireEvent.click(within(dragging.row('1')).getByRole('button'));
    await waitFor(() => expect(dragging.row('2')).not.toBeVisible());

    const success = await dragging.drop('4', '2', 'top');

    expect(success).toBe(true);
    expect(drops).toEqual([{ group: null, previous: '3', next: undefined }]);
    expect(other.row('2')).toBeVisible();
  });

  it('keeps the original target when the collapsed hierarchy\'s last row carries no id', async () => {
    const dragging = await mountDragging({
      workPackages: [hierarchy.unrelated, hierarchy.parent, hierarchy.first, hierarchy.last],
      showHierarchies: true,
    });
    fireEvent.click(within(dragging.row('1')).getByRole('button'));
    await waitFor(() => expect(dragging.row('2')).not.toBeVisible());
    delete dragging.row('3').dataset.workPackageId;

    const success = await dragging.drop('4', '2', 'top');

    expect(success).toBe(true);
    expect(drops).toEqual([{ group: null, previous: '1', next: '2' }]);
  });

  it('leaves expanded relation rows out of the dropped order', async () => {
    const table = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      relations: [{ from: '3', to: '1', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      states,
    });
    harnesses.push(table);
    table.expand('3', 'relationsOfTypeFollows');
    await table.render();
    const prepareMove = vi.spyOn(table.injector.get(WorkPackageViewOrderService), 'prepareMove');
    expect(table.rowIds()).toEqual(['1', '2', '3', '1']);

    await table.drop('1', '3', 'bottom');

    expect(prepareMove).toHaveBeenCalledExactlyOnceWith(table.querySpace.query.value, ['1', '2', '3'], '1', 2, expect.any(Function));
  });
});

function deferred<T = void>() {
  let resolve!:(value:T) => void;
  let reject!:(reason:unknown) => void;
  const promise = new Promise<T>((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}

describe('DragAndDropTransformer row moves', () => {
  let harness:TableHarness;
  let announce:MockInstance<typeof LiveRegionElement.prototype.announce>;

  const threeRows = [{ id: '1' }, { id: '2' }, { id: '3' }];

  const renderTable = async (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({
      workPackages: threeRows,
      manualSort: true,
      ...options,
      configuration: { dragAndDropEnabled: true, ...options.configuration },
    });
    await harness.render();
    return harness.table.rowMover!;
  };

  const orderService = () => harness.injector.get(WorkPackageViewOrderService);

  const spyOnPrepareMove = () => vi.spyOn(orderService(), 'prepareMove');

  const holdPersist = () => {
    const gate = deferred();
    const persisted = deferred();
    const started = deferred();
    const service = orderService();
    const original = service.prepareMove.bind(service);
    const prepareMove = vi.spyOn(service, 'prepareMove').mockImplementation(async (...args) => {
      const prepared = await original(...args);
      return {
        ...prepared,
        persist: async () => {
          started.resolve();
          await gate.promise;
          await prepared.persist();
          persisted.resolve();
        },
      };
    });
    return { prepareMove, release: () => gate.resolve(), persisted: persisted.promise, started: started.promise };
  };

  /** Feeds the refresh after a save from `refresh`; the first lookup loads the moved work package as usual. */
  const stubRefresh = (refresh:() => Promise<void>) => {
    const workPackages = harness.injector.get(ApiV3Service).work_packages;
    const original = workPackages.id.bind(workPackages);
    let lookups = 0;
    return vi.spyOn(workPackages, 'id').mockImplementation((id) => {
      lookups += 1;
      if (lookups === 1) return original(id);
      return { get: () => from(refresh().then(() => firstValueFrom(original(id).get()))) } as unknown as ReturnType<typeof original>;
    });
  };

  const pickup = (id:string) => {
    const handle = document.createElement('span');
    handle.classList.add('wp-table--drag-and-drop-handle');
    const dragService = harness.injector.get(DragAndDropService) as unknown as FakeDragAndDropService;
    return dragService.memberOf(harness.tbody).canPickup(harness.row(id), handle);
  };

  beforeEach(() => {
    document.body.append(document.createElement('live-region'));
    announce = vi.spyOn(LiveRegionElement.prototype, 'announce');
    window.I18n.store({
      en: { js: { sortable_lists: { announcements: {
        moved: '%{label} moved to position %{position} of %{total}',
        moved_batch: { other: '%{count} items moved to positions %{first} through %{last} of %{total}' },
      } } } },
    });
  });

  afterEach(async () => {
    await harness.destroy();
    document.querySelector('live-region')?.remove();
    announce.mockRestore();
  });

  it('offers down and bottom on the first row', async () => {
    const mover = await renderTable();

    expect(mover.movableDirections(['1'])).toEqual(new Set(['down', 'bottom']));
    expect(mover.movableDirections(['2'])).toEqual(new Set(['top', 'up', 'down', 'bottom']));
    expect(mover.movableDirections(['3'])).toEqual(new Set(['top', 'up']));
  });

  it('disables every direction in a single-row table', async () => {
    const mover = await renderTable({ workPackages: [{ id: '1' }] });

    expect(mover.movableDirections(['1'])).toEqual(new Set());
  });

  it('offers no moves outside manual sorting', async () => {
    const mover = await renderTable({ manualSort: false });

    expect(mover.movableDirections(['2'])).toBeNull();
  });

  it('offers no moves in a descending manual sort', async () => {
    const mover = await renderTable({ manualSortDirection: QUERY_SORT_BY_DESC });

    expect(mover.movableDirections(['2'])).toBeNull();
  });

  it('moves to an edge within the group without preparing an attribute update', async () => {
    const prepareDrop = vi.fn();
    const mover = await renderTable({ workPackages: groupedWorkPackages, groups, dragAction: { prepareDrop } });
    expect(mover.movableDirections(['2'])).toEqual(new Set(['top', 'up']));
    expect(mover.movableDirections(['3'])).toEqual(new Set(['down', 'bottom']));

    const rendered = harness.nextRender();
    mover.move(['2'], 'top');
    await rendered;

    expect(harness.rowIds()).toEqual(['2', '1', '3', '4']);
    expect(prepareDrop).not.toHaveBeenCalled();
    await vi.waitFor(() => expect(announce).toHaveBeenCalledWith('Work package 2 moved to position 1 of 2', { politeness: 'polite' }));
  });

  it('reorders sibling roots with their descendants and preserves their parentage', async () => {
    const prepareDrop = vi.fn();
    const mover = await renderTable({
      workPackages: [{ id: '1' }, { id: '2', ancestors: [{ id: '1' }] }, { id: '3' }, { id: '4', ancestors: [{ id: '3' }] }],
      showHierarchies: true,
      dragAction: { prepareDrop },
    });
    expect(mover.movableDirections(['2'])).toEqual(new Set());
    expect(mover.movableDirections(['1'])).toEqual(new Set(['down', 'bottom']));

    const rendered = harness.nextRender();
    mover.move(['1'], 'down');
    await rendered;

    expect(harness.rowIds()).toEqual(['3', '4', '1', '2']);
    expect(prepareDrop).not.toHaveBeenCalled();
  });

  it('prepares again when the table renders while a move is being prepared', async () => {
    const mover = await renderTable({ workPackages: groupedWorkPackages, groups });
    const service = orderService();
    const original = service.prepareMove.bind(service);
    const prepareMove = vi.spyOn(service, 'prepareMove').mockImplementation(async (...args) => {
      const prepared = await original(...args);
      if (prepareMove.mock.calls.length === 1) harness.table.redrawTableAndTimeline();
      return prepared;
    });

    mover.move(['1'], 'down');

    await vi.waitFor(() => expect(harness.rowIds()).toEqual(['2', '1', '3', '4']));
    expect(prepareMove).toHaveBeenCalledTimes(2);
    await vi.waitFor(() => expect(announce).toHaveBeenCalledWith('Work package 1 moved to position 2 of 2', { politeness: 'polite' }));
  });

  it('keeps preparing until no render lands during preparation', async () => {
    const mover = await renderTable({ workPackages: groupedWorkPackages, groups });
    const service = orderService();
    const original = service.prepareMove.bind(service);
    const prepareMove = vi.spyOn(service, 'prepareMove').mockImplementation(async (...args) => {
      const prepared = await original(...args);
      if (prepareMove.mock.calls.length <= 2) harness.table.redrawTableAndTimeline();
      return prepared;
    });

    mover.move(['1'], 'down');

    await vi.waitFor(() => expect(harness.rowIds()).toEqual(['2', '1', '3', '4']));
    expect(prepareMove).toHaveBeenCalledTimes(3);
  });

  describe('when every preparation is overtaken by a render', () => {
    const renderDuringEveryPrepare = (onPrepare:() => void = () => undefined) => {
      const service = orderService();
      const original = service.prepareMove.bind(service);
      return vi.spyOn(service, 'prepareMove').mockImplementation(async (...args) => {
        const prepared = await original(...args);
        onPrepare();
        harness.table.redrawTableAndTimeline();
        return prepared;
      });
    };

    const renderDuringEveryBlockPrepare = () => {
      const service = orderService();
      const original = service.prepareBlockMove.bind(service);
      return vi.spyOn(service, 'prepareBlockMove').mockImplementation(async (...args) => {
        const prepared = await original(...args);
        harness.table.redrawTableAndTimeline();
        return prepared;
      });
    };

    beforeEach(() => {
      window.I18n.store({
        en: { js: { sortable_lists: { announcements: {
          move_failed_check_position: 'Move failed. Check the item\'s current position.',
          move_failed_check_positions_batch: { other: 'Move failed. Check the %{count} items\' current positions.' },
        } } } },
      });
    });

    it('announces that the move failed', async () => {
      const mover = await renderTable({ workPackages: groupedWorkPackages, groups });
      const prepareMove = renderDuringEveryPrepare();

      mover.move(['1'], 'down');

      await vi.waitFor(() => expect(announce).toHaveBeenCalledExactlyOnceWith('Move failed. Check the item\'s current position.', { politeness: 'assertive' }));
      expect(prepareMove).toHaveBeenCalledTimes(5);
      expect(harness.rowIds()).toEqual(['1', '2', '3', '4']);
    });

    it('announces that a move of several work packages failed', async () => {
      const mover = await renderTable({ workPackages: ['1', '2', '3', '4', '5'].map((id) => ({ id })) });
      const prepareBlockMove = renderDuringEveryBlockPrepare();

      mover.move(['4', '2'], 'down');

      await vi.waitFor(() => expect(announce).toHaveBeenCalledExactlyOnceWith('Move failed. Check the 2 items\' current positions.', { politeness: 'assertive' }));
      expect(prepareBlockMove).toHaveBeenCalledTimes(5);
      expect(harness.rowIds()).toEqual(['1', '2', '3', '4', '5']);
    });

    it('stays silent when the user left the query during a single-row move', async () => {
      const mover = await renderTable();
      const prepareMove = renderDuringEveryPrepare(() => {
        harness.querySpace.query.putValue({ ...harness.querySpace.query.value } as QueryResource);
      });

      mover.move(['1'], 'down');

      await vi.waitFor(() => expect(prepareMove).toHaveBeenCalledOnce());
      await harness.table.whenRendered();
      expect(announce).not.toHaveBeenCalled();
    });

    it('stays silent once the user moved on to another query', async () => {
      const mover = await renderTable({ workPackages: groupedWorkPackages, groups });
      const prepareMove = renderDuringEveryPrepare(() => {
        if (prepareMove.mock.calls.length === 3) {
          harness.querySpace.query.putValue({ ...harness.querySpace.query.value } as QueryResource);
        }
      });

      mover.move(['1'], 'down');

      await vi.waitFor(() => expect(prepareMove).toHaveBeenCalledTimes(3));
      await harness.table.whenRendered();
      expect(announce).not.toHaveBeenCalled();
    });
  });

  it('applies an accepted move after another render of the same view', async () => {
    const mover = await renderTable({ workPackages: groupedWorkPackages, groups });
    const { started, release } = holdPersist();
    mover.move(['1'], 'down');
    await started;

    harness.table.redrawTableAndTimeline();
    await harness.table.whenRendered();
    release();

    await vi.waitFor(() => expect(harness.rowIds()).toEqual(['2', '1', '3', '4']));
  });

  it('closes a non-contiguous selection into one block in table order', async () => {
    const mover = await renderTable({ workPackages: ['1', '2', '3', '4', '5'].map((id) => ({ id })) });
    const rendered = harness.nextRender();

    mover.move(['4', '2'], 'down');
    await rendered;

    expect(harness.rowIds()).toEqual(['1', '3', '5', '2', '4']);
    await vi.waitFor(() => expect(announce).toHaveBeenCalledWith('2 items moved to positions 4 through 5 of 5', { politeness: 'polite' }));
    expect(mover.movableDirections(['4', '2'])).toEqual(new Set(['up', 'top']));
  });

  it('moves selected siblings together with their descendants', async () => {
    const mover = await renderTable({ showHierarchies: true, workPackages: [
      { id: '1' }, { id: '2', ancestors: [{ id: '1' }] }, { id: '3' }, { id: '4' },
    ] });
    const rendered = harness.nextRender();
    mover.move(['4', '3'], 'up');
    await rendered;

    expect(harness.rowIds()).toEqual(['3', '4', '1', '2']);
  });

  it('moves a selection within its group while preserving the neighboring group', async () => {
    const mover = await renderTable({ groups: [{ ...groups[0], count: 3 }, groups[1]], workPackages: [
      groupedWorkPackages[0], groupedWorkPackages[1], { id: '5', attributes: { status: newStatus } },
      groupedWorkPackages[2], groupedWorkPackages[3],
    ] });
    const rendered = harness.nextRender();
    mover.move(['2', '5'], 'top');
    await rendered;

    expect(harness.rowIds()).toEqual(['2', '5', '1', '3', '4']);
  });

  it('only offers bulk moves within one group or sibling set', async () => {
    const grouped = await renderTable({ workPackages: groupedWorkPackages, groups });
    expect(grouped.movableDirections(['1', '3'])).toBeNull();
    expect(grouped.movableDirections(['1', '2'])).toEqual(new Set());
    await harness.destroy();

    const hierarchy = await renderTable({ showHierarchies: true, workPackages: [{ id: '1' }, { id: '2', ancestors: [{ id: '1' }] }] });
    expect(hierarchy.movableDirections(['1', '2'])).toBeNull();
  });

  it('offers no moves when the query cannot be reordered', async () => {
    const mover = await renderTable({ canReorder: false });

    expect(mover.movableDirections(['2'])).toBeNull();
  });

  it('offers moves when the query can be reordered', async () => {
    const mover = await renderTable({ canReorder: true });

    expect(mover.movableDirections(['2'])).toEqual(new Set(['top', 'up', 'down', 'bottom']));
  });

  it('offers no moves for a work package that is not rendered', async () => {
    const mover = await renderTable();

    expect(mover.movableDirections(['999'])).toBeNull();
  });

  it('offers no moves when the table has drag and drop disabled', async () => {
    const mover = await renderTable({ configuration: { dragAndDropEnabled: false } });

    expect(mover.movableDirections(['2'])).toBeNull();
  });

  it('moves a row down through the drop path', async () => {
    const mover = await renderTable();
    const prepareMove = spyOnPrepareMove();
    const rendered = harness.nextRender();

    mover.move(['1'], 'down');
    await rendered;

    expect(prepareMove).toHaveBeenCalledExactlyOnceWith(harness.querySpace.query.value, ['1', '2', '3'], '1', 1, expect.any(Function));
    expect(harness.rowIds()).toEqual(['2', '1', '3']);
  });

  it('moves a row to the top', async () => {
    const mover = await renderTable();
    const prepareMove = spyOnPrepareMove();
    const rendered = harness.nextRender();

    mover.move(['3'], 'top');
    await rendered;

    expect(prepareMove).toHaveBeenCalledExactlyOnceWith(harness.querySpace.query.value, ['1', '2', '3'], '3', 0, expect.any(Function));
    expect(harness.rowIds()).toEqual(['3', '1', '2']);
  });

  it('moves a row to the bottom', async () => {
    const mover = await renderTable();
    const prepareMove = spyOnPrepareMove();
    const rendered = harness.nextRender();

    mover.move(['1'], 'bottom');
    await rendered;

    expect(prepareMove).toHaveBeenCalledExactlyOnceWith(harness.querySpace.query.value, ['1', '2', '3'], '1', 2, expect.any(Function));
    expect(harness.rowIds()).toEqual(['2', '3', '1']);
  });

  it('announces the committed position by the row header name', async () => {
    const mover = await renderTable();

    mover.move(['1'], 'down');

    await vi.waitFor(() => expect(announce).toHaveBeenCalled());
    expect(announce).toHaveBeenCalledExactlyOnceWith('Work package 1 moved to position 2 of 3', { politeness: 'polite' });
  });

  it('announces only after the refreshed render commits', async () => {
    const mover = await renderTable();
    const { release, persisted } = holdPersist();
    const refresh = deferred();
    stubRefresh(() => refresh.promise);

    mover.move(['1'], 'down');
    release();
    await persisted;
    await new Promise((resolve) => { setTimeout(resolve, 20); });

    expect(announce).not.toHaveBeenCalled();

    const rendered = harness.nextRender();
    refresh.resolve();
    await rendered;

    await vi.waitFor(() => expect(announce).toHaveBeenCalled());
    expect(announce).toHaveBeenCalledExactlyOnceWith('Work package 1 moved to position 2 of 3', { politeness: 'polite' });
  });

  it('refuses a second menu move while the first is pending', async () => {
    const mover = await renderTable();
    const { prepareMove, release } = holdPersist();

    mover.move(['1'], 'down');
    await vi.waitFor(() => expect(prepareMove).toHaveBeenCalled());

    expect(mover.movableDirections(['2'])).toEqual(new Set());
    mover.move(['2'], 'down');

    const rendered = harness.nextRender();
    release();
    await rendered;

    expect(prepareMove).toHaveBeenCalledOnce();
    await vi.waitFor(() => expect(mover.movableDirections(['2'])).not.toEqual(new Set()));
  });

  it('refuses a pointer pickup while a menu move is pending', async () => {
    const mover = await renderTable();
    const { prepareMove, release } = holdPersist();
    expect(pickup('3')).toBe(true);

    mover.move(['1'], 'down');
    await vi.waitFor(() => expect(prepareMove).toHaveBeenCalled());

    expect(pickup('3')).toBe(false);

    release();
    await vi.waitFor(() => expect(pickup('3')).toBe(true));
  });

  it('keeps moves disabled after a failed refresh until the table re-renders', async () => {
    const mover = await renderTable();
    const notification = harness.injector.get(HalResourceNotificationService);
    const handleRawError = vi.spyOn(notification, 'handleRawError');
    const prepareMove = spyOnPrepareMove();
    const lookup = stubRefresh(() => Promise.reject(new Error('refresh failed')));

    mover.move(['1'], 'down');
    await vi.waitFor(() => expect(handleRawError).toHaveBeenCalled());
    await new Promise((resolve) => { setTimeout(resolve, 20); });

    expect(announce).not.toHaveBeenCalled();
    expect(mover.movableDirections(['1'])).toEqual(new Set());

    lookup.mockRestore();
    await harness.render([{ id: '2' }, { id: '1' }, { id: '3' }]);
    await vi.waitFor(() => expect(mover.movableDirections(['1'])).not.toEqual(new Set()));

    prepareMove.mockClear();
    const rendered = harness.nextRender();
    mover.move(['1'], 'down');
    await rendered;

    expect(prepareMove).toHaveBeenCalledExactlyOnceWith(harness.querySpace.query.value, ['2', '1', '3'], '1', 2, expect.any(Function));
    expect(harness.rowIds()).toEqual(['2', '3', '1']);
  });

  it('ignores expanded relation rows when offering and making moves', async () => {
    harness = buildTable({
      workPackages: threeRows,
      manualSort: true,
      relations: [{ from: '3', to: '1', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      configuration: { dragAndDropEnabled: true },
    });
    harness.expand('3', 'relationsOfTypeFollows');
    await harness.render();
    const mover = harness.table.rowMover!;
    const prepareMove = spyOnPrepareMove();
    expect(harness.rowIds()).toEqual(['1', '2', '3', '1']);

    expect(mover.movableDirections(['3'])).toEqual(new Set(['top', 'up']));

    const rendered = harness.nextRender();
    mover.move(['2'], 'down');
    await rendered;

    expect(prepareMove).toHaveBeenCalledExactlyOnceWith(harness.querySpace.query.value, ['1', '2', '3'], '2', 2, expect.any(Function));
  });

  it('keeps moves available in a query that rendered while a failed refresh was pending', async () => {
    const mover = await renderTable();
    const refreshStarted = deferred();
    const refresh = deferred();
    stubRefresh(() => {
      refreshStarted.resolve();
      return refresh.promise;
    });

    mover.move(['1'], 'down');
    await refreshStarted.promise;
    harness.querySpace.query.putValue({ ...harness.querySpace.query.value } as QueryResource);
    await harness.render(threeRows);
    refresh.reject(new Error('refresh failed'));

    await vi.waitFor(() => {
      expect(mover.movableDirections(['1'])).toEqual(new Set(['top', 'up', 'down', 'bottom']));
      expect(pickup('1')).toBe(true);
    });
  });

  it('keeps moves available when the same query rendered while a failed refresh was pending', async () => {
    const mover = await renderTable();
    const refreshStarted = deferred();
    const refresh = deferred();
    stubRefresh(() => {
      refreshStarted.resolve();
      return refresh.promise;
    });

    mover.move(['1'], 'down');
    await refreshStarted.promise;
    await harness.render([{ id: '2' }, { id: '1' }, { id: '3' }]);
    refresh.reject(new Error('refresh failed'));

    await vi.waitFor(() => {
      expect(mover.movableDirections(['1'])).toEqual(new Set(['top', 'up', 'down', 'bottom']));
      expect(pickup('1')).toBe(true);
    });
  });

  it('releases the guard at once when a move is abandoned before saving', async () => {
    const mover = await renderTable();
    const notification = harness.injector.get(HalResourceNotificationService);
    const handleRawError = vi.spyOn(notification, 'handleRawError');
    vi.spyOn(orderService(), 'prepareMove').mockRejectedValue(new Error('positions unavailable'));

    mover.move(['1'], 'down');
    await vi.waitFor(() => expect(handleRawError).toHaveBeenCalled());

    await vi.waitFor(() => expect(mover.movableDirections(['1'])).toEqual(new Set(['down', 'bottom'])));
    expect(harness.rowIds()).toEqual(['1', '2', '3']);
    expect(announce).not.toHaveBeenCalled();
  });

  it('announces nothing after the view moved on during the save', async () => {
    const mover = await renderTable();
    const { prepareMove, release, persisted } = holdPersist();

    mover.move(['1'], 'down');
    await vi.waitFor(() => expect(prepareMove).toHaveBeenCalled());
    harness.querySpace.query.putValue({ ...harness.querySpace.query.value } as QueryResource);
    release();
    await persisted;

    await vi.waitFor(() => expect(mover.movableDirections(['2'])).toEqual(new Set(['top', 'up', 'down', 'bottom'])));
    expect(announce).not.toHaveBeenCalled();
  });

  it('ignores a direction that is not available', async () => {
    const mover = await renderTable();
    const prepareMove = spyOnPrepareMove();

    mover.move(['1'], 'up');
    await new Promise((resolve) => { setTimeout(resolve, 20); });

    expect(prepareMove).not.toHaveBeenCalled();
    expect(announce).not.toHaveBeenCalled();
  });

  it('announces a failed move when a render overtakes it before persisting', async () => {
    window.I18n.store({
      en: { js: { sortable_lists: { announcements: {
        move_failed_check_position: 'Move failed. Check the item\'s current position.',
      } } } },
    });
    const mover = await renderTable();
    const service = orderService();
    const original = service.prepareMove.bind(service);
    const persist = vi.fn();
    vi.spyOn(service, 'prepareMove').mockImplementation(async (...args) => {
      const prepared = await original(...args);
      await harness.render([{ id: '3' }, { id: '1' }, { id: '2' }]);
      return { ...prepared, persist };
    });

    mover.move(['1'], 'down');

    await vi.waitFor(() => expect(mover.movableDirections(['1'])).toEqual(new Set(['top', 'up', 'down', 'bottom'])));
    expect(persist).not.toHaveBeenCalled();
    expect(announce).toHaveBeenCalledExactlyOnceWith('Move failed. Check the item\'s current position.', { politeness: 'assertive' });
    expect(harness.rowIds()).toEqual(['3', '1', '2']);
  });
});
