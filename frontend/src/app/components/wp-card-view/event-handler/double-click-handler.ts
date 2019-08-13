import {Injector} from '@angular/core';
import {CardEventHandler} from "core-components/wp-card-view/event-handler/card-view-handler-registry";
import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {WorkPackageTableSelection} from "core-components/wp-fast-table/state/wp-table-selection.service";
import {WorkPackageTableFocusService} from "core-components/wp-fast-table/state/wp-table-focus.service";
import {StateService} from "@uirouter/core";

export class CardDblClickHandler implements CardEventHandler {

  // Injections
  public $state:StateService = this.injector.get(StateService);
  public wpTableSelection:WorkPackageTableSelection = this.injector.get(WorkPackageTableSelection);
  public wpTableFocus:WorkPackageTableFocusService = this.injector.get(WorkPackageTableFocusService);

  constructor(public readonly injector:Injector,
              card:WorkPackageCardViewComponent) {
  }

  public get EVENT() {
    return 'dblclick.cardView.card';
  }

  public get SELECTOR() {
    return `.wp-card`;
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return jQuery(card.container.nativeElement);
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:JQueryEventObject) {
    let target = jQuery(evt.target);

    // Ignore links
    if (target.is('a') || target.parent().is('a')) {
      return true;
    }

    // Locate the row from event
    let element = target.closest(this.SELECTOR);
    let wpId = element.data('workPackageId');

    if (!wpId) {
      return true;
    }

    this.$state.go(
      'work-packages.show',
      {workPackageId: wpId}
    );
    return false;
  }
}

