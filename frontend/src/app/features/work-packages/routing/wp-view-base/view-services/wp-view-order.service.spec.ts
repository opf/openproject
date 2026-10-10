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

import { TableDragActionsRegistryService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service';
import { TableDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-action.service';
import { Injector } from '@angular/core';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { PrimaryRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/primary-render-pass';
import { DragDropHandleRenderPass } from 'core-app/features/work-packages/components/wp-fast-table/builders/drag-and-drop/drag-drop-handle-render-pass';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { TestBed } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewOrderService } from './wp-view-order.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { WorkPackageViewSortByService } from './wp-view-sort-by.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

describe('WorkPackageViewOrderService', () => {
  let service:WorkPackageViewOrderService;
  let querySpace:IsolatedQuerySpace;
  let mockUpdateFn:ReturnType<typeof vi.fn>;

  let queryA:QueryResource;
  let queryB:QueryResource;
  let endpointA:{ order:{ get:ReturnType<typeof vi.fn>; update:ReturnType<typeof vi.fn> } };
  let endpointB:typeof endpointA;
  let manual:boolean;
  const reportError = vi.fn();

  function deferred<T>() {
    let resolve!:(value:T) => void;
    let reject!:(error:unknown) => void;
    const promise = new Promise<T>((complete, fail) => { resolve = complete; reject = fail; });
    return { promise, resolve, reject };
  }

  function render() {
    const table = { destroyed: false, configuration: { dragAndDropEnabled: true }, querySpace } as unknown as WorkPackageTable;
    const pass = { draft: { occurrences: [] } } as unknown as PrimaryRenderPass;
    new DragDropHandleRenderPass(TestBed.inject(Injector), table, pass).render();
  }

  class CausedUpdatesServiceStub {
    add = vi.fn();
  }

  class WorkPackageViewSortByServiceStub {
    get isManualSortingMode() { return manual; }
  }

  class PathHelperServiceStub {
  }

  beforeEach(async () => {
    mockUpdateFn = vi.fn().mockResolvedValue(new Date());

    manual = false;
    reportError.mockReset();
    queryA = { id: '123', orderedWorkPackages: { '1': 100, '2': 200 } } as unknown as QueryResource;
    queryB = { id: '456', orderedWorkPackages: { '8': 800 } } as unknown as QueryResource;
    endpointA = { order: { update: mockUpdateFn, get: vi.fn().mockResolvedValue({ '1': 100, '2': 200 }) } };
    endpointB = { order: { update: vi.fn().mockResolvedValue(new Date()), get: vi.fn().mockResolvedValue({ '8': 800 }) } };
    const apiV3ServiceStub = {
      queries: { id: (query:QueryResource) => query === queryA ? endpointA : endpointB },
    };

    await TestBed.configureTestingModule({
      providers: [
        States,
        { provide: TableDragActionsRegistryService, useValue: { get: (injector:Injector) => new TableDragActionService(querySpace, injector) } },
        { provide: WorkPackageNotificationService, useValue: { handleRawError: reportError } },
        IsolatedQuerySpace,
        { provide: ApiV3Service, useValue: apiV3ServiceStub },
        { provide: CausedUpdatesService, useClass: CausedUpdatesServiceStub },
        { provide: WorkPackageViewSortByService, useClass: WorkPackageViewSortByServiceStub },
        { provide: PathHelperService, useClass: PathHelperServiceStub },
        WorkPackageViewOrderService,
      ],
    }).compileComponents();

    service = TestBed.inject(WorkPackageViewOrderService);
    querySpace = TestBed.inject(IsolatedQuerySpace);

    querySpace.query.putValue(queryA);
  });

  describe('remove', () => {
    it('returns filtered order synchronously', () => {
      const order = ['1', '2', '3', '4'];
      const wpId = '2';

      const result = service.remove(order, wpId);

      expect(result).toEqual(['1', '3', '4']);
    });

    it('calls update but does not await it', () => {
      const order = ['1', '2', '3'];
      const wpId = '2';

      const update = vi.spyOn(service, 'update');

      service.remove(order, wpId);

      expect(update).toHaveBeenCalledWith({ [wpId]: -1 });
    });
  });

  describe('move', () => {
    it('rejects an id that is not in the order, without touching it', async () => {
      const order = ['1', '2', '3'];

      await expect(service.move(order, 'gone', 1)).rejects.toThrow('not in the current order');

      expect(order).toEqual(['1', '2', '3']);
      expect(mockUpdateFn).not.toHaveBeenCalled();
    });

    it('rejects an out-of-bounds target index, without touching the order', async () => {
      const order = ['1', '2', '3'];

      await expect(service.move(order, '2', -1)).rejects.toThrow('out of bounds');
      await expect(service.move(order, '2', 3)).rejects.toThrow('out of bounds');

      expect(order).toEqual(['1', '2', '3']);
      expect(mockUpdateFn).not.toHaveBeenCalled();
    });

    it('rejects a target index that is not a whole number', async () => {
      const order = ['1', '2', '3'];

      await expect(service.move(order, '2', NaN)).rejects.toThrow('out of bounds');
      await expect(service.move(order, '2', 1.5)).rejects.toThrow('out of bounds');

      expect(order).toEqual(['1', '2', '3']);
      expect(mockUpdateFn).not.toHaveBeenCalled();
    });

    it('moves the id and persists the new positions', async () => {
      const order = ['1', '2', '3'];

      const result = await service.move(order, '1', 2);

      expect(result).toEqual(['2', '3', '1']);
      expect(mockUpdateFn).toHaveBeenCalled();
    });
  });

  describe('removePersisted', () => {
    it('resolves with filtered order after update resolves', async () => {
      const order = ['1', '2', '3', '4'];
      const wpId = '2';

      const result = await service.removePersisted(order, wpId);

      expect(result).toEqual(['1', '3', '4']);
    });

    it('rejects when update rejects', async () => {
      const order = ['1', '2', '3'];
      const wpId = '2';

      const updateError = new Error('Update failed');
      mockUpdateFn.mockRejectedValueOnce(updateError);

      await expect(service.removePersisted(order, wpId)).rejects.toThrow('Update failed');
    });

    it('filters order the same way as remove', async () => {
      const order = ['1', '2', '3', '4', '5'];
      const wpId = '3';

      const result = await service.removePersisted(order, wpId);

      expect(result).toEqual(['1', '2', '4', '5']);
    });
  });


  describe('captured persistence', () => {
    it('prepares without writing and persists A after navigation during its read', async () => {
      const read = deferred<QueryOrder>();
      endpointA.order.get.mockReturnValue(read.promise);
      let ownsA = true;
      const order = ['1', '2'];
      const beforeB = { ...queryB.orderedWorkPackages };
      const preparing = service.prepareMove(queryA, order, '1', 1, () => ownsA);
      ownsA = false;
      querySpace.query.putValue(queryB);
      await service.update({ '8': 800 });
      endpointB.order.update.mockClear();
      const publish = vi.spyOn(querySpace.query, 'putValue');
      read.resolve({ '1': 100, '2': 200 });
      const prepared = await preparing;
      expect(order).toEqual(['1', '2']);
      expect(prepared.order).toEqual(['2', '1']);
      expect(endpointA.order.update).not.toHaveBeenCalled();
      await prepared.persist();
      expect(endpointA.order.update).toHaveBeenCalledExactlyOnceWith({ '1': 200, '2': 100 });
      expect(endpointB.order.update).not.toHaveBeenCalled();
      expect(querySpace.query.value).toBe(queryB);
      expect(queryB.orderedWorkPackages).toEqual(beforeB);
      expect(publish).not.toHaveBeenCalled();
      expect(await service.positionsFor(queryB)).toEqual(beforeB);
    });

    it('retains unsaved A positions after B becomes current', async () => {
      queryA.id = 'new';
      querySpace.query.putValue(queryB);
      await service.update({ '8': 800 });
      const prepared = await service.prepareAdd(queryA, ['1', '2'], '3', () => false);
      expect(queryA.orderedWorkPackages).toEqual({ '1': 100, '2': 200 });
      await prepared.persist();
      expect(queryA.orderedWorkPackages).toEqual({ '1': 100, '2': 200, '3': 8392 });
      expect(endpointA.order.get).not.toHaveBeenCalled();
      expect(queryB.orderedWorkPackages).toEqual({ '8': 800 });
    });

    it('publishes saved movement and unsaved insertion for live owners', async () => {
      const caused = vi.spyOn(TestBed.inject(CausedUpdatesService), 'add');
      const moved = await service.prepareMove(queryA, ['1', '2'], '1', 1, () => true);
      await moved.persist();
      expect(queryA.orderedWorkPackages).toEqual({ '1': 200, '2': 100 });
      expect(caused).toHaveBeenCalledWith(queryA);
      queryA.id = 'new';
      const added = await service.prepareAdd(queryA, ['2', '1'], '3', () => true, 0);
      await added.persist();
      expect(added.order).toEqual(['3', '2', '1']);
      expect(await service.positionsFor(queryA)).toEqual(queryA.orderedWorkPackages);
      expect(endpointA.order.update).toHaveBeenCalledTimes(1);
    });

    it('propagates an order write failure without mutating the query or publishing a delta', async () => {
      const prepared = await service.prepareMove(queryA, ['1', '2'], '1', 1, () => true);
      endpointA.order.update.mockRejectedValueOnce(new Error('order write failed'));
      const publish = vi.spyOn(querySpace.query, 'putValue');
      await expect(prepared.persist()).rejects.toThrow('order write failed');
      expect(queryA.orderedWorkPackages).toEqual({ '1': 100, '2': 200 });
      expect(await service.positionsFor(queryA)).toEqual({ '1': 100, '2': 200 });
      expect(publish).not.toHaveBeenCalled();
    });

    it('rejects invalid moves before reads or writes', async () => {
      for (const index of [-1, 2, NaN, 0.5]) {
        await expect(service.prepareMove(queryA, ['1', '2'], '1', index, () => true)).rejects.toThrow('out of bounds');
      }
      await expect(service.prepareMove(queryA, ['1', '2'], 'gone', 0, () => true)).rejects.toThrow('not in the current order');
      expect(endpointA.order.get).not.toHaveBeenCalled();
      expect(endpointA.order.update).not.toHaveBeenCalled();
    });

    it('shares initialization and two real render reads without publishing after navigation', async () => {
      manual = true;
      const read = deferred<QueryOrder>();
      endpointA.order.get.mockReturnValue(read.promise);
      service.initialize(queryA);
      render();
      render();
      expect(endpointA.order.get).toHaveBeenCalledTimes(1);
      querySpace.query.putValue(queryB);
      const publish = vi.spyOn(querySpace.query, 'putValue');
      read.resolve({ '1': 100 });
      await read.promise;
      expect(publish).not.toHaveBeenCalled();
      expect(queryB.orderedWorkPackages).toEqual({ '8': 800 });
      expect(endpointB.order.get).not.toHaveBeenCalled();
      await service.positionsFor(queryB);
      expect(endpointB.order.get).toHaveBeenCalledTimes(1);
    });

    it('shares live initialization/rendering and returns independent fresh-cache copies', async () => {
      manual = true;
      const read = deferred<QueryOrder>();
      endpointA.order.get.mockReturnValue(read.promise);
      service.initialize(queryA);
      render();
      render();
      read.resolve({ '1': 100 });
      await read.promise;
      render();
      const copied = await service.positionsFor(queryA);
      copied['1'] = 999;
      expect(await service.positionsFor(queryA)).toEqual({ '1': 100 });
      expect(endpointA.order.get).toHaveBeenCalledTimes(1);
    });

    it('reloads empty and stale cache values', async () => {
      endpointA.order.get.mockResolvedValueOnce({});
      await service.positionsFor(queryA);
      await service.positionsFor(queryA);
      vi.useFakeTimers({ toFake: ['Date'] });
      try {
        vi.setSystemTime(Date.now() + 60001);
        await service.positionsFor(queryA);
        expect(endpointA.order.get).toHaveBeenCalledTimes(3);
      } finally {
        vi.useRealTimers();
      }
    });

    it('does not replace a newer local cache update with a pending read', async () => {
      const read = deferred<QueryOrder>();
      endpointA.order.get.mockReturnValue(read.promise);
      const loading = service.positionsFor(queryA);
      queryA.id = 'new';
      await service.update({ '2': 500 });
      read.resolve({ '1': 100 });
      await loading;
      expect(await service.positionsFor(queryA)).toEqual({ '2': 500 });
    });

    it('observes initialization rejection, reports rendering failure, and retries', async () => {
      manual = true;
      const error = new Error('load positions');
      const report = vi.spyOn(console, 'error').mockImplementation(() => undefined);
      const read = deferred<QueryOrder>();
      endpointA.order.get.mockReturnValueOnce(read.promise);
      service.initialize(queryA);
      render();
      read.reject(error);
      await vi.waitFor(() => expect(reportError).toHaveBeenCalledExactlyOnceWith(error));
      await vi.waitFor(() => expect(report).toHaveBeenCalledExactlyOnceWith('Query order initialization failed', error));
      await expect(service.positionsFor(queryA)).resolves.toEqual({ '1': 100, '2': 200 });
      expect(endpointA.order.get).toHaveBeenCalledTimes(2);
      report.mockRestore();
    });

    it('retains the legacy unsaved fallback and add contract', async () => {
      queryA.id = 'new';
      expect(await service.withLoadedPositions()).toEqual({});
      const order = ['1'];
      expect(await service.add(order, '2')).toBe(order);
      expect(order).toEqual(['1', '2']);
      expect(endpointA.order.get).not.toHaveBeenCalled();
    });
  });
});
