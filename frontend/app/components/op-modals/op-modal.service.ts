import {
  ApplicationRef,
  ComponentFactoryResolver, ComponentRef,
  Inject,
  Injectable,
  Injector
} from '@angular/core';
import {ComponentPortal, ComponentType, DomPortalOutlet, PortalInjector} from '@angular/cdk/portal';
import {TransitionService} from '@uirouter/core';
import {FocusHelperToken, OpModalLocalsToken} from 'core-app/angular4-transition-utils';
import {OpModalComponent} from 'core-components/op-modals/op-modal.component';

@Injectable()
export class OpModalService {
  public active:OpModalComponent|null = null;

  // Hold a reference to the DOM node we're using as a host
  private portalHostElement:HTMLElement;
  // And a reference to the actual portal host interface on top of the element
  private bodyPortalHost:DomPortalOutlet;

  constructor(private componentFactoryResolver:ComponentFactoryResolver,
              @Inject(FocusHelperToken) readonly FocusHelper:any,
              private appRef:ApplicationRef,
              private $transitions:TransitionService,
              private injector:Injector) {

    const hostElement = this.portalHostElement = document.createElement('div');
    hostElement.classList.add('op-modals--overlay');
    document.body.appendChild(hostElement);

    // Listen to keyups on window to close context menus
    Mousetrap.bind('escape', () => {
      if (this.active && this.active.closeOnEscape) {
        this.close();
      }
    });

    // Listen to any click when should close outside modal
    jQuery(window).click((evt) => {
      if (this.active &&
        this.active.closeOnOutsideClick &&
        !this.portalHostElement.contains(evt.target)) {
        this.close();
      }
    });

    this.bodyPortalHost = new DomPortalOutlet(
      hostElement,
      this.componentFactoryResolver,
      this.appRef,
      this.injector
    );
  }

  /**
   * Open a Modal reference and append it to the portal
   */
  public show<T extends OpModalComponent>(modal:ComponentType<T>, locals:any = {}):void {
    this.close();

    // Create a portal for the given component class and render it
    const portal = new ComponentPortal(modal, null, this.injectorFor(locals));
    const ref:ComponentRef<OpModalComponent> = this.bodyPortalHost.attach(portal) as ComponentRef<OpModalComponent>;
    const instance = ref.instance as T;
    this.active = instance;
    this.portalHostElement.style.display = 'block';

    setTimeout(() => {
      // Focus on the first element
      this.active && this.active.onOpen(this.activeModal);
    });
  }

  public isActive(modal:OpModalComponent) {
    return this.active && this.active === modal;
  }

  /**
   * Closes currently open modal window
   */
  public close() {
    // Detach any component currently in the portal
    if (this.active && this.active.onClose()) {
      this.bodyPortalHost.detach();
      this.portalHostElement.style.display = 'none';
      this.active = null;
    }
  }

  public get activeModal():JQuery {
    return jQuery(this.portalHostElement).find('.op-modal--container');
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

    injectorTokens.set(OpModalLocalsToken, data);

    return new PortalInjector(this.injector, injectorTokens);
  }
}
