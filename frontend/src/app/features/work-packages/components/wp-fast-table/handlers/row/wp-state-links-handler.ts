import { Injector } from '@angular/core';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { States } from 'core-app/core/states/states.service';
import { StateService } from '@uirouter/core';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { KeepTabService } from '../../../wp-single-view-tabs/keep-tab/keep-tab.service';
import { tableRowClassName } from '../../builders/rows/single-row-builder';
import { uiStateLinkClass } from '../../builders/ui-state-link-builder';
import { TableEventComponent, TableEventHandler } from '../table-handler-registry';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class WorkPackageStateLinksHandler implements TableEventHandler {
  // Injections
  @LazyInject() public $state:StateService;

  @LazyInject() public keepTab:KeepTabService;

  @LazyInject() public states:States;

  @LazyInject() public wpTableSelection:WorkPackageViewSelectionService;

  @LazyInject() public wpTableFocus:WorkPackageViewFocusService;

  constructor(public readonly injector:Injector) {
  }

  public get EVENT():EventType {
    return 'click';
  }

  public get SELECTOR() {
    return `.${uiStateLinkClass}`;
  }

  public eventScope(view:TableEventComponent) {
    return view.workPackageTable.tableAndTimelineContainer;
  }

  protected workPackage:WorkPackageResource;

  public handleEvent(view:TableEventComponent, evt:KeyboardEvent) {
    evt.stopPropagation();

    // Avoid the state capture when clicking with modifier to allow browser opening in new tab
    if (evt.shiftKey || evt.ctrlKey || evt.metaKey || evt.altKey) {
      return true;
    }

    // Locate the details link from event
    const target = evt.target as HTMLElement;
    const element = target.closest<HTMLElement>(this.SELECTOR);
    if (!element) { return true; }

    const state = element.dataset.wpState;
    const workPackageId = element.dataset.workPackageId;

    // Normal link processing if there are no state and work package information
    if (!state || !workPackageId) {
      return true;
    }

    // Blur the target to avoid focus being kept there
    target.closest('a')?.blur();

    // The current row is the last selected work package
    // not matter what other rows are (de-)selected below.
    // Thus save that row for the details view button.
    // Locate the row from event
    const row = target.closest<HTMLElement>(`.${tableRowClassName}`);
    if (!row) { return true; }

    const classIdentifier = row.dataset.classIdentifier!;
    const [index] = view.workPackageTable.findRenderedRow(classIdentifier);

    // Update single selection if no modifier present
    this.wpTableSelection.setSelection(workPackageId, index);

    view.stateLinkClicked.emit({ workPackageId, requestedState: state });

    evt.preventDefault();
    return false;
  }
}
