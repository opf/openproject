import {Injector} from '@angular/core';
import {WorkPackageTableRelationColumnsService} from '../../state/wp-table-relation-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableRelationColumns} from '../../wp-table-relation-columns';
import {TableState} from 'core-components/wp-table/table-state/table-state';

export class RelationsTransformer {

  public wpTableRelationColumns = this.injector.get(WorkPackageTableRelationColumnsService);
  public tableState:TableState = this.injector.get(TableState);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    this.tableState.updates.relationUpdates
      .values$('Refreshing expanded relations on user request')
      .subscribe((state:WorkPackageTableRelationColumns) => {
        table.redrawTableAndTimeline();
      });
  }
}
