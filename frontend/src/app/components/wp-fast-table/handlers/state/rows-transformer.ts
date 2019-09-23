import {Injector} from '@angular/core';
import {filter, takeUntil} from 'rxjs/operators';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {States} from 'core-components/states.service';
import {WorkPackageViewOrderService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-order.service";
import {WorkPackageViewSortByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sort-by.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {debugLog} from "core-app/helpers/debug_output";

export class RowsTransformer {

  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  public wpTableSortBy = this.injector.get(WorkPackageViewSortByService);
  public wpTableOrder = this.injector.get(WorkPackageViewOrderService);
  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    // Redraw table if the current row state changed
    this.querySpace
      .initialized
      .values$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe(() => {
        let rows:WorkPackageResource[];

        if (this.wpTableSortBy.isManualSortingMode) {
          rows = this.wpTableOrder.orderedWorkPackages();
        } else {
          rows = this.querySpace.results.value!.elements;
        }

        table.initialSetup(rows);
      });

    // Refresh a single row if it exists
    this.states.workPackages.observeChange()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions.asObservable()),
        filter(() => {
          let rendered = this.querySpace.rendered.getValueOr([]);
          return rendered && rendered.length > 0;
        })
      )
      .subscribe(([changedId, wp]) => {
        if (wp === undefined) {
          return;
        }

        this.table.refreshRows(wp);
      });
  }
}
