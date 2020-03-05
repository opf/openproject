import {ApplicationRef, ComponentFactoryResolver, Injectable, Injector} from '@angular/core';
import {ComponentPortal, DomPortalOutlet, PortalInjector} from "@angular/cdk/portal";
import {TransitionService} from "@uirouter/core";
import {OpContextMenuHandler} from "core-components/op-context-menu/op-context-menu-handler";
import {OpContextMenuLocalsMap, OpContextMenuLocalsToken} from "core-components/op-context-menu/op-context-menu.types";
import {OPContextMenuComponent} from "core-components/op-context-menu/op-context-menu.component";
import {keyCodes} from 'core-app/modules/common/keyCodes.enum';
import {FocusHelperService} from 'core-app/modules/common/focus/focus-helper';

@Injectable({ providedIn: 'root' })
export class OPContextMenuService {
  public active:OpContextMenuHandler|null = null;

  // Hold a reference to the DOM node we're using as a host
  private portalHostElement:HTMLElement;
  // And a reference to the actual portal host interface on top of the element
  private bodyPortalHost:DomPortalOutlet;

  // Allow temporarily disabling the close handler
  private isOpening = false;

  constructor(private componentFactoryResolver:ComponentFactoryResolver,
              readonly FocusHelper:FocusHelperService,
              private appRef:ApplicationRef,
              private $transitions:TransitionService,
              private injector:Injector) {

    const hostElement = this.portalHostElement = document.createElement('div');
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
    jQuery(window).on('keydown', (evt:JQuery.TriggeredEvent) => {
      if (this.active && evt.which === keyCodes.ESCAPE) {
        this.close();
      }

      return true;
    });

    // Listen to any click and close the active context menu
    const that = this;
    document.getElementById('wrapper')!.addEventListener('click', function(evt:Event) {
      if (that.active &&  !that.portalHostElement.contains(evt.target as Element)) {
        that.close();
      }
    },  true);
  }

  /**
   * Open a ContextMenu reference and append it to the portal
   * @param contextMenu A reference to a context menu handler
   */
  public show(menu:OpContextMenuHandler, event:JQuery.TriggeredEvent, component:any = OPContextMenuComponent) {
    this.close();

    // Create a portal for the given component class and render it
    this.isOpening = true;
    const portal = new ComponentPortal(component, null, this.injectorFor(menu.locals));
    this.bodyPortalHost.attach(portal);
    this.portalHostElement.style.display = 'block';
    this.active = menu;

    setTimeout(() => {
      this.reposition(event);
      // Focus on the first element
      this.active && this.active.onOpen(this.activeMenu);
      this.isOpening = false;
    });
  }

  public isActive(menu:OpContextMenuHandler) {
    return this.active && this.active === menu;
  }

  /**
   * Closes all currently open context menus.
   */
  public close() {
    if (this.isOpening) {
      return;
    }

    // Detach any component currently in the portal
    this.bodyPortalHost.detach();
    this.portalHostElement.style.display = 'none';
    this.active && this.active.onClose();
    this.active = null;
  }

  public reposition(event:JQuery.TriggeredEvent) {
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
    // Pass the service because otherwise we're getting a cyclic dependency between the portal
    // host service and the bound portal
    data.service = this;

    injectorTokens.set(OpContextMenuLocalsToken, data);

    return new PortalInjector(this.injector, injectorTokens);
  }
}
