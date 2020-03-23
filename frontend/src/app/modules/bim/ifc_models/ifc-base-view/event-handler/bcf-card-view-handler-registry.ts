import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {
  CardEventHandler,
  CardViewHandlerRegistry
} from "core-components/wp-card-view/event-handler/card-view-handler-registry";
import {BcfDoubleClickHandler} from "core-app/modules/bim/ifc_models/ifc-base-view/event-handler/bcf-double-click-handler";
import {BcfClickHandler} from "core-app/modules/bim/ifc_models/ifc-base-view/event-handler/bcf-click-handler";
import {CardRightClickHandler} from "core-components/wp-card-view/event-handler/right-click-handler";


export class BcfCardViewHandlerRegistry extends CardViewHandlerRegistry {

  protected eventHandlers:((c:WorkPackageCardViewComponent) => CardEventHandler)[] = [
    // Clicking on the card (not within a cell)
    c => new BcfClickHandler(this.injector, c),
    // Double clicking on the card
    c => new BcfDoubleClickHandler(this.injector, c),
    // Right clicking on cards
    t => new CardRightClickHandler(this.injector, t),
  ];
}

