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

import { Injectable, Injector, inject } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { reorderById, type Edge } from 'core-common/drag-and-drop/reorder';
import type {
  SortableListsDropEvent,
  SortableListsRemovedEvent,
} from 'core-app/shared/directives/sortable-lists/sortable-lists.directive';
import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

@Injectable()
export class WorkPackageCardDragAndDropService {
  readonly states = inject(States);
  readonly injector = inject(Injector);
  readonly reorderService = inject(WorkPackageViewOrderService);
  readonly wpCreate = inject(WorkPackageCreateService);
  readonly notificationService = inject(WorkPackageNotificationService);
  readonly apiV3Service = inject(ApiV3Service);
  readonly currentProject = inject(CurrentProjectService);
  readonly wpInlineCreate = inject(WorkPackageInlineCreateService);

  private _workPackages:WorkPackageResource[];

  /**
   * Bumped on every `workPackages` assignment. Lets an async continuation
   * (rollback, source-failure refresh, background reconciliation) tell
   * whether anything newer has landed since it captured its snapshot — an
   * order-equality check alone cannot see a same-order refresh delivering
   * fresher resource objects.
   */
  private orderRevision = 0;

  /** Whether the card view has an active inline created wp */
  public activeInlineCreateWp?:WorkPackageResource;

  /** A reference to the component in use, to have access to the current input variables */
  public cardView:WorkPackageCardViewComponent;

  /** Set once torn down, so a late-resolving async continuation is a no-op rather than touching a dead view */
  private destroyed = false;

  public init(componentRef:WorkPackageCardViewComponent) {
    this.cardView = componentRef;
  }

  public destroy() {
    this.destroyed = true;
  }

  /**
   * Get the current work packages
   */
  public get workPackages():WorkPackageResource[] {
    return this._workPackages;
  }

  /**
   * Set work packages array,
   * remembering to keep the active inline-create
   *
   * Always rebuilt from `workPackages`: every optimistic apply, rollback and
   * reconciliation goes through here, so an open inline-create card must not
   * cost the incoming order.
   */
  public set workPackages(workPackages:WorkPackageResource[]) {
    this.orderRevision += 1;

    if (this.activeInlineCreateWp) {
      // Kept at the slot it already holds — `onCardSaved` reads that index
      // back to place the persisted resource.
      const index = (this._workPackages ?? []).findIndex((wp) => isNewResource(wp));
      const rebuilt = workPackages.filter((wp) => !isNewResource(wp));
      rebuilt.splice(index === -1 ? 0 : index, 0, this.activeInlineCreateWp);
      this._workPackages = rebuilt;
    } else {
      this._workPackages = [...workPackages];
    }
  }

  /**
   * Get current order
   */
  private get currentOrder():string[] {
    return this.workPackages
      .filter((wp) => wp && !isNewResource(wp))
      .map((el) => el.id!);
  }

  /**
   * Apply an id order to the view synchronously from already-loaded States —
   * no API round trip before render. A later successful persist may still
   * reconcile from the server in the background via `updateOrder`.
   */
  private applyLocalOrder(order:string[]):void {
    if (this.destroyed) {
      return;
    }

    this.workPackages = order
      .map((id) => this.states.workPackages.get(id).value)
      .filter((wp):wp is WorkPackageResource => !!wp);
    // Selection (select-all, shift-range) reads its order from
    // `tableRendered`, which the results path keeps in step with the cards.
    // An optimistic apply has to do the same or selection lags a drag.
    this.cardView.cardView.updateRenderedCardsValues(this.workPackages);
    this.cardView.cdRef.detectChanges();
  }

  private currentOrderEquals(order:string[]):boolean {
    const current = this.currentOrder;
    return current.length === order.length && current.every((id, index) => id === order[index]);
  }

  /**
   * True while no `workPackages` assignment has happened since `revision`
   * was captured and the order still matches — the gate every rollback,
   * source-failure refresh and background reconciliation batch checks
   * before overwriting the (possibly fresher) current state.
   */
  private stillAt(revision:number, order:string[]):boolean {
    return this.orderRevision === revision && this.currentOrderEquals(order);
  }

  /**
   * Handle a drop resolved by the sortable-lists directives. Same-list is a
   * pure reorder; cross-list resolves the moved item from States and inserts
   * it on this (target) list's side.
   */
  handleDrop(event:SortableListsDropEvent):void {
    // The event carries the SOURCE list id only — it is always routed to
    // THIS list's own output when resolving as the target, so "cross-list"
    // means the source differs from this list's own id.
    if (event.sourceListId !== this.cardView.resolvedListId) {
      this.handleCrossListDrop(event);
      return;
    }

    try {
      const before = this.currentOrder;
      const after = reorderById({
        list: before,
        getId: (id) => id,
        sourceId: event.sourceId,
        targetId: event.targetId,
        closestEdge: event.edge,
        axis: event.axis,
      });

      if (after === before) {
        event.complete(true); // no-op: nothing moved, nothing to persist
        return;
      }

      this.applyLocalOrder(after);
      void this.persistMove(before, after, event);
    } catch (e) {
      // Guarantee settlement on a sync throw too, or the engine's busy flag never clears.
      this.notificationService.handleRawError(e);
      event.complete(false);
    }
  }

  /**
   * Handle a removal resolved by the sortable-lists directives on the
   * SOURCE list's side of a cross-list move. Applies the removal optimistically,
   * then persists only once the target side has settled (`event.completion`).
   */
  handleRemoved(event:SortableListsRemovedEvent):void {
    let before:string[];
    let optimistic:string[];
    let revision:number;

    try {
      before = this.currentOrder;
      optimistic = before.filter((id) => id !== event.itemId);
      this.applyLocalOrder(optimistic);
      revision = this.orderRevision;
    } catch (e) {
      // Guarantee settlement on a sync throw too, or the engine's busy flag never clears.
      this.notificationService.handleRawError(e);
      event.finalize();
      return;
    }

    void event.completion
      .then(async (ok) => {
        if (ok) {
          // Target succeeded: persist the removal here; a failure here does not
          // undo the target's already-completed insert.
          await this.reorderService
            .removePersisted(before, event.itemId)
            .catch((e) => {
              this.notificationService.handleRawError(e);

              // Where the order IS the membership (a free board), the failure
              // left the card in both queries — restore it rather than hide a
              // server state the next refresh would resurrect anyway. Where
              // membership moved by other means (an action board's attribute
              // PATCH), only this list's position entry failed, so the
              // optimistic removal stands.
              if (this.cardView.orderIsMembership && this.stillAt(revision, optimistic)) {
                this.applyLocalOrder(before);
              }
            });
        } else if (this.stillAt(revision, optimistic)) {
          // Target rejected: restore, but only if nothing fresher (e.g. a
          // results update) has since changed the local order.
          this.applyLocalOrder(before);
        }
      })
      .finally(() => event.finalize());
  }

  private async persistMove(before:string[], after:string[], event:SortableListsDropEvent):Promise<void> {
    const revision = this.orderRevision;
    let success = false;

    try {
      const toIndex = after.indexOf(event.sourceId);
      // Defensive copy: `move` mutates its `order` arg in place, and `before`
      // is the rollback reference on failure below.
      await this.reorderService.move([...before], event.sourceId, toIndex);
      this.cardView.onMoved.emit();
      success = true;
      void this.updateOrder(after, revision);
    } catch (e) {
      this.notificationService.handleRawError(e);
      if (this.stillAt(revision, after)) {
        this.applyLocalOrder(before);
      }
    } finally {
      event.complete(success);
    }
  }

  private handleCrossListDrop(event:SortableListsDropEvent):void {
    try {
      const workPackage = this.states.workPackages.get(event.sourceId).value;
      if (!workPackage) {
        event.complete(false);
        return;
      }

      const toIndex = this.insertionIndexFor(this.currentOrder, event.targetId, event.edge);
      void this
        .addWorkPackageToQuery(workPackage, toIndex, true)
        .then((success) => event.complete(success))
        .catch((e) => {
          this.notificationService.handleRawError(e);
          event.complete(false);
        });
    } catch (e) {
      // Guarantee settlement on a sync throw too, or the engine's busy flag never clears.
      this.notificationService.handleRawError(e);
      event.complete(false);
    }
  }

  // `null` targetId (container/empty-list drop) maps to `addWorkPackageToQuery`'s own -1 = append convention.
  private insertionIndexFor(order:string[], targetId:string|null, edge:Edge|null):number {
    if (targetId === null) {
      return -1;
    }

    const index = order.indexOf(targetId);
    if (index === -1) {
      return -1;
    }

    return edge === 'bottom' || edge === 'right' ? index + 1 : index;
  }

  /**
   * Update current order from the API (background reconciliation only —
   * never a prerequisite for rendering the optimistic local order). Discards
   * the fetched batch if anything newer has landed since `revision` was
   * captured, and reports its own fetch failures rather than leaving them
   * an unhandled rejection.
   */
  private updateOrder(newOrder:string[], revision:number) {
    newOrder = Array.from(new Set(newOrder));

    Promise
      .all(newOrder.map((id) => this
        .apiV3Service
        .work_packages
        .id(id)
        .get()
        .toPromise()))
      .then((workPackages:WorkPackageResource[]) => {
        if (this.destroyed || !this.stillAt(revision, newOrder)) {
          return;
        }
        this.workPackages = workPackages;
        this.cardView.cdRef.detectChanges();
      })
      .catch((e) => this.notificationService.handleRawError(e));
  }

  /**
   * Inline create a new card
   */
  public addNewCard() {
    this.wpCreate
      .createOrContinueWorkPackage(this.currentProject.identifier)
      .then((changeset:WorkPackageChangeset) => {
        this.activeInlineCreateWp = changeset.projectedResource;
        this.workPackages = this.workPackages;
        this.cardView.cdRef.detectChanges();
      });
  }

  /**
   * Add the given work package to the query.
   *
   * With `optimistic` (the cross-list drag path, whose source side is also
   * removed optimistically) the card renders before persistence and rolls
   * back on failure. Without it (the autocomplete/reference path, where the
   * source list keeps its card until the board attribute PATCH lands) the
   * card only renders once `workPackageAddedHandler` has persisted —
   * rendering earlier would show the card in both lists.
   */
  async addWorkPackageToQuery(workPackage:WorkPackageResource, toIndex = -1, optimistic = false):Promise<boolean> {
    const insertionOrder = () => {
      const before = this.currentOrder.filter((id) => id !== workPackage.id);
      const insertIndex = toIndex === -1 ? before.length : toIndex;
      const after = [...before];
      after.splice(insertIndex, 0, workPackage.id!);

      return { before, after, insertIndex };
    };
    let { before, after, insertIndex } = insertionOrder();

    this.states.workPackages.get(workPackage.id!).putValue(workPackage);
    if (optimistic) {
      this.applyLocalOrder(after);
    }
    let revision = this.orderRevision;
    let membershipPersisted:boolean;

    try {
      const result = await this.cardView.workPackageAddedHandler(workPackage);
      membershipPersisted = result.membershipPersisted;
      if (!optimistic) {
        ({ before, after, insertIndex } = insertionOrder());
        this.applyLocalOrder(after);
        revision = this.orderRevision;
      }
    } catch (e) {
      this.notificationService.handleRawError(e, workPackage);
      if (this.stillAt(revision, after)) {
        this.applyLocalOrder(before);
      }
      return false;
    }

    try {
      // Defensive copy: `add` mutates its `order` arg in place, and `before`
      // is the rollback reference on failure below.
      await this.reorderService.add([...before], workPackage.id!, insertIndex);
      void this.updateOrder(after, revision);
      return true;
    } catch (e) {
      this.notificationService.handleRawError(e, workPackage);
      if (!membershipPersisted && this.stillAt(revision, after)) {
        this.applyLocalOrder(before);
      }
      return membershipPersisted;
    }
  }

  /**
   * Remove the new card
   */
  public removeReferenceWorkPackageForm() {
    if (this.activeInlineCreateWp) {
      this.removeCard(this.activeInlineCreateWp);
    }
  }

  removeCard(wp:WorkPackageResource) {
    const index = this.workPackages.indexOf(wp);
    this.workPackages.splice(index, 1);
    this.activeInlineCreateWp = undefined;

    if (!isNewResource(wp)) {
      const newOrder = this.reorderService.remove(this.currentOrder, wp.id!);
      const revision = this.orderRevision;
      this.updateOrder(newOrder, revision);
    }
  }

  /**
   * On new card saved
   */
  async onCardSaved(wp:WorkPackageResource) {
    const index = this.workPackages.findIndex((el) => el.id === 'new');

    if (index !== -1) {
      this.activeInlineCreateWp = undefined;

      const before = this.currentOrder;
      const newOrder = [...before];
      newOrder.splice(index, 0, wp.id!);

      // Replace the synthetic `new` card with the persisted resource
      // synchronously: `updateOrder`'s guard compares against the rendered
      // order, which must already contain the persisted id or the fetched
      // batch would always be discarded.
      this.states.workPackages.get(wp.id!).putValue(wp);
      this.applyLocalOrder(newOrder);
      const revision = this.orderRevision;

      try {
        // Defensive copy: `add` mutates its `order` arg in place.
        await this.reorderService.add([...before], wp.id!, index);
        void this.updateOrder(newOrder, revision);
      } catch (e) {
        this.notificationService.handleRawError(e, wp);
      }

      // Notify inline create service
      this.wpInlineCreate.newInlineWorkPackageCreated.next(wp.id!);
    }
  }
}
