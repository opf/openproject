import {Injector} from '@angular/core';
import {WorkPackageTableRelationColumnsService} from '../../state/wp-table-relation-columns.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";
import {takeUntil} from "rxjs/operators";

export class RelationsTransformer {

  public wpTableRelationColumns = this.injector.get(WorkPackageTableRelationColumnsService);
  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {

    this.wpTableRelationColumns
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions)
      )
      .subscribe(() => {
        table.redrawTableAndTimeline();
      });
  }
}
