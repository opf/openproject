import {Injector} from '@angular/core';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {States} from 'core-components/states.service';
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {mergeMap, take, takeUntil} from "rxjs/operators";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageTableRefreshService} from "core-components/wp-table/wp-table-refresh-request.service";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";
import {RequestSwitchmap} from "core-app/helpers/rxjs/request-switchmap";
import {Observable} from "rxjs";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";

export class DragAndDropTransformer {

  private readonly querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  private readonly states:States = this.injector.get(States);
  private readonly pathHelper = this.injector.get(PathHelperService);
  private readonly dragService:DragAndDropService|null = this.injector.get(DragAndDropService, null);
  private readonly reorderService = this.injector.get(ReorderQueryService);
  private readonly inlineCreateService = this.injector.get(WorkPackageInlineCreateService);
  private readonly wpNotifications = this.injector.get(WorkPackageNotificationService);
  private readonly wpTableRefresh = this.injector.get(WorkPackageTableRefreshService);

  // We remember when we want to update the query with a given order
  private queryUpdates = new RequestSwitchmap(
    (order:string[]) => this.saveOrderInQuery(order)
  );

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
        //next: () => this.table.redrawTableAndTimeline(),
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
      moves: function(el:any, source:any, handle:HTMLElement) {
        return handle.classList.contains('wp-table--drag-and-drop-handle');
      },
      onMoved: (el:HTMLElement) => {
        let row = el as HTMLTableRowElement;
        const wpId:string = row.dataset.workPackageId!;
        const newOrder = this.reorderService.move(this.currentOrder, wpId, row.rowIndex - 1);
        this.updateOrder(newOrder);
      },
      onRemoved: (el:HTMLElement) => {
        const wpId:string = el.dataset.workPackageId!;
        const newOrder = this.reorderService.remove(this.currentOrder, wpId);
        this.updateOrder(newOrder);
      },
      onAdded: (el:HTMLElement) => {
        let row = el as HTMLTableRowElement;
        const wpId:string = row.dataset.workPackageId!;
        const newOrder = this.reorderService.add(this.currentOrder, wpId, row.rowIndex - 1);
        this.updateOrder(newOrder);

        return Promise.resolve(true);
      }
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

  protected get currentOrder():string[] {
    return this.querySpace
      .results
      .mapOr((results) => results.elements.map(el => el.id!), []);
  }

  private saveOrderInQuery(order:string[]):Observable<unknown> {
    return this.querySpace.query
      .values$()
      .pipe(
        take(1),
        mergeMap(query => this.reorderService.saveOrderInQuery(query, order))
      );
  }
}
