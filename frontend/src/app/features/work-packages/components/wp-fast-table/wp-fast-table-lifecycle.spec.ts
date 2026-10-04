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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Subject } from 'rxjs';
import { skip } from 'rxjs/operators';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { WorkPackageShareModalComponent } from 'core-app/features/work-packages/components/wp-share-modal/wp-share.modal';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { ElementRef, EnvironmentInjector, Injector, runInInjectionContext } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, waitFor } from '@testing-library/dom';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { EmbeddedTablesMacroComponent } from 'core-app/features/work-packages/components/wp-table/embedded/embedded-tables-macro.component';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { tableRefreshRequest } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.actions';
import { usePlatform } from 'core-common/testing/platform';
import { States } from 'core-app/core/states/states.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageTableConfigurationObject } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { TableUiWork } from './table-ui-work';
import { buildDom, buildTable, TableHarness, TableHarnessOptions } from './testing/table-harness';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { queryColumnTypes } from 'core-app/features/work-packages/components/wp-query/query-column';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TableEditForm } from 'core-app/features/work-packages/components/wp-edit-form/table-edit-form';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { nextFrame, nextTask } from 'core-common/testing/timing';
import { buildWorkPackage } from './testing/work-package-fixture';
import { TimelineRenderPass } from './builders/timeline/timeline-render-pass';
import { DragDropHandleBuilder } from './builders/drag-and-drop/drag-drop-handle-builder';
import { placeholderOccurrenceKey } from './rendered-occurrence-ledger';

function deferred<T>() {
  let resolve!:(value:T) => void;
  const promise = new Promise<T>((complete) => { resolve = complete; });
  return { promise, resolve };
}

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };

const grouped:TableHarnessOptions = {
  workPackages: [
    { id: '1', attributes: { status: newStatus } },
    { id: '2', attributes: { status: newStatus } },
    { id: '3', attributes: { status: inProgressStatus } },
  ],
  groups: [
    { value: 'New', href: newStatus.href, count: 2 },
    { value: 'In progress', href: inProgressStatus.href, count: 1 },
  ],
};

describe('WorkPackageTable lifecycle', () => {
  usePlatform('Linux');
  const harnesses:TableHarness[] = [];

  const mount = async (options:TableHarnessOptions) => {
    const harness = buildTable(options);
    harnesses.push(harness);
    await harness.render();
    return harness;
  };

  const toggleGroup = (harness:TableHarness, index:number) => {
    fireEvent.click(harness.groupHeader(index).querySelector('.expander')!);
  };

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((harness) => harness.destroy()));
    vi.restoreAllMocks();
  });


  it('owns a native lifetime independently of its services', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const shared = harness.querySpace.tableRendered.value;
    const observed:boolean[] = [];
    harness.table.destroyRef.onDestroy(() => observed.push(harness.table.destroyed));
    harness.table.destroy();
    harness.table.destroy();
    expect(observed).toEqual([true]);
    expect(harness.querySpace.tableRendered.value).toBe(shared);
    expect(harness.injector.get(States)).toBeDefined();
  });

  it('publishes within its frame, leaving nothing to overwrite cards after disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const shared = harness.querySpace.tableRendered.value;
    const frames:FrameRequestCallback[] = [];
    const frameSpy = vi.spyOn(window, 'requestAnimationFrame')
      .mockImplementation((callback) => frames.push(callback));
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    try {
      harness.table.redrawTableAndTimeline();
      frames.shift()!(0);
      expect(harness.querySpace.tableRendered.value).not.toBe(shared);
      harness.table.destroy();
      const cards = [{ classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false }];
      harness.querySpace.tableRendered.putValue(cards);
      await vi.runAllTimersAsync();
      expect(harness.querySpace.tableRendered.value).toBe(cards);
    } finally {
      vi.useRealTimers();
      frameSpy.mockRestore();
    }
  });

  it('ignores a cancelled frame even if its callback executes', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const before = harness.tbody.innerHTML;
    harness.table.originalRowIndex['1'].object.subject = 'Rebuilt';
    const frames:FrameRequestCallback[] = [];
    const frameSpy = vi.spyOn(window, 'requestAnimationFrame')
      .mockImplementation((callback) => frames.push(callback));
    try {
      harness.table.redrawTableAndTimeline();
      harness.table.destroy();
      const cards = [{ classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false }];
      harness.querySpace.tableRendered.putValue(cards);
      frames.shift()!(0);
      expect(harness.tbody.innerHTML).toBe(before);
      expect(harness.querySpace.tableRendered.value).toBe(cards);
    } finally {
      frameSpy.mockRestore();
    }
  });

  it('ignores queued table-only insertion after disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const before = harness.tbody.innerHTML;
    harness.table.originalRowIndex['1'].object.subject = 'Rebuilt';
    const frames:FrameRequestCallback[] = [];
    const frameSpy = vi.spyOn(window, 'requestAnimationFrame')
      .mockImplementation((callback) => frames.push(callback));
    try {
      harness.table.redrawTable();
      harness.table.destroy();
      const cards = [{ classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false }];
      harness.querySpace.tableRendered.putValue(cards);
      frames.shift()!(0);
      expect(harness.tbody.innerHTML).toBe(before);
      expect(harness.querySpace.tableRendered.value).toBe(cards);
    } finally {
      frameSpy.mockRestore();
    }
  });

  describe('publishing a render', () => {
    const recordEmissions = (harness:TableHarness, record:() => void = () => undefined) => {
      const emissions:RenderedWorkPackage[][] = [];
      const subscription = harness.querySpace.tableRendered.values$().pipe(skip(1)).subscribe((rendered) => {
        emissions.push(rendered);
        record();
      });
      return { emissions, stop: () => subscription.unsubscribe() };
    };

    it('publishes a table-only redraw once its rows are in the table', async () => {
      const harness = await mount({ workPackages: [{ id: '1' }] });
      const oldRow = harness.row('1');
      harness.table.originalRowIndex['1'].object.subject = 'Rebuilt';
      const atPublish:{ oldRowAttached:boolean, text:string|null }[] = [];
      const { stop } = recordEmissions(harness, () => atPublish.push({
        oldRowAttached: harness.tbody.contains(oldRow),
        text: harness.row('1').textContent,
      }));
      try {
        harness.table.redrawTable();
        await waitFor(() => expect(atPublish).toHaveLength(1));
        expect(atPublish).toEqual([{ oldRowAttached: false, text: expect.stringContaining('Rebuilt') as string }]);
      } finally {
        stop();
      }
    });

    it('keeps the timeline of a full redraw superseded by a table-only one', async () => {
      const harness = await mount({ workPackages: [{ id: '1' }], timelineVisible: true });
      const oldTimelineRow = harness.timelineRow('1');
      harness.table.originalRowIndex['1'].object.subject = 'Rebuilt';
      const { emissions, stop } = recordEmissions(harness);
      try {
        harness.table.redrawTableAndTimeline();
        harness.table.redrawTable();
        await waitFor(() => expect(emissions).toHaveLength(1));
        await nextFrame();
        await nextTask();
        expect(emissions).toHaveLength(1);
        expect(harness.row('1')).toHaveTextContent('Rebuilt');
        expect(harness.timelineRow('1')).not.toBe(oldTimelineRow);
      } finally {
        stop();
      }
    });

    it('drops a superseded render without touching the table', async () => {
      const harness = await mount({ workPackages: [{ id: '1' }] });
      const before = harness.tbody.innerHTML;
      const frames:FrameRequestCallback[] = [];
      const frameSpy = vi.spyOn(window, 'requestAnimationFrame')
        .mockImplementation((callback) => frames.push(callback));
      const { emissions, stop } = recordEmissions(harness);
      try {
        harness.table.originalRowIndex['1'].object.subject = 'First';
        harness.table.redrawTable();
        harness.table.originalRowIndex['1'].object.subject = 'Second';
        harness.table.redrawTable();
        frames.shift()!(0);
        expect(harness.tbody.innerHTML).toBe(before);
        expect(emissions).toHaveLength(0);
        frames.shift()!(0);
        expect(harness.row('1')).toHaveTextContent('Second');
        expect(emissions).toHaveLength(1);
      } finally {
        stop();
        frameSpy.mockRestore();
      }
    });
  });

  it('leaves all render entry points inert after disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    harness.table.destroy();
    const before = harness.tbody.innerHTML;
    const shared = harness.querySpace.tableRendered.value;
    const reset = vi.spyOn(harness.table.editing, 'reset');
    const api = harness.injector.get(ApiV3Service);
    const cache = vi.spyOn(api.work_packages.cache, 'current');
    harness.table.initialSetup([buildWorkPackage({ id: '2' })]);
    harness.table.redrawTableAndTimeline();
    harness.table.redrawTable();
    harness.table.refreshRows(buildWorkPackage({ id: '1', subject: 'Changed' }));
    harness.table.setGroupsCollapseState({ group: true });
    expect(reset).not.toHaveBeenCalled();
    expect(cache).not.toHaveBeenCalled();
    expect(harness.tbody.innerHTML).toBe(before);
    expect(harness.querySpace.tableRendered.value).toBe(shared);
  });

  it('isolates owned cleanup failures before resetting editing', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const error = new Error('owned cleanup');
    const editingError = new Error('editing reset');
    const report = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const order:string[] = [];
    const listener = vi.fn();
    const target = new EventTarget();
    target.addEventListener('event', listener);
    onDestroySafely(harness.table.destroyRef, () => { throw error; });
    onDestroySafely(harness.table.destroyRef, () => order.push('second'));
    onDestroySafely(harness.table.destroyRef, () => target.removeEventListener('event', listener));
    vi.spyOn(harness.table.editing, 'reset').mockImplementation(() => {
      order.push('editing');
      throw editingError;
    });
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    try {
      const laterWork = new TableUiWork(harness.table.destroyRef);
      laterWork.task(() => order.push('task'));
      harness.table.destroy();
      harness.table.destroy();
      target.dispatchEvent(new Event('event'));
      await vi.runAllTimersAsync();
      expect(order).toEqual(['second', 'editing']);
      expect(listener).not.toHaveBeenCalled();
      expect(report).toHaveBeenCalledWith('UI cleanup failed', error);
      expect(report).toHaveBeenCalledWith('UI cleanup failed', editingError);
    } finally {
      vi.useRealTimers();
    }
  });

  it('clears forms before independently destroying each disposed editor', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const error = new Error('editor portal');
    const report = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    const first = vi.fn(() => {
      expect(harness.table.editing.forms).toEqual({});
      throw error;
    });
    const second = vi.fn();
    harness.table.editing.forms = {
      first: { destroy: first } as unknown as TableEditForm,
      second: { destroy: second } as unknown as TableEditForm,
    };
    harness.table.destroy();
    harness.table.destroy();
    expect(first).toHaveBeenCalledTimes(1);
    expect(second).toHaveBeenCalledTimes(1);
    expect(report).toHaveBeenCalledWith('UI cleanup failed', error);
  });

  it('allows a loaded child into shared cache without redrawing a disposed table', async () => {
    const harness = await mount({ workPackages: [{ id: '1', attributes: { children: [{ id: '2' }] } }], columns: ['id', 'subject', 'children'] });
    const api = harness.injector.get(ApiV3Service);
    const loaded = deferred<WorkPackageResource[]>();
    const requireAll = vi.spyOn(api.work_packages, 'requireAll').mockImplementation(() => loaded.promise);
    const columns = harness.injector.get(WorkPackageViewColumnsService);
    columns.findById('children')!._type = queryColumnTypes.RELATION_CHILD;
    harness.injector.get(WorkPackageViewRelationColumnsService).setExpandFor('1', 'children');
    harness.table.redrawTable();
    await nextFrame();
    expect(requireAll).toHaveBeenCalledWith(['2']);
    const before = harness.tbody.innerHTML;
    harness.table.destroy();
    const cards = [{ classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false }];
    harness.querySpace.tableRendered.putValue(cards);
    const child = buildWorkPackage({ id: '2' });
    harness.injector.get(States).workPackages.get('2').putValue(child);
    loaded.resolve([child]);
    await loaded.promise;
    await nextFrame();
    expect(harness.injector.get(States).workPackages.get('2').value).toBe(child);
    expect(harness.tbody.innerHTML).toBe(before);
    expect(harness.querySpace.tableRendered.value).toBe(cards);
  });

  it('does not replace row cells when positions finish after disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }], configuration: { dragAndDropEnabled: true } });
    const loaded = deferred<QueryOrder>();
    vi.spyOn(harness.injector.get(WorkPackageViewOrderService), 'positionsFor').mockReturnValue(loaded.promise);
    harness.table.redrawTableAndTimeline();
    await nextFrame();
    const before = harness.tbody.innerHTML;
    const firstCell = harness.row('1').firstElementChild;
    harness.table.destroy();
    loaded.resolve({ '1': 100 });
    await loaded.promise;
    expect(harness.tbody.innerHTML).toBe(before);
    expect(harness.row('1').firstElementChild).toBe(firstCell);
  });

  it('does not replace row cells when positions finish for a preceding query', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }], configuration: { dragAndDropEnabled: true } });
    const loaded = deferred<QueryOrder>();
    vi.spyOn(harness.injector.get(WorkPackageViewOrderService), 'positionsFor').mockReturnValue(loaded.promise);
    harness.table.redrawTableAndTimeline();
    await nextFrame();
    const before = harness.tbody.innerHTML;
    const firstCell = harness.row('1').firstElementChild;
    harness.querySpace.query.putValue({ id: 'successor' } as QueryResource);
    loaded.resolve({ '1': 100 });
    await loaded.promise;
    expect(harness.tbody.innerHTML).toBe(before);
    expect(harness.row('1').firstElementChild).toBe(firstCell);
  });

  it('uses the latest cached work package when drag positions finish', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }], configuration: { dragAndDropEnabled: true } });
    const positions = deferred<QueryOrder>();
    vi.spyOn(harness.injector.get(WorkPackageViewOrderService), 'positionsFor').mockReturnValue(positions.promise);
    const build = vi.spyOn(DragDropHandleBuilder.prototype, 'build');
    harness.table.redrawTableAndTimeline();
    await nextFrame();

    const latest = buildWorkPackage({ id: '1', subject: 'Latest' });
    harness.injector.get(States).workPackages.get('1').putValue(latest);
    positions.resolve({});

    await waitFor(() => expect(build).toHaveBeenLastCalledWith(latest, undefined));
  });

  it('registers the drag-and-drop placeholder without rendering it on the timeline', async () => {
    const harness = await mount({
      workPackages: [],
      configuration: { dragAndDropEnabled: true },
      timelineVisible: true,
    });
    const placeholder = harness.tbody.querySelector<HTMLTableRowElement>('.wp--placeholder-row')!;

    expect(placeholder.dataset.occurrenceKey).toBe(placeholderOccurrenceKey());
    expect(harness.table.ledger.byKey(placeholderOccurrenceKey())?.element).toBe(placeholder);
    expect(harness.table.timelineBody).toBeEmptyDOMElement();
  });

  it('reports a genuinely rejected position load after disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }], configuration: { dragAndDropEnabled: true } });
    const error = new Error('position request');
    let reject!:(reason:unknown) => void;
    const pending = new Promise<QueryOrder>((_resolve, fail) => { reject = fail; });
    vi.spyOn(harness.injector.get(WorkPackageViewOrderService), 'positionsFor').mockReturnValue(pending);
    const report = vi.spyOn(harness.injector.get(WorkPackageNotificationService), 'handleRawError');
    harness.table.redrawTableAndTimeline();
    harness.table.destroy();
    reject(error);
    await waitFor(() => expect(report).toHaveBeenCalledExactlyOnceWith(error));
  });

  it('retires inline-create work and removes its drag registration at disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const member = vi.spyOn(harness.injector.get(DragAndDropService), 'remove');
    const api = harness.injector.get(ApiV3Service);
    harness.querySpace.query.value!.id = '10';
    const positions = deferred<QueryOrder>();
    const update = vi.fn();
    vi.spyOn(api.queries, 'id').mockReturnValue({ order: { get: () => positions.promise, update } } as unknown as ReturnType<ApiV3Service['queries']['id']>);
    const get = vi.spyOn(api.work_packages, 'id');
    harness.injector.get(WorkPackageInlineCreateService).newInlineWorkPackageCreated.next('2');
    harness.table.destroy();
    harness.table.destroy();
    positions.resolve({});
    await positions.promise;
    await Promise.resolve();
    expect(update).not.toHaveBeenCalled();
    expect(get).not.toHaveBeenCalled();
    expect(member).toHaveBeenCalledExactlyOnceWith(harness.tbody);
  });

  it('does not redraw after inline-create resource loading finishes after disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const loaded = new Subject<WorkPackageResource>();
    const get = vi.spyOn(harness.injector.get(ApiV3Service).work_packages, 'id')
      .mockReturnValue({ get: () => loaded } as unknown as ReturnType<ApiV3Service['work_packages']['id']>);
    const setup = vi.spyOn(harness.table, 'initialSetup');
    harness.injector.get(WorkPackageInlineCreateService).newInlineWorkPackageCreated.next('2');
    await waitFor(() => expect(get).toHaveBeenCalled());
    harness.table.destroy();
    loaded.next(buildWorkPackage({ id: '1' }));
    await Promise.resolve();
    await Promise.resolve();
    expect(setup).not.toHaveBeenCalled();
  });

  it('reports rejected inline-create order persistence after disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const error = new Error('inline order request');
    let reject!:(reason:unknown) => void;
    const pending = new Promise<string>((_resolve, fail) => { reject = fail; });
    const api = harness.injector.get(ApiV3Service);
    harness.querySpace.query.value!.id = '10';
    const update = vi.fn(() => pending);
    vi.spyOn(api.queries, 'id').mockReturnValue({ order: { get: () => Promise.resolve({}), update } } as unknown as ReturnType<ApiV3Service['queries']['id']>);
    const report = vi.spyOn(harness.injector.get(WorkPackageNotificationService), 'handleRawError');
    harness.injector.get(WorkPackageInlineCreateService).newInlineWorkPackageCreated.next('2');
    await waitFor(() => expect(update).toHaveBeenCalled());
    harness.table.destroy();
    reject(error);
    await waitFor(() => expect(report).toHaveBeenCalledExactlyOnceWith(error));
  });

  describe('with an expanded children column', () => {
    const mountExpanded = async (options:Omit<TableHarnessOptions, 'workPackages'>) => {
      const harness = buildTable({
        workPackages: [{ id: '1', children: [{ id: '2' }] }],
        columns: ['id', 'subject', { id: 'children', children: true }],
        loadChildren: false,
        ...options,
      });
      harnesses.push(harness);
      harness.expand('1', 'children');
      await harness.render();
      return harness;
    };

    const settle = async () => {
      await Promise.resolve();
      await nextFrame();
      await nextFrame();
    };

    it('requests a missing child once until the next initial setup', async () => {
      const unresolved:WorkPackageResource[] = [];
      const requireAll = vi.fn(() => (requireAll.mock.calls.length > 3 ? new Promise<WorkPackageResource[]>(() => undefined) : Promise.resolve(unresolved)));
      const harness = await mountExpanded({ requireAll });
      await settle();
      expect(requireAll).toHaveBeenCalledTimes(1);
      expect(requireAll).toHaveBeenCalledWith(['2']);

      await harness.render();
      await settle();
      expect(requireAll).toHaveBeenCalledTimes(2);
    });

    it('draws the timeline row of a child loaded after the render', async () => {
      const loaded = deferred<WorkPackageResource[]>();
      const requireAll = vi.fn(() => loaded.promise);
      const harness = await mountExpanded({ requireAll, timelineVisible: true });
      const child = buildWorkPackage({ id: '2' });
      harness.injector.get(States).workPackages.get('2').putValue(child);
      loaded.resolve([child]);
      await settle();
      expect(harness.tbody.querySelector('[data-occurrence-key="relation:children:1:2"]')).not.toBeNull();
      expect(harness.timelineRow('2')).toBeInTheDocument();
    });
  });

  it('keeps the timeline untouched on a table-only redraw', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }], timelineVisible: true });
    const timelineRow = harness.timelineRow('1');
    const tableRow = harness.row('1');
    const timelineRender = vi.spyOn(TimelineRenderPass.prototype, 'render');
    harness.table.originalRowIndex['1'].object.subject = 'Rebuilt';

    harness.table.redrawTable();
    await harness.nextRender();
    expect(harness.row('1')).not.toBe(tableRow);
    expect(harness.timelineRow('1')).toBe(timelineRow);
    expect(timelineRender).not.toHaveBeenCalled();

    harness.table.redrawTableAndTimeline();
    await harness.nextRender();
    expect(timelineRender).toHaveBeenCalledTimes(1);
    expect(harness.timelineRow('1')).not.toBe(timelineRow);
  });

  describe('with two tables showing the same work packages', () => {
    let states:States;
    let first:TableHarness;
    let second:TableHarness;

    beforeEach(async () => {
      states = new States();
      first = await mount({ ...grouped, states });
      second = await mount({ ...grouped, states });
    });

    it('keeps selection and the current work package with the table that was clicked', () => {
      first.click('2');

      expect(first.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(first.focus.focusedWorkPackage).toBe('2');
      expect(first.row('2')).toHaveClass('-checked');
      expect(second.selection.isEmpty).toBe(true);
      expect(second.focus.focusedWorkPackage).toBe('1');
      expect(second.row('2')).not.toHaveClass('-checked');
    });

    it('collapses a group only in its own table', async () => {
      toggleGroup(first, 0);

      await waitFor(() => expect(first.row('1')).not.toBeVisible());
      expect(second.row('1')).toBeVisible();
      expect(second.row('2')).toBeVisible();
      expect(second.renderedState()).toEqual([['1', false], ['2', false], ['3', false]]);
    });

    it('refreshes a changed work package in every table showing it', async () => {
      states.workPackages.get('1').putValue(buildWorkPackage({ id: '1', subject: 'Renamed', attributes: { status: newStatus } }));

      await waitFor(() => expect(first.row('1')).toHaveTextContent('Renamed'));
      await waitFor(() => expect(second.row('1')).toHaveTextContent('Renamed'));
    });

    it('keeps the surviving table working after the other is destroyed', async () => {
      await first.destroy();

      second.click('2');
      toggleGroup(second, 1);

      expect(second.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      await waitFor(() => expect(second.row('3')).not.toBeVisible());
    });

    it('retires selection, folding, refresh and sharing while the other table stays live', async () => {
      first.click('2');
      const selected = vi.spyOn(first.selection, 'selectAll');
      const reset = vi.spyOn(first.selection, 'reset');
      const refreshed = vi.spyOn(first.table, 'refreshRows');
      const firstRefresh = vi.fn();
      const secondRefresh = vi.fn();
      first.injector.get(ActionsService).ofType(tableRefreshRequest).subscribe(firstRefresh);
      second.injector.get(ActionsService).ofType(tableRefreshRequest).subscribe(secondRefresh);
      first.table.destroy();
      first.table.destroy();

      first.click('3');
      toggleGroup(first, 0);
      fireEvent.keyDown(first.row('1'), { key: 'a', ctrlKey: true });
      first.injector.get(ActionsService).dispatch(shareModalUpdated({ workPackageId: '1' }));
      second.injector.get(ActionsService).dispatch(shareModalUpdated({ workPackageId: '1' }));
      states.workPackages.get('1').putValue(buildWorkPackage({ id: '1', subject: 'Surviving refresh', attributes: { status: newStatus } }));
      await waitFor(() => expect(second.row('1')).toHaveTextContent('Surviving refresh'));
      expect(first.row('1')).not.toHaveTextContent('Surviving refresh');
      expect(first.row('1')).toBeVisible();
      expect(first.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(selected).not.toHaveBeenCalled();
      expect(refreshed).not.toHaveBeenCalled();
      expect(firstRefresh).not.toHaveBeenCalled();
      expect(secondRefresh).toHaveBeenCalledOnce();

      second.click('2');
      fireEvent.keyDown(second.row('1'), { key: 'a', ctrlKey: true });
      expect(second.selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '3']);
      fireEvent.keyDown(document.body, { key: 'Escape' });
      expect(second.selection.isEmpty).toBe(true);
      expect(reset).not.toHaveBeenCalled();
      expect(first.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      toggleGroup(second, 1);
      await waitFor(() => expect(second.row('3')).not.toBeVisible());
    });

    it('stops redrawing a table once the table is destroyed', async () => {
      const setup = vi.spyOn(first.table, 'initialSetup');
      first.table.destroy();

      first.querySpace.results.putValue({ elements: [buildWorkPackage({ id: '9' })] } as WorkPackageCollectionResource);
      first.querySpace.initialized.putValue(null);
      await second.render([{ id: '9', attributes: { status: newStatus } }]);

      expect(second.rowIds()).toEqual(['9']);
      expect(first.rowIds()).toEqual(['1', '2', '3']);
      expect(setup).not.toHaveBeenCalled();
    });
  });

  describe('with consumer configuration over production defaults', () => {
    const mountConfigured = (configuration?:WorkPackageTableConfigurationObject) => mount({
      workPackages: [{ id: '1' }, { id: '2' }],
      configuration,
      productionDefaults: true,
    });

    it('opens the table menu with the default configuration', async () => {
      const harness = await mountConfigured();
      const opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');

      expect(fireEvent.contextMenu(harness.row('1'))).toBe(false);
      expect(opened).toHaveBeenCalledTimes(1);
    });

    it('leaves the native context menu alone in the embedded table macro', async () => {
      const host = Injector.create({
        providers: [{ provide: ElementRef, useValue: new ElementRef(document.createElement('div')) }],
        parent: TestBed.inject(Injector),
      });
      const macro = runInInjectionContext(host, () => new EmbeddedTablesMacroComponent());
      const harness = await mountConfigured(macro.configuration);
      const opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');

      expect(fireEvent.contextMenu(harness.row('1'))).toBe(true);
      expect(fireEvent.keyDown(harness.row('1'), { key: 'F10', shiftKey: true, altKey: true })).toBe(true);

      expect(opened).not.toHaveBeenCalled();
      expect(harness.selection.isEmpty).toBe(true);
    });
  });

  it('removes context-menu callbacks on direct table disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }], configuration: { contextMenuEnabled: true } });
    const opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');
    harness.table.destroy();
    expect(fireEvent.contextMenu(harness.row('1'))).toBe(true);
    expect(fireEvent.keyDown(harness.row('1'), { key: 'F10', shiftKey: true, altKey: true })).toBe(true);
    expect(opened).not.toHaveBeenCalled();
  });

  it('mounts a fresh table on a retained root without old callbacks', async () => {
    const dom = buildDom();
    const options = { ...grouped, dom, configuration: { contextMenuEnabled: true } };
    const first = await mount(options);
    const clicked = vi.fn();
    first.outputs.itemClicked.subscribe(clicked);
    const firstMenu = vi.spyOn(first.injector.get(OPContextMenuService), 'show');
    const firstSelect = vi.spyOn(first.selection, 'selectAll');
    const firstReset = vi.spyOn(first.selection, 'reset');
    first.table.destroy();
    const second = await mount(options);
    const secondClicked = vi.fn();
    second.outputs.itemClicked.subscribe(secondClicked);
    const secondMenu = vi.spyOn(second.injector.get(OPContextMenuService), 'show');
    try {
      expect(second.injector).not.toBe(first.injector);
      second.click('2');
      fireEvent.contextMenu(second.row('1'));
      fireEvent.keyDown(second.row('1'), { key: 'a', ctrlKey: true });
      expect(second.selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '3']);
      fireEvent.keyDown(document.body, { key: 'Escape' });
      expect(second.selection.isEmpty).toBe(true);
      expect(clicked).not.toHaveBeenCalled();
      expect(firstMenu).not.toHaveBeenCalled();
      expect(firstSelect).not.toHaveBeenCalled();
      expect(firstReset).not.toHaveBeenCalled();
      expect(secondClicked).toHaveBeenCalledOnce();
      expect(secondMenu).toHaveBeenCalledOnce();
    } finally {
      await first.destroy();
      await second.destroy();
      dom.wrapper.remove();
    }
  });

  it.each(['direct', 'injector'] as const)('retires real sharing cells on %s disposal and replaces their same-root owner', async (mode) => {
    const dom = buildDom();
    const firstModal = vi.fn();
    const options = { workPackages: [{ id: '1' }], columns: ['id', 'sharedWithUsers'], dom };
    const first = buildTable({ ...options, providers: [{ provide: OpModalService, useValue: { show: firstModal } }] });
    const firstInjector = first.injector as EnvironmentInjector;
    const errors:ErrorEvent[] = [];
    const captureError = (event:ErrorEvent) => { errors.push(event); event.preventDefault(); };
    window.addEventListener('error', captureError);
    let second:TableHarness|undefined;
    try {
      await first.render();
      const oldCell = first.row('1').querySelector<HTMLElement>('[data-column-id="sharedWithUsers"]')!;
      const workPackage = first.injector.get(States).workPackages.get('1').value;
      if (mode === 'direct') {
        fireEvent.click(oldCell);
        first.table.destroy();
      } else {
        // The owning component retires the table before its real injector.
        // Keep the modal LazyInject unprimed through both disposals.
        first.table.destroy();
        firstInjector.destroy();
      }
      const expectedCalls = mode === 'direct'
        ? [[WorkPackageShareModalComponent, 'global', { workPackage }, false, true]]
        : [];
      expect(firstModal.mock.calls).toEqual(expectedCalls);
      firstModal.mockClear();
      const lookup = vi.spyOn(firstInjector, 'get');
      fireEvent.click(oldCell);
      expect(firstModal).not.toHaveBeenCalled();
      expect(lookup).not.toHaveBeenCalled();
      expect(errors).toEqual([]);
      expect(first.table.destroyed).toBe(true);
      lookup.mockRestore();

      const secondModal = vi.fn();
      second = buildTable({ ...options, providers: [{ provide: OpModalService, useValue: { show: secondModal } }] });
      await second.render();
      fireEvent.click(second.row('1').querySelector('[data-column-id="sharedWithUsers"]')!);
      expect(secondModal).toHaveBeenCalledExactlyOnceWith(
        WorkPackageShareModalComponent, 'global', { workPackage: second.injector.get(States).workPackages.get('1').value }, false, true,
      );
      // Ordinary redraws detach old cells, which must have no direct handlers.
      fireEvent.click(oldCell);
      expect(firstModal).not.toHaveBeenCalled();
      expect(secondModal).toHaveBeenCalledOnce();
      expect(errors).toEqual([]);
    } finally {
      window.removeEventListener('error', captureError);
      if (!firstInjector.destroyed) await first.destroy();
      await second?.destroy();
      dom.wrapper.remove();
    }
  });

  it('does not duplicate click and context menu effects across rerenders', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }, { id: '2' }], configuration: { contextMenuEnabled: true } });
    await harness.render([{ id: '1' }, { id: '2' }]);
    await harness.render([{ id: '2' }, { id: '1' }]);
    const clicked:string[] = [];
    harness.outputs.itemClicked.subscribe(({ workPackageId }) => clicked.push(workPackageId));
    const opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');

    harness.click('1');
    fireEvent.contextMenu(harness.row('2'));

    expect(clicked).toEqual(['1']);
    expect(opened).toHaveBeenCalledTimes(1);
  });
});
