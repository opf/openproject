import { Injector } from '@angular/core';
import { debugLog } from '../../../../helpers/debug_output';
import { States } from '../../../states.service';
import { displayClassName, editableClassName, readOnlyClassName } from 'core-app/modules/fields/display/display-field-renderer';

import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { ClickOrEnterHandler } from '../click-or-enter-handler';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { ClickPositionMapper } from "core-app/modules/common/set-click-position/set-click-position";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { EditFieldHandler } from "core-app/modules/fields/edit/editing-portal/edit-field-handler";

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

  protected processEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):boolean {
    debugLog('Starting editing on cell: ', evt.target);
    evt.preventDefault();

    // Locate the cell from event
    const target = jQuery(evt.target).closest(`.${displayClassName}`);
    // Get the target field name
    const fieldName = target.data('fieldName');

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
      .then((handler:EditFieldHandler) => {
        handler.$onUserActivate.next();
        handler.focus(positionOffset);
      })
      .catch(() => target.addClass(readOnlyClassName));

    return false;
  }
}
