import {InputState} from 'reactivestates';
import {debugLog} from '../../../../helpers/debug_output';
import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {States} from '../../../states.service';
import {TableRowEditContext} from '../../../wp-edit-form/table-row-edit-context';
import {WorkPackageEditForm} from '../../../wp-edit-form/work-package-edit-form';
import {cellClassName, editableClassName, readOnlyClassName} from '../../builders/cell-builder';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {ClickOrEnterHandler} from '../click-or-enter-handler';
import {TableEventHandler} from '../table-handler-registry';

export class EditCellHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  public states:States;

  public get EVENT() {
    return 'click.table.cell, keydown.table.cell';
  }

  public get SELECTOR() {
    return `.${cellClassName}.${editableClassName}`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.container);
  }

  constructor(table: WorkPackageTable) {
    super();
    injectorBridge(this);
  }

  protected processEvent(table: WorkPackageTable, evt:JQueryEventObject):boolean {
    debugLog('Starting editing on cell: ', evt.target);
    evt.preventDefault();

    // Locate the cell from event
    let target = jQuery(evt.target).closest(`.${cellClassName}`);
    // Get the target field name
    let fieldName = target.data('fieldName');

    if (!fieldName) {
      debugLog('Click handled by cell not a field? ', evt.target);
      return true;
    }

    // Locate the row
    const rowElement = target.closest(`.${tableRowClassName}`);
    // Get the work package we're editing
    const workPackageId = rowElement.data('workPackageId');
    // Get the row context
    const classIdentifier = rowElement.data('classIdentifier');

    // Get any existing edit state for this work package
    let state = this.editState(workPackageId);
    let form = state.value || this.startEditing(state, workPackageId);

    // Get the position where the user clicked.
    const positionOffset = this.getClickPosition(evt);

    // Set editing context to table
    form.editContext = new TableRowEditContext(workPackageId, classIdentifier);

    // Activate the field
    form.activate(fieldName)
      .then((fieldElement:ng.IAugmentedJQuery) => {
        this.setClickPosition(fieldElement.find('input'), positionOffset);
      })
      .catch(() => {
        target.addClass(readOnlyClassName);
      });

    return false;
  }

  private setClickPosition(element:ng.IAugmentedJQuery, offset:number):void {
    try {
      (element[0] as HTMLInputElement).setSelectionRange(offset, offset);
    } catch(e) {
      debugLog('Failed to set click position for edit field.', e);
    }
  }

  private getClickPosition(evt:JQueryEventObject):number {
    try {
      const range = document.caretRangeFromPoint(evt.clientX, evt.clientY);
      return range.startOffset;
    } catch(e) {
      debugLog('Failed to get click position for edit field.', e);
      return 0;
    }
  }

  private startEditing(state: InputState<WorkPackageEditForm>, workPackageId:string):WorkPackageEditForm {
    let form = new WorkPackageEditForm(workPackageId);
    state.putValue(form);
    return form;
  }

  /**
   * Retrieve the edit state for this work package
   */
  private editState(workPackageId: string): InputState<WorkPackageEditForm> {
    return this.states.editing.get(workPackageId);
  }
}

EditCellHandler.$inject = ['states'];
