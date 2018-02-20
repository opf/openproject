import {Injector} from '@angular/core';
import {States} from '../../../states.service';
import {WorkPackageTableRelationColumnsService} from '../../state/wp-table-relation-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableRelationColumns} from '../../wp-table-relation-columns';

export class RelationsTransformer {

  public wpTableRelationColumns = this.injector.get(WorkPackageTableRelationColumnsService);
  public states:States = this.injector.get(States);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    this.states.updates.relationUpdates
      .values$('Refreshing expanded relations on user request')
      .subscribe((state:WorkPackageTableRelationColumns) => {
        table.redrawTableAndTimeline();
      });
  }
}
