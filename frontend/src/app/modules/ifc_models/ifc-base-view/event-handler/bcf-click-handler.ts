import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {StateService} from "@uirouter/core";
import {CardClickHandler} from "core-components/wp-card-view/event-handler/click-handler";

export class BcfClickHandler extends CardClickHandler {

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

    if (!wpId) {
      return true;
    }

    const state = this.injector.get(StateService);
    const current = state.current;

    // TODO do not use defaults
    state.go('.single_bcf', { workPackageId: wpId });

    return false;
  }
}
