import {ApplicationRef, ComponentFactoryResolver, Injectable, Injector} from '@angular/core';
import {ComponentPortal, DomPortalOutlet, PortalInjector} from '@angular/cdk/portal';
import {TransitionService} from '@uirouter/core';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';
import {ExternalQueryConfigurationComponent} from "core-components/wp-table/external-configuration/external-query-configuration.component";
import {
  OpQueryConfigurationLocalsToken,
  OpQueryConfigurationTriggerEvent
} from "core-components/wp-table/external-configuration/external-query-configuration.constants";

export type Class = { new(...args:any[]):any; };

@Injectable()
export class ExternalQueryConfigurationService {

  // Hold a reference to the DOM node we're using as a host
  private _portalHostElement:HTMLElement;
  // And a reference to the actual portal host interface on top of the element
  private _bodyPortalHost:DomPortalOutlet;

  constructor(private componentFactoryResolver:ComponentFactoryResolver,
              readonly FocusHelper:FocusHelperService,
              private appRef:ApplicationRef,
              private $transitions:TransitionService,
              private injector:Injector) {
  }

  public setupListener() {
    // Listen to keyups on window to close context menus
    jQuery(window)
      .on(OpQueryConfigurationTriggerEvent,
        (event:JQuery.TriggeredEvent, originator:JQuery, currentQuery:any) => {
      this.show(originator, currentQuery);
      return false;
    });
  }

  /**
   * Create a portal host element to contain the table configuration components.
   */
  private get bodyPortalHost() {
    if (!this._portalHostElement) {
      const hostElement = this._portalHostElement = document.createElement('div');
      hostElement.classList.add('op-external-query-configuration--container');
      document.body.appendChild(hostElement);

      this._bodyPortalHost = new DomPortalOutlet(
        hostElement,
        this.componentFactoryResolver,
        this.appRef,
        this.injector
      );
    }

    return this._bodyPortalHost;
  }

  /**
   * Open a Modal reference and append it to the portal
   */
  public show(currentQuery:any,
              callback:(newQuery:any) => void,
              disabledTabs:{[key:string]:string} = {}) {
    this.detach();

    // Create a portal for the given component class and render it
    const portal = new ComponentPortal(
      this.externalQueryConfigurationComponent(),
      null,
      this.injectorFor({
                        callback: callback,
                        currentQuery: currentQuery,
                        disabledTabs: disabledTabs
                      })
    );
    this.bodyPortalHost.attach(portal);
    this._portalHostElement.style.display = 'block';
  }

  /**
   * Closes currently open modal window
   */
  public detach() {
    // Detach any component currently in the portal
    if (this.bodyPortalHost.hasAttached()) {
      this.bodyPortalHost.detach();
      this._portalHostElement.style.display = 'none';
    }
  }

  /**
   * Create an augmented injector that is equal to this service's injector + the additional data
   * passed into +show+.
   * This allows callers to pass data into the newly created modal.
   *
   */
  private injectorFor(data:any) {
    const injectorTokens = new WeakMap();
    // Pass the service because otherwise we're getting a cyclic dependency between the portal
    // host service and the bound portal
    data.service = this;

    injectorTokens.set(OpQueryConfigurationLocalsToken, data);

    return new PortalInjector(this.injector, injectorTokens);
  }

  externalQueryConfigurationComponent():Class {
    return ExternalQueryConfigurationComponent;
  }
}
