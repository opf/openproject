import {Injector} from '@angular/core';
import {debugLog} from '../../../../helpers/debug_output';
import {ClickPositionMapper} from '../../../common/set-click-position/set-click-position';
import {States} from '../../../states.service';
import {cellClassName, editableClassName, readOnlyClassName} from '../../../wp-edit-form/display-field-renderer';
import {WorkPackageEditingService} from '../../../wp-edit-form/work-package-editing-service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {ClickOrEnterHandler} from '../click-or-enter-handler';
import {TableEventHandler} from '../table-handler-registry';

export class EditCellHandler extends ClickOrEnterHandler implements TableEventHandler {

  // Injections
  public states:States = this.injector.get(States);
  public wpEditing:WorkPackageEditingService = this.injector.get(WorkPackageEditingService);

  // Keep a reference to all

  public get EVENT() {
    return 'click.table.cell, keydown.table.cell';
  }

  public get SELECTOR() {
    return `.${cellClassName}.${editableClassName}`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.container);
  }

  constructor(public readonly injector:Injector, table:WorkPackageTable) {
    super();
    // $injectFields(this, 'states', 'wpEditing');
  }

  protected processEvent(table:WorkPackageTable, evt:JQueryEventObject):boolean {
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
    const workPackage = this.states.workPackages.get(workPackageId).value!;
    // Get the row context
    const classIdentifier = rowElement.data('classIdentifier');

    // Get any existing edit state for this work package
    const form = table.editing.startEditing(workPackage, classIdentifier);

    // Get the position where the user clicked.
    const positionOffset = ClickPositionMapper.getPosition(evt);

    // Activate the field
    form.activate(fieldName)
      .then((handler) => {
        const element = handler.element.find('input');
        ClickPositionMapper.setPosition(element, positionOffset);
      })
      .catch(() => {
        target.addClass(readOnlyClassName);
      });

    return false;
  }
}
