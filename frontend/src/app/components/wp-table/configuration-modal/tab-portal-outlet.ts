/**
 * A PortalOutlet that lets multiple components live for the lifetime of the outlet,
 * allowing faster switching and persistent data.
 */
import {ComponentPortal} from '@angular/cdk/portal';
import {
  ApplicationRef,
  ComponentFactoryResolver,
  ComponentRef,
  EmbeddedViewRef,
  Injector
} from '@angular/core';

export interface TabInterface {
  name:string;
  title:string;
  disableBecause?:string;
  componentClass:{ new(...args:any[]):TabComponent };
}

export interface TabComponent {
  onSave:() => void;
}

export interface ActiveTabInterface {
  name:string;
  portal:ComponentPortal<TabComponent>;
  componentRef:ComponentRef<TabComponent>;
  dispose:() => void;
}

export class TabPortalOutlet {

  // Active tabs that have been instantiated
  public activeTabs:{ [name:string]:ActiveTabInterface } = {};

  // The current tab
  public currentTab:ActiveTabInterface|null = null;

  constructor(
    public availableTabs:TabInterface[],
    public outletElement:HTMLElement,
    private componentFactoryResolver:ComponentFactoryResolver,
    private appRef:ApplicationRef,
    private injector:Injector) {
  }

  public get activeComponents():TabComponent[] {
    const tabs = _.values(this.activeTabs);
    return tabs.map((tab:ActiveTabInterface) => tab.componentRef.instance);
  }

  public switchTo(name:string) {
    const tab = _.find(this.availableTabs, tab => tab.name === name);

    if (!tab) {
      throw(`Trying to switch to unknown tab ${name}.`);
    }

    if (tab.disableBecause != null) {
      return false;
    }

    // Detach any current instance
    this.detach();

    // Get existing or new component instance
    const instance = this.activateInstance(tab);

    // At this point the component has been instantiated, so we move it to the location in the DOM
    // where we want it to be rendered.
    this.outletElement.innerHTML = '';
    this.outletElement.appendChild(this._getComponentRootNode(instance.componentRef));
    this.outletElement.dataset.tabName = tab.title;
    this.currentTab = instance;

    return false;
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
    _.each(this.activeTabs, active => active.dispose());

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
    const componentFactory = this.componentFactoryResolver.resolveComponentFactory(tab.componentClass);
    const componentRef = componentFactory.create(this.injector);
    const portal = new ComponentPortal(tab.componentClass, null, this.injector);

    // Attach component view
    this.appRef.attachView(componentRef.hostView);

    return {
      name: tab.name,
      portal: portal,
      componentRef: componentRef,
      dispose: () => {
        this.appRef.detachView(componentRef.hostView);
        componentRef.destroy();
      }
    };
  }

  /** Gets the root HTMLElement for an instantiated component. */
  private _getComponentRootNode(componentRef:ComponentRef<any>):HTMLElement {
    return (componentRef.hostView as EmbeddedViewRef<any>).rootNodes[0] as HTMLElement;
  }
}
