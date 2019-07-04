import {Injector} from '@angular/core';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {mergeMap, take, takeUntil} from "rxjs/operators";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {RequestSwitchmap} from "core-app/helpers/rxjs/request-switchmap";
import {Observable, of} from "rxjs";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {RenderedRow} from "core-components/wp-fast-table/builders/primary-render-pass";
import {WorkPackageTableSortByService} from "core-components/wp-fast-table/state/wp-table-sort-by.service";
import {TableDragActionsRegistryService} from "core-components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service";
import {TableDragActionService} from "core-components/wp-table/drag-and-drop/actions/table-drag-action.service";
import {States} from "core-components/states.service";
import {WorkPackageTableTimelineService} from "core-components/wp-fast-table/state/wp-table-timeline.service";
import {tableRowClassName} from "core-components/wp-fast-table/builders/rows/single-row-builder";
import {DragAndDropService} from "core-app/modules/common/drag-and-drop/drag-and-drop.service";
import {ReorderQueryService} from "core-app/modules/common/drag-and-drop/reorder-query.service";
import {DragAndDropHelpers} from "core-app/modules/common/drag-and-drop/drag-and-drop.helpers";
import {WorkPackageTableOrderService} from "core-components/wp-fast-table/state/wp-table-order.service";

export class DragAndDropTransformer {

  private readonly states:States = this.injector.get(States);
  private readonly querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  private readonly dragService:DragAndDropService|null = this.injector.get(DragAndDropService, null);
  private readonly reorderService = this.injector.get(ReorderQueryService);
  private readonly inlineCreateService = this.injector.get(WorkPackageInlineCreateService);
  private readonly wpNotifications = this.injector.get(WorkPackageNotificationService);
  private readonly wpTableSortBy = this.injector.get(WorkPackageTableSortByService);
  private readonly pathHelper = this.injector.get(PathHelperService);
  private readonly wpTableTimeline = this.injector.get(WorkPackageTableTimelineService);
  private readonly wpTableOrder = this.injector.get(WorkPackageTableOrderService);

  // We remember when we want to update the query with a given order
  private queryUpdates = new RequestSwitchmap(
    (order:string[]) => this.saveOrderInQuery(order)
  );
  private readonly dragActionRegistry = this.injector.get(TableDragActionsRegistryService);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    // The DragService may not have been provided
    // in which case we do not provide drag and drop
    if (this.dragService === null) {
      return;
    }

    this.inlineCreateService.newInlineWorkPackageCreated
      .pipe(takeUntil(this.querySpace.stopAllSubscriptions))
      .subscribe((wpId) => {
        const newOrder = this.reorderService.add(this.currentOrder, wpId);
        this.updateOrder(newOrder);
      });

    // Keep query loading requests
    this.queryUpdates
      .observe(this.querySpace.stopAllSubscriptions.pipe(take(1)))
      .subscribe({
        next: () =>  {
          if (this.wpTableTimeline.isVisible) {
            this.table.originalRows = this.currentRenderedOrder.map((e) => e.workPackageId!);
            this.table.redrawTableAndTimeline();
          }
        },
        error: (error:any) => this.wpNotifications.handleRawError(error)
      });

    this.querySpace.stopAllSubscriptions
      .pipe(take(1))
      .subscribe(() => {
        this.dragService!.remove(this.table.tbody);
      });

    this.dragService.register({
      dragContainer: this.table.tbody,
      scrollContainers: [this.table.tbody],
      accepts: () => true,
      moves: (el:any, source:any, handle:HTMLElement) => {
        if (!handle.classList.contains('wp-table--drag-and-drop-handle')) {
          return false;
        }

        const wpId:string = el.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value!;
        return this.actionService.canPickup(workPackage);
      },
      onMoved: (el:HTMLElement, target:HTMLElement, source:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value!;
        const rowIndex = this.findRowIndex(el);

        this.actionService
          .handleDrop(workPackage, el)
          .then(() => {
            const newOrder = this.reorderService.move(this.currentOrder, wpId, rowIndex);
            this.updateOrder(newOrder);
            this.actionService.onNewOrder(newOrder);
            this.wpTableSortBy.switchToManualSorting();
          })
          .catch(() => {
            // Restore element in from container
            DragAndDropHelpers.reinsert(el, el.dataset.sourceIndex || -1, source);
          });
      },
      onRemoved: (el:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const newOrder = this.reorderService.remove(this.currentOrder, wpId);
        this.updateOrder(newOrder);
      },
      onAdded: (el:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value!;
        const rowIndex = this.findRowIndex(el);

        return this.actionService
          .handleDrop(workPackage, el)
          .then(() => {
            const newOrder = this.reorderService.add(this.currentOrder, wpId, rowIndex);
            this.updateOrder(newOrder);
            this.actionService.onNewOrder(newOrder);

            return true;
          })
          .catch(() => false);
      },
      onCloned: (clone:HTMLElement, original:HTMLElement) => {
        // Maintain widths from original
        Array.from(original.children).forEach((source:HTMLElement, index:number) => {
          const target = clone.children.item(index) as HTMLElement;
          target.style.width = source.offsetWidth + "px";
        });
      },
      onShadowInserted: (el:HTMLElement) => {
        this.actionService.changeShadowElement(el);
      },
      onCancel: (el:HTMLElement) => {
        this.actionService.changeShadowElement(el, true);
      },
    });
  }

  /**
   * Update current order
   */
  private updateOrder(newOrder:string[]) {
    newOrder = _.uniq(newOrder);

    // Ensure dragged work packages are being removed.
    this.queryUpdates.request(newOrder);
  }

  protected get actionService():TableDragActionService {
    return this.dragActionRegistry.get(this.injector);
  }

  protected get currentOrder():string[] {
    return this
      .currentRenderedOrder
      .map((row) => row.workPackageId!);
  }

  protected get currentRenderedOrder():RenderedRow[] {
    return this
      .querySpace
      .renderedWorkPackages
      .getValueOr([]);
  }

  private saveOrderInQuery(order:string[]):Observable<unknown> {
    return this.querySpace.query
      .values$()
      .pipe(
        take(1),
        mergeMap(query => {
          const renderMap = _.keyBy(this.currentRenderedOrder, 'workPackageId');
          const mappedOrder = order.map(id => renderMap[id]!);

          /** Update rendered order for e.g., redrawing timeline */
          this.querySpace.rendered.putValue(mappedOrder);

          /** Maintain order when reloading unsaved page */
          this.wpTableOrder.setNewOrder(query, order);

          if (query.persisted) {
              return this.reorderService.saveOrderInQuery(query, order);
          }

          return of(null);
        })
      );
  }

  /**
   * Find the index of the row in the set of rendered work packages.
   * This will skip non-work-package rows such as group headers
   * @param el
   */
  private findRowIndex(el:HTMLElement):number {
    const rows = Array.from(this.table.tbody.getElementsByClassName(tableRowClassName));
    return rows.indexOf(el) || 0;
  }
}
