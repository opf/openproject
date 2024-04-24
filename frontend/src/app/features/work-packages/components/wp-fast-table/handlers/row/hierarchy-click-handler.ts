import { Injector } from '@angular/core';
import { States } from 'core-app/core/states/states.service';
import { TableEventComponent, TableEventHandler } from 'core-app/features/work-packages/components/wp-fast-table/handlers/table-handler-registry';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { ClickOrEnterHandler } from '../click-or-enter-handler';

export class HierarchyClickHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  @InjectField() public states:States;

  @InjectField() public wpTableHierarchies:WorkPackageViewHierarchiesService;

  constructor(public readonly injector:Injector) {
    super();
  }

  public get EVENT() {
    return 'click.table.hierarchy';
  }

  public get SELECTOR() {
    return `.wp-table--hierarchy-indicator`;
  }

  public eventScope(view:TableEventComponent) {
    return jQuery(view.workPackageTable.tbody);
  }

  public processEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):void {
    const target = jQuery(evt.target);

    // Locate the row from event
    const element = target.closest(`.${tableRowClassName}`);
    const wpId = element.data('workPackageId');

    this.wpTableHierarchies.toggle(wpId);

    evt.stopImmediatePropagation();
    evt.preventDefault();
  }
}
