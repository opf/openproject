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

import {Component, ElementRef, HostListener, Injector, Input, OnInit} from '@angular/core';
import {MainMenuToggleService} from '../main-menu/main-menu-toggle.service';
import {distinctUntilChanged, map, take} from 'rxjs/operators';
import {Subscription} from 'rxjs/Subscription';
import {BehaviorSubject} from 'rxjs/BehaviorSubject';
import {downgradeComponent} from '@angular/upgrade/static';
import {opUiComponentsModule} from '../../angular-modules';

@Component({
  selector: 'main-menu-resizer',
  template: `
    <div class="main-menu--resizer">
      <a href="#"
         title="{{toggleTitle}}"
         class="main-menu--navigation-toggler"
         (accessibleClick)="toggleService.toggleNavigation($event)">
        <i class="icon-resizer-vertical-lines"
          aria-hidden="true"></i>
      </a>
    </div>
  `
})

export class MainMenuResizerComponent implements OnInit {
  private resizeEvent:string;
  private localStorageKey:string;
  private toggleTitle:string;

  private elementWidth:number;
  private oldPosition:number;
  private mouseMoveHandler:any;
  private element:HTMLElement;
  private htmlNode:HTMLElement;
  private mainMenu = jQuery('#main-menu')[0];

  public moving:boolean = false;

  private subscription:Subscription;

  constructor(protected toggleService:MainMenuToggleService,
              private elementRef:ElementRef) {
  }

  ngOnInit() {
    this.subscription = this.toggleService.all$
      .pipe(
        distinctUntilChanged()
      )
      .subscribe(setToggleTitle => {
        this.toggleTitle = setToggleTitle;
      });

    this.resizeEvent     = "main-menu-resize";
    this.localStorageKey = "openProject-mainMenuWidth";
  }

  @HostListener('mousedown', ['$event'])
  private handleMouseDown(e:MouseEvent) {
    // ignore event if it is a click on the collapse/expand handle
    var toggler = jQuery('.main-menu--navigation-toggler i')[0];
    if (e.target === toggler) {
      return;
    }

    e.preventDefault();
    e.stopPropagation();

    // Only on left mouse click the resizing is started
    if (e.buttons === 1 || e.which === 1) {
      // Getting starting position
      this.oldPosition = e.clientX;
      this.elementWidth = this.mainMenu.clientWidth;
      this.moving = true;

      // Necessary to encapsulate this to be able to remove the event listener later
      this.mouseMoveHandler = this.resizeElement.bind(this, this.mainMenu);

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

    this.moving = false;

    // save new width in service (if width < 230 set default value after reloading the page)
    this.toggleService.saveWidth(this.localStorageKey, this.elementWidth);
    console.log("Saved element width: ", this.elementWidth);

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
    if (collapsedState === 'collapsed') {
      if (this.elementWidth > 10) {
        jQuery('#main-menu-toggle').click();
        this.toggleService.setWidth(element, this.elementWidth);
      } else {
        this.toggleService.setWidth(this.mainMenu, 0);
      }
    } else if (this.elementWidth <= 10) {
      jQuery('#main-menu-toggle').click();
      this.toggleService.setWidth(this.mainMenu, 0);
    } else {
      this.toggleService.setWidth(element, this.elementWidth);
    }
  }

}

opUiComponentsModule.directive(
  'mainMenuResizer',
  downgradeComponent({component: MainMenuResizerComponent})
);
