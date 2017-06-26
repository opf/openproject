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
    this.states.query.context.fireOnTransition(this.states.table.rows, 'Query loaded')
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
      .filter(() => this.states.query.context.current === 'Query loaded')
      .subscribe(([changedId, wp]) => {
        if (wp === undefined) {
          return;
        }

        this.table.refreshRows(wp as WorkPackageResourceInterface);
      });
  }
}

RowsTransformer.$inject = ['states'];
