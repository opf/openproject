import {Injector} from '@angular/core';
import {CardEventHandler} from "core-components/wp-card-view/event-handler/card-view-handler-registry";
import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {WorkPackageViewFocusService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service";
import {WorkPackageCardViewService} from "core-components/wp-card-view/services/wp-card-view.service";
import {StateService} from "@uirouter/core";
import {DeviceService} from "core-app/modules/common/browser/device.service";

export class CardClickHandler implements CardEventHandler {

  // Injections
  public deviceService:DeviceService = this.injector.get(DeviceService);
  public $state:StateService = this.injector.get(StateService);
  public wpTableSelection:WorkPackageViewSelectionService = this.injector.get(WorkPackageViewSelectionService);
  public wpTableFocus:WorkPackageViewFocusService = this.injector.get(WorkPackageViewFocusService);
  public wpCardView:WorkPackageCardViewService = this.injector.get(WorkPackageCardViewService);

  constructor(public readonly injector:Injector,
              card:WorkPackageCardViewComponent) {
  }

  public get EVENT() {
    return 'click.cardView.card';
  }

  public get SELECTOR() {
    return `.wp-card`;
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return jQuery(card.container.nativeElement);
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:JQuery.TriggeredEvent) {
    let target = jQuery(evt.target);

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    // Locate the card from event
    let element = target.closest('wp-single-card');
    let wpId = element.data('workPackageId');
    let classIdentifier = element.data('classIdentifier');

    if (!wpId) {
      return true;
    }

    let index = this.wpCardView.findRenderedCard(classIdentifier);

    // Update single selection if no modifier present
    if (!(evt.ctrlKey || evt.metaKey || evt.shiftKey)) {
      this.wpTableSelection.setSelection(wpId, index);
    }

    // Multiple selection if shift present
    if (evt.shiftKey) {
      this.wpTableSelection.setMultiSelectionFrom(this.wpCardView.renderedCards, wpId, index);
    }

    // Single selection expansion if ctrl / cmd(mac)
    if (evt.ctrlKey || evt.metaKey) {
      this.wpTableSelection.toggleRow(wpId);
    }

    // The current card is the last selected work package
    // not matter what other card are (de-)selected below.
    // Thus save that card for the details view button.
    this.wpTableFocus.updateFocus(wpId);

    // open work package on mobile after first click
    if (this.deviceService.isMobile) {
      this.$state.go(
        'work-packages.show',
        {workPackageId: wpId}
      );
    }

    return false;
  }
}
