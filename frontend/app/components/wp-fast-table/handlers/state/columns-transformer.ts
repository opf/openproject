import {States} from '../../../states.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';

export class ColumnsTransformer {
  public states:States;

  constructor(public table: WorkPackageTable) {
    injectorBridge(this);

    this.states.table.columns.observe(null).subscribe(() => {
      if (table.rows.length > 0) {
        var t0 = performance.now();
        table.refreshBody();
        var t1 = performance.now();
        console.log("column redraw took " + (t1 - t0) + " milliseconds.");
      }
    });
  }
}

ColumnsTransformer.$inject = ['states'];
