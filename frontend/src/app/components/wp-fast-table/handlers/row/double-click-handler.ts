import {Injector} from '@angular/core';
import {StateService} from '@uirouter/core';
import {WorkPackageViewFocusService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service';
import {debugLog} from '../../../../helpers/debug_output';
import {States} from '../../../states.service';
import {tdClassName, wpCellTdClassName} from '../../builders/cell-builder';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';
import {LinkHandling} from "core-app/modules/common/link-handling/link-handling";
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";

export class RowDoubleClickHandler implements TableEventHandler {

  // Injections
  public $state:StateService = this.injector.get(StateService);
  public states:States = this.injector.get(States);
  public wpTableSelection:WorkPackageViewSelectionService = this.injector.get(WorkPackageViewSelectionService);
  public wpTableFocus:WorkPackageViewFocusService = this.injector.get(WorkPackageViewFocusService);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
  }

  public get EVENT() {
    return 'dblclick.table.row';
  }

  public get SELECTOR() {
    return `.${wpCellTdClassName}`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tbody);
  }

  public handleEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent) {
    let target = jQuery(evt.target);

    // Skip clicks with modifiers
    if (LinkHandling.isClickedWithModifier(evt)) {
      return true;
    }

    // Shortcut to any clicks within a cell
    // We don't want to handle these.
    if (target.parents(`.${tdClassName}`).length) {
      debugLog('Skipping click on inner cell');
      return true;
    }

    // Locate the row from event
    let element = target.closest(this.SELECTOR).closest(`.${tableRowClassName}`);
    let wpId = element.data('workPackageId');

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    // Save the currently focused work package
    this.wpTableFocus.updateFocus(wpId);

    this.$state.go(
      'work-packages.show',
      {workPackageId: wpId}
    );

    return false;
  }
}

