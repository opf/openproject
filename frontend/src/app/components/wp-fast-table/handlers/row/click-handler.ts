import {Injector} from '@angular/core';
import {StateService} from '@uirouter/core';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {debugLog} from '../../../../helpers/debug_output';
import {States} from '../../../states.service';
import {KeepTabService} from '../../../wp-single-view-tabs/keep-tab/keep-tab.service';
import {tdClassName} from '../../builders/cell-builder';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';

export class RowClickHandler implements TableEventHandler {

  // Injections
  public $state:StateService = this.injector.get(StateService);
  public states:States = this.injector.get(States);
  public keepTab:KeepTabService = this.injector.get(KeepTabService);
  public wpTableSelection:WorkPackageTableSelection = this.injector.get(WorkPackageTableSelection);
  public wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
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

  public handleEvent(table:WorkPackageTable, evt:JQueryEventObject) {
    let target = jQuery(evt.target);

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
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
    let classIdentifier = element.data('classIdentifier');

    if (!wpId) {
      return true;
    }

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    let [index, row] = table.findRenderedRow(classIdentifier);

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

    // The current row is the last selected work package
    // not matter what other rows are (de-)selected below.
    // Thus save that row for the details view button.
    this.wpTableFocus.updateFocus(wpId);
    return false;
  }
}

