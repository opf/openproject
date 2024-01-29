import { Injector } from '@angular/core';
import { filter, map } from 'rxjs/operators';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { tableRefreshRequest } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.actions';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';

export class SharingTransformer {
  public actions$ = this.injector.get(ActionsService);

  constructor(
    readonly injector:Injector,
    readonly table:WorkPackageTable,
  ) {
    this.actions$
      .ofType(shareModalUpdated)
      .pipe(
        map((action) => action.workPackageId),
        filter((id) => !!this.table.renderedRows.find((el:RenderedWorkPackage) => el.workPackageId === id)),
      )
      .subscribe(() => {
        this.actions$.dispatch(tableRefreshRequest());
      });
  }
}
