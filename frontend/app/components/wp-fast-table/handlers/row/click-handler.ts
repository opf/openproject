import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-events-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {rowClassName} from '../../builders/row-builder';
import {tdClassName} from '../../builders/cell-builder';

export class RowClickHandler implements TableEventHandler {
  // Injections
  public states:States;
  public wpTableSelection:WorkPackageTableSelection;

  constructor() {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'click.table.row';
  }

  public get SELECTOR() {
    return `.${rowClassName}`;
  }

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    let target = jQuery(evt.target);

    // Shortcut to any clicks within a cell
    // We don't want to handle these.
    if (target.parents(`.${tdClassName}`).length) {
      console.log('Skipping click on inner cell');
      return;
    }

    console.log('ROW CLICK!');

    // Locate the row from event
    let element = target.closest(this.SELECTOR);
    let row = table.rowObject(element.data('workPackageId'));

    // Ignore links
    if (target.is('a')) {
      return;
    }

    // The current row is the last selected work package
    // not matter what other rows are (de-)selected below.
    // Thus save that row for the details view button.
    this.states.table.activeRow.put(row);

    // Update single selection if no modifier present
    if (!(evt.ctrlKey || evt.metaKey || evt.shiftKey)) {
      this.wpTableSelection.setSelection(row);
    }

    // Multiple selection if shift present
    if (evt.shiftKey) {
      this.clearSelection();
      this.wpTableSelection.setMultiSelectionFrom(table.rows, row);
    }

    // Single selection expansion if ctrl / cmd(mac)
    if (evt.ctrlKey || evt.metaKey) {
      this.wpTableSelection.toggleRow(row.workPackageId);
    }
  }

  // TODO check if this can be replace with css user-select: none?
  // Thanks to http://stackoverflow.com/a/880518
  private clearSelection() {
    var selection = (document as any).selection;
    if(selection && selection.empty) {
      selection.empty();
    } else if(window.getSelection) {
      var sel = window.getSelection();
      sel.removeAllRanges();
    }
  }
}

RowClickHandler.$inject = ['states', 'wpTableSelection'];
