// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {Injectable, Injector} from '@angular/core';
import {BehaviorSubject} from 'rxjs';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {DeviceService} from "app/modules/common/browser/device.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

@Injectable({ providedIn: 'root' })
export class MainMenuToggleService {
  public toggleTitle:string;
  private elementWidth:number;
  private elementMinWidth = 11;
  private readonly defaultWidth:number = 230;
  private readonly localStorageKey:string = 'openProject-mainMenuWidth';
  private readonly localStorageStateKey:string = 'openProject-mainMenuCollapsed';

  @InjectField() currentProject:CurrentProjectService;

  private global = (window as any);
  private htmlNode = document.getElementsByTagName('html')[0];
  private mainMenu = jQuery('#main-menu')[0];  // main menu, containing sidebar and resizer
  private hideElements = jQuery('.can-hide-navigation');

  // Title needs to be sync in main-menu-toggle.component.ts and main-menu-resizer.component.ts
  private titleData = new BehaviorSubject<string>('');
  public titleData$ = this.titleData.asObservable();

  // Notes all changes of the menu size (currently needed in wp-resizer.component.ts)
  private changeData = new BehaviorSubject<any>({});
  public changeData$ = this.changeData.asObservable();

  constructor(protected I18n:I18nService,
              public injector:Injector,
              readonly deviceService:DeviceService) {
  }

  public initializeMenu():void {
    if (!this.mainMenu) { return; }

    this.elementWidth = parseInt(window.OpenProject.guardedLocalStorage(this.localStorageKey) as string);
    const menuCollapsed = window.OpenProject.guardedLocalStorage(this.localStorageStateKey) as string;

    if (!this.elementWidth) {
      this.saveWidth(this.mainMenu.offsetWidth);
    } else if (menuCollapsed && JSON.parse(menuCollapsed)) {
      this.closeMenu();
    }
    else {
      this.setWidth();
    }

    let currentProject:CurrentProjectService = this.injector.get(CurrentProjectService);
    if (jQuery(document.body).hasClass('controller-my') && this.elementWidth === 0 || currentProject.id === null) {
      this.saveWidth(this.defaultWidth);
    }

    // mobile version default: hide menu on initialization
    this.closeWhenOnMobile();
  }

  // click on arrow or hamburger icon
  public toggleNavigation(event?:JQuery.TriggeredEvent):void {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }

    if (!this.showNavigation) { // sidebar is hidden -> show menu
      if (this.deviceService.isMobile) { // mobile version
        this.setWidth(window.innerWidth);
      } else { // desktop version
        const savedWidth = parseInt(window.OpenProject.guardedLocalStorage(this.localStorageKey) as string);
        const widthToSave = savedWidth >= this.elementMinWidth ? savedWidth : this.defaultWidth;

        this.saveWidth(widthToSave);
      }
    } else { // sidebar is expanded -> close menu
      this.closeMenu();
    }

    // Set focus on first visible main menu item.
    // This needs to be called after AngularJS has rendered the menu, which happens some when after(!) we leave this
    // method here. So we need to set the focus after a timeout.
    setTimeout(function () {
      jQuery('#main-menu [class*="-menu-item"]:visible').first().focus();
    }, 500);
  }

  public closeMenu():void {
    this.setWidth(0);
    window.OpenProject.guardedLocalStorage(this.localStorageStateKey, 'true');
    jQuery('.wp-query-menu--search-input').blur();
  }

  public closeWhenOnMobile():void {
    if (this.deviceService.isMobile) {
      this.closeMenu();
      window.OpenProject.guardedLocalStorage(this.localStorageStateKey, 'false');
    }
  }
  public saveWidth(width?:number):void {
    this.setWidth(width);
    window.OpenProject.guardedLocalStorage(this.localStorageKey, String(this.elementWidth));
    window.OpenProject.guardedLocalStorage(this.localStorageStateKey, String(this.elementWidth === 0));
  }

  public setWidth(width?:any):void {
    if (width !== undefined) {
      // Leave a minimum amount of space for space fot the content
      let maxMenuWidth = this.deviceService.isMobile ? window.innerWidth - 120 : window.innerWidth - 520;
      if (width > maxMenuWidth) {
        this.elementWidth = maxMenuWidth;
      } else {
        this.elementWidth = width as number;
      }
    }

    this.snapBack();
    this.setToggleTitle();
    this.toggleClassHidden();

    this.global.showNavigation = this.showNavigation;
    this.htmlNode.style.setProperty("--main-menu-width", this.elementWidth + 'px');

    // Send change event when size of menu is changing (menu toggled or resized)
    // Event should only be fired, when transition is finished
    let changeEvent = jQuery.Event("change");
    jQuery('#content-wrapper').on('transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd', () => {
      this.changeData.next(changeEvent);
    });
  }

  public get showNavigation():boolean {
    return (this.elementWidth >= this.elementMinWidth);
  }

  private snapBack():void {
    if (this.elementWidth < this.elementMinWidth) {
      this.elementWidth = 0;
    }
  }

  private setToggleTitle():void {
    if (this.showNavigation) {
      this.toggleTitle = this.I18n.t('js.label_hide_project_menu');
    } else {
      this.toggleTitle = this.I18n.t('js.label_expand_project_menu');
    }
    this.titleData.next(this.toggleTitle);
  }

  private toggleClassHidden():void {
    this.hideElements.toggleClass('hidden-navigation', !this.showNavigation);
  }
}
