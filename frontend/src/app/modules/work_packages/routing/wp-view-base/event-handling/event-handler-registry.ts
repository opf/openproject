import {InjectionToken, Injector} from '@angular/core';

export interface WorkPackageViewEventHandler<T> {
  /** Event name to register **/
  EVENT:string;

  /** Event context CSS selector */
  SELECTOR:string;

  /** Event callback handler */
  handleEvent(view:T, evt:JQuery.TriggeredEvent):void;

  /** Event scope method */
  eventScope(view:T):JQuery;
}

export interface WorkPackageViewHandlerClass<T> {
  new(injector:Injector):WorkPackageViewEventHandler<any>;
}

export const WorkPackageViewHandlerToken = new InjectionToken<WorkPackageViewEventHandler<any>>('CardEventHandler');

/**
 * Abstract view handler registry for globally handling arbitrary event on the
 * view container. Used e.g., for table to register single event callbacks for the entirety
 * of the table.
 */
export abstract class WorkPackageViewHandlerRegistry<T> {

  constructor(public readonly injector:Injector) {
  }

  protected abstract eventHandlers:((view:T) => WorkPackageViewEventHandler<T>)[];

  attachTo(viewRef:T) {
    this.eventHandlers.map(factory => {
      let handler = factory(viewRef);
      let target = handler.eventScope(viewRef);

      target.on(handler.EVENT, handler.SELECTOR, (evt:JQuery.TriggeredEvent) => {
        handler.handleEvent(viewRef, evt);
      });

      return handler;
    });
  }
}
