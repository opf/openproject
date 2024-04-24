import { Injector } from '@angular/core';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { takeUntil } from 'rxjs/operators';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { WorkPackageTable } from '../../wp-fast-table';

export class ColumnsTransformer {
  @InjectField() public querySpace:IsolatedQuerySpace;

  @InjectField() public wpTableColumns:WorkPackageViewColumnsService;

  constructor(public readonly injector:Injector,
    public table:WorkPackageTable) {
    this.wpTableColumns
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
      )
      .subscribe(() => {
        if (table.originalRows.length > 0) {
          const t0 = performance.now();
          // Redraw the table section, ignore timeline
          table.redrawTable();

          const t1 = performance.now();

          debugLog(`column redraw took ${t1 - t0} milliseconds.`);
        }
      });
  }
}
