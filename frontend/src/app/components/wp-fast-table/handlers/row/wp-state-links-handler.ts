import {Injector} from '@angular/core';
import {WorkPackageViewFocusService} from 'core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {States} from '../../../states.service';
import {KeepTabService} from '../../../wp-single-view-tabs/keep-tab/keep-tab.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {TableEventHandler} from '../table-handler-registry';
import {StateService} from '@uirouter/core';
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class WorkPackageStateLinksHandler implements TableEventHandler {

  // Injections
  @InjectField() public $state:StateService;
  @InjectField() public keepTab:KeepTabService;
  @InjectField() public states:States;
  @InjectField() public wpTableSelection:WorkPackageViewSelectionService;
  @InjectField() public wpTableFocus:WorkPackageViewFocusService;

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
    return jQuery(table.tableAndTimelineContainer);
  }

  protected workPackage:WorkPackageResource;

  public handleEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent) {
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
