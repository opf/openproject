import {Injector} from '@angular/core';
import {debugLog} from '../../../../helpers/debug_output';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';


export class RowsTransformer {

  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    // Redraw table if the current row state changed
    this.states.query.context.fireOnTransition(this.states.table.rows, 'Query loaded')
      .values$('Initializing table after query was initialized')
      .takeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((rows:WorkPackageResourceInterface[]) => {
        var t0 = performance.now();

        table.initialSetup(rows);

        var t1 = performance.now();
        debugLog('[RowTransformer] Reinitialized in ' + (t1 - t0) + ' milliseconds.');
      });

    // Refresh a single row if it exists
    this.states.workPackages.observeChange()
      .takeUntil(this.states.table.stopAllSubscriptions.asObservable())
      .filter(() => this.states.query.context.current === 'Query loaded')
      .subscribe(([changedId, wp]) => {
        if (wp === undefined) {
          return;
        }

        this.table.refreshRows(wp as WorkPackageResourceInterface);
      });
  }
}
