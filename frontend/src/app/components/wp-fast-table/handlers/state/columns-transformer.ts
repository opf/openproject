import { Injector } from '@angular/core';
import { debugLog } from '../../../../helpers/debug_output';
import { WorkPackageTable } from '../../wp-fast-table';
import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { takeUntil } from "rxjs/operators";
import { WorkPackageViewColumnsService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export class ColumnsTransformer {

  @InjectField() public querySpace:IsolatedQuerySpace;
  @InjectField() public wpTableColumns:WorkPackageViewColumnsService;

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    this.wpTableColumns
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe(() => {
        if (table.originalRows.length > 0) {

          var t0 = performance.now();
          // Redraw the table section, ignore timeline
          table.redrawTable();

          var t1 = performance.now();

          debugLog('column redraw took ' + (t1 - t0) + ' milliseconds.');
        }
      });
  }
}
