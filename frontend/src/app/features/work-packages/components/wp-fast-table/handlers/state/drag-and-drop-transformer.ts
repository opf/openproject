import { Injector } from '@angular/core';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { take, takeUntil } from 'rxjs/operators';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { TableDragActionsRegistryService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service';
import { TableDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-action.service';
import { States } from 'core-app/core/states/states.service';
import { DragAndDropService, DragIntent } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
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

  @LazyInject() private readonly wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() private readonly apiV3Service:ApiV3Service;

  @LazyInject() private readonly wpListService:WorkPackagesListService;

  @LazyInject() private readonly dragActionRegistry:TableDragActionsRegistryService;

  @LazyInject(DragAndDropService, null) private readonly dragService:DragAndDropService|null;

  constructor(public readonly injector:Injector,
    public table:WorkPackageTable) {
    // The DragService may not have been provided
    // in which case we do not provide drag and drop
    if (this.dragService === null) {
      return;
    }

    this.inlineCreateService.newInlineWorkPackageCreated
      .pipe(takeUntil(this.querySpace.stopAllSubscriptions))
      .subscribe(async (wpId) => {
        const newOrder = await this.wpTableOrder.add(this.currentOrder, wpId);
        this.updateRenderedOrder(newOrder);
      });

    this.querySpace.stopAllSubscriptions
      .pipe(take(1))
      .subscribe(() => {
        this.dragService!.remove(this.table.tbody);
      });

    this.dragService.register({
      dragContainer: this.table.tbody,
      scrollContainers: [this.table.scrollContainer],
      itemIdOf: (row) => row.dataset.workPackageId ?? null,
      accepts: () => true,
      canPickup: (row, handle) => {
        if (!handle?.classList.contains('wp-table--drag-and-drop-handle')) {
          return false;
        }

        const wpId:string = row.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value;
        return !!workPackage && this.actionService.canPickup(workPackage);
      },
      // Custom native preview: the row was cloned into `container` already;
      // collapse it to a single subject cell, since a bare `<tr>` clone
      // outside the table loses its column widths.
      onPreviewRendered: (row, container) => {
        const wpId:string = row.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value;
        const clone = container.firstElementChild as HTMLElement|null;
        if (!workPackage || !clone) {
          return;
        }

        const colspan = clone.children.length;
        const td = document.createElement('td');
        td.textContent = workPackage.subjectWithId();
        td.colSpan = colspan;
        td.classList.add('wp-table--cell-td', 'subject');

        clone.style.maxWidth = '500px';
        clone.innerHTML = td.outerHTML;
      },
      // Multi-select drag is not supported — the engine's payload is the
      // single picked-up row. Collapse the selection to that row so the
      // drag never LOOKS like it carries the other selected rows along.
      onDragStarted: (row) => this.collapseSelectionTo(row),
      onMoved: (intent, complete) => this.performMove(intent, complete),
    });
  }

  /** Reduce a multi-row selection to just the picked-up row (see onDragStarted). */
  private collapseSelectionTo(row:HTMLElement):void {
    const wpId = row.dataset.workPackageId;
    if (!wpId) {
      return;
    }

    // `getSelectedWorkPackageIds`, not `selectionCount`: the count also
    // includes false-valued entries a deselect leaves behind.
    const selected = this.wpTableSelection.getSelectedWorkPackageIds();
    const soleSelection = selected.length === 1 && selected[0] === wpId;
    if (selected.length > 0 && !soleSelection) {
      this.wpTableSelection.setSelection(wpId, this.currentOrder.indexOf(wpId));
    }
  }

  /**
   * Resolve and persist a same-list move, then re-render from the
   * persisted order. `complete` must always be called to settle the
   * transaction.
   */
  private performMove(intent:DragIntent, complete:(success:boolean) => void):void {
    void (async () => {
      const wpId = intent.sourceId;

      try {
        const workPackage = await firstValueFrom(this.apiV3Service.work_packages.id(wpId).get());
        const { targetId, edge } = this.resolveEffectiveTarget(intent);

        const newOrder = reorderById({
          list: this.currentOrder,
          getId: (id) => id,
          sourceId: wpId,
          targetId,
          closestEdge: edge,
          axis: 'vertical',
        });
        const rowIndex = newOrder.indexOf(wpId);

        const persistedOrder = await this.wpTableOrder.move(this.currentOrder, wpId, rowIndex);

        const el = locateTableRow(wpId);
        await this.withRowAtTarget(el, newOrder[rowIndex + 1] ?? null, async () => {
          if (el) {
            await this.actionService.handleDrop(workPackage, el);
          }
        });

        // Awaited so the transaction (and the engine's busy gate) stays open
        // across the rebuild, not just the DOM-order computation above.
        await this.updateRenderedOrder(persistedOrder);
        this.actionService.onNewOrder(persistedOrder);

        // Save the query when switching to manual
        const query = this.querySpace.query.value;
        if (query && this.wpTableSortBy.switchToManualSorting(query)) {
          await this.wpListService.createOrSave(query);
        }

        complete(true);
      } catch (e) {
        this.halNotification.handleRawError(e);
        complete(false);
      }
    })();
  }

  /**
   * The hierarchy/group-by action services infer the drop's new parent or
   * group from the row's DOM neighbors (`previousElementSibling` etc). The
   * engine itself never relocates the row, so it is moved to the resolved
   * position for the span of `fn`. Restored ONLY on failure — on success
   * `updateRenderedOrder` tears the row back out via `replaceChildren()`
   * moments later, so restoring first would visibly snap it back before
   * that rebuild moves it again.
   */
  private async withRowAtTarget(el:HTMLElement|null, siblingId:string|null, fn:() => Promise<void>):Promise<void> {
    if (!el) {
      await fn();
      return;
    }

    const { parentNode, nextSibling } = el;
    const sibling = siblingId ? locateTableRow(siblingId) : null;

    if (sibling) {
      this.table.tbody.insertBefore(el, sibling);
    } else {
      this.table.tbody.appendChild(el);
    }

    try {
      await fn();
    } catch (e) {
      parentNode?.insertBefore(el, nextSibling);
      throw e;
    }
  }

  /**
   * Translate the intent's target/edge into id-order terms, redirecting a
   * drop that lands on a collapsed (hidden) group member to after that
   * group's last row instead — dropping "inside" a collapsed group is
   * meaningless since its members aren't individually visible.
   */
  private resolveEffectiveTarget(intent:DragIntent):{ targetId:string|null; edge:Edge|null } {
    const siblingId = this.siblingIdFor(intent);
    const siblingRow = siblingId ? locateTableRow(siblingId) : null;

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
  private async updateRenderedOrder(order:string[]) {
    order = Array.from(new Set(order));

    const mappedOrder = await Promise.all(
      order.map(
        (wpId) => firstValueFrom(this.apiV3Service.work_packages.id(wpId).get()),
      ),
    );

    /** Re-render the table */
    this.table.initialSetup(mappedOrder);
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
