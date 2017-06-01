import {debugLog} from "../../../../helpers/debug_output";
import {injectorBridge} from "../../../angular/angular-injector-bridge.functions";
import {WorkPackageResourceInterface} from "../../../api/api-v3/hal-resources/work-package-resource.service";
import {States} from "../../../states.service";
import {WorkPackageTable} from "../../wp-fast-table";
import {WorkPackageTableRow} from "../../wp-table.interfaces";


export class RowsTransformer {
  public states: States;

  constructor(public table: WorkPackageTable) {
    injectorBridge(this);

    // Redraw table if the current row state changed
    this.states.table.context.fireOnTransition(this.states.table.rows, 'Query loaded')
      .values$('Initializing table after query was initialized')
      .takeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((rows: WorkPackageResourceInterface[]) => {
        var t0 = performance.now();

        table.initialSetup(rows);

        var t1 = performance.now();
        debugLog("[RowTransformer] Reinitialized in " + (t1 - t0) + " milliseconds.");
      });

    // Refresh a single row if it exists
    this.states.workPackages.observeChange()
      .takeUntil(this.states.table.stopAllSubscriptions.asObservable())
      .subscribe(([changedId, wp, state]) => {
        if (wp === undefined) {
          return;
        }

        // let [changedId, wp] = nextVal;
        let row: WorkPackageTableRow = table.rowIndex[changedId];

        if (wp && row) {
          row.object = wp as any;
          this.refreshWorkPackage(table, row);
        }
      });
  }

  /**
   * Refreshes a single entity from changes in the work package itself.
   * Will skip rendering when dirty or fresh. Does not check for table changes.
   */
  private refreshWorkPackage(table: WorkPackageTable, row: WorkPackageTableRow) {
    table.refreshRow(row);
  }
}

RowsTransformer.$inject = ['states'];
