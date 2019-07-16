import {Injector} from '@angular/core';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
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
import {DragAndDropHelpers} from "core-app/modules/common/drag-and-drop/drag-and-drop.helpers";
import {WorkPackageTableOrderService} from "core-components/wp-fast-table/state/wp-table-order.service";

export class DragAndDropTransformer {

  private readonly states:States = this.injector.get(States);
  private readonly querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  private readonly dragService:DragAndDropService|null = this.injector.get(DragAndDropService, null);
  private readonly inlineCreateService = this.injector.get(WorkPackageInlineCreateService);
  private readonly wpNotifications = this.injector.get(WorkPackageNotificationService);
  private readonly wpTableSortBy = this.injector.get(WorkPackageTableSortByService);
  private readonly wpTableTimeline = this.injector.get(WorkPackageTableTimelineService);
  private readonly wpTableOrder = this.injector.get(WorkPackageTableOrderService);

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
      scrollContainers: [this.table.container],
      accepts: () => true,
      moves: (el:any, source:any, handle:HTMLElement) => {
        if (!handle.classList.contains('wp-table--drag-and-drop-handle')) {
          return false;
        }

        const wpId:string = el.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value!;
        return this.actionService.canPickup(workPackage);
      },
      onMoved: async (el:HTMLElement, target:HTMLElement, source:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value!;
        const rowIndex = this.findRowIndex(el);

        try {
          const newOrder = await this.wpTableOrder.move(this.currentOrder, wpId, rowIndex);
          await this.actionService.handleDrop(workPackage, el);
          this.updateRenderedOrder(newOrder);
          this.actionService.onNewOrder(newOrder);
          this.wpTableSortBy.switchToManualSorting();
        } catch (e) {
          this.wpNotifications.handleRawError(e);

          // Restore element in from container
          DragAndDropHelpers.reinsert(el, el.dataset.sourceIndex || -1, source);
        }
      },
      onRemoved: (el:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const newOrder = this.wpTableOrder.remove(this.currentOrder, wpId);
        this.updateRenderedOrder(newOrder);
      },
      onAdded: (el:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const workPackage = this.states.workPackages.get(wpId).value!;
        const rowIndex = this.findRowIndex(el);

        return this.actionService
          .handleDrop(workPackage, el)
          .then(async () => {
            const newOrder = await this.wpTableOrder.add(this.currentOrder, wpId, rowIndex);
            this.updateRenderedOrder(newOrder);
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
   * Update current rendered order
   */
  private updateRenderedOrder(order:string[]) {
    order = _.uniq(order);

    const renderMap = _.keyBy(this.currentRenderedOrder, 'workPackageId');
    const mappedOrder = order.map(id => renderMap[id]!);

    /** Update rendered order for e.g., redrawing timeline */
    this.querySpace.rendered.putValue(mappedOrder);

    /** If the timeline is visible, we will need to redraw it */
    this.table.originalRows = this.currentRenderedOrder.map((e) => e.workPackageId!);
    this.table.redrawTableAndTimeline();
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
