import {
  ApplicationRef,
  ComponentFactoryResolver,
  Injectable,
  InjectionToken,
  Injector
} from '@angular/core';
import {ComponentPortal, DomPortalOutlet, PortalInjector} from "@angular/cdk/portal";
import {
  OPContextMenuComponent,
  OpContextMenuItem
} from "core-components/op-context-menu/op-context-menu.component";
import {OpContextMenuTrigger} from "core-components/op-context-menu/trigger/op-context-menu-trigger";
import {TransitionService} from "@uirouter/core";

export interface OpContextMenuLocalsMap {
  items:OpContextMenuItem[];
  [key:string]:any;
};

export const OpContextMenuLocalsToken = new InjectionToken<OpContextMenuLocalsMap>('CONTEXT_MENU_LOCALS');

@Injectable()
export class OPContextMenuService {
  public active:OpContextMenuTrigger|null = null;

  // Hold a reference to the DOM node we're using as a host
  private portalHostElement:HTMLElement;
  // And a reference to the actual portal host interface on top of the element
  private bodyPortalHost:DomPortalOutlet;

  constructor(private componentFactoryResolver:ComponentFactoryResolver,
              private appRef:ApplicationRef,
              private $transitions:TransitionService,
              private injector:Injector) {

    const hostElement = this.portalHostElement = document.createElement('div')
    hostElement.classList.add('op-context-menu--overlay');
    document.body.appendChild(hostElement);

    this.bodyPortalHost = new DomPortalOutlet(
      hostElement,
      this.componentFactoryResolver,
      this.appRef,
      this.injector
    );

    // Close context menus on state change
    $transitions.onStart({}, () => this.close());

    // Listen to keyups on window to close context menus
    Mousetrap.bind('escape', () => this.close());

    // Listen to any click and close the active context menu
    jQuery(window).click(() => {
      this.active && this.close();
    });
  }

  /**
   * Open a ContextMenu reference and append it to the portal
   * @param contextMenu A reference to a context menu class
   * @param data A set of locals injectable as 'CONTEXT_MENU_LOCALS' token in the component
   */
  public show(menu:OpContextMenuTrigger, event:Event) {
    this.close();

    // Create a portal for the given component class and render it
    const portal = new ComponentPortal(OPContextMenuComponent, null, this.injectorFor(menu.locals));
    this.bodyPortalHost.attach(portal);
    this.portalHostElement.style.display = 'block';
    this.active = menu;

    setTimeout(() => {
      this.reposition(event);
      // Focus on the first element
      this.activeMenu.find('.menu-item').first().focus();
    });
  }

  public isActive(menu:OpContextMenuTrigger) {
    return this.active && this.active === menu;
  }

  /**
   * Closes all currently open context menus.
   */
  public close() {
    // Detach any component currently in the portal
    this.bodyPortalHost.detach();
    this.portalHostElement.style.display = 'none';
    this.active && this.active.onClose();
    this.active = null;
  }

  public reposition(event:Event) {
    if (!this.active) {
      return;
    }

    this.activeMenu
      .position(this.active.positionArgs(event))
      .css('visibility', 'visible');
  }

  public get activeMenu():JQuery {
    return jQuery(this.portalHostElement).find('.dropdown');
  }

  /**
   * Create an augmented injector that is equal to this service's injector + the additional data
   * passed into +show+.
   * This allows callers to pass data into the newly created context menu component.
   *
   * @param {OpContextMenuLocalsMap} data
   * @returns {PortalInjector}
   */
  private injectorFor(data:OpContextMenuLocalsMap) {
    const injectorTokens = new WeakMap();
    injectorTokens.set(OpContextMenuLocalsToken, data);

    return new PortalInjector(this.injector, injectorTokens);
  }
}
