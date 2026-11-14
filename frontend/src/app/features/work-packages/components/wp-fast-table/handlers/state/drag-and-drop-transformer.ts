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
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { QUERY_SORT_BY_ASC } from 'core-app/features/hal/resources/query-sort-by-resource';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { PreparedQueryOrder, WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { isSelectableOccurrence } from 'core-app/features/work-packages/routing/wp-view-base/view-services/rendered-occurrences';
import { locateTableRow } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-row-helpers';
import { collapsedGroupClass } from 'core-app/features/work-packages/components/wp-fast-table/helpers/wp-table-hierarchy-helpers';
import { reorderById, type Edge } from 'core-common/drag-and-drop/reorder';
import { WorkPackageTable } from '../../wp-fast-table';
import type { PrimaryRenderPass } from '../../builders/primary-render-pass';
import { wpOccurrenceKey } from '../../rendered-occurrence-ledger';
import { selectionGesture } from './selection-feedback';
import type { MoveDirection, RowMover } from './row-mover';
import { firstValueFrom } from 'rxjs';
import { filter, take } from 'rxjs/operators';
import { announce } from '@primer/live-region-element';

const maxPrepareAttempts = 5;

/** `abandoned`: given up before saving; `failed`: an error the notification service already reported. */
type MoveOutcome = 'moved'|'unchanged'|'abandoned'|'failed';

export class DragAndDropTransformer implements RowMover {
  @LazyInject() private readonly states:States;

  @LazyInject() private readonly querySpace:IsolatedQuerySpace;

  @LazyInject() private readonly inlineCreateService:WorkPackageInlineCreateService;

  @LazyInject() private readonly halNotification:HalResourceNotificationService;

  @LazyInject() private readonly wpTableSortBy:WorkPackageViewSortByService;

  @LazyInject() private readonly wpTableGroupBy:WorkPackageViewGroupByService;

  @LazyInject() private readonly wpTableHierarchies:WorkPackageViewHierarchiesService;

  @LazyInject() private readonly wpTableOrder:WorkPackageViewOrderService;

  @LazyInject() private readonly selectionGestures:WorkPackageViewSelectionGesturesService;

  @LazyInject() private readonly apiV3Service:ApiV3Service;

  @LazyInject() private readonly wpListService:WorkPackagesListService;

  @LazyInject() private readonly dragActionRegistry:TableDragActionsRegistryService;

  @LazyInject(DragAndDropService, null) private readonly dragService:DragAndDropService|null;

  private moveInFlight = false;

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
    table.attachRowMover(this);

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
        if (table.destroyed || this.moveInFlight) return false;
        if (!handle?.classList.contains('wp-table--drag-and-drop-handle')) {
          return false;
        }

        const wpId = row.dataset.workPackageId;
        if (!wpId) return false;

        const workPackage = this.states.workPackages.get(wpId).value;
        return !!workPackage && this.actionService.canPickup(workPackage);
      },
      // A detached `<tr>` clone loses its column widths and drags the row's
      // selection background along with it, so the preview is built fresh.
      renderPreview: (row, preview) => {
        if (table.destroyed) return;
        const wpId = row.dataset.workPackageId;
        const workPackage = wpId ? this.states.workPackages.get(wpId).value : undefined;
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
      onMoved: (intent, complete) => { void this.performMove(intent, complete); },
    });
  }

  public movableDirections(ids:readonly string[]):ReadonlySet<MoveDirection>|null {
    const directions = this.directionsFor(ids);
    return directions && this.moveInFlight ? new Set() : directions;
  }

  private directionsFor(ids:readonly string[]):Set<MoveDirection>|null {
    const query = this.querySpace.query.value;
    if (!query || !this.canMoveRows(query)) return null;
    if (!ids.length) return null;
    const order = this.menuOrder(ids[0], ids.length > 1);
    const positions = ids.map((id) => order.indexOf(id));
    if (positions.includes(-1)) return null;

    const directions = new Set<MoveDirection>();
    if (Math.min(...positions) > 0) directions.add('top').add('up');
    if (Math.max(...positions) < order.length - 1) directions.add('down').add('bottom');
    return directions;
  }

  public move(ids:readonly string[], direction:MoveDirection):void {
    const query = this.querySpace.query.value;
    if (!query || !this.movableDirections(ids)?.has(direction)) return;
    const workPackageId = ids[0];
    if (ids.length > 1 || this.wpTableGroupBy.isEnabled || this.wpTableHierarchies.isEnabled) {
      void this.moveWithinPeers(ids, direction, query);
      return;
    }
    const intent = this.intentFor(workPackageId, direction);
    if (!intent) return;

    void this.performMove(intent, () => undefined).then((outcome) => {
      if (outcome === 'moved') {
        this.announceMove(workPackageId, query);
      } else if (outcome === 'abandoned' && !this.table.destroyed && this.querySpace.query.value === query) {
        this.announceMoveFailed(1);
      }
    });
  }

  private menuOrder(workPackageId:string, bulk = false):string[] {
    const table = this.table;
    if (this.wpTableGroupBy.isEnabled) {
      const groups = new Map<string, string>();
      let group:string|undefined;
      for (const row of table.ledger.occurrences) {
        if (row.kind === 'groupHeader') group = row.key;
        if (group && row.workPackageId && row.key === wpOccurrenceKey(row.workPackageId)) {
          groups.set(row.workPackageId, group);
        }
      }
      const sourceGroup = groups.get(workPackageId);
      return sourceGroup ? table.originalRows.filter((id) => groups.get(id) === sourceGroup) : [];
    }
    if (this.wpTableHierarchies.isEnabled) {
      if (!table.originalRowIndex[workPackageId]) return [];
      const parentOf = (id:string) => table.originalRowIndex[id].object.getAncestors().at(-1)?.id;
      const parent = parentOf(workPackageId);
      return table.originalRows.filter((id) => parentOf(id) === parent);
    }
    return bulk ? table.originalRows : this.currentOrder;
  }

  private async moveWithinPeers(ids:readonly string[], direction:MoveDirection, query:QueryResource):Promise<void> {
    const table = this.table;
    const bulk = new Set(ids).size > 1;
    const isCurrent = () => !table.destroyed && this.querySpace.query.value === query;
    this.moveInFlight = true;
    try {
      let attempt = await this.preparePeerMove(ids, direction, query, isCurrent);
      for (let tries = 1; attempt && isCurrent() && this.renderedSince(attempt.renderPass) && tries < maxPrepareAttempts; tries++) {
        await table.whenRendered();
        attempt = isCurrent() ? await this.preparePeerMove(ids, direction, query, isCurrent) : null;
      }
      if (attempt && isCurrent() && this.renderedSince(attempt.renderPass)) {
        this.announceMoveFailed(new Set(ids).size);
        return;
      }
      if (!attempt || !isCurrent() || !this.canMoveRows(query)) return;
      const { prepared, block } = attempt;
      await prepared.persist();
      if (!isCurrent()) return;
      await table.whenRendered();
      if (!isCurrent() || !this.canMoveRows(query)) return;

      const currentPeers = new Set(this.menuOrder(ids[0], bulk));
      const orderedPeers = prepared.order.filter((id) => currentPeers.has(id));
      if (!orderedPeers.length) return;
      const slots = new Set(orderedPeers);
      let nextPeer = 0;
      const resources = table.originalRows.map((id) => {
        const reorderedId = slots.has(id) ? orderedPeers[nextPeer++] : id;
        return table.originalRowIndex[reorderedId].object;
      });
      table.initialSetup(resources);
      await table.whenRendered();
      if (table.destroyed || this.querySpace.query.value !== query) return;
      if (bulk) {
        const peers = this.menuOrder(ids[0], true);
        const start = peers.indexOf(block[0]);
        if (start >= 0 && block.every((id, offset) => peers[start + offset] === id)) {
          void announce(I18n.t('js.sortable_lists.announcements.moved_batch', {
            count: block.length, first: start + 1, last: start + block.length, total: peers.length,
          }), { politeness: 'polite' });
        }
      } else {
        this.announceMove(block[0], query);
      }
    } catch (error:unknown) {
      if (!table.destroyed) this.halNotification.handleRawError(error);
    } finally {
      this.moveInFlight = false;
    }
  }

  /** Prepares against the rows as rendered now; a render that lands meanwhile makes the result stale. */
  private async preparePeerMove(
    ids:readonly string[],
    direction:MoveDirection,
    query:QueryResource,
    isCurrent:() => boolean,
  ):Promise<{ prepared:PreparedQueryOrder, renderPass:PrimaryRenderPass|null, block:string[] }|null> {
    if (!this.directionsFor(ids)?.has(direction)) return null;
    const selected = new Set(ids);
    const bulk = selected.size > 1;
    const order = this.menuOrder(ids[0], bulk);
    const block = order.filter((id) => selected.has(id));
    const first = order.indexOf(block[0]);
    const last = order.indexOf(block[block.length - 1]);
    const targets = { top: 0, up: first - 1, down: last - block.length + 2, bottom: order.length - block.length } satisfies Record<MoveDirection, number>;
    const renderPass = this.table.lastRenderPass;
    const prepared = bulk
      ? await this.wpTableOrder.prepareBlockMove(query, order, block, targets[direction], isCurrent)
      : await this.wpTableOrder.prepareMove(query, order, block[0], targets[direction], isCurrent);
    return { prepared, renderPass, block };
  }

  private renderedSince(renderPass:PrimaryRenderPass|null):boolean {
    return this.table.hasPendingRender || this.table.lastRenderPass !== renderPass;
  }

  private intentFor(workPackageId:string, direction:MoveDirection):DragIntent|null {
    const order = this.menuOrder(workPackageId);
    const index = order.indexOf(workPackageId);
    const targets:Record<MoveDirection, [string|undefined, Edge]> = {
      top: [order[0], 'top'],
      up: [order[index - 1], 'top'],
      down: [order[index + 1], 'bottom'],
      bottom: [order[order.length - 1], 'bottom'],
    };
    const [targetId, edge] = targets[direction];
    return index === -1 || targetId === undefined ? null : { sourceId: workPackageId, targetId, edge };
  }

  private announceMoveFailed(count:number):void {
    const message = count > 1
      ? I18n.t('js.sortable_lists.announcements.move_failed_check_positions_batch', { count })
      : I18n.t('js.sortable_lists.announcements.move_failed_check_position');
    void announce(message, { politeness: 'assertive' });
  }

  private announceMove(workPackageId:string, query:QueryResource|undefined):void {
    if (this.table.destroyed || this.querySpace.query.value !== query) return;
    const order = this.menuOrder(workPackageId);
    const index = order.indexOf(workPackageId);
    if (index === -1) return;

    const row = locateTableRow(workPackageId, this.table.tbody);
    const label = row?.querySelector<HTMLElement>('th[scope="row"]')?.dataset.rowHeaderName
      ?? this.states.workPackages.get(workPackageId).value?.subjectWithId()
      ?? workPackageId;
    void announce(
      I18n.t('js.sortable_lists.announcements.moved', { label, position: index + 1, total: order.length }),
      { politeness: 'polite' },
    );
  }

  private canMoveRows(query:QueryResource):boolean {
    return this.table.configuration.dragAndDropEnabled
      && this.wpTableSortBy.isManualSortingMode
      && this.wpTableSortBy.current[0].direction.href === QUERY_SORT_BY_ASC
      && (isNewResource(query) || !!query.updateOrderedWorkPackages);
  }

  private collapseSelectionTo(row:HTMLElement):void {
    if (this.table.destroyed || !this.table.configuration.selectionEnabled) return;
    const wpId = row.dataset.workPackageId;
    if (wpId) {
      selectionGesture(this.table, 'navigation', () => {
        this.selectionGestures.collapseTo(wpId, this.table.renderedRows, row.dataset.classIdentifier);
      });
    }
  }

  /** Prepare against the live view, then finish every accepted persistence phase and the refreshed render. */
  private performMove(intent:DragIntent, complete:(success:boolean) => void):Promise<MoveOutcome> {
    const table = this.table;
    if (table.destroyed || this.moveInFlight) {
      complete(false);
      return Promise.resolve('abandoned');
    }
    this.moveInFlight = true;
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
    let refresh:Promise<boolean>|null = null;
    let renderedOrderIsStale = false;
    let stagedPass:PrimaryRenderPass|null = null;
    const settleRefresh = async ():Promise<boolean> => {
      if (!refresh) return false;
      if (!(await refresh)) {
        renderedOrderIsStale = isCurrent() && table.lastRenderPass === stagedPass;
        return false;
      }
      await table.whenRendered();
      return isCurrent();
    };

    return (async ():Promise<MoveOutcome> => {
      try {
        if (!originalQuery) {
          complete(false);
          return 'abandoned';
        }
        const loaded = await firstValueFrom(api.work_packages.id(wpId).get());
        workPackage = loaded;
        if (!isCurrent()) {
          complete(false);
          return 'abandoned';
        }
        // A refresh while loading may remove either endpoint of the intent.
        const order = this.currentOrder;
        if (!order.includes(wpId) || (intent.targetId !== null && !order.includes(intent.targetId))) {
          complete(false);
          return 'abandoned';
        }
        const { targetId, edge } = this.resolveEffectiveTarget(intent);
        const renderPass = table.lastRenderPass;
        const source = locateTableRow(wpId, table.tableAndTimelineContainer);
        const target = targetId ? locateTableRow(targetId, table.tableAndTimelineContainer) : null;
        if (!source || (targetId !== null && !target)) {
          complete(false);
          return 'abandoned';
        }
        const { parentNode, nextSibling } = source;
        const stillEligible = () => isCurrent()
          && table.lastRenderPass === renderPass
          && source.parentNode === table.tbody
          && (!target || target.parentNode === table.tbody)
          && this.currentOrder.length === order.length
          && this.currentOrder.every((id, index) => id === order[index])
          && actionService.canPickup(loaded);
        recoverIfCurrent = () => {
          if (!isCurrent() || table.lastRenderPass !== renderPass || source.parentNode !== parentNode) return;
          table.mutate('positions', () => {
            parentNode?.insertBefore(source, nextSibling?.parentNode === parentNode ? nextSibling : null);
          });
        };
        if (!stillEligible()) {
          complete(false);
          return 'abandoned';
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
          return 'unchanged';
        }
        const manualSort = !sortService.isManualSortingMode
          ? sortService.available.find((sort) => sort.column.href?.endsWith('/manualSorting'))
          : undefined;
        const preparedOrder = await orderService.prepareMove(originalQuery, order, wpId, newOrder.indexOf(wpId), isCurrent);
        if (!stillEligible()) {
          complete(false);
          return 'abandoned';
        }
        // Only preparation observes the staged neighbors. Persistence captures no row.
        stagedPass = renderPass;
        table.mutate('positions', () => {
          if (target) table.tbody.insertBefore(source, edge === 'top' ? target : target.nextSibling);
          else table.tbody.appendChild(source);
        });
        const preparedAction = await actionService.prepareDrop(workPackage, source);
        if (!stillEligible()) {
          recoverIfCurrent();
          complete(false);
          return 'abandoned';
        }
        const ownsQuery = (expectedQuery = originalQuery) => !table.destroyed && querySpace.query.value === expectedQuery;
        const preparedQuery = manualSort ? await listService.prepareSave(originalQuery, ownsQuery) : undefined;
        if (!stillEligible()) {
          recoverIfCurrent();
          complete(false);
          return 'abandoned';
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
          if (!isCurrent()) return;
          refresh = refreshLiveView(preparedOrder.order).then(
            () => true,
            (error:unknown) => {
              reportUiFailure(error);
              return false;
            },
          );
        };
        if (preparedQuery && manualSort) {
          originalQuery.setSortBy([manualSort]);
          await preparedQuery.persist();
        }
        complete(true);
        recoverIfCurrent();
        return await settleRefresh() ? 'moved' : 'failed';
      } catch (error:unknown) {
        recoverIfCurrent();
        notification.handleRawError(error, workPackage);
        complete(false);
        await settleRefresh();
        return 'failed';
      } finally {
        if (renderedOrderIsStale) this.releaseMovesAfterNextRender();
        else this.moveInFlight = false;
      }
    })();
  }

  /** The DOM already shows the saved order while the rendered state still holds the old one until a new pass commits. */
  private releaseMovesAfterNextRender():void {
    const table = this.table;
    if (table.destroyed) return;
    const stalePass = table.lastRenderPass;
    this.querySpace.tableRendered.values$()
      .pipe(
        filter(() => table.lastRenderPass !== stalePass),
        take(1),
        takeUntilDestroyed(table.destroyRef),
      )
      .subscribe(() => { this.moveInFlight = false; });
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
    const lastMemberId = siblingRow ? this.lastCollapsedGroupMemberId(siblingRow) : undefined;

    return lastMemberId
      ? { targetId: lastMemberId, edge: 'bottom' }
      : { targetId: intent.targetId, edge: intent.edge };
  }

  private lastCollapsedGroupMemberId(row:HTMLElement):string|undefined {
    const collapsedGroupCssClass = Array.from(row.classList).find((cls) => cls.includes(collapsedGroupClass()));
    if (!collapsedGroupCssClass) return undefined;

    const collapsedGroupId = collapsedGroupCssClass.replace(collapsedGroupClass(), '');
    const groupMembers = this.table.tbody.getElementsByClassName(collapsedGroupClass(collapsedGroupId));
    const lastMember = groupMembers.item(groupMembers.length - 1);
    return lastMember instanceof HTMLElement ? lastMember.dataset.workPackageId : undefined;
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

  /** The query's own rows; expanded relation rows repeat work packages shown elsewhere. */
  protected get currentOrder():string[] {
    return this.table.ledger.occurrences
      .filter((row) => row.renderType === 'primary')
      .filter(isSelectableOccurrence)
      .map((row) => row.workPackageId);
  }
}
