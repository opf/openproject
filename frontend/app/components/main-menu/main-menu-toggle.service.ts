// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {Inject, Injectable} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {opServicesModule} from 'core-app/angular-modules';
import {downgradeInjectable} from '@angular/upgrade/static';
import {BehaviorSubject} from 'rxjs/BehaviorSubject';

@Injectable()
export class MainMenuToggleService {
  showNavigation:boolean = true;
  toggleTitle:string;
  oldStorageValue:number; // menu width after hiding menu (applied after reload)
  localStorageValue:number;
  elementWidth:number;

  htmlNode = document.getElementsByTagName('html')[0];
  mainMenu = jQuery('#main-menu')[0];  // main menu, containing sidebar and resizer
  hideElements = jQuery('.can-hide-navigation');

  private allData = new BehaviorSubject<string>('');
  public allData$ = this.allData.asObservable();

  constructor(@Inject(I18nToken) protected I18n:op.I18n) {
  }

  public initializeMenu() {
    // mobile version default: hidden menu on initialization
    if (window.innerWidth < 680) {
      this.closeMenu();
    }
    // for desktop: save inital width in localStorage
    else {
      if (this.mainMenu.offsetWidth < 10) { // if mainMenu is collapsed, set width 0 in localStorage
        this.saveWidth("openProject-mainMenuWidth", 0);
        this.showNavigation = false;
      } else if (this.mainMenu.offsetWidth < 230 && this.mainMenu.offsetWidth > 10) { // set back to default width
        this.saveWidth("openProject-mainMenuWidth", 230);
      } else {  // Get initial width from mainMenu and save in storage
        this.saveWidth("openProject-mainMenuWidth", this.mainMenu.offsetWidth);
      }
    }
    this.addRemoveClassHidden();
    this.setToggleTitle();
  }

  // click on arrow or hamburger icon
  public toggleNavigation(event:JQueryEventObject) {
    event.stopPropagation();
    event.preventDefault();
    // mobile version
    if (window.innerWidth < 680) {
        if (this.localStorageValue === 0) { // if main menu collapsed -> menu shall expand
          this.showNavigation = true;
          this.saveWidth("openProject-mainMenuWidth", window.innerWidth);
          // On mobile the main menu shall close whenever you click outside the menu.
          this.setupAutocloseMainMenu();
        } else {
          this.closeMenu();
        }
    }
    // desktop version
    else {
      if (this.mainMenu.offsetWidth < 10) { // sidebar is hidden -> show menu
        this.showNavigation = true;
        if (this.oldStorageValue !== undefined && this.oldStorageValue > 230) {  // save storage value and apply to menu width
          this.saveWidth("openProject-mainMenuWidth", this.oldStorageValue);
        } else { // if value of storage value < 230, set back to default size
          this.saveWidth("openProject-mainMenuWidth", 230);
        }
      } else { // sidebar is expanded -> close menu
        this.closeMenu();
      }
    }
    this.addRemoveClassHidden();
    this.setToggleTitle();
    // Set focus on first visible main menu item.
    // This needs to be called after AngularJS has rendered the menu, which happens some when after(!) we leave this
    // method here. So we need to set the focus after a timeout.
    setTimeout(function() {
      jQuery('#main-menu [class*="-menu-item"]:visible').first().focus();
    }, 500);
  }

  private closeMenu() {
    this.showNavigation = false;
    this.oldStorageValue = this.localStorageValue;
    this.saveWidth("openProject-mainMenuWidth", 0);
    this.hideElements.addClass('hidden-navigation');
  }

  private setToggleTitle() {
    if (this.showNavigation) {
      this.toggleTitle = I18n.t('js.label_hide_project_menu');
    } else {
      this.toggleTitle = I18n.t('js.label_expand_project_menu');
    }
    this.allData.next(this.toggleTitle);
  }

  private addRemoveClassHidden() {
    if (this.showNavigation) {
      this.hideElements.removeClass('hidden-navigation');
    } else {
      this.hideElements.addClass('hidden-navigation');
    }
  }

  public saveWidth(localStorageKey:string, width:number) {
    window.OpenProject.guardedLocalStorage(localStorageKey, String(width));
    this.localStorageValue = Number(window.OpenProject.guardedLocalStorage(localStorageKey));
    this.setWidth(this.mainMenu, width);
  }

  public setWidth(element:HTMLElement, width:number) {
    let viewportWidth = document.documentElement.clientWidth;
    let newValue = width <= 10 ? 0 : width;
    newValue = newValue >= viewportWidth - 150 ? viewportWidth - 150 : newValue;
    this.htmlNode.style.setProperty("--main-menu-width", newValue + 'px');
  }

  private setupAutocloseMainMenu() {
    let that = this;
    jQuery('#main-menu').on('focusout.main_menu', function (event) {
      jQuery('#main-menu').off('focusout.main_menu');
      // Check that main menu is not closed and that the `focusout` event is not a click on an element
      // that tries to close the menu anyways.
      if (!that.showNavigation || document.getElementById('main-menu-toggle') ===  event.relatedTarget) {
        return;
      }
      else {
        // There might be a time gap between `focusout` and the focussing of the activeElement, thus we need a timeout.
        setTimeout(function() {
          if (!jQuery.contains(<Element>document.getElementById('main-menu'), document.activeElement) &&
              (document.getElementById('main-menu-toggle') !== document.activeElement)) {
            // activeElement is outside of main menu.
            that.closeMenu();
          }
        }, 0);
      }
    });
  }
}

opServicesModule.service('toggleService', downgradeInjectable(MainMenuToggleService));
