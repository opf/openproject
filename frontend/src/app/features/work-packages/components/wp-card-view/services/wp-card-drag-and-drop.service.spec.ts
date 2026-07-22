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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  Component, inject, input, signal,
} from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import {
  NativeDragSimulation,
  towardsEdgeOf,
} from 'core-common/drag-and-drop/testing/native-drag-simulation';
import { OpSortableListsDirective } from 'core-app/shared/directives/sortable-lists/sortable-lists.directive';
import { OpSortableListsListDirective } from 'core-app/shared/directives/sortable-lists/sortable-lists-list.directive';
import { OpSortableListsItemDirective } from 'core-app/shared/directives/sortable-lists/sortable-lists-item.directive';
import type {
  SortableListsDropEvent,
  SortableListsRemovedEvent,
} from 'core-app/shared/directives/sortable-lists/sortable-lists.directive';
import { WorkPackageCardDragAndDropService } from './wp-card-drag-and-drop.service';

// The list id this service instance owns in every unit-level (non-DOM) test
// below — matches `cardView.resolvedListId` so `handleDrop` resolves events
// with this id as the source as a SAME-list move.
const LIST_ID = 'list-under-test';

function buildWp(id:string):WorkPackageResource {
  return { id } as unknown as WorkPackageResource;
}

function idsOf(list:WorkPackageResource[]):(string|null)[] {
  return list.map((wp) => wp.id);
}

function deferred<T>():{ promise:Promise<T>; resolve:(value:T) => void; reject:(error:unknown) => void } {
  let resolve!:(value:T) => void;
  let reject!:(error:unknown) => void;
  const promise = new Promise<T>((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}

// Flushes every pending microtask (a fixed number of `await Promise.resolve()`
// hops is fragile against chain length changes; a macrotask boundary is not).
function flush():Promise<void> {
  return new Promise((resolve) => { setTimeout(resolve, 0); });
}

// Mirrors WorkPackageViewOrderService#move/#add mutating `order` in place —
// used by rejection-path tests to prove rollback restores the true pre-move
// order rather than the (already-mutated) array handed to the stub.
function mutateMove(order:string[], wpId:string, toIndex:number):void {
  const fromIndex = order.findIndex((id) => id === wpId);
  order.splice(fromIndex, 1);
  order.splice(toIndex, 0, wpId);
}

function mutateAdd(order:string[], wpId:string, toIndex:number):void {
  order.splice(toIndex, 0, wpId);
}

// `reorderServiceStub`'s fields are typed via the ambient (default-generic)
// `ReturnType<typeof vi.fn>`, under which `mockImplementation`'s parameter
// infers as void-returning. Narrow locally so a mutating-then-rejecting stub
// (mirroring the real service) type-checks and lints clean.
function mockRejectAfterMutating(
  mock:unknown,
  mutate:(order:string[], wpId:string, toIndex:number) => void,
  error:Error,
):void {
  (mock as { mockImplementation(fn:(order:string[], wpId:string, toIndex:number) => Promise<string[]>):void })
    .mockImplementation((order, wpId, toIndex) => {
      mutate(order, wpId, toIndex);
      return Promise.reject(error);
    });
}

function buildDropEvent(overrides:{
  sourceId:string;
  sourceListId?:string;
  targetId?:string|null;
  edge?:SortableListsDropEvent['edge'];
  complete?:SortableListsDropEvent['complete'];
}):SortableListsDropEvent {
  return {
    transactionId: 'txn-drop',
    sourceId: overrides.sourceId,
    sourceListId: overrides.sourceListId ?? LIST_ID,
    targetId: overrides.targetId ?? null,
    edge: overrides.edge ?? null,
    complete: overrides.complete ?? vi.fn(),
  };
}

function buildRemovedEvent(overrides:{
  itemId:string;
  completion:Promise<boolean>;
  targetListId?:string;
  finalize?:SortableListsRemovedEvent['finalize'];
}):SortableListsRemovedEvent {
  return {
    transactionId: 'txn-removed',
    itemId: overrides.itemId,
    targetListId: overrides.targetListId ?? 'some-other-list',
    completion: overrides.completion,
    finalize: overrides.finalize ?? vi.fn(),
  };
}

describe('WorkPackageCardDragAndDropService', () => {
  let service:WorkPackageCardDragAndDropService;
  let states:States;
  let reorderServiceStub:{
    move:ReturnType<typeof vi.fn>;
    add:ReturnType<typeof vi.fn>;
    remove:ReturnType<typeof vi.fn>;
    removePersisted:ReturnType<typeof vi.fn>;
    orderedWorkPackages:ReturnType<typeof vi.fn>;
  };
  let notificationStub:{ handleRawError:ReturnType<typeof vi.fn> };
  let cardView:{
    cdRef:{ detectChanges:ReturnType<typeof vi.fn> };
    onMoved:{ emit:ReturnType<typeof vi.fn> };
    workPackageAddedHandler:ReturnType<typeof vi.fn>;
    resolvedListId:string;
  };

  function seed(...ids:string[]):void {
    ids.forEach((id) => states.workPackages.get(id).putValue(buildWp(id)));
  }

  beforeEach(async () => {
    reorderServiceStub = {
      move: vi.fn().mockResolvedValue(undefined),
      add: vi.fn().mockResolvedValue(undefined),
      remove: vi.fn((order:string[], id:string) => order.filter((x) => x !== id)),
      removePersisted: vi.fn().mockResolvedValue(undefined),
      orderedWorkPackages: vi.fn().mockReturnValue([]),
    };
    notificationStub = { handleRawError: vi.fn() };

    await TestBed.configureTestingModule({
      providers: [
        States,
        { provide: WorkPackageViewOrderService, useValue: reorderServiceStub },
        { provide: WorkPackageNotificationService, useValue: notificationStub },
        { provide: WorkPackageCreateService, useValue: { createOrContinueWorkPackage: vi.fn() } },
        { provide: WorkPackageInlineCreateService, useValue: { newInlineWorkPackageCreated: { next: vi.fn() } } },
        { provide: ApiV3Service, useValue: { work_packages: { id: (id:string) => ({ get: () => ({ toPromise: () => Promise.resolve(buildWp(id)) }) }) } } },
        { provide: CurrentProjectService, useValue: { identifier: 'test-project' } },
        WorkPackageCardDragAndDropService,
      ],
    }).compileComponents();

    service = TestBed.inject(WorkPackageCardDragAndDropService);
    states = TestBed.inject(States);

    cardView = {
      cdRef: { detectChanges: vi.fn() },
      onMoved: { emit: vi.fn() },
      workPackageAddedHandler: vi.fn().mockResolvedValue(undefined),
      resolvedListId: LIST_ID,
    };
    service.init(cardView as unknown as WorkPackageCardViewComponent);
  });

  describe('handleDrop — same-list reorder', () => {
    beforeEach(() => {
      seed('a', 'b', 'c');
      service.workPackages = ['a', 'b', 'c'].map(buildWp);
    });

    it('moves the source after the target on a bottom-edge drop', () => {
      const event = buildDropEvent({ sourceId: 'a', targetId: 'c', edge: 'bottom' });

      service.handleDrop(event);

      expect(idsOf(service.workPackages)).toEqual(['b', 'c', 'a']);
      expect(reorderServiceStub.move).toHaveBeenCalledWith(['a', 'b', 'c'], 'a', 2);
    });

    it('moves the source before the target on a top-edge drop', () => {
      const event = buildDropEvent({ sourceId: 'c', targetId: 'a', edge: 'top' });

      service.handleDrop(event);

      expect(idsOf(service.workPackages)).toEqual(['c', 'a', 'b']);
      expect(reorderServiceStub.move).toHaveBeenCalledWith(['a', 'b', 'c'], 'c', 0);
    });

    it('appends the source on a null-target (container) drop', () => {
      const event = buildDropEvent({ sourceId: 'a', targetId: null });

      service.handleDrop(event);

      expect(idsOf(service.workPackages)).toEqual(['b', 'c', 'a']);
      expect(reorderServiceStub.move).toHaveBeenCalledWith(['a', 'b', 'c'], 'a', 2);
    });

    it('releases busy synchronously without persisting on a same-reference no-op', () => {
      // 'c' is already last: a null-target append is a no-op (spec §reorder.ts).
      const complete = vi.fn();
      const event = buildDropEvent({ sourceId: 'c', targetId: null, complete });

      service.handleDrop(event);

      expect(complete).toHaveBeenCalledWith(true);
      expect(reorderServiceStub.move).not.toHaveBeenCalled();
      expect(cardView.onMoved.emit).not.toHaveBeenCalled();
    });

    it('applies the optimistic order before persistence resolves, and emits onMoved only on success', async () => {
      const move = deferred<void>();
      reorderServiceStub.move.mockReturnValue(move.promise);
      const complete = vi.fn();
      const event = buildDropEvent({ sourceId: 'a', targetId: 'c', edge: 'bottom', complete });

      service.handleDrop(event);

      // Optimistic: already applied, before persistence has settled.
      expect(idsOf(service.workPackages)).toEqual(['b', 'c', 'a']);
      expect(cardView.onMoved.emit).not.toHaveBeenCalled();
      expect(complete).not.toHaveBeenCalled();

      move.resolve(undefined);
      await flush();

      expect(cardView.onMoved.emit).toHaveBeenCalledTimes(1);
      expect(complete).toHaveBeenCalledWith(true);
    });

    it('rolls back the local order and skips onMoved when persistence fails', async () => {
      const error = new Error('move failed');
      // Mimic the real service mutating its `order` arg before rejecting, so
      // this proves rollback restores the true pre-move order, not the
      // (aliased) array reorderService was handed.
      mockRejectAfterMutating(reorderServiceStub.move, mutateMove, error);
      const complete = vi.fn();
      const event = buildDropEvent({ sourceId: 'a', targetId: 'c', edge: 'bottom', complete });

      service.handleDrop(event);
      await flush();

      expect(idsOf(service.workPackages)).toEqual(['a', 'b', 'c']);
      expect(cardView.onMoved.emit).not.toHaveBeenCalled();
      expect(notificationStub.handleRawError).toHaveBeenCalledWith(error);
      expect(complete).toHaveBeenCalledWith(false);
    });

    it('does not reconcile from the API when persistence fails', async () => {
      const updateOrderSpy = vi
        .spyOn(service as unknown as { updateOrder(order:string[]):void }, 'updateOrder')
        .mockImplementation(():void => undefined);
      mockRejectAfterMutating(reorderServiceStub.move, mutateMove, new Error('move failed'));
      const event = buildDropEvent({ sourceId: 'a', targetId: 'c', edge: 'bottom' });

      service.handleDrop(event);
      await flush();

      expect(updateOrderSpy).not.toHaveBeenCalled();
    });

    it('reconciles from the API with the optimistic order once persistence succeeds', async () => {
      const updateOrderSpy = vi
        .spyOn(service as unknown as { updateOrder(order:string[]):void }, 'updateOrder')
        .mockImplementation(():void => undefined);
      const event = buildDropEvent({ sourceId: 'a', targetId: 'c', edge: 'bottom' });

      service.handleDrop(event);
      await flush();

      expect(updateOrderSpy).toHaveBeenCalledWith(['b', 'c', 'a']);
    });

    it('does not reconcile from the API on a same-reference no-op', () => {
      const updateOrderSpy = vi
        .spyOn(service as unknown as { updateOrder(order:string[]):void }, 'updateOrder')
        .mockImplementation(():void => undefined);
      const event = buildDropEvent({ sourceId: 'c', targetId: null });

      service.handleDrop(event);

      expect(updateOrderSpy).not.toHaveBeenCalled();
    });

    it('settles the transaction (complete: false) when the handler throws synchronously', () => {
      cardView.cdRef.detectChanges.mockImplementation(() => { throw new Error('boom'); });
      const complete = vi.fn();
      const event = buildDropEvent({ sourceId: 'a', targetId: 'c', edge: 'bottom', complete });

      expect(() => service.handleDrop(event)).not.toThrow();

      expect(complete).toHaveBeenCalledWith(false);
    });
  });

  describe('handleDrop — cross-list target side', () => {
    it('resolves the item from States, inserts it locally, and persists via addWorkPackageToQuery', async () => {
      seed('x');
      service.workPackages = [];
      const complete = vi.fn();
      const event = buildDropEvent({
        sourceId: 'x', sourceListId: 'source-list', targetId: null, complete,
      });

      service.handleDrop(event);

      // Optimistic insert, synchronous, before the handler/persist await.
      expect(idsOf(service.workPackages)).toEqual(['x']);

      await flush();

      expect(cardView.workPackageAddedHandler).toHaveBeenCalledWith(states.workPackages.get('x').value);
      expect(reorderServiceStub.add).toHaveBeenCalledWith([], 'x', 0);
      expect(complete).toHaveBeenCalledWith(true);
    });

    it('reconciles from the API with the optimistic order once the insert succeeds', async () => {
      seed('x');
      service.workPackages = [];
      const updateOrderSpy = vi
        .spyOn(service as unknown as { updateOrder(order:string[]):void }, 'updateOrder')
        .mockImplementation(():void => undefined);
      const event = buildDropEvent({ sourceId: 'x', sourceListId: 'source-list', targetId: null });

      service.handleDrop(event);
      await flush();

      expect(updateOrderSpy).toHaveBeenCalledWith(['x']);
    });

    it('inserts before/after the target item according to the edge', () => {
      seed('x', 'p', 'q');
      service.workPackages = ['p', 'q'].map(buildWp);
      const event = buildDropEvent({
        sourceId: 'x', sourceListId: 'source-list', targetId: 'q', edge: 'top',
      });

      service.handleDrop(event);

      expect(idsOf(service.workPackages)).toEqual(['p', 'x', 'q']);
    });

    it('rolls back the local insert and completes false when persistence fails', async () => {
      seed('x');
      service.workPackages = [];
      cardView.workPackageAddedHandler.mockRejectedValue(new Error('add failed'));
      const complete = vi.fn();
      const event = buildDropEvent({
        sourceId: 'x', sourceListId: 'source-list', targetId: null, complete,
      });

      service.handleDrop(event);
      expect(idsOf(service.workPackages)).toEqual(['x']);

      await flush();

      expect(idsOf(service.workPackages)).toEqual([]);
      expect(notificationStub.handleRawError).toHaveBeenCalled();
      expect(complete).toHaveBeenCalledWith(false);
    });

    it('does not reconcile from the API when the insert fails', async () => {
      seed('x');
      service.workPackages = [];
      cardView.workPackageAddedHandler.mockRejectedValue(new Error('add failed'));
      const updateOrderSpy = vi
        .spyOn(service as unknown as { updateOrder(order:string[]):void }, 'updateOrder')
        .mockImplementation(():void => undefined);
      const event = buildDropEvent({ sourceId: 'x', sourceListId: 'source-list', targetId: null });

      service.handleDrop(event);
      await flush();

      expect(updateOrderSpy).not.toHaveBeenCalled();
    });

    it('rolls back to the true pre-insert order when reorderService.add rejects a cross-list insert', async () => {
      seed('x', 'p', 'q');
      service.workPackages = ['p', 'q'].map(buildWp);
      const addError = new Error('add persistence failed');
      // Mimic the real service mutating its `order` arg before rejecting, so
      // this proves rollback restores the true pre-insert order, not the
      // (aliased) array reorderService was handed.
      mockRejectAfterMutating(reorderServiceStub.add, mutateAdd, addError);
      const complete = vi.fn();
      const event = buildDropEvent({
        sourceId: 'x', sourceListId: 'source-list', targetId: 'q', edge: 'top', complete,
      });

      service.handleDrop(event);
      await flush();

      expect(idsOf(service.workPackages)).toEqual(['p', 'q']);
      expect(notificationStub.handleRawError).toHaveBeenCalledWith(addError, expect.anything());
      expect(complete).toHaveBeenCalledWith(false);
    });

    it('completes false without inserting when the source id cannot be resolved from States', () => {
      service.workPackages = [];
      const complete = vi.fn();
      const event = buildDropEvent({
        sourceId: 'unknown', sourceListId: 'source-list', targetId: null, complete,
      });

      service.handleDrop(event);

      expect(complete).toHaveBeenCalledWith(false);
      expect(idsOf(service.workPackages)).toEqual([]);
      expect(cardView.workPackageAddedHandler).not.toHaveBeenCalled();
    });

    it('settles the transaction (complete: false) when the cross-list handler throws synchronously', () => {
      service.workPackages = [];
      const getSpy = vi.spyOn(states.workPackages, 'get').mockImplementation(() => { throw new Error('boom'); });
      const complete = vi.fn();
      const event = buildDropEvent({
        sourceId: 'x', sourceListId: 'source-list', targetId: null, complete,
      });

      expect(() => service.handleDrop(event)).not.toThrow();

      expect(complete).toHaveBeenCalledWith(false);
      getSpy.mockRestore();
    });
  });

  describe('handleRemoved — source-side settlement', () => {
    beforeEach(() => {
      seed('a', 'b');
      service.workPackages = ['a', 'b'].map(buildWp);
    });

    it('applies the removal optimistically before completion settles', () => {
      const completion = deferred<boolean>();
      const event = buildRemovedEvent({ itemId: 'a', completion: completion.promise });

      service.handleRemoved(event);

      expect(idsOf(service.workPackages)).toEqual(['b']);
      expect(reorderServiceStub.removePersisted).not.toHaveBeenCalled();
    });

    it('persists only after the target completes successfully, then finalizes', async () => {
      const completion = deferred<boolean>();
      const removePersisted = deferred<string[]>();
      reorderServiceStub.removePersisted.mockReturnValue(removePersisted.promise);
      const finalize = vi.fn();
      const event = buildRemovedEvent({ itemId: 'a', completion: completion.promise, finalize });

      service.handleRemoved(event);
      completion.resolve(true);
      await flush();

      expect(reorderServiceStub.removePersisted).toHaveBeenCalledWith(['a', 'b'], 'a');
      expect(finalize).not.toHaveBeenCalled();

      removePersisted.resolve(['b']);
      await flush();

      expect(finalize).toHaveBeenCalledTimes(1);
    });

    it('notifies and refreshes from the order service when the persisted removal itself fails, without undoing the target', async () => {
      const removeError = new Error('remove failed');
      reorderServiceStub.removePersisted.mockRejectedValue(removeError);
      const refreshedWp = buildWp('b');
      reorderServiceStub.orderedWorkPackages.mockReturnValue([refreshedWp]);
      const finalize = vi.fn();
      const event = buildRemovedEvent({ itemId: 'a', completion: Promise.resolve(true), finalize });

      service.handleRemoved(event);
      await flush();

      expect(notificationStub.handleRawError).toHaveBeenCalledWith(removeError);
      expect(idsOf(service.workPackages)).toEqual(['b']);
      expect(finalize).toHaveBeenCalledTimes(1);
    });

    it('restores the local order with no compensating API call when the target rejects', async () => {
      const finalize = vi.fn();
      const event = buildRemovedEvent({ itemId: 'a', completion: Promise.resolve(false), finalize });

      service.handleRemoved(event);
      await flush();

      expect(idsOf(service.workPackages)).toEqual(['a', 'b']);
      expect(reorderServiceStub.removePersisted).not.toHaveBeenCalled();
      expect(finalize).toHaveBeenCalledTimes(1);
    });

    it('skips restoring when a fresher order already changed the list mid-flight', async () => {
      const completion = deferred<boolean>();
      const event = buildRemovedEvent({ itemId: 'a', completion: completion.promise });

      service.handleRemoved(event);
      expect(idsOf(service.workPackages)).toEqual(['b']);

      // Something else (e.g. a results update) changes the local state before
      // the target settles — it no longer matches the optimistic snapshot.
      service.workPackages = ['b', 'c'].map(buildWp);
      seed('c');

      completion.resolve(false);
      await flush();

      expect(reorderServiceStub.removePersisted).not.toHaveBeenCalled();
      expect(idsOf(service.workPackages)).toEqual(['b', 'c']);
    });

    it('finalizes (busy released) when applying the optimistic removal throws synchronously', () => {
      cardView.cdRef.detectChanges.mockImplementation(() => { throw new Error('boom'); });
      const finalize = vi.fn();
      const event = buildRemovedEvent({ itemId: 'a', completion: Promise.resolve(true), finalize });

      expect(() => service.handleRemoved(event)).not.toThrow();

      expect(finalize).toHaveBeenCalledTimes(1);
    });

    it('does not throw when the view is destroyed while a transaction is pending', async () => {
      const completion = deferred<boolean>();
      const event = buildRemovedEvent({ itemId: 'a', completion: completion.promise });

      expect(() => service.handleRemoved(event)).not.toThrow();
      const detectChangesCallsBeforeDestroy = cardView.cdRef.detectChanges.mock.calls.length;

      service.destroy();
      completion.resolve(true);

      await expect(flush()).resolves.toBeUndefined();
      expect(cardView.cdRef.detectChanges.mock.calls.length).toBe(detectChangesCallsBeforeDestroy);
    });
  });
});

// Real-directive integration coverage: end-to-end drag mechanics that a
// pure unit-level call to `handleDrop`/`handleRemoved` cannot prove — the
// desktop-only drag gate, and the actual cross-list removed-before-drop
// wiring driving two independently-provided service instances.
describe('WorkPackageCardDragAndDropService — real two-list directive fixture', () => {
  @Component({
    selector: 'op-test-sortable-card-list',
    standalone: true,
    imports: [OpSortableListsListDirective, OpSortableListsItemDirective],
    providers: [WorkPackageCardDragAndDropService],
    template: `
      <div
        class="list"
        opSortableListsList
        [opSortableListsListId]="listId()"
        (opSortableListsDrop)="dragDrop.handleDrop($event)"
        (opSortableListsRemoved)="dragDrop.handleRemoved($event)"
      >
        @for (wp of items(); track wp.id) {
          <div
            class="item"
            [opSortableListsItem]="wp.id"
            [opSortableListsItemCanDrag]="itemCanDrag()"
            style="height: 40px; width: 200px;"
          >{{ wp.id }}</div>
        }
      </div>
    `,
  })
  class TestCardListHostComponent {
    // Signal inputs, not `@Input()`: under this harness's zoneless CD a
    // plain-field input mutation on a non-OnPush child is not reliably
    // picked up by a manual `fixture.detectChanges()` — only a signal write
    // is (see `items`/`resync` below for the same reasoning re: `dragDrop`).
    listId = input('list');

    mobile = input(false);

    dragDrop = inject(WorkPackageCardDragAndDropService);

    items = signal<WorkPackageResource[]>([]);

    // Mirrors `WorkPackageCardViewComponent.itemCanDrag`'s desktop-only gate.
    itemCanDrag = ():boolean => !this.mobile();

    resync():void {
      this.items.set([...this.dragDrop.workPackages]);
    }
  }

  @Component({
    standalone: true,
    imports: [OpSortableListsDirective, TestCardListHostComponent],
    template: `
      <div class="root" opSortableLists>
        <op-test-sortable-card-list listId="list-a" [mobile]="mobileA()" />
        <op-test-sortable-card-list listId="list-b" [mobile]="mobileB()" />
      </div>
    `,
  })
  class TestCardRootHostComponent {
    mobileA = signal(false);

    mobileB = signal(false);
  }

  let fixture:ComponentFixture<TestCardRootHostComponent>;
  let host:TestCardRootHostComponent;
  let listAHost:TestCardListHostComponent;
  let listBHost:TestCardListHostComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TestCardRootHostComponent],
      providers: [
        States,
        { provide: WorkPackageViewOrderService, useValue: {
          move: vi.fn().mockResolvedValue(undefined),
          add: vi.fn().mockResolvedValue(undefined),
          remove: vi.fn((order:string[], id:string) => order.filter((x) => x !== id)),
          removePersisted: vi.fn().mockResolvedValue(undefined),
          orderedWorkPackages: vi.fn().mockReturnValue([]),
        } },
        { provide: WorkPackageNotificationService, useValue: { handleRawError: vi.fn() } },
        { provide: WorkPackageCreateService, useValue: { createOrContinueWorkPackage: vi.fn() } },
        { provide: WorkPackageInlineCreateService, useValue: { newInlineWorkPackageCreated: { next: vi.fn() } } },
        { provide: ApiV3Service, useValue: { work_packages: { id: (id:string) => ({ get: () => ({ toPromise: () => Promise.resolve(buildWp(id)) }) }) } } },
        { provide: CurrentProjectService, useValue: { identifier: 'test-project' } },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(TestCardRootHostComponent);
    host = fixture.componentInstance;

    const states = TestBed.inject(States);
    const seedWp = (id:string) => states.workPackages.get(id).putValue(buildWp(id));
    ['a1', 'a2', 'b1', 'b2'].forEach(seedWp);

    fixture.detectChanges(); // constructs both list hosts and their own service instances

    // `queryAll` on a `componentInstance instanceof` predicate also matches every
    // DESCENDANT element within that component's own template (its debug-tree
    // context, not just its host element) — querying the host TAG directly
    // avoids picking up the same instance twice.
    const listHosts = fixture.debugElement.queryAll(By.css('op-test-sortable-card-list'));
    listAHost = listHosts[0].componentInstance as TestCardListHostComponent;
    listBHost = listHosts[1].componentInstance as TestCardListHostComponent;

    // The fixture's own change detection stands in for the real `cdRef`
    // wiring `WorkPackageCardViewComponent` provides in production.
    wireCardView(listAHost);
    wireCardView(listBHost);
  });

  function wireCardView(listHost:TestCardListHostComponent):void {
    listHost.dragDrop.init({
      cdRef: { detectChanges: () => { listHost.resync(); fixture.detectChanges(); } },
      onMoved: { emit: vi.fn() },
      workPackageAddedHandler: vi.fn().mockResolvedValue(true),
      resolvedListId: listHost.listId(),
    } as unknown as WorkPackageCardViewComponent);
  }

  // Sets the service's own state (what production code and the rest of this
  // suite assert against) and the host's mirrored render signal in one step.
  function setItems(listHost:TestCardListHostComponent, ids:string[]):void {
    listHost.dragDrop.workPackages = ids.map(buildWp);
    listHost.resync();
  }

  function listItems(index:0|1):HTMLElement[] {
    return [...(fixture.nativeElement as HTMLElement).querySelectorAll<HTMLElement>('.list')[index].querySelectorAll<HTMLElement>('.item')];
  }

  it('blocks the drag start on mobile and allows it on desktop', async () => {
    setItems(listAHost, ['a1', 'a2']);
    setItems(listBHost, ['b1', 'b2']);
    host.mobileA.set(true);
    fixture.detectChanges();

    const blocked = new NativeDragSimulation(listItems(0)[0]);
    await blocked.start();
    expect(listItems(0)[0].hasAttribute('data-dragging')).toBe(false);

    const allowed = new NativeDragSimulation(listItems(1)[0]);
    await allowed.start();
    expect(listItems(1)[0].dataset.dragging).toBe('source');
    await allowed.cancel();
  });

  it('moves an item cross-list end to end: target inserts, source removal persists, both settle', async () => {
    setItems(listAHost, ['a1', 'a2']);
    setItems(listBHost, ['b1', 'b2']);
    fixture.detectChanges();

    const reorderService = TestBed.inject(WorkPackageViewOrderService) as unknown as {
      removePersisted:ReturnType<typeof vi.fn>;
      add:ReturnType<typeof vi.fn>;
    };

    const simulation = new NativeDragSimulation(listItems(0)[0]);
    await simulation.start();
    await simulation.drop(listItems(1)[0], towardsEdgeOf(listItems(1)[0], 'top'));

    // Target (list-b) applies the optimistic insert synchronously, within
    // the drop dispatch — true regardless of how far the async settlement
    // below has progressed by the time the simulation helper returns.
    expect(idsOf(listBHost.dragDrop.workPackages)).toEqual(['a1', 'b1', 'b2']);

    await flush();

    expect(reorderService.add).toHaveBeenCalledWith(['b1', 'b2'], 'a1', 0);
    expect(reorderService.removePersisted).toHaveBeenCalledWith(['a1', 'a2'], 'a1');
    expect(idsOf(listAHost.dragDrop.workPackages)).toEqual(['a2']);
  });
});
