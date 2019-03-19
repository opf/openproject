import {Injector} from '@angular/core';
import {WorkPackageTableRelationColumnsService} from '../../state/wp-table-relation-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableRelationColumns} from '../../wp-table-relation-columns';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";

export class RelationsTransformer {

  public wpTableRelationColumns = this.injector.get(WorkPackageTableRelationColumnsService);
  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    this.querySpace.updates.relationUpdates
      .values$('Refreshing expanded relations on user request')
      .subscribe((state:WorkPackageTableRelationColumns) => {
        table.redrawTableAndTimeline();
      });
  }
}
