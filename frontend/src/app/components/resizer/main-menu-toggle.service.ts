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

import {Injectable} from '@angular/core';
import {BehaviorSubject} from 'rxjs';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {Injector} from "@angular/core";

@Injectable()
export class MainMenuToggleService {
  public toggleTitle:string;

  private elementWidth:number;
  private readonly localStorageKey:string = 'openProject-mainMenuWidth';
  private readonly defaultWidth:number = 230;

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
              protected injector:Injector) {
  }

  public initializeMenu() : void {
    if (!this.mainMenu) return;

    this.elementWidth = parseInt(window.OpenProject.guardedLocalStorage(this.localStorageKey) as string);

    if (!this.elementWidth) {
      this.saveWidth(this.mainMenu.offsetWidth);
    } else {
      this.setWidth();
    }

    let currentProject:CurrentProjectService = this.injector.get(CurrentProjectService);
    if (jQuery(document.body).hasClass('controller-my') && this.elementWidth == 0 || currentProject.id === null) {
      this.saveWidth(this.defaultWidth);
    }

    // mobile version default: hide menu on initialization
    if (window.innerWidth < 680) this.closeMenu();
  }

  // click on arrow or hamburger icon
  public toggleNavigation(event?:JQueryEventObject) : void {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }

    if (!this.showNavigation()) { // sidebar is hidden -> show menu
      if (window.innerWidth < 680) { // mobile version
        this.setWidth(window.innerWidth);
        // On mobile the main menu shall close whenever you click outside the menu.
        this.setupAutocloseMainMenu();
      } else { // desktop version
        this.saveWidth(this.defaultWidth);
      }
    } else { // sidebar is expanded -> close menu
      this.closeMenu();
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

  public closeMenu() : void {
    this.saveWidth(0);
    this.hideElements.addClass('hidden-navigation');
  }

  private setToggleTitle() : void {
    if (this.showNavigation()) {
      this.toggleTitle = this.I18n.t('js.label_hide_project_menu');
    } else {
      this.toggleTitle = this.I18n.t('js.label_expand_project_menu');
    }
    this.titleData.next(this.toggleTitle);
  }

  private addRemoveClassHidden() : void {
    this.hideElements.toggleClass('hidden-navigation', !this.showNavigation());
  }

  public saveWidth(width?:number) : void {
    this.setWidth(width);
    window.OpenProject.guardedLocalStorage(this.localStorageKey, String(this.elementWidth));
    this.setToggleTitle();
    // Send change event when size of menu is changing (menu toggled or resized)
    // Event should only be fired, when transition is finished
    let changeEvent = jQuery.Event("change");
    jQuery('#content-wrapper').on('transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd', () => {
      this.changeData.next(changeEvent);
    });
  }

  public setWidth(width?:any) : void {
    if (width != undefined) {
      this.elementWidth = width as number;
    }
    this.snapBack();
    this.ensureContentVisibility();

    this.global.showNavigation = this.showNavigation();
    this.addRemoveClassHidden();
    this.htmlNode.style.setProperty("--main-menu-width", this.elementWidth + 'px');
  }

  private setupAutocloseMainMenu() : void {
    let that = this;
    jQuery('#main-menu').off('focusout.main_menu');
    jQuery('#main-menu').on('focusout.main_menu', function (event) {
      // Check that main menu is not closed and that the `focusout` event is not a click on an element
      // that tries to close the menu anyways.
      if (!that.showNavigation() || document.getElementById('main-menu-toggle') ===  event.relatedTarget) {
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

  private snapBack() : void {
    if (this.elementWidth <= 10) {
      this.elementWidth = 0;
    }
  }

  private ensureContentVisibility() : void {
    let viewportWidth = document.documentElement.clientWidth;
    if (this.elementWidth >= viewportWidth - 150) {
      this.elementWidth = viewportWidth - 150;
    }
  }

  public showNavigation() : boolean {
    return (this.elementWidth > 10);
  }
}
