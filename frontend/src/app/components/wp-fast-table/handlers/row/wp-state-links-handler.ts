import {Injector} from '@angular/core';
import {WorkPackageTableFocusService} from 'core-components/wp-fast-table/state/wp-table-focus.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {States} from '../../../states.service';
import {KeepTabService} from '../../../wp-single-view-tabs/keep-tab/keep-tab.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';
import {WorkPackageTableSelection} from '../../state/wp-table-selection.service';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';
import {StateService} from '@uirouter/core';

export class WorkPackageStateLinksHandler implements TableEventHandler {

  // Injections
  public $state:StateService = this.injector.get(StateService);
  public keepTab:KeepTabService = this.injector.get(KeepTabService);
  public states:States = this.injector.get(States);
  public wpTableSelection:WorkPackageTableSelection = this.injector.get(WorkPackageTableSelection);
  public wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);

  constructor(public readonly injector:Injector,
              table:WorkPackageTable) {
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

  public handleEvent(table:WorkPackageTable, evt:JQueryEventObject) {
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
      {workPackageId: workPackageId, focus: true}
    );

    evt.preventDefault();
    evt.stopPropagation();
    return false;
  }
}
