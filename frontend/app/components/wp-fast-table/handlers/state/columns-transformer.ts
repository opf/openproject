import {debugLog} from '../../../../helpers/debug_output';
import {$injectFields, injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {States} from '../../../states.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';

export class ColumnsTransformer {
  public states:States;
  public wpTableColumns:WorkPackageTableColumnsService;

  constructor(public table: WorkPackageTable) {
    $injectFields(this, 'states', 'wpTableColumns');

    this.states.updates.columnsUpdates
      .values$('Refreshing columns on user request')
      .filter(() => this.wpTableColumns.hasRelationColumns() === false)
      .takeUntil(this.states.table.stopAllSubscriptions)
      .subscribe(() => {
        if (table.originalRows.length > 0) {

          var t0 = performance.now();
          // Redraw the table section, ignore timeline
          table.redrawTable();

          var t1 = performance.now();

          debugLog("column redraw took " + (t1 - t0) + " milliseconds.");
        }
    });
  }
}
