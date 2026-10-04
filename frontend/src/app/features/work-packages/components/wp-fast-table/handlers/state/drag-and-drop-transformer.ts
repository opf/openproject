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

import { Injector } from '@angular/core';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { TableDragActionsRegistryService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service';
import { TableDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-action.service';
import { States } from 'core-app/core/states/states.service';
import { DragAndDropService, DragIntent } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { isInsideCollapsedGroup, locateTableRow } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-row-helpers';
import { collapsedGroupClass } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-hierarchy-helpers';
import { reorderById, type Edge } from 'core-common/drag-and-drop/reorder';
import { WorkPackageTable } from '../../wp-fast-table';
import { firstValueFrom } from 'rxjs';

export class DragAndDropTransformer {
  @LazyInject() private readonly states:States;

  @LazyInject() private readonly querySpace:IsolatedQuerySpace;

  @LazyInject() private readonly inlineCreateService:WorkPackageInlineCreateService;

  @LazyInject() private readonly halNotification:HalResourceNotificationService;

  @LazyInject() private readonly wpTableSortBy:WorkPackageViewSortByService;

  @LazyInject() private readonly wpTableOrder:WorkPackageViewOrderService;

  @LazyInject() private readonly selectionGestures:WorkPackageViewSelectionGesturesService;

  @LazyInject() private readonly apiV3Service:ApiV3Service;

  @LazyInject() private readonly wpListService:WorkPackagesListService;

  @LazyInject() private readonly dragActionRegistry:TableDragActionsRegistryService;

  @LazyInject(DragAndDropService, null) private readonly dragService:DragAndDropService|null;

  constructor(public readonly injector:Injector,
    public table:WorkPackageTable) {
    // The DragService may not have been provided
    // in which case we do not provide drag and drop
    if (table.destroyed) return;
    const dragService = this.dragService;
    if (dragService === null) {
      return;
    }

    onDestroySafely(table.destroyRef, () => dragService.remove(table.tbody));

    this.inlineCreateService.newInlineWorkPackageCreated
      .pipe(takeUntilDestroyed(table.destroyRef))
      .subscribe((wpId) => {
        const notification = this.halNotification;
        const querySpace = this.querySpace;
        const query = querySpace.query.value;
        const orderService = this.wpTableOrder;
        const api = this.apiV3Service;
        const order = this.currentOrder;
        const isCurrent = () => !table.destroyed && querySpace.query.value === query;
        if (!query || !isCurrent()) return;
        void (async () => {
          const prepared = await orderService.prepareAdd(query, order, wpId, isCurrent);
          if (!isCurrent()) return;
          await prepared.persist();
          await this.updateRenderedOrder(prepared.order, isCurrent, api);
        })().catch((error:unknown) => notification.handleRawError(error));
      });

    dragService.register({
      dragContainer: this.table.tbody,
      scrollContainers: [this.table.scrollContainer],
      itemIdOf: (row) => (table.destroyed ? null : row.dataset.workPackageId ?? null),
      accepts: () => !table.destroyed,
      canPickup: (row, handle) => {
        if (table.destroyed) return false;
        if (!handle?.classList.contains('wp-table--drag-and-drop-handle')) {
          return false;
        }

        const wpId:string = row.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value;
        return !!workPackage && this.actionService.canPickup(workPackage);
      },
      // A detached `<tr>` clone loses its column widths and drags the row's
      // selection background along with it, so the preview is built fresh.
      renderPreview: (row, preview) => {
        if (table.destroyed) return;
        const wpId:string = row.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value;
        if (!workPackage) {
          return;
        }

        // Sized from the row, capped by the stylesheet's max-width.
        preview.style.width = `${row.getBoundingClientRect().width}px`;

        const label = document.createElement('span');
        label.textContent = workPackage.subjectWithId();
        preview.appendChild(label);
      },
      // Multi-select drag is not supported — the engine's payload is the
      // single picked-up row. Collapse the selection to that row so the
      // drag never LOOKS like it carries the other selected rows along.
      onDragStarted: (row) => this.collapseSelectionTo(row),
      onMoved: (intent, complete) => this.performMove(intent, complete),
    });
  }

  private collapseSelectionTo(row:HTMLElement):void {
    if (this.table.destroyed) return;
    const wpId = row.dataset.workPackageId;
    if (wpId) {
      this.selectionGestures.collapseTo(wpId, this.table.renderedRows, row.dataset.classIdentifier);
    }
  }

  /** Prepare against the live view, then finish every accepted persistence phase. */
  private performMove(intent:DragIntent, complete:(success:boolean) => void):void {
    const table = this.table;
    if (table.destroyed) {
      complete(false);
      return;
    }
    const notification = this.halNotification;
    const api = this.apiV3Service;
    const orderService = this.wpTableOrder;
    const listService = this.wpListService;
    const actionService = this.actionService;
    const querySpace = this.querySpace;
    const sortService = this.wpTableSortBy;
    const originalQuery = querySpace.query.value;
    const wpId = intent.sourceId;
    let workPackage = this.states.workPackages.get(wpId).value;
    const isCurrent = () => !table.destroyed && querySpace.query.value === originalQuery;
    let recoverIfCurrent:() => void = () => undefined;

    void (async () => {
      try {
        if (!originalQuery) {
          complete(false);
          return;
        }
        workPackage = await firstValueFrom(api.work_packages.id(wpId).get());
        if (!isCurrent()) {
          complete(false);
          return;
        }
        // A refresh while loading may remove either endpoint of the intent.
        const order = this.currentOrder;
        if (!order.includes(wpId) || (intent.targetId !== null && !order.includes(intent.targetId))) {
          complete(false);
          return;
        }
        const { targetId, edge } = this.resolveEffectiveTarget(intent);
        const renderPass = table.lastRenderPass;
        const source = locateTableRow(wpId, table.tableAndTimelineContainer);
        const target = targetId ? locateTableRow(targetId, table.tableAndTimelineContainer) : null;
        if (!source || (targetId !== null && !target)) {
          complete(false);
          return;
        }
        const { parentNode, nextSibling } = source;
        const stillEligible = () => isCurrent()
          && table.lastRenderPass === renderPass
          && source.parentNode === table.tbody
          && (!target || target.parentNode === table.tbody)
          && this.currentOrder.length === order.length
          && this.currentOrder.every((id, index) => id === order[index])
          && actionService.canPickup(workPackage!);
        recoverIfCurrent = () => {
          if (!isCurrent() || table.lastRenderPass !== renderPass || source.parentNode !== parentNode) return;
          parentNode?.insertBefore(source, nextSibling?.parentNode === parentNode ? nextSibling : null);
        };
        if (!stillEligible()) {
          complete(false);
          return;
        }
        const newOrder = reorderById({
          list: order,
          getId: (id) => id,
          sourceId: wpId,
          targetId,
          closestEdge: edge,
          axis: 'vertical',
        });
        // A valid unchanged order remains a successful no-op.
        if (newOrder === order) {
          complete(true);
          return;
        }
        const manualSort = !sortService.isManualSortingMode
          ? sortService.available.find((sort) => sort.column.href?.endsWith('/manualSorting'))
          : undefined;
        const preparedOrder = await orderService.prepareMove(originalQuery, order, wpId, newOrder.indexOf(wpId), isCurrent);
        if (!stillEligible()) {
          complete(false);
          return;
        }
        // Only preparation observes the staged neighbors. Persistence captures no row.
        if (target) table.tbody.insertBefore(source, edge === 'top' ? target : target.nextSibling);
        else table.tbody.appendChild(source);
        const preparedAction = await actionService.prepareDrop(workPackage, source);
        if (!stillEligible()) {
          recoverIfCurrent();
          complete(false);
          return;
        }
        const ownsQuery = (expectedQuery = originalQuery) => !table.destroyed && querySpace.query.value === expectedQuery;
        const preparedQuery = manualSort ? await listService.prepareSave(originalQuery, ownsQuery) : undefined;
        if (!stillEligible()) {
          recoverIfCurrent();
          complete(false);
          return;
        }
        const refreshLiveView = async (ids:readonly string[]) => {
          if (!isCurrent()) return;
          const resources = await Promise.all(Array.from(new Set(ids)).map(
            (id) => firstValueFrom(api.work_packages.id(id).get()),
          ));
          if (!isCurrent()) return;
          table.initialSetup(resources);
          actionService.onNewOrder([...ids]);
        };
        const reportUiFailure = (error:unknown) => notification.handleRawError(error, workPackage);

        // Acceptance begins at the first write: navigation cannot cancel later phases.
        await preparedOrder.persist();
        await preparedAction.persist();
        recoverIfCurrent = () => {
          if (isCurrent()) void refreshLiveView(preparedOrder.order).catch(reportUiFailure);
        };
        if (preparedQuery && manualSort) {
          originalQuery.setSortBy([manualSort]);
          await preparedQuery.persist();
        }
        complete(true);
        recoverIfCurrent();
      } catch (error:unknown) {
        recoverIfCurrent();
        notification.handleRawError(error, workPackage);
        complete(false);
      }
    })();
  }

  /**
   * Translate the intent's target/edge into id-order terms, redirecting a
   * drop that lands on a collapsed (hidden) group member to after that
   * group's last row instead — dropping "inside" a collapsed group is
   * meaningless since its members aren't individually visible.
   */
  private resolveEffectiveTarget(intent:DragIntent):{ targetId:string|null; edge:Edge|null } {
    const siblingId = this.siblingIdFor(intent);
    const siblingRow = siblingId ? locateTableRow(siblingId, this.table.tableAndTimelineContainer) : null;

    if (!isInsideCollapsedGroup(siblingRow)) {
      return { targetId: intent.targetId, edge: intent.edge };
    }

    const collapsedGroupCssClass = Array.from(siblingRow!.classList).find((cls) => cls.includes(collapsedGroupClass()))!;
    const collapsedGroupId = collapsedGroupCssClass.replace(collapsedGroupClass(), '');
    const groupMembers = this.table.tbody.getElementsByClassName(collapsedGroupClass(collapsedGroupId));
    const lastMember = groupMembers[groupMembers.length - 1] as HTMLElement;

    return { targetId: lastMember.dataset.workPackageId!, edge: 'bottom' };
  }

  /** The id that would immediately follow the source row once dropped, before collapsed-group redirection. */
  private siblingIdFor(intent:DragIntent):string|null {
    if (intent.targetId === null) {
      return null;
    }
    if (intent.edge === 'top') {
      return intent.targetId;
    }

    const order = this.currentOrder;
    const index = order.indexOf(intent.targetId);
    return index === -1 ? null : (order[index + 1] ?? null);
  }

  /**
   * Update current rendered order
   */
  private async updateRenderedOrder(order:readonly string[], isCurrent:() => boolean, api:ApiV3Service):Promise<void> {
    if (!isCurrent()) return;
    const resources = await Promise.all(Array.from(new Set(order)).map(
      (id) => firstValueFrom(api.work_packages.id(id).get()),
    ));
    if (isCurrent()) this.table.initialSetup(resources);
  }

  protected get actionService():TableDragActionService {
    return this.dragActionRegistry.get(this.injector);
  }

  protected get currentOrder():string[] {
    return this
      .currentRenderedOrder
      .map((row) => row.workPackageId!);
  }

  protected get currentRenderedOrder():RenderedWorkPackage[] {
    return this
      .querySpace
      .renderedWorkPackages
      .getValueOr([]);
  }
}
