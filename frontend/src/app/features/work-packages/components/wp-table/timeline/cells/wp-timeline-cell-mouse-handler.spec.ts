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

import moment from 'moment';
import { type Mock } from 'vitest';
import { createEnvironmentInjector, DestroyRef, EnvironmentInjector, Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, waitFor } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { clearSelectionOnEscape } from 'core-common/selection-escape';
import { registerWorkPackageMouseHandler } from './wp-timeline-cell-mouse-handler';
import { TimelineCellRenderer } from './timeline-cell-renderer';
import { WorkPackageTimelineCell } from './wp-timeline-cell';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { TimelineMilestoneCellRenderer } from './timeline-milestone-cell-renderer';
import { WorkPackageCellLabels } from './wp-timeline-cell-labels';
import { RenderInfo } from '../wp-timeline';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { buildWorkPackage } from '../../../wp-fast-table/testing/work-package-fixture';

function buildWorkPackageCollection(elements:WorkPackageResource[]):WorkPackageCollectionResource {
  return Object.assign(
    new WorkPackageCollectionResource(TestBed.inject(Injector), {}, true, () => undefined, 'WorkPackageCollection'),
    { elements, count: elements.length, total: elements.length },
  );
}

function mountHandler(sharedCell?:HTMLElement, dead?:'table'|'controller') {
  const tableInjector = createEnvironmentInjector([], TestBed.inject(EnvironmentInjector));
  const controllerInjector = createEnvironmentInjector([], TestBed.inject(EnvironmentInjector));
  const cell = sharedCell ?? document.createElement('div');
  const bar = document.createElement('div');
  cell.appendChild(bar);
  document.body.appendChild(cell);
  const change = {
    clear: vi.fn(),
    isEmpty: () => false,
    projectedResource: { startDate: '2026-01-05', dueDate: '2026-01-06' },
    pristineResource: { duration: null },
  };
  const renderer = {
    type: 'generic',
    render: vi.fn(() => document.createElement('div')),
    createAndAddLabels: vi.fn(() => ({})),
    onMouseDown: vi.fn(() => 'both'),
    onDaysMoved: vi.fn(),
    assignDateValues: vi.fn(),
    update: vi.fn(() => true),
    onMouseDownEnd: vi.fn(),
    isEmpty: vi.fn(() => true),
    displayPlaceholderUnderCursor: vi.fn(() => document.createElement('div')),
    canMoveDates: vi.fn(() => true),
    cursorOrDatesAreNonWorking: vi.fn(() => false),
    cursorDateAndDayOffset: vi.fn(() => [moment('2026-01-05'), 0]),
  };
  let resolveSave!:(value:{ resource:WorkPackageResource }) => void;
  let rejectSave!:(error:unknown) => void;
  const saved = new Promise<{ resource:WorkPackageResource }>((resolve, reject) => {
    resolveSave = resolve;
    rejectSave = reject;
  });
  const save = vi.fn(() => saved);
  const events = { push: vi.fn() } satisfies Pick<HalEventsService, 'push'>;
  const notifications = { showSave: vi.fn(), handleRawError: vi.fn() } satisfies Pick<WorkPackageNotificationService, 'showSave'|'handleRawError'>;
  const loading = { table: { promise: undefined as Promise<unknown>|undefined } };
  const refreshed = new Subject<WorkPackageCollectionResource>();
  const timelineRendered = new Subject<void>();
  const querySpace = { tableRendered: { value: [{ workPackageId: '1' }] }, timelineRendered };
  const api = { work_packages: { filterUpdatedSince: vi.fn(() => ({ get: () => refreshed })) } };
  const injector = Injector.create({ providers: [
    { provide: ApiV3Service, useValue: api },
    { provide: IsolatedQuerySpace, useValue: querySpace },
    { provide: HalResourceEditingService, useValue: { changeFor: () => change, save } },
    { provide: HalEventsService, useValue: events },
    { provide: WorkPackageNotificationService, useValue: notifications },
    { provide: LoadingIndicatorService, useValue: loading },
    { provide: SchemaCacheService, useValue: { of: () => ({ isMilestone: false }) } },
  ] });
  const resource = buildWorkPackage({ id: '1', attributes: { isLeaf: true, scheduleManually: false } });
  const renderInfo = {
    workPackage: resource,
    viewParams: { pixelPerDay: 10, dateDisplayStart: moment('2026-01-01'), activeSelectionMode: null },
  } as unknown as RenderInfo;
  const table = { destroyRef: tableInjector.get(DestroyRef), destroy: () => tableInjector.destroy() };
  const timeline = {
    destroyRef: controllerInjector.get(DestroyRef),
    workPackageTable: table,
    timelineBody: cell,
    disableViewParamsCalculation: false,
    getAbsoluteLeftCoordinates: () => 0,
    resetCursor: vi.fn(),
    refreshView: vi.fn(),
  };
  if (dead === 'table') tableInjector.destroy();
  if (dead === 'controller') controllerInjector.destroy();
  const unregister = registerWorkPackageMouseHandler(
    injector, () => renderInfo, timeline as unknown as WorkPackageTimelineTableController,
    { changeFor: () => change, save } as unknown as HalResourceEditingService,
    events as unknown as HalEventsService, notifications as unknown as WorkPackageNotificationService,
    loading as LoadingIndicatorService, cell, bar, {} as WorkPackageCellLabels,
    renderer as unknown as TimelineCellRenderer, renderInfo,
  );
  return { cell, bar, injector, renderInfo, change, renderer, save, events, notifications, loading, refreshed,
    timelineRendered, api, resource, timeline, tableInjector, controllerInjector, unregister,
    resolveSave, rejectSave,
    finishRefresh() {
      refreshed.next(buildWorkPackageCollection([resource]));
      refreshed.complete();
    },
    destroy() {
      unregister();
      if (!tableInjector.destroyed) tableInjector.destroy();
      if (!controllerInjector.destroyed) controllerInjector.destroy();
      injector.destroy();
      cell.remove();
    },
  };
}

describe('registerWorkPackageMouseHandler', () => {
  const mounts:ReturnType<typeof mountHandler>[] = [];
  let m:ReturnType<typeof mountHandler>;
  let clear:Mock<() => void>;
  let selectionListener:(event:Event) => void;
  function mount(sharedCell?:HTMLElement, dead?:'table'|'controller') {
    const value = mountHandler(sharedCell, dead);
    mounts.push(value);
    return value;
  }
  beforeEach(() => {
    TestBed.configureTestingModule({});
    m = mount();
    clear = vi.fn();
    selectionListener = (event) => clearSelectionOnEscape(event as KeyboardEvent, () => true, clear);
    document.addEventListener('keydown', selectionListener);
  });
  afterEach(() => {
    document.removeEventListener('keydown', selectionListener);
    mounts.splice(0).forEach((value) => value.destroy());
  });
  const escape = { key: 'Escape' };
  function startBarDrag(value = m) { fireEvent.mouseDown(value.bar, { button: 0, clientX: 0 }); }
  function startEmptyCellDrag() {
    fireEvent.mouseMove(m.cell, { clientX: 0 });
    fireEvent.mouseDown(m.cell, { button: 0, clientX: 0 });
  }
  describe.each([
    ['an existing bar', () => startBarDrag()],
    ['an empty cell', () => startEmptyCellDrag()],
  ])('while dragging %s', (_name, startDrag) => {
    it('keeps the Escape keydown from clearing the selection', () => {
      startDrag();
      expect(fireEvent.keyDown(document.body, escape)).toBe(false);
      expect(clear).not.toHaveBeenCalled();
    });
    it('still cancels the drag on keyup and frees the next Escape', () => {
      startDrag();
      fireEvent.keyDown(document.body, escape);
      fireEvent.keyUp(document.body, escape);
      expect(m.change.clear).toHaveBeenCalledOnce();
      expect(m.renderer.onMouseDownEnd).toHaveBeenCalledOnce();
      expect(m.save).not.toHaveBeenCalled();
      fireEvent.keyDown(document.body, escape);
      expect(clear).toHaveBeenCalledOnce();
    });
    it('disposes input without saving, resetting the changeset, or continuing rendering', () => {
      startDrag();
      m.renderer.update.mockClear();
      m.timeline.workPackageTable.destroy();
      fireEvent.mouseMove(document.body, { clientX: 40 });
      fireEvent.mouseUp(document.body);
      fireEvent.keyUp(document.body, escape);
      expect(m.save).not.toHaveBeenCalled();
      expect(m.change.clear).not.toHaveBeenCalled();
      expect(m.renderer.update).not.toHaveBeenCalled();
      expect(m.renderer.onMouseDownEnd).not.toHaveBeenCalled();
      expect(m.timeline.refreshView).not.toHaveBeenCalled();
      expect(m.timeline.resetCursor).toHaveBeenCalledOnce();
      expect(m.bar).not.toHaveClass('active-drag');
    });
  });
  it('lets Escape clear the selection when no drag is active', () => {
    expect(fireEvent.keyDown(document.body, escape)).toBe(false);
    expect(clear).toHaveBeenCalledOnce();
  });
  it('preserves another controller gesture when one is disposed', () => {
    const second = mount();
    startBarDrag();
    startBarDrag(second);
    m.timeline.workPackageTable.destroy();
    fireEvent.mouseMove(document.body, { clientX: 40 });
    expect(m.renderer.update).not.toHaveBeenCalled();
    expect(second.renderer.update).toHaveBeenCalledOnce();
    fireEvent.keyUp(document.body, escape);
    expect(second.change.clear).toHaveBeenCalledOnce();
    expect(m.change.clear).not.toHaveBeenCalled();
  });
  it('keeps the latest shared header handler when an old registration retires', () => {
    const second = mount(m.cell);
    m.timeline.workPackageTable.destroy();
    fireEvent.mouseMove(m.cell);
    expect(m.renderer.displayPlaceholderUnderCursor).not.toHaveBeenCalled();
    expect(second.renderer.displayPlaceholderUnderCursor).toHaveBeenCalledOnce();
  });
  it.each(['table', 'controller'] as const)('ignores registration on an already-destroyed %s', (dead) => {
    const value = mount(undefined, dead);
    fireEvent.mouseDown(value.bar);
    fireEvent.mouseMove(value.cell);
    fireEvent.mouseUp(document.body);
    expect(value.save).not.toHaveBeenCalled();
    expect(value.renderer.onMouseDown).not.toHaveBeenCalled();
    expect(value.cell.onmousemove).toBeNull();
  });
  it('keeps submitted persistence and refresh alive after table disposal', async () => {
    startBarDrag();
    fireEvent.mouseUp(document.body);
    expect(m.save).toHaveBeenCalledOnce();
    let settled = false;
    void m.loading.table.promise!.then(() => { settled = true; });
    m.timeline.workPackageTable.destroy();
    await Promise.resolve();
    expect(settled).toBe(false);
    m.resolveSave({ resource: m.resource });
    await waitFor(() => expect(m.refreshed.observed).toBe(true));
    expect(m.api.work_packages.filterUpdatedSince).toHaveBeenCalledWith(['1'], expect.any(String));
    m.finishRefresh();
    await waitFor(() => expect(settled).toBe(true));
    expect(m.notifications.showSave).toHaveBeenCalledWith(m.resource);
    expect(m.events.push).toHaveBeenCalledWith(m.resource, { eventType: 'updated' });
    expect(m.change.clear).not.toHaveBeenCalled();
    expect(m.renderer.onMouseDownEnd).not.toHaveBeenCalled();
  });
  it.each(['table', 'controller'] as const)('settles the render wait on %s disposal', async (owner) => {
    startBarDrag();
    fireEvent.mouseUp(document.body);
    m.resolveSave({ resource: m.resource });
    await waitFor(() => expect(m.refreshed.observed).toBe(true));
    m.finishRefresh();
    await waitFor(() => expect(m.timelineRendered.observed).toBe(true));
    m[owner === 'table' ? 'tableInjector' : 'controllerInjector'].destroy();
    await m.loading.table.promise;
    expect(m.timelineRendered.observed).toBe(false);
    expect(m.change.clear).not.toHaveBeenCalled();
    expect(m.renderer.onMouseDownEnd).not.toHaveBeenCalled();
  });
  it('reports a submitted save failure once after disposal without resetting', async () => {
    startBarDrag();
    fireEvent.mouseUp(document.body);
    m.timeline.workPackageTable.destroy();
    const error = new Error('save failed');
    m.rejectSave(error);
    await expect(m.loading.table.promise).rejects.toBe(error);
    await waitFor(() => expect(m.notifications.handleRawError).toHaveBeenCalledExactlyOnceWith(error, m.resource));
    expect(m.change.clear).not.toHaveBeenCalled();
    expect(m.renderer.onMouseDownEnd).not.toHaveBeenCalled();
  });
  it('finishes a normal submitted save after rendering', async () => {
    startBarDrag();
    fireEvent.mouseUp(document.body);
    m.resolveSave({ resource: m.resource });
    await waitFor(() => expect(m.refreshed.observed).toBe(true));
    m.finishRefresh();
    await waitFor(() => expect(m.timelineRendered.observed).toBe(true));
    m.timelineRendered.next();
    await m.loading.table.promise;
    await waitFor(() => expect(m.change.clear).toHaveBeenCalledOnce());
    expect(m.renderer.onMouseDownEnd).toHaveBeenCalledOnce();
  });
  function makeCell() {
    m.unregister();
    const host = document.createElement('div');
    host.className = 'test-cell';
    m.cell.appendChild(host);
    const cell = new WorkPackageTimelineCell(
      m.injector, m.timeline as unknown as WorkPackageTimelineTableController,
      { generic: m.renderer as unknown as TimelineCellRenderer, milestone: m.renderer as unknown as TimelineMilestoneCellRenderer },
      m.renderInfo, 'test-cell', '1',
    );
    return { cell, host };
  }

  it('unregisters a cleared cell before creating its replacement', async () => {
    const { cell, host } = makeCell();
    cell.refreshView(m.renderInfo);
    await Promise.resolve();
    const oldBar = host.firstElementChild!;
    fireEvent.mouseDown(oldBar);
    cell.clear();
    fireEvent.mouseUp(document.body);
    fireEvent.mouseDown(oldBar);
    expect(m.save).not.toHaveBeenCalled();
    expect(m.renderer.onMouseDown).toHaveBeenCalledOnce();
    cell.refreshView(m.renderInfo);
    await Promise.resolve();
    fireEvent.mouseDown(host.firstElementChild!);
    expect(m.renderer.onMouseDown).toHaveBeenCalledTimes(2);
    fireEvent.keyUp(document.body, escape);
    cell.clear();
  });

  it('does not update a lazy cell after its captured attachment is retired', async () => {
    const { cell } = makeCell();
    cell.refreshView(m.renderInfo);
    m.tableInjector.destroy();
    m.timeline.workPackageTable = { destroyRef: m.controllerInjector.get(DestroyRef), destroy: () => undefined };
    await Promise.resolve();
    expect(m.renderer.update).not.toHaveBeenCalled();
    cell.clear();
  });

});
