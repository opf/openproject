import {Injector} from '@angular/core';
import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {CardClickHandler} from "core-components/wp-card-view/event-handler/click-handler";
import {CardDblClickHandler} from "core-components/wp-card-view/event-handler/double-click-handler";
import {CardRightClickHandler} from "core-components/wp-card-view/event-handler/right-click-handler";

export interface CardEventHandler {
  EVENT:string;
  SELECTOR:string;

  handleEvent(card:WorkPackageCardViewComponent, evt:JQueryEventObject):void;

  eventScope(card:WorkPackageCardViewComponent):JQuery;
}

export class CardViewHandlerRegistry {

  constructor(public readonly injector:Injector) {
  }

  private eventHandlers:((c:WorkPackageCardViewComponent) => CardEventHandler)[] = [
    // Clicking on the card (not within a cell)
    c => new CardClickHandler(this.injector, c),
    // Double Clicking on the row (not within a cell)
    c => new CardDblClickHandler(this.injector, c),
    // Right clicking on cards
    t => new CardRightClickHandler(this.injector, t),
  ];

  attachTo(card:WorkPackageCardViewComponent) {
    this.eventHandlers.map(factory => {
      let handler = factory(card);
      let target = handler.eventScope(card);

      target.on(handler.EVENT, handler.SELECTOR, (evt:JQueryEventObject) => {
        handler.handleEvent(card, evt);
      });

      return handler;
    });
  }
}
