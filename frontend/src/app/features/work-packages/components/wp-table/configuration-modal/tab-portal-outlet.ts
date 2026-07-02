/**
 * A PortalOutlet that lets multiple components live for the lifetime of the outlet,
 * allowing faster switching and persistent data.
 */
import { ComponentPortal } from '@angular/cdk/portal';
import {
  ApplicationRef,
  ComponentRef,
  createComponent,
  EmbeddedViewRef,
  Injector,
} from '@angular/core';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';

export interface TabInterface extends TabDefinition {
  componentClass:new(...args:any[]) => TabComponent;
}

export interface TabComponent {
  onSave:() => void;
}

export interface ActiveTabInterface extends TabDefinition {
  portal:ComponentPortal<TabComponent>;
  componentRef:ComponentRef<TabComponent>;
  dispose:() => void;
}

export class TabPortalOutlet {
  // Active tabs that have been instantiated
  public activeTabs:Record<string, ActiveTabInterface> = {};

  // The current tab
  public currentTab:ActiveTabInterface|null = null;

  constructor(
    public availableTabs:TabInterface[],
    public outletElement:HTMLElement,
    private appRef:ApplicationRef,
    private injector:Injector,
  ) {
  }

  public get activeComponents():TabComponent[] {
    const tabs = Object.values(this.activeTabs);
    return tabs.map((tab:ActiveTabInterface) => tab.componentRef.instance);
  }

  public switchTo(tab:TabInterface):void {
    if (tab.disable !== undefined) {
      return;
    }

    // Detach any current instance
    this.detach();

    // Get existing or new component instance
    const instance = this.activateInstance(tab);

    // At this point the component has been instantiated, so we move it to the location in the DOM
    // where we want it to be rendered.
    this.outletElement.innerHTML = '';
    this.outletElement.appendChild(this._getComponentRootNode(instance.componentRef));
    this.outletElement.dataset.tabName = tab.name;
    this.currentTab = instance;
  }

  public detach():void {
    const current = this.currentTab;
    if (current !== null) {
      current.portal.setAttachedHost(null);
      this.currentTab = null;
    }
  }

  /**
   * Clears out a portal from the DOM.
   */
  dispose():void {
    // Dispose all active tabs
    Object.values(this.activeTabs).forEach((active) => active.dispose());

    // Remove outlet element
    if (this.outletElement.parentNode != null) {
      this.outletElement.parentNode.removeChild(this.outletElement);
    }
  }

  private activateInstance(tab:TabInterface):ActiveTabInterface {
    if (!this.activeTabs[tab.name]) {
      this.activeTabs[tab.name] = this.createComponent(tab);
    }

    return this.activeTabs[tab.name] || null;
  }

  private createComponent(tab:TabInterface):ActiveTabInterface {
    const componentRef = createComponent(tab.componentClass, {
      environmentInjector: this.appRef.injector,
      elementInjector: this.injector,
    });
    const portal = new ComponentPortal(tab.componentClass, null, this.injector);

    // Attach component view
    this.appRef.attachView(componentRef.hostView);

    return {
      ...tab,
      portal,
      componentRef,
      dispose: () => {
        this.appRef.detachView(componentRef.hostView);
        componentRef.destroy();
      },
    };
  }

  /** Gets the root HTMLElement for an instantiated component. */
  private _getComponentRootNode(componentRef:ComponentRef<any>):HTMLElement {
    return (componentRef.hostView as EmbeddedViewRef<any>).rootNodes[0] as HTMLElement;
  }
}
