import { Injector } from '@angular/core';
import { CardEventHandler } from "core-components/wp-card-view/event-handler/card-view-handler-registry";
import { WorkPackageCardViewComponent } from "core-components/wp-card-view/wp-card-view.component";
import { WorkPackageViewSelectionService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import { WorkPackageViewFocusService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service";
import { WorkPackageCardViewService } from "core-components/wp-card-view/services/wp-card-view.service";
import { StateService } from "@uirouter/core";
import { DeviceService } from "core-app/modules/common/browser/device.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export class CardClickHandler implements CardEventHandler {

  // Injections
  @InjectField() deviceService:DeviceService;
  @InjectField() $state:StateService;
  @InjectField() wpTableSelection:WorkPackageViewSelectionService;
  @InjectField() wpTableFocus:WorkPackageViewFocusService;
  @InjectField() wpCardView:WorkPackageCardViewService;

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
    const target = jQuery(evt.target);

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    // Locate the card from event
    const element = target.closest('wp-single-card');
    const wpId = element.data('workPackageId');

    if (!wpId) {
      return true;
    }

    this.handleWorkPackage(card, wpId, element, evt);

    return false;
  }


  protected handleWorkPackage(card:WorkPackageCardViewComponent, wpId:any, element:JQuery, evt:JQuery.TriggeredEvent) {
    this.setSelection(card, wpId, element, evt);

    card.itemClicked.emit({ workPackageId: wpId, double: false });
  }

  protected setSelection(card:WorkPackageCardViewComponent, wpId:string, element:JQuery, evt:JQuery.TriggeredEvent) {
    const classIdentifier = element.data('classIdentifier');
    const index = this.wpCardView.findRenderedCard(classIdentifier);

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

    card.selectionChanged.emit(this.wpTableSelection.getSelectedWorkPackageIds());

    // The current card is the last selected work package
    // not matter what other card are (de-)selected below.
    // Thus save that card for the details view button.
    this.wpTableFocus.updateFocus(wpId);
  }

}
