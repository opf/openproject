import {Injector} from '@angular/core';
import {debugLog} from '../../../../helpers/debug_output';
import {WorkPackageResourceInterface} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {States} from 'core-components/states.service';

export class RowsTransformer {

  public tableState:TableState = this.injector.get(TableState);
  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    // Redraw table if the current row state changed
    this.states.query.context.fireOnTransition(this.tableState.rows, 'Query loaded')
      .values$('Initializing table after query was initialized')
      .takeUntil(this.tableState.stopAllSubscriptions)
      .subscribe((rows:WorkPackageResourceInterface[]) => {
        var t0 = performance.now();

        table.initialSetup(rows);

        var t1 = performance.now();
        debugLog('[RowTransformer] Reinitialized in ' + (t1 - t0) + ' milliseconds.');
      });

    // Refresh a single row if it exists
    this.states.workPackages.observeChange()
      .takeUntil(this.tableState.stopAllSubscriptions.asObservable())
      .filter(() => this.states.query.context.current === 'Query loaded')
      .subscribe(([changedId, wp]) => {
        if (wp === undefined) {
          return;
        }

        this.table.refreshRows(wp as WorkPackageResourceInterface);
      });
  }
}
