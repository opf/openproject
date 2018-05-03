//-- copyright
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
//++

import {Component, ElementRef, HostListener, Injector, Input, OnDestroy, OnInit} from '@angular/core';

@Component({
  selector: 'main-menu-resizer',
  template: `
    <div class="main-menu--resizer" ng-class="{ 'show': !showNavigation }">
      <a href="#"
         title="<%= l(:show_hide_project_menu) %>"
         class="main-menu--navigation-toggler"
         ng-click="mainMenu.toggleNavigation()">
        <i class="icon4 icon-arrow-left2" aria-hidden="true"></i>
      </a>
    </div>
  `
})

export class MainMenuResizerDirective implements OnInit, OnDestroy {
  private elementClass:string;
  private resizeEvent:string;
  private localStorageKey:string;

  private resizingElement:HTMLElement;
  private elementWidth:number;
  private oldPosition:number;
  private mouseMoveHandler:any;
  private element:HTMLElement;
  private htmlNode:HTMLElement;

  public moving:boolean = false;

  constructor(private elementRef:ElementRef) {
  }

  ngOnInit() {
    this.elementClass    = "main-menu";
    this.resizeEvent     = "main-menu-resize";
    this.localStorageKey = "openProject-mainMenuWidth";

    this.htmlNode = <HTMLElement>document.getElementsByTagName('html')[0];

    // Get element
    this.resizingElement = <HTMLElement>document.getElementsByClassName(this.elementClass)[0];
    // Get initial width from local storage and apply
    let localStorageValue = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    this.elementWidth = localStorageValue ? parseInt(localStorageValue,
      10) : this.resizingElement.offsetWidth;

    this.setWidth(this.resizingElement, this.elementWidth);

    // Add event listener
    this.element = this.elementRef.nativeElement;
  }

  ngOnDestroy() {
    // Reset the style when killing this directive, otherwise the style remains
    this.resizingElement.style.width = null;
  }

  @HostListener('mousedown', ['$event'])
  private handleMouseDown(e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    // Only on left mouse click the resizing is started
    if (e.buttons === 1 || e.which === 1) {
      // Getting starting position
      this.oldPosition = e.clientX;

      this.moving = true;

      // Necessary to encapsulate this to be able to remove the event listener later
      this.mouseMoveHandler = this.resizeElement.bind(this, this.resizingElement);

      // Change cursor icon
      // This is handled via JS to ensure
      // that the cursor stays the same even when the mouse leaves the actual resizer.
      document.getElementsByTagName("body")[0].setAttribute('style',
        'cursor: col-resize !important');

      // Enable mouse move
      window.addEventListener('mousemove', this.mouseMoveHandler);
    }
  }

  @HostListener('window:mouseup', ['$event'])
  private handleMouseUp(e:MouseEvent):boolean {
    if (!this.moving) {
      return true;
    }

    // Disable mouse move
    window.removeEventListener('mousemove', this.mouseMoveHandler);

    // Change cursor icon back
    document.body.style.cursor = 'auto';

    let localStorageValue = window.OpenProject.guardedLocalStorage(this.localStorageKey);
    if (localStorageValue) {
      this.elementWidth = parseInt(localStorageValue, 10);
    }

    this.moving = false;



    // Send a event that we resized this element
    const event = new Event(this.resizeEvent);
    window.dispatchEvent(event);

    return false;
  }

  private resizeElement(element:HTMLElement, e:MouseEvent) {
    e.preventDefault();
    e.stopPropagation();

    let delta = e.clientX - this.oldPosition;
    this.oldPosition = e.clientX;

    this.elementWidth = this.elementWidth + delta;

    let collapsedState = sessionStorage.getItem('openproject:navigation-toggle');
    if (collapsedState == 'collapsed') {
      if (this.elementWidth > 10) {
        jQuery('#mobile-main-menu-toggle').click();
        this.setWidth(element, this.elementWidth);
      } else {
        this.setWidth(this.resizingElement, 0);
      }
    } else if (this.elementWidth <= 10) {
      jQuery('#mobile-main-menu-toggle').click();
      this.setWidth(this.resizingElement, 0);
    } else {
      this.setWidth(element, this.elementWidth);
    }
  }

  private setWidth(element:HTMLElement, width:number) {
    let viewportWidth = document.documentElement.clientWidth;
    let newValue = width <= 10 ? 0 : width;
    newValue = newValue >= viewportWidth - 150 ? viewportWidth - 150 : newValue;

    window.OpenProject.guardedLocalStorage(this.localStorageKey, String(newValue));

    this.htmlNode.style.setProperty("--main-menu-width", newValue + 'px');
  }
}
