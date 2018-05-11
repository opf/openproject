import {Injector} from '@angular/core';
import {scrollTableRowIntoView} from 'core-components/wp-fast-table/helpers/wp-table-row-helpers';
import {distinctUntilChanged, map, takeUntil} from 'rxjs/operators';
import {indicatorCollapsedClass} from '../../builders/modes/hierarchy/single-hierarchy-row-builder';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {collapsedGroupClass, hierarchyGroupClass, hierarchyRootClass} from '../../helpers/wp-table-hierarchy-helpers';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageTableHierarchies} from '../../wp-table-hierarchies';
import {WorkPackageTableHierarchiesService} from './../../state/wp-table-hierarchy.service';
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
