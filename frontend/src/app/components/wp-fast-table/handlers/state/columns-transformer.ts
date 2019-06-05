import {Injector} from '@angular/core';
import {filter, takeUntil} from 'rxjs/operators';
import {debugLog} from '../../../../helpers/debug_output';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";

export class ColumnsTransformer {

  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  public wpTableColumns:WorkPackageTableColumnsService = this.injector.get(WorkPackageTableColumnsService);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    this.querySpace.updates.columnsUpdates
      .values$('Refreshing columns on user request')
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
