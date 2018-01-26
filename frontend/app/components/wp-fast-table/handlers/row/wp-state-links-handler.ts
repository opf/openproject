import {$injectFields, injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {TableEventHandler} from '../table-handler-registry';
import {KeepTabService} from '../../../wp-panels/keep-tab/keep-tab.service';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';
import {tableRowClassName} from "../../builders/rows/single-row-builder";
import {States} from "../../../states.service";
import {WorkPackageTableSelection} from "../../state/wp-table-selection.service";
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {StateService} from '@uirouter/angularjs';

export class WorkPackageStateLinksHandler implements TableEventHandler {
  // Injections
  public $state:StateService;
  public keepTab:KeepTabService;
  public states:States;
  public wpTableSelection:WorkPackageTableSelection;
  public wpTableFocus:WorkPackageTableFocusService;

  constructor(table: WorkPackageTable) {
    $injectFields(this, '$state', 'keepTab', 'states', 'wpTableSelection', 'wpTableFocus');
  }

  public get EVENT() {
    return 'click.table.wpLink';
  }

  public get SELECTOR() {
    return `.${uiStateLinkClass}`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.container);
  }

  protected workPackage:WorkPackageResource;

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    // Avoid the state capture when clicking with modifier
    if (evt.shiftKey || evt.ctrlKey || evt.metaKey || evt.altKey) {
      return true;
    }

    // Locate the details link from event
    const target = jQuery(evt.target);
    const element = target.closest(this.SELECTOR);
    const state = element.data('wpState');
    const workPackageId = element.data('workPackageId');

    // Blur the target to avoid focus being kept there
    target.closest('a').blur();

    // The current row is the last selected work package
    // not matter what other rows are (de-)selected below.
    // Thus save that row for the details view button.
    // Locate the row from event
    let row = target.closest(`.${tableRowClassName}`);
    let classIdentifier = row.data('classIdentifier');
    let [index, _] = table.findRenderedRow(classIdentifier);

    this.wpTableFocus.updateFocus(workPackageId);

    // Update single selection if no modifier present
    this.wpTableSelection.setSelection(workPackageId, index);

    this.$state.go(
      (this.keepTab as any)[state],
      { workPackageId: workPackageId, focus: true }
    );

    evt.preventDefault();
    evt.stopPropagation();
    return false;
  }
}
