import { Injector } from '@angular/core';
import { distinctUntilChanged, takeUntil } from 'rxjs/operators';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { WorkPackageTable } from '../../wp-fast-table';

export class HighlightingTransformer {
  @InjectField() public wpTableHighlighting:WorkPackageViewHighlightingService;

  @InjectField() public querySpace:IsolatedQuerySpace;

  constructor(public readonly injector:Injector,
    table:WorkPackageTable) {
    this.wpTableHighlighting
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
        distinctUntilChanged(),
      )
      .subscribe(() => table.redrawTable());
  }
}
