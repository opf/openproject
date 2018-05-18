import {Injector} from '@angular/core';
import {States} from '../../../states.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTableHierarchiesService} from '../../state/wp-table-hierarchy.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {ClickOrEnterHandler} from '../click-or-enter-handler';
import {TableEventHandler} from '../table-handler-registry';

export class HierarchyClickHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  public states:States = this.injector.get(States);
  public wpTableHierarchies:WorkPackageTableHierarchiesService = this.injector.get(WorkPackageTableHierarchiesService);

  constructor(public readonly injector:Injector, table:WorkPackageTable) {
    super();
  }

  public get EVENT() {
    return 'click.table.hierarchy';
  }

  public get SELECTOR() {
    return `.${tableRowClassName} .wp-table--hierarchy-indicator `;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tbody);
  }

  public processEvent(table:WorkPackageTable, evt:JQueryEventObject):boolean {
    let target = jQuery(evt.target);

    // Locate the row from event
    let element = target.closest(`.${tableRowClassName}`);
    let wpId = element.data('workPackageId');

    this.wpTableHierarchies.toggle(wpId);

    evt.stopImmediatePropagation();
    evt.preventDefault();
    return false;
  }
}
