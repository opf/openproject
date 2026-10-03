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

import { ElementRef, Injector, runInInjectionContext } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, waitFor } from '@testing-library/dom';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { EmbeddedTablesMacroComponent } from 'core-app/features/work-packages/components/wp-table/embedded/embedded-tables-macro.component';
import { States } from 'core-app/core/states/states.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageTableConfigurationObject } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { TableUiWork } from './table-ui-work';
import { buildTable, TableHarness, TableHarnessOptions } from './testing/table-harness';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { queryColumnTypes } from 'core-app/features/work-packages/components/wp-query/query-column';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TableEditForm } from 'core-app/features/work-packages/components/wp-edit-form/table-edit-form';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { nextFrame } from 'core-common/testing/timing';
import { buildWorkPackage } from './testing/work-package-fixture';

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

  it('cannot publish over cards after its frame already ran', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }] });
    const frames:FrameRequestCallback[] = [];
    const frameSpy = vi.spyOn(window, 'requestAnimationFrame')
      .mockImplementation((callback) => frames.push(callback));
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    try {
      harness.table.redrawTableAndTimeline();
      frames.shift()!(0);
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
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    try {
      harness.table.redrawTableAndTimeline();
      harness.table.destroy();
      const cards = [{ classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false }];
      harness.querySpace.tableRendered.putValue(cards);
      frames.shift()!(0);
      await vi.runAllTimersAsync();
      expect(harness.tbody.innerHTML).toBe(before);
      expect(harness.querySpace.tableRendered.value).toBe(cards);
    } finally {
      vi.useRealTimers();
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
    vi.spyOn(harness.injector.get(WorkPackageViewOrderService), 'withLoadedPositions').mockReturnValue(loaded.promise);
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

  it('reports a genuinely rejected position load after disposal', async () => {
    const harness = await mount({ workPackages: [{ id: '1' }], configuration: { dragAndDropEnabled: true } });
    const error = new Error('position request');
    let reject!:(reason:unknown) => void;
    const pending = new Promise<QueryOrder>((_resolve, fail) => { reject = fail; });
    vi.spyOn(harness.injector.get(WorkPackageViewOrderService), 'withLoadedPositions').mockReturnValue(pending);
    const report = vi.spyOn(harness.injector.get(WorkPackageNotificationService), 'handleRawError');
    harness.table.redrawTableAndTimeline();
    harness.table.destroy();
    reject(error);
    await waitFor(() => expect(report).toHaveBeenCalledExactlyOnceWith(error));
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

    it('stops redrawing a table once its query space stops', async () => {
      first.querySpace.stopAllSubscriptions.next();

      first.querySpace.results.putValue({ elements: [buildWorkPackage({ id: '9' })] } as WorkPackageCollectionResource);
      first.querySpace.initialized.putValue(null);
      await second.render([{ id: '9', attributes: { status: newStatus } }]);

      expect(second.rowIds()).toEqual(['9']);
      expect(first.rowIds()).toEqual(['1', '2', '3']);
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
