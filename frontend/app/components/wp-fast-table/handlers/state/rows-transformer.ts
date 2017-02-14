import {debugLog} from '../../../../helpers/debug_output';
import {locateRow} from '../../helpers/wp-table-row-helpers';
import {States} from '../../../states.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';

export class RowsTransformer {
  public states:States;

  constructor(public table: WorkPackageTable) {
    injectorBridge(this);

    // Redraw table if the current row state changed
    this.states.table.rows.observeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((rows:WorkPackageResource[]) => {
      var t0 = performance.now();

      table.initialSetup(rows);
      table.postRender();

      var t1 = performance.now();
      debugLog("[RowTransformer] Reinitialized in " + (t1 - t0) + " milliseconds.");
    });


    // Refresh a single row if it exists
    this.states.workPackages.observeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((nextVal:[string, WorkPackageResource]) => {
        if (!nextVal) {
          return;
        }

        let [changedId, wp] = nextVal;
        let row = table.rowIndex[changedId];

        if (wp && row) {
          row.object = wp;
          this.refreshWorkPackage(table, row);
        }
      });
  }

  /**
   * Refreshes a single entity from changes in the work package itself.
   * Will skip rendering when dirty or fresh. Does not check for table changes.
   */
  private refreshWorkPackage(table, row) {
    // If the work package is dirty, we're working on it
    if (row.object.dirty) {
      debugLog("Skipping row " + row.workPackageId + " since its dirty");
      return;
    }

    // Get the row for the WP if refreshing existing
    let oldRow = row.element || locateRow(row.workPackageId);

    if (oldRow.dataset['lockVersion'] === row.object.lockVersion.toString()) {
      debugLog("Skipping row " + row.workPackageId + " since its fresh");
      return;
    }

    table.refreshRow(row);
  }
}

RowsTransformer.$inject = ['states'];
