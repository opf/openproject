import {Injector} from '@angular/core';
import {distinctUntilChanged, takeUntil} from 'rxjs/operators';
import {WorkPackageTable} from '../../wp-fast-table';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {WorkPackageTableHighlightingService} from 'core-components/wp-fast-table/state/wp-table-highlighting.service';

export class HighlightingTransformer {

  public wpTableHighlighting:WorkPackageTableHighlightingService = this.injector.get(WorkPackageTableHighlightingService);
  public querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
    this.querySpace.highlighting
      .values$('Refreshing highlights on user request')
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
        distinctUntilChanged()
      )
      .subscribe(() => table.redrawTable());
  }
}
