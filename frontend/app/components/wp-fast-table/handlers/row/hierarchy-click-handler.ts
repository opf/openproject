import {ClickOrEnterHandler} from '../click-or-enter-handler';
import {WorkPackageTableHierarchyService} from '../../state/wp-table-hierarchy.service';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {rowClassName} from '../../builders/rows/single-row-builder';

export class HierarchyClickHandler extends ClickOrEnterHandler {
  // Injections
  public states:States;
  public wpTableHierarchy:WorkPackageTableHierarchyService;

  constructor() {
    super();
    injectorBridge(this);
  }

  public get EVENT() {
    return 'click.table.hierarchy';
  }

  public get SELECTOR() {
    return `.${rowClassName} .wp-table--hierarchy-indicator `;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tbody);
  }

  public processEvent(table: WorkPackageTable, evt:JQueryEventObject):boolean {
    let target = jQuery(evt.target);

    // Locate the row from event
    let element = target.closest(`.${rowClassName}`);
    let wpId = element.data('workPackageId');

    this.wpTableHierarchy.toggle(wpId);

    evt.stopImmediatePropagation();
    evt.preventDefault();
    return false;
  }
}

HierarchyClickHandler.$inject = ['states', 'wpTableHierarchy'];
