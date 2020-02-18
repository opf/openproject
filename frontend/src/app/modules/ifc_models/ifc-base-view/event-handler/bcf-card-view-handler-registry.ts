import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {
  CardEventHandler,
  CardViewHandlerRegistry
} from "core-components/wp-card-view/event-handler/card-view-handler-registry";
import {BcfClickHandler} from "core-app/modules/ifc_models/ifc-base-view/event-handler/bcf-click-handler";


export class BcfCardViewHandlerRegistry extends CardViewHandlerRegistry {

  protected eventHandlers:((c:WorkPackageCardViewComponent) => CardEventHandler)[] = [
    // Clicking on the card (not within a cell)
    c => new BcfClickHandler(this.injector, c),
  ];
}

