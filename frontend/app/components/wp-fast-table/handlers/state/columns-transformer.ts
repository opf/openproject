import {debugLog} from '../../../../helpers/debug_output';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';

export class ColumnsTransformer {
  public states:States;

  constructor(public table: WorkPackageTable) {
    injectorBridge(this);

    // observeOnScope
    // observeUntil
    this.states.table.columns.values$()
      .takeUntil(this.states.table.stopAllSubscriptions).subscribe(() => {
      if (table.rows.length > 0) {

        var t0 = performance.now();
        // Redraw the table section, ignore timeline
        table.redrawTable();
        var t1 = performance.now();

        debugLog("column redraw took " + (t1 - t0) + " milliseconds.");
      }
    });
  }
}

ColumnsTransformer.$inject = ['states'];
