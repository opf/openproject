import {debugLog} from '../../../../helpers/debug_output';
import {$injectFields} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {tdClassName} from '../../builders/cell-builder';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';

export class RowDoubleClickHandler implements TableEventHandler {
  // Injections
  public $state:ng.ui.IStateService;
  public states:States;
  public wpTableSelection:WorkPackageTableSelection;
  public wpTableFocus:WorkPackageTableFocusService;

  constructor(table:WorkPackageTable) {
    $injectFields(this, '$state', 'states', 'wpTableSelection', 'wpTableFocus');
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

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    let target = jQuery(evt.target);

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
       { workPackageId: wpId }
    );

    return false;
  }
}

