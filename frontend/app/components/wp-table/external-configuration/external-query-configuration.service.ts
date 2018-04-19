import {ApplicationRef, ComponentFactoryResolver, Inject, Injectable, InjectionToken, Injector} from '@angular/core';
import {ComponentPortal, DomPortalOutlet, PortalInjector} from '@angular/cdk/portal';
import {TransitionService} from '@uirouter/core';
import {FocusHelperToken} from 'core-app/angular4-transition-utils';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';
import {ExternalQueryConfigurationComponent} from 'core-components/wp-table/external-configuration/external-query-configuration.component';
import {downgradeInjectable} from '@angular/upgrade/static';
import {opServicesModule} from 'core-app/angular-modules';

export const external_table_trigger_class = 'external-table-configuration--container';
export const OpQueryConfigurationLocals = new InjectionToken<any>('OpQueryConfigurationLocals');
export const OpQueryConfigurationTriggerEvent = 'op:queryconfiguration:trigger';
export const OpQueryConfigurationUpdatedEvent = 'op:queryconfiguration:updated';

@Injectable()
export class ExternalQueryConfigurationService {
  // Hold a reference to the DOM node we're using as a host
  private _portalHostElement:HTMLElement;
  // And a reference to the actual portal host interface on top of the element
  private _bodyPortalHost:DomPortalOutlet;

  constructor(private componentFactoryResolver:ComponentFactoryResolver,
              @Inject(FocusHelperToken) readonly FocusHelper:any,
              private appRef:ApplicationRef,
              private $transitions:TransitionService,
              private injector:Injector) {
  }

  public setupListener() {
    // Listen to keyups on window to close context menus
    jQuery(window).on(OpQueryConfigurationTriggerEvent, (event:JQueryEventObject, originator:JQuery, currentQuery:any) => {
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
  public show<T extends OpModalComponent>(originator:JQuery, currentQuery:any):void {
    this.detach();

    // Create a portal for the given component class and render it
    const portal = new ComponentPortal(
      ExternalQueryConfigurationComponent,
      null,
      this.injectorFor({ originator: originator, currentQuery: currentQuery }));
    this.bodyPortalHost.attach(portal);
    this._portalHostElement.style.display = 'block';
  }

  /**
   * Closes currently open modal window
   */
  public close(originator:JQuery, queryProps:any) {
    this.detach();
    originator.data('queryProps', queryProps);
    originator.trigger(OpQueryConfigurationUpdatedEvent, [queryProps]);
  }

  private detach() {
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

    injectorTokens.set(OpQueryConfigurationLocals, data);

    return new PortalInjector(this.injector, injectorTokens);
  }
}

opServicesModule.service('externalQueryConfiguration', downgradeInjectable(ExternalQueryConfigurationService))
