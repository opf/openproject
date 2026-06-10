import { Injector } from '@angular/core';
import { filter, takeUntil } from 'rxjs/operators';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageTable } from '../../wp-fast-table';

export class RowsTransformer {
  @LazyInject() querySpace:IsolatedQuerySpace;

  @LazyInject() wpTableSortBy:WorkPackageViewSortByService;

  @LazyInject() wpTableOrder:WorkPackageViewOrderService;

  @LazyInject() states:States;

  constructor(public readonly injector:Injector,
    public table:WorkPackageTable) {
    // Redraw table if the current row state changed
    this.querySpace
      .initialized
      .values$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
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
          const rendered = this.querySpace.tableRendered.getValueOr([]);
          return rendered && rendered.length > 0;
        }),
      )
      .subscribe(([changedId, wp]) => {
        if (wp === undefined) {
          return;
        }

        this.table.refreshRows(wp);
      });
  }
}
