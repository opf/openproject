import {Injector} from '@angular/core';
import {filter, takeUntil} from 'rxjs/operators';
import {debugLog} from '../../../../helpers/debug_output';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {States} from 'core-components/states.service';

export class RowsTransformer {

  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    // Redraw table if the current row state changed
    this.querySpace.ready.fireOnTransition(this.querySpace.rows, 'Query loaded')
      .values$('Initializing table after query was initialized')
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe((rows:WorkPackageResource[]) => {
        table.initialSetup(rows);
      });

    // Refresh a single row if it exists
    this.states.workPackages.observeChange()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions.asObservable()),
        filter(() => this.querySpace.ready.current === 'Query loaded')
      )
      .subscribe(([changedId, wp]) => {
        if (wp === undefined) {
          return;
        }

        this.table.refreshRows(wp);
      });
  }
}
