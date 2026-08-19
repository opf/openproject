import { Injector } from '@angular/core';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { takeUntil } from 'rxjs/operators';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { WorkPackageTable } from '../../wp-fast-table';

export class RelationsTransformer {
  @LazyInject() public wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  @LazyInject() public querySpace:IsolatedQuerySpace;

  constructor(public readonly injector:Injector,
    table:WorkPackageTable) {
    this.wpTableRelationColumns
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
      )
      .subscribe(() => {
        table.redrawTableAndTimeline();
      });
  }
}
