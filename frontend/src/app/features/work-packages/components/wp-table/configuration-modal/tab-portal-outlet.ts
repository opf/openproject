//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
