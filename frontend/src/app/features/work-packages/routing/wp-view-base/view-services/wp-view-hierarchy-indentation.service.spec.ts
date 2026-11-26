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

import { computed } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { WorkPackageViewHierarchyIdentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service';
import { WorkPackageViewDisplayRepresentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { Observable, of, Subject, throwError } from 'rxjs';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import type { MockedObject } from 'vitest';
type SpyObj<T> = MockedObject<T>;

describe('WorkPackageViewIndentation service', () => {
  let service:WorkPackageViewHierarchyIdentationService;
  let states:States;
  let querySpace:IsolatedQuerySpace;
  let parentServiceSpy:SpyObj<any>;
  let hierarchyServiceStub:any;
  let loadWorkPackage:(wpId:string) => Observable<unknown>;
  const notifications = { showSave: vi.fn(), handleRawError: vi.fn() };
  const toasts = { addWarning: vi.fn(), addError: vi.fn() };

  class HierarchyServiceStub {
    get isEnabled() {
      return true;
    }
  }

  class ApiV3serviceStub {
    work_packages = {
      id: (wpId:string) => ({
        get: () => loadWorkPackage(wpId),
      }),
    };
  }

  beforeEach(async () => {
    parentServiceSpy = {
      changeParent: vi.fn().mockName('WorkPackageRelationHierarchyService.changeParent')
    };

    parentServiceSpy.changeParent.mockResolvedValue();
    vi.clearAllMocks();
    parentServiceSpy.changeParent.mockResolvedValue();
    loadWorkPackage = (wpId) => of(states.workPackages.get(wpId).value);

    await TestBed.configureTestingModule({
      providers: [
        States,
        IsolatedQuerySpace,
        { provide: WorkPackageViewDisplayRepresentationService, useValue: { isList: true } },
        { provide: ApiV3Service, useClass: ApiV3serviceStub },
        { provide: WorkPackageViewHierarchiesService, useClass: HierarchyServiceStub },
        { provide: WorkPackageRelationsHierarchyService, useValue: parentServiceSpy },
        { provide: WorkPackageNotificationService, useValue: notifications },
        { provide: ToastService, useValue: toasts },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        WorkPackageViewHierarchyIdentationService,
      ],
    }).compileComponents();
    service = TestBed.inject(WorkPackageViewHierarchyIdentationService);
    querySpace = TestBed.inject(IsolatedQuerySpace);
    hierarchyServiceStub = TestBed.inject(WorkPackageViewHierarchiesService);
    states = TestBed.inject(States);
  });

  describe('canIndent', () => {
    it('Cannot indent without changeParent link', () => {
      const workPackage:any = { id: '1234' };

      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Cannot indent when is first index', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo' };

      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can indent as second when it has no ancestors', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };

      expect(service.canIndent(workPackage)).toBeTruthy();
    });

    it('Cannot indent when possible but hierarchy disabled', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      vi.spyOn(hierarchyServiceStub, 'isEnabled', 'get').mockReturnValue(false);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };

      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can not indent with a predecessor that is an ancestor already', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['2345'] };

      expect(service.canIndent(workPackage)).toBeFalsy();
    });

    it('Can indent with a predecessor that is NOT an ancestor already', () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['2345'] };

      expect(service.canIndent(workPackage)).toBeTruthy();
    });
  });

  describe('canOutdent', () => {
    it('Cannot outdent without changeParent link', () => {
      const workPackage:any = { id: '1234' };

      expect(service.canOutdent(workPackage)).toBeFalsy();
    });

    it('Cannot outdent with changeParent link but disabled', () => {
      const workPackage:any = { id: '1234', changeParent: () => 'foo', parent: { id: '2345' } };

      vi.spyOn(hierarchyServiceStub, 'isEnabled', 'get').mockReturnValue(false);

      expect(service.canOutdent(workPackage)).toBeFalsy();
    });

    it('can outdent with changeParent link', () => {
      const workPackage:any = { id: '1234', changeParent: () => 'foo', parent: { id: '2345' } };

      expect(service.canOutdent(workPackage)).toBeTruthy();
    });
  });

  describe('indent', () => {
    it('Can indent with a predecessor that is NOT an ancestor already', async () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      const predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: [] };

      states.workPackages.get('2345').putValue(predecessor);

      void service.indent(workPackage);

      await vi.waitFor(() => expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345', { notify: false, origin: querySpace }));
    });

    it('can indent next to a nested predecessor', async () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: [] };
      const predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: ['5555'] };

      states.workPackages.get('2345').putValue(predecessor);

      void service.indent(workPackage);

      await vi.waitFor(() => expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '5555', { notify: false, origin: querySpace }));
    });

    it('Can indent with a predecessor that shares an ancestor chain', async () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '5555', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = { id: '1234', changeParent: () => 'foo', ancestorIds: ['5555'] };
      const predecessor:any = { id: '2345', changeParent: () => 'foo', ancestorIds: ['5555'] };

      states.workPackages.get('2345').putValue(predecessor);

      void service.indent(workPackage);

      await vi.waitFor(() => expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345', { notify: false, origin: querySpace }));
    });
  });

  describe('outdent', () => {
    it('will outdent to the previous last ancestorId', async () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = {
        id: '1234', changeParent: () => 'foo', parent: '5555', ancestorIds: ['2345', '5555'],
      };

      void service.outdent(workPackage);

      await vi.waitFor(() => expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, '2345', { notify: false, origin: querySpace }));
    });

    it('will outdent to null in case of ancestorIds.length < 2', async () => {
      querySpace.tableRendered.putValue([
        { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      ]);

      const workPackage:any = {
        id: '1234', changeParent: () => 'foo', parent: '2345', ancestorIds: ['2345'],
      };

      void service.outdent(workPackage);

      await vi.waitFor(() => expect(parentServiceSpy.changeParent).toHaveBeenCalledWith(workPackage, null, { notify: false, origin: querySpace }));
    });
  });

  describe('running an indent or outdent', () => {
    const rows = [
      { workPackageId: '2345', hidden: false, classIdentifier: 'foo' },
      { workPackageId: '1234', hidden: false, classIdentifier: 'foo' },
      { workPackageId: '5678', hidden: false, classIdentifier: 'foo' },
    ];
    let child:WorkPackageResource;
    let otherChild:WorkPackageResource;
    let second:WorkPackageResource;
    let reload:ReturnType<typeof deferred<void>>;
    let laterReload:ReturnType<typeof deferred<void>>;
    let reloadTable:ReturnType<typeof vi.fn>;

    const buildWorkPackage = (attributes:Record<string, unknown>) => attributes as unknown as WorkPackageResource;

    function deferred<T>() {
      let resolve!:(value:T) => void;
      let reject!:(reason:unknown) => void;
      const promise = new Promise<T>((res, rej) => {
        resolve = res;
        reject = rej;
      });
      promise.catch(() => undefined);
      return { promise, resolve, reject };
    }

    const rerender = () => {
      querySpace.tableRendered.clear('test');
      querySpace.tableRendered.putValue(rows);
    };

    const saved = () => vi.waitFor(() => expect(parentServiceSpy.changeParent).toHaveBeenCalled());
    const reloadRequested = () => vi.waitFor(() => expect(reloadTable).toHaveBeenCalled());
    const outcomeOf = (operation:Promise<void>) => operation.then(() => 'resolved', (error:unknown) => error);
    const destroyService = () => TestBed.resetTestingModule();

    beforeEach(() => {
      querySpace.tableRendered.putValue(rows);
      child = buildWorkPackage({ id: '1234', changeParent: () => 'foo', parent: '2345', ancestorIds: ['2345'] });
      otherChild = buildWorkPackage({ id: '5678', changeParent: () => 'foo', parent: '2345', ancestorIds: ['2345'] });
      second = buildWorkPackage({ id: '1234', changeParent: () => 'foo', ancestorIds: [] });
      states.workPackages.get('2345').putValue(buildWorkPackage({ id: '2345', ancestorIds: [] }));
      reload = deferred<void>();
      laterReload = deferred<void>();
      reloadTable = vi.fn()
        .mockReturnValueOnce(reload.promise)
        .mockReturnValue(laterReload.promise);
      querySpace.reloadTable.putValue(reloadTable as () => Promise<void>);
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it('claims the table before sending anything', () => {
      void service.outdent(child);

      expect(querySpace.tableOperation.hasValue()).toBe(true);
      expect(parentServiceSpy.changeParent).not.toHaveBeenCalled();
    });

    it('settles for its caller only after the table was released', async () => {
      const order:string[] = [];
      const done = service.outdent(child);
      void querySpace.tableOperation.value!.then(() => order.push('table released'));
      void done.then(() => order.push('caller'));

      await reloadRequested();
      reload.resolve();
      await done;

      expect(order).toEqual(['table released', 'caller']);
    });

    it('reloads the table only once the change is saved', async () => {
      const patch = deferred<void>();
      parentServiceSpy.changeParent.mockReturnValue(patch.promise);
      void service.outdent(child);
      await saved();
      expect(reloadTable).not.toHaveBeenCalled();

      patch.resolve();

      await reloadRequested();
      expect(reloadTable).toHaveBeenCalledTimes(1);
    });

    it('shows the toast only after its reload has been rendered', async () => {
      const done = service.outdent(child);
      await reloadRequested();
      expect(notifications.showSave).not.toHaveBeenCalled();
      expect(querySpace.tableOperation.hasValue()).toBe(true);

      reload.resolve();
      await done;

      expect(notifications.showSave).toHaveBeenCalledExactlyOnceWith(child);
      expect(querySpace.tableOperation.hasValue()).toBe(false);
      expect(service.canOutdent(child)).toBe(true);
    });

    it('does not take another render of the table for its own reload', async () => {
      void service.outdent(child);
      await reloadRequested();

      rerender();
      await new Promise((resolve) => { setTimeout(resolve); });

      expect(notifications.showSave).not.toHaveBeenCalled();
      expect(querySpace.tableOperation.hasValue()).toBe(true);
    });

    it('offers no hierarchy change while one is in flight', async () => {
      void service.outdent(child);

      expect(service.canOutdent(otherChild)).toBe(false);
      expect(service.canIndent(otherChild)).toBe(false);
      await expect(service.outdent(otherChild)).rejects.toBeUndefined();
      await saved();
      expect(parentServiceSpy.changeParent).toHaveBeenCalledTimes(1);
    });

    it('lets a reactive reader follow whether a hierarchy change is possible', async () => {
      const outdentable = computed(() => service.canOutdent(otherChild));
      expect(outdentable()).toBe(true);

      const done = service.outdent(child);
      expect(outdentable()).toBe(false);

      await reloadRequested();
      reload.resolve();
      await done;
      expect(outdentable()).toBe(true);
    });

    describe('when the change is rejected', () => {
      let outcome:Promise<unknown>;

      beforeEach(() => {
        parentServiceSpy.changeParent.mockRejectedValue(new Error('conflict'));
      });

      it('keeps the table until a reload shows what the server holds', async () => {
        outcome = outcomeOf(service.outdent(child));
        await reloadRequested();
        expect(querySpace.tableOperation.hasValue()).toBe(true);

        reload.resolve();

        expect(await outcome).toMatchObject({ message: 'conflict' });
        expect(querySpace.tableOperation.hasValue()).toBe(false);
        expect(service.canOutdent(child)).toBe(true);
        expect(reloadTable).toHaveBeenCalledTimes(1);
        expect(notifications.showSave).not.toHaveBeenCalled();
        expect(notifications.handleRawError).not.toHaveBeenCalled();
        expect(toasts.addWarning).not.toHaveBeenCalled();
      });

      it('releases the table with a warning when that reload fails, and tries again once the table renders', async () => {
        outcome = outcomeOf(service.outdent(child));
        await reloadRequested();

        reload.reject(new Error('unavailable'));

        expect(await outcome).toMatchObject({ message: 'conflict' });
        expect(toasts.addWarning).toHaveBeenCalledTimes(1);
        expect(service.canOutdent(child)).toBe(false);

        rerender();
        expect(reloadTable).toHaveBeenCalledTimes(2);
        expect(service.canOutdent(child)).toBe(false);

        laterReload.resolve();
        await vi.waitFor(() => expect(service.canOutdent(child)).toBe(true));
      });

      it('keeps the table for as long as that reload takes', async () => {
        vi.useFakeTimers();
        outcome = outcomeOf(service.outdent(child));

        await vi.advanceTimersByTimeAsync(60_000);

        expect(querySpace.tableOperation.hasValue()).toBe(true);
        expect(toasts.addWarning).not.toHaveBeenCalled();

        reload.resolve();

        expect(await outcome).toMatchObject({ message: 'conflict' });
        expect(querySpace.tableOperation.hasValue()).toBe(false);
        expect(service.canOutdent(child)).toBe(true);
        expect(toasts.addWarning).not.toHaveBeenCalled();
      });
    });

    it('reports and releases the table when loading the predecessor fails', async () => {
      const failure = new Error('not found');
      loadWorkPackage = () => throwError(() => failure);

      await expect(service.indent(second)).rejects.toBe(failure);

      expect(notifications.handleRawError).toHaveBeenCalledExactlyOnceWith(failure, second);
      expect(parentServiceSpy.changeParent).not.toHaveBeenCalled();
      expect(reloadTable).not.toHaveBeenCalled();
      expect(querySpace.tableOperation.hasValue()).toBe(false);
      expect(service.canIndent(second)).toBe(true);
    });

    it('gives up on a predecessor that never loads and sends nothing later', async () => {
      vi.useFakeTimers();
      const loading = new Subject<unknown>();
      loadWorkPackage = () => loading;
      const outcome = outcomeOf(service.indent(second));

      await vi.advanceTimersByTimeAsync(30_000);
      expect(await outcome).toBeInstanceOf(Error);
      expect(querySpace.tableOperation.hasValue()).toBe(false);
      expect(toasts.addError).toHaveBeenCalledTimes(1);
      expect(toasts.addWarning).not.toHaveBeenCalled();

      loading.next({ id: '2345', ancestorIds: [] });
      loading.complete();
      await vi.advanceTimersByTimeAsync(0);

      expect(parentServiceSpy.changeParent).not.toHaveBeenCalled();
      expect(service.canIndent(second)).toBe(true);
    });

    describe('when the change does not return in time', () => {
      let patch:ReturnType<typeof deferred<void>>;
      let outcome:Promise<unknown>;

      beforeEach(async () => {
        vi.useFakeTimers();
        patch = deferred<void>();
        parentServiceSpy.changeParent.mockReturnValue(patch.promise);
        outcome = outcomeOf(service.outdent(child));
        await vi.advanceTimersByTimeAsync(30_000);
      });

      it('releases the table with a warning and keeps hierarchy changes off', async () => {
        expect(await outcome).toBeInstanceOf(Error);
        expect(querySpace.tableOperation.hasValue()).toBe(false);
        expect(toasts.addWarning).toHaveBeenCalledTimes(1);
        expect(service.canOutdent(child)).toBe(false);
        expect(reloadTable).not.toHaveBeenCalled();
      });

      it.each([
        ['succeeds', () => patch.resolve()],
        ['fails', () => patch.reject(new Error('conflict'))],
      ])('reloads once the change %s after all, and then allows hierarchy changes again', async (_outcome, settle) => {
        settle();
        await vi.advanceTimersByTimeAsync(0);
        expect(reloadTable).toHaveBeenCalledTimes(1);
        expect(service.canOutdent(child)).toBe(false);

        reload.resolve();
        await vi.advanceTimersByTimeAsync(0);

        expect(service.canOutdent(child)).toBe(true);
        expect(notifications.showSave).not.toHaveBeenCalled();
      });
    });

    it('keeps the table until its reload is rendered, however long that takes', async () => {
      vi.useFakeTimers();
      const done = service.outdent(child);

      await vi.advanceTimersByTimeAsync(60_000);

      expect(querySpace.tableOperation.hasValue()).toBe(true);
      expect(notifications.showSave).not.toHaveBeenCalled();
      expect(toasts.addWarning).not.toHaveBeenCalled();

      reload.resolve();
      await done;

      expect(notifications.showSave).toHaveBeenCalledTimes(1);
      expect(toasts.addWarning).not.toHaveBeenCalled();
      expect(querySpace.tableOperation.hasValue()).toBe(false);
      expect(service.canOutdent(child)).toBe(true);
    });

    it('warns at once when its reload fails, and recovers with the next reload of the table', async () => {
      const done = service.outdent(child);
      await reloadRequested();

      reload.reject(new Error('unavailable'));
      await done;

      expect(notifications.showSave).not.toHaveBeenCalled();
      expect(toasts.addWarning).toHaveBeenCalledTimes(1);
      expect(service.canOutdent(child)).toBe(false);

      rerender();
      expect(reloadTable).toHaveBeenCalledTimes(2);
      laterReload.resolve();
      await vi.waitFor(() => expect(service.canOutdent(child)).toBe(true));
    });

    it('treats a table that cannot be reloaded as out of date', async () => {
      querySpace.reloadTable.clear('no view');

      await service.outdent(child);

      expect(notifications.showSave).not.toHaveBeenCalled();
      expect(toasts.addWarning).toHaveBeenCalledTimes(1);
      expect(service.canOutdent(child)).toBe(false);
    });

    it('does not claim the table when the action is not possible', async () => {
      await expect(service.indent(buildWorkPackage({ id: '9999' }))).rejects.toBeUndefined();

      expect(querySpace.tableOperation.hasValue()).toBe(false);
    });

    describe('when destroyed', () => {
      const nothingFurtherHappens = async () => {
        await vi.advanceTimersByTimeAsync(40_000);
        expect(toasts.addWarning).not.toHaveBeenCalled();
        expect(toasts.addError).not.toHaveBeenCalled();
        expect(notifications.showSave).not.toHaveBeenCalled();
        expect(vi.getTimerCount()).toBe(0);
      };

      beforeEach(() => {
        vi.useFakeTimers();
      });

      it('while loading the predecessor, settles and never sends the change', async () => {
        const loading = new Subject<unknown>();
        loadWorkPackage = () => loading;
        const outcome = outcomeOf(service.indent(second));
        await vi.advanceTimersByTimeAsync(0);

        destroyService();
        expect(await outcome).toBe('resolved');

        loading.next({ id: '2345', ancestorIds: [] });
        loading.complete();
        await vi.advanceTimersByTimeAsync(0);
        expect(parentServiceSpy.changeParent).not.toHaveBeenCalled();
        await nothingFurtherHappens();
      });

      it('while saving, settles and does nothing when the change returns', async () => {
        const patch = deferred<void>();
        parentServiceSpy.changeParent.mockReturnValue(patch.promise);
        const outcome = outcomeOf(service.outdent(child));
        await vi.advanceTimersByTimeAsync(0);

        destroyService();
        expect(await outcome).toBe('resolved');

        patch.resolve();
        await vi.advanceTimersByTimeAsync(0);
        expect(reloadTable).not.toHaveBeenCalled();
        await nothingFurtherHappens();
      });

      it('while waiting for its reload, settles and releases the table', async () => {
        const outcome = outcomeOf(service.outdent(child));
        await vi.advanceTimersByTimeAsync(0);
        expect(reloadTable).toHaveBeenCalledTimes(1);

        destroyService();
        expect(await outcome).toBe('resolved');
        expect(querySpace.tableOperation.hasValue()).toBe(false);

        reload.resolve();
        await nothingFurtherHappens();
      });
    });
  });
});
