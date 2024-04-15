import { Injector } from '@angular/core';
import { displayClassName, editableClassName, readOnlyClassName } from 'core-app/shared/components/fields/display/display-field-renderer';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { getPosition } from 'core-app/shared/helpers/set-click-position/set-click-position';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { States } from 'core-app/core/states/states.service';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { ClickOrEnterHandler } from '../click-or-enter-handler';
import { WorkPackageTable } from '../../wp-fast-table';
import { tableRowClassName } from '../../builders/rows/single-row-builder';

export class EditCellHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  @InjectField() public states:States;

  @InjectField() public halEditing:HalResourceEditingService;

  // Keep a reference to all

  public get EVENT() {
    return 'click.table.cell, keydown.table.cell';
  }

  public get SELECTOR() {
    return `.${displayClassName}.${editableClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return jQuery(view.workPackageTable.tableAndTimelineContainer);
  }

  constructor(public readonly injector:Injector) {
    super();
  }

  protected processEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):void {
    debugLog('Starting editing on cell: ', evt.target);
    evt.preventDefault();

    // Locate the cell from event
    const target = jQuery(evt.target).closest(`.${displayClassName}`);
    // Get the target field name
    const fieldName = target.data('fieldName');

    if (!fieldName) {
      debugLog('Click handled by cell not a field? ', evt.target);
      return;
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
    const positionOffset = getPosition(evt);

    // Activate the field
    form.activate(fieldName)
      .then((handler:EditFieldHandler) => {
        handler.$onUserActivate.next();
        handler.focus(positionOffset);
      })
      .catch(() => target.addClass(readOnlyClassName));
  }
}
