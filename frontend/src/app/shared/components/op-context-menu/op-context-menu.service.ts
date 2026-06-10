import { ApplicationRef, Injectable, Injector, inject } from '@angular/core';
import { ComponentPortal, ComponentType, DomPortalOutlet } from '@angular/cdk/portal';
import { TransitionService } from '@uirouter/core';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import {
  OpContextMenuLocalsMap,
  OpContextMenuLocalsToken,
} from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { OPContextMenuComponent } from 'core-app/shared/components/op-context-menu/op-context-menu.component';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';

@Injectable({ providedIn: 'root' })
export class OPContextMenuService {
  readonly FocusHelper = inject(FocusHelperService);
  private appRef = inject(ApplicationRef);
  private $transitions = inject(TransitionService);
  private injector = inject(Injector);

  public active:OpContextMenuHandler|null = null;

  // Hold a reference to the DOM node we're using as a host
  private portalHostElement:HTMLElement;

  // And a reference to the actual portal host interface on top of the element
  private bodyPortalHost:DomPortalOutlet;

  // Allow temporarily disabling the close handler
  private isOpening = false;
  private openSeq = 0;

  public register() {
    const existing = document.querySelector('.op-context-menu--overlay');
    existing?.remove();

    const hostElement = this.portalHostElement = document.createElement('div');
    hostElement.classList.add('op-context-menu--overlay');
    document.body.appendChild(hostElement);

    this.bodyPortalHost = new DomPortalOutlet(
      hostElement,
      this.appRef,
      this.injector,
    );

    // Close context menus on state change
    this.$transitions.onStart({}, () => { this.close(); });

    // Listen to keyups on window to close context menus
    window.addEventListener('keydown', (evt) => {
      if (this.active && evt.key === 'Escape') {
        this.close(true);
      }

      return true;
    });

    const that = this;
    const wrapper = document.getElementById('wrapper');
    if (wrapper) {
      // Listen to any click and close the active context menu
      wrapper.addEventListener('click', (evt:Event) => {
        if (that.active && !that.portalHostElement.contains(evt.target as Element)) {
          that.close();
        }
      });
      // Listen if it scrolles then close the active context menu
      wrapper.addEventListener('scroll', (evt:Event) => {
        if (that.active && !that.portalHostElement.contains(evt.target as Element)) {
          that.close();
        }
      }, true);
    }
  }

  /**
   * Open a ContextMenu reference and append it to the portal
   * @param menu A reference to a context menu handler
   * @param event The event that triggered the context menu for positioning
   * @param component The context menu component to mount
   *
   */
  public show(menu:OpContextMenuHandler, event:Event, component:ComponentType<unknown> = OPContextMenuComponent):void {
    this.close();
    this.isOpening = true;
    const seq = this.openSeq += 1;

    // Create and attach portal
    const portal = new ComponentPortal(component, null, this.injectorFor(menu.locals));
    this.bodyPortalHost.attach(portal);

    // Avoid flicker until positioned
    const hostEl = this.portalHostElement;
    hostEl.style.visibility = 'hidden';
    hostEl.style.display = 'block';
    this.active = menu;

    // Wait one frame to ensure component DOM exists, then position
    requestAnimationFrame(() => {
      if (!this.active || this.openSeq !== seq) {
        this.isOpening = false;
        return;
      }

      void this.reposition(event)
        .then(() => {
          if (this.active && this.openSeq === seq) {
            hostEl.style.visibility = 'visible';
            requestAnimationFrame(() => {
              // Defer onOpen to next frame to ensure styles are applied
              if (this.active && this.openSeq === seq) {
                this.active.onOpen(this.activeMenu);
              }
            });
          }
        })
        .catch((err) => {
          // Fail-safe: close if positioning fails
          console.error('Context menu positioning failed:', err);
          if (this.openSeq === seq) this.close();
        })
        .finally(() => {
          if (this.openSeq === seq) this.isOpening = false;
        });
    });
  }

  public isActive(menu:OpContextMenuHandler):boolean {
    return !!this.active && this.active === menu;
  }

  /**
   * Closes all currently open context menus.
   */
  public close(focus = false):void {
    if (this.isOpening) {
      return;
    }

    // Detach any component currently in the portal
    this.bodyPortalHost.detach();
    this.portalHostElement.style.display = 'none';
    this.active?.onClose(focus);
    this.active = null;
  }

  public reposition(event:Event):Promise<void> {
    if (!this.active) {
      return Promise.resolve();
    }

    return this.active.computePosition(this.activeMenu, event)
      .then(({ x, y }) => {
        Object.assign(this.activeMenu.style, {
          left: `${x}px`,
          top: `${y}px`,
          position: 'absolute',
          visibility: 'visible'
        });
      });
  }

  public get activeMenu():HTMLElement {
    return this.portalHostElement.querySelector('.dropdown')!;
  }

  /**
   * Create an augmented injector that is equal to this service's injector + the additional data
   * passed into +show+.
   * This allows callers to pass data into the newly created context menu component.
   *
   * @param {OpContextMenuLocalsMap} data
   * @returns {Injector}
   */
  private injectorFor(data:OpContextMenuLocalsMap) {
    // Pass the service because otherwise we're getting a cyclic dependency between the portal
    // host service and the bound portal
    data.service = this;

    return Injector.create({
      providers: [
        { provide: OpContextMenuLocalsToken, useValue: data },
      ],
      parent: this.injector,
    });
  }
}
