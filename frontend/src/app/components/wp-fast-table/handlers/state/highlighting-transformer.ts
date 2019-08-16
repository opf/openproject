import {Injector} from '@angular/core';
import {distinctUntilChanged, takeUntil} from 'rxjs/operators';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageViewHighlightingService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-highlighting.service';

export class HighlightingTransformer {

  public wpTableHighlighting:WorkPackageViewHighlightingService = this.injector.get(WorkPackageViewHighlightingService);
  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
    this.wpTableHighlighting
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
        distinctUntilChanged()
      )
      .subscribe(() => table.redrawTable());
  }
}
