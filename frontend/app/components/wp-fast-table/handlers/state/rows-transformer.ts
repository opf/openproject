import {States} from '../../../states.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';

export class RowsTransformer {
  public states:States;

  constructor(public table: WorkPackageTable) {
    injectorBridge(this);

    // Redraw table if the current row state changed
    this.states.table.rows.observe(null)
      .subscribe((rows:WorkPackageResource[]) => {
      var t0 = performance.now();

      table.initialSetup(rows);

      var t1 = performance.now();
      console.log("[RowTransformer] Reinitialized in " + (t1 - t0) + " milliseconds.");
    });


    // Refresh a single row if it exists
    this.states.workPackages.observe(null)
      .subscribe(([changedId, wp]: [string, WorkPackageResource]) => {
        let row = table.rowIndex[changedId];

        if (wp && row) {
          row.object = wp;
          table.refreshWorkPackage(row);
          table.rowIndex[changedId] = row;
        }
      });
  }
}

RowsTransformer.$inject = ['states'];
