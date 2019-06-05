import {Injector} from '@angular/core';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {States} from 'core-components/states.service';
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {DragAndDropService} from "core-app/modules/boards/drag-and-drop/drag-and-drop.service";
import {RenderedRow, RowRenderInfo} from "core-components/wp-fast-table/builders/primary-render-pass";
import {take, takeUntil} from "rxjs/operators";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WorkPackageTableRefreshService} from "core-components/wp-table/wp-table-refresh-request.service";
import {ReorderQueryService} from "core-app/modules/boards/drag-and-drop/reorder-query.service";

export class DragAndDropTransformer {

  private readonly querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  private readonly states:States = this.injector.get(States);
  private readonly pathHelper = this.injector.get(PathHelperService);
  private readonly dragService = this.injector.get(DragAndDropService, null);
  private readonly reorderService = this.injector.get(ReorderQueryService);
  private readonly inlineCreateService = this.injector.get(WorkPackageInlineCreateService);
  private readonly wpTableRefresh = this.injector.get(WorkPackageTableRefreshService);

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
        this.reorderService.add(this.currentOrder, wpId);
        this.wpTableRefresh.request('Drag and Drop added item');
      });

    this.querySpace.stopAllSubscriptions
      .pipe(take(1))
      .subscribe(() => {
        this.dragService
          .remove(this.table.tbody)
          .then(() => this.wpTableRefresh.request('Drag and Drop change'));
      });

    this.dragService.register({
      container: this.table.tbody,
      scrollContainers: [this.table.tbody],
      moves: function(el:any, source:any, handle:HTMLElement) {
        return handle.classList.contains('wp-table--drag-and-drop-handle');
      },
      onMoved: (row:HTMLTableRowElement) => {
        const wpId:string = row.dataset.workPackageId!;
        this.reorderService.move(this.currentOrder, wpId, row.rowIndex - 1);
        this.wpTableRefresh.request('Drag and Drop moved item');
      },
      onRemoved: (row:HTMLTableRowElement) => {
        const wpId:string = row.dataset.workPackageId!;
        this.reorderService.remove(this.currentOrder, wpId);
        this.wpTableRefresh.request('Drag and Drop moved item');
      },
      onAdded: (row:HTMLTableRowElement) => {
        const wpId:string = row.dataset.workPackageId!;
        this.reorderService.add(this.currentOrder, wpId, row.rowIndex - 1);
        this.wpTableRefresh.request('Drag and Drop moved item');
      }
    });
  }

  protected get currentOrder():string[] {
    return this.querySpace
      .results
      .mapOr((results) => results.elements.map(el => el.id!), []);
  }
}
