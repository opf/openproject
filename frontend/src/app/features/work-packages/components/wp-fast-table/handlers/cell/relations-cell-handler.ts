import { Injector } from '@angular/core';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { relationCellIndicatorClassName, relationCellTdClassName } from '../../builders/relation-cell-builder';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { ClickOrEnterHandler } from '../click-or-enter-handler';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class RelationsCellHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  @LazyInject() wpTableRelationColumns:WorkPackageViewRelationColumnsService;

  public get EVENT():EventType[] {
    return ['click', 'keydown'];
  }

  public get SELECTOR() {
    return `.${relationCellIndicatorClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tableAndTimelineContainer;
  }

  constructor(public readonly injector:Injector) {
    super();
  }

  protected processEvent(table:WorkPackageTable, evt:MouseEvent|KeyboardEvent):void {
    debugLog('Handled click on relation cell %o', evt.target);
    evt.preventDefault();

    // Locate the relation td
    const td = (evt.target as HTMLElement).closest<HTMLTableColElement>(`.${relationCellTdClassName}`);
    const columnId = td?.dataset.columnId ?? '';

    // Locate the row
    const rowElement = (evt.target as HTMLElement).closest<HTMLTableRowElement>(`.${tableRowClassName}`);
    const workPackageId = rowElement?.dataset.workPackageId ?? '';

    // If currently expanded
    if (this.wpTableRelationColumns.getExpandFor(workPackageId) === columnId) {
      this.wpTableRelationColumns.collapse(workPackageId);
    } else {
      this.wpTableRelationColumns.setExpandFor(workPackageId, columnId);
    }
  }
}
