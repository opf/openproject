import {Injector} from '@angular/core';
import {StateService} from '@uirouter/core';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {debugLog} from '../../../../helpers/debug_output';
import {States} from '../../../states.service';
import {tdClassName} from '../../builders/cell-builder';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';
import {LinkHandling} from "core-app/modules/common/link-handling/link-handling";

export class RowDoubleClickHandler implements TableEventHandler {

  // Injections
  public $state:StateService = this.injector.get(StateService);
  public states:States = this.injector.get(States);
  public wpTableSelection:WorkPackageTableSelection = this.injector.get(WorkPackageTableSelection);
  public wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
  }

  public get EVENT() {
    return 'dblclick.table.row';
  }

  public get SELECTOR() {
    return `.${tableRowClassName}`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tbody);
  }

  public handleEvent(table:WorkPackageTable, evt:JQueryEventObject) {
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
    let element = target.closest(this.SELECTOR);
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

