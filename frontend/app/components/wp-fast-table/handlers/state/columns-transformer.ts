import {debugLog} from '../../../../helpers/debug_output';
import {States} from '../../../states.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';

export class ColumnsTransformer {
  public states:States;

  constructor(public table: WorkPackageTable) {
    injectorBridge(this);

    // observeOnScope
    // observeUntil
    this.states.table.columns.observeUntil(this.states.table.stopAllSubscriptions).subscribe(() => {
      if (table.rows.length > 0) {

        var t0 = performance.now();
        // Redraw all visible rows without reloading the table
        table.rows.forEach((wpId) => {
          let row = table.rowIndex[wpId];
          table.refreshRow(row);
        });
        table.postRender();
        var t1 = performance.now();

        debugLog("column redraw took " + (t1 - t0) + " milliseconds.");
      }
    });
  }
}

ColumnsTransformer.$inject = ['states'];
