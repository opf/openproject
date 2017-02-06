import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {States} from '../../../states.service';
import {TableEventHandler} from '../table-handler-registry';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {rowClassName} from '../../builders/rows/single-row-builder';
import {tdClassName} from '../../builders/cell-builder';

export class RowDoubleClickHandler implements TableEventHandler {
  // Injections
  public $state:ng.ui.IStateService;
  public states:States;
  public wpTableSelection:WorkPackageTableSelection;

  constructor() {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'dblclick.table.row';
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

    console.log('ROW DOUBLE CLICK!');

    // Locate the row from event
    let element = target.closest(this.SELECTOR);
    let row = table.rowObject(element.data('workPackageId'));

    // Ignore links
    if (target.is('a')) {
      return;
    }

    // Save the currently focused work package
    this.states.focusedWorkPackage.put(row.workPackageId);

    this.$state.go(
      'work-packages.show',
       { workPackageId: row.workPackageId }
    );
  }
}

RowDoubleClickHandler.$inject = ['$state', 'states', 'wpTableSelection'];
