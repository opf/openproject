import { Injector } from '@angular/core';
import { StateService } from '@uirouter/core';
import { WorkPackageViewFocusService } from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { debugLog } from '../../../../helpers/debug_output';
import { States } from '../../../states.service';
import { tdClassName } from '../../builders/cell-builder';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { WorkPackageTable } from '../../wp-fast-table';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { LinkHandling } from "core-app/modules/common/link-handling/link-handling";
import { WorkPackageViewSelectionService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import { displayClassName } from "core-app/modules/fields/display/display-field-renderer";
import { activeFieldClassName } from "core-app/modules/fields/edit/edit-form/edit-form";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export class RowDoubleClickHandler implements TableEventHandler {

  // Injections
  @InjectField() public $state:StateService;
  @InjectField() public states:States;
  @InjectField() public wpTableSelection:WorkPackageViewSelectionService;
  @InjectField() public wpTableFocus:WorkPackageViewFocusService;

  constructor(public readonly injector:Injector) {
  }

  public get EVENT() {
    return 'dblclick.table.row';
  }

  public get SELECTOR() {
    return `.${tdClassName}`;
  }

  public eventScope(view:TableEventComponent) {
    return jQuery(view.workPackageTable.tbody);
  }

  public handleEvent(view:TableEventComponent, evt:JQuery.TriggeredEvent) {
    const target = jQuery(evt.target);

    // Skip clicks with modifiers
    if (LinkHandling.isClickedWithModifier(evt)) {
      return true;
    }

    // Shortcut to any clicks within a cell
    // We don't want to handle these.
    if (target.hasClass(`${displayClassName}`) || target.hasClass(`${activeFieldClassName}`)) {
      debugLog('Skipping click on inner cell');
      return true;
    }

    // Locate the row from event
    const element = target.closest(this.SELECTOR).closest(`.${tableRowClassName}`);
    const wpId = element.data('workPackageId');

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    // Save the currently focused work package
    this.wpTableFocus.updateFocus(wpId);

    view.itemClicked.emit({ workPackageId: wpId, double: true });

    return false;
  }
}

