import { Injector } from '@angular/core';
import { States } from 'core-app/core/states/states.service';
import { TableEventComponent, TableEventHandler } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { ClickOrEnterHandler } from '../click-or-enter-handler';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class HierarchyClickHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  @LazyInject() public states:States;

  @LazyInject() public wpTableHierarchies:WorkPackageViewHierarchiesService;

  constructor(public readonly injector:Injector) {
    super();
  }

  public get EVENT():EventType {
    return 'click';
  }

  public get SELECTOR() {
    return '.wp-table--hierarchy-indicator';
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tbody;
  }

  public processEvent(table:WorkPackageTable, evt:MouseEvent|KeyboardEvent):void {
    const target = evt.target as HTMLElement;

    // Locate the row from event
    const element = target.closest<HTMLElement>(`.${tableRowClassName}`);
    const wpId = element?.dataset.workPackageId ?? '';

    this.wpTableHierarchies.toggle(wpId);

    evt.stopImmediatePropagation();
    evt.preventDefault();
  }
}
