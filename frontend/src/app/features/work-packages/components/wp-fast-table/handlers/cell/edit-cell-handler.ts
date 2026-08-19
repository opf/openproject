import { Injector } from '@angular/core';
import {
  displayClassName,
  displayTriggerLink,
  editableClassName,
  readOnlyClassName,
} from 'core-app/shared/components/fields/display/display-field-renderer';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { getPosition } from 'core-app/shared/helpers/set-click-position/set-click-position';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { States } from 'core-app/core/states/states.service';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { ClickOrEnterHandler } from '../click-or-enter-handler';
import { WorkPackageTable } from '../../wp-fast-table';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class EditCellHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  @LazyInject() public states:States;

  @LazyInject() public halEditing:HalResourceEditingService;

  // Keep a reference to all

  public get EVENT():EventType[] {
    return ['click', 'keydown'];
  }

  public get SELECTOR() {
    return `.${displayClassName}.${editableClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tableAndTimelineContainer;
  }

  constructor(public readonly injector:Injector) {
    super();
  }

  protected processEvent(table:WorkPackageTable, evt:MouseEvent|KeyboardEvent):void {
    debugLog('Starting editing on cell: ', evt.target);

    // Don't intercept clicks on anchor elements - let the browser follow the link
    const clickTarget = evt.target as HTMLElement;
    const foundElement = clickTarget.closest(`a:not(.${displayTriggerLink}),macro`);
    if (foundElement) {
      return;
    }


    evt.preventDefault();

    // Locate the cell from event
    const target = (evt.target as HTMLElement).closest<HTMLElement>(`.${displayClassName}`);
    // Get the target field name
    const fieldName = target?.dataset.fieldName;

    if (!fieldName) {
      debugLog('Click handled by cell not a field? ', evt.target);
      return;
    }

    // Locate the row
    const rowElement = target.closest<HTMLTableRowElement>(`.${tableRowClassName}`)!;
    // Get the work package we're editing
    const workPackageId = rowElement.dataset.workPackageId!;
    const workPackage = this.states.workPackages.get(workPackageId).value!;
    // Get the row context
    const classIdentifier = rowElement.dataset.classIdentifier!;

    // Get any existing edit state for this work package
    const form = table.editing.startEditing(workPackage, classIdentifier);

    let positionOffset = 0;
    if (evt.type === 'click') {
      // Get the position where the user clicked.
      positionOffset = getPosition(evt as MouseEvent);
    }

    // Activate the field
    form.activate(fieldName)
      .then((handler:EditFieldHandler) => {
        handler.$onUserActivate.next();
        handler.focus(positionOffset);
      })
      .catch(() => target.classList.add(readOnlyClassName));
  }
}
