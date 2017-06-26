import {ClickOrEnterHandler} from '../click-or-enter-handler';
import {WorkPackageTableHierarchiesService} from '../../state/wp-table-hierarchy.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {tableRowClassName} from '../../builders/rows/single-row-builder';

export class HierarchyClickHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  public states:States;
  public wpTableHierarchies:WorkPackageTableHierarchiesService;

  constructor(table: WorkPackageTable) {
    super();
    injectorBridge(this);
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

  public processEvent(table: WorkPackageTable, evt:JQueryEventObject):boolean {
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

HierarchyClickHandler.$inject = ['states', 'wpTableHierarchies'];
