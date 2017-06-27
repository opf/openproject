import {debugLog} from '../../../../helpers/debug_output';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {tdClassName} from '../../builders/cell-builder';

export class RowClickHandler implements TableEventHandler {
  // Injections
  public states:States;
  public wpTableSelection:WorkPackageTableSelection;

  constructor(table: WorkPackageTable) {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'click.table.row';
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
    let classIdentifier = element.data('classIdentifier');

    if (!wpId) {
      return true;
    }

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    // The current row is the last selected work package
    // not matter what other rows are (de-)selected below.
    // Thus save that row for the details view button.
    let [index, row] = table.findRenderedRow(classIdentifier);
    this.states.focusedWorkPackage.putValue(wpId);

    // Update single selection if no modifier present
    if (!(evt.ctrlKey || evt.metaKey || evt.shiftKey)) {
      this.wpTableSelection.setSelection(wpId, index);
    }

    // Multiple selection if shift present
    if (evt.shiftKey) {
      this.wpTableSelection.setMultiSelectionFrom(table.renderedRows, wpId, index);
    }

    // Single selection expansion if ctrl / cmd(mac)
    if (evt.ctrlKey || evt.metaKey) {
      this.wpTableSelection.toggleRow(wpId);
    }

    return false;
  }
}

RowClickHandler.$inject = ['states', 'wpTableSelection'];
