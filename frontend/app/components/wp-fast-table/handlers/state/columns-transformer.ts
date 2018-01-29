import {Injector} from '@angular/core';
import {debugLog} from '../../../../helpers/debug_output';
import {States} from '../../../states.service';
import {WorkPackageTableColumnsService} from '../../state/wp-table-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';

export class ColumnsTransformer {

  public states:States = this.injector.get(States);
  public wpTableColumns:WorkPackageTableColumnsService = this.injector.get(WorkPackageTableColumnsService);

  constructor(public readonly injector:Injector,
              public table:WorkPackageTable) {

    // $injectFields(this, 'states', 'wpTableColumns');

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

          debugLog('column redraw took ' + (t1 - t0) + ' milliseconds.');
        }
      });
  }
}
