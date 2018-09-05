import {Injector} from '@angular/core';
import {distinctUntilChanged, takeUntil} from 'rxjs/operators';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {WorkPackageTableHighlightingService} from 'core-components/wp-fast-table/state/wp-table-highlighting.service';

export class HighlightingTransformer {

  public wpTableHighlighting:WorkPackageTableHighlightingService = this.injector.get(WorkPackageTableHighlightingService);
  public tableState:TableState = this.injector.get(TableState);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
    this.tableState.highlighting
      .values$('Refreshing highlights on user request')
      .pipe(
        takeUntil(this.tableState.stopAllSubscriptions),
        distinctUntilChanged()
      )
      .subscribe(() => table.redrawTable());
  }
}
