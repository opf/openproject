import {Injector} from '@angular/core';
import {WorkPackageCardViewComponent} from "core-components/wp-card-view/wp-card-view.component";
import {CardClickHandler} from "core-components/wp-card-view/event-handler/click-handler";

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
    c => new CardClickHandler(this.injector, c)
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
