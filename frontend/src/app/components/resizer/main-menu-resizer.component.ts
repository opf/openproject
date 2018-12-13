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

import {ChangeDetectorRef, Component, ElementRef, HostListener, OnDestroy, OnInit} from '@angular/core';
import {distinctUntilChanged} from 'rxjs/operators';
import {Subscription} from 'rxjs';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {MainMenuToggleService} from "core-components/resizer/main-menu-toggle.service";
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {ResizeDelta} from "core-app/modules/common/resizer/resizer.component";

@Component({
  selector: 'main-menu-resizer',
  template: `
    <resizer class="main-menu--resizer"
             [customHandler]="true"
             [cursorClass]="'col-resize'"
             (end)="resizeEnd()"
             (start)="resizeStart()"
             (move)="resizeMove($event)">
      <a href="#"
         [attr.title]="toggleTitle"
         class="main-menu--navigation-toggler"
         (accessibleClick)="toggleService.toggleNavigation($event)">
        <i class="icon-resizer-vertical-lines"
           aria-hidden="true"></i>
      </a>
    </resizer>
  `
})

export class MainMenuResizerComponent implements OnInit, OnDestroy {
  public toggleTitle:string;
  private resizeEvent:string;
  private localStorageKey:string;

  private elementWidth:number;
  private mainMenu = jQuery('#main-menu')[0];

  public moving:boolean = false;

  private subscription:Subscription;

  constructor(readonly toggleService:MainMenuToggleService,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    this.subscription = this.toggleService.titleData$
      .pipe(
        distinctUntilChanged(),
        untilComponentDestroyed(this)
      )
      .subscribe(setToggleTitle => {
        this.toggleTitle = setToggleTitle;
        this.cdRef.detectChanges();
      });

    this.resizeEvent     = "main-menu-resize";
    this.localStorageKey = "openProject-mainMenuWidth";
  }

  ngOnDestroy() {
    this.subscription.unsubscribe();
  }

  public resizeStart() {
    this.elementWidth = this.mainMenu.clientWidth;
  }

  public resizeMove(deltas:ResizeDelta) {
    this.toggleService.saveWidth(this.elementWidth + deltas.x);
  }

  public resizeEnd() {
    const event = new Event(this.resizeEvent);
    window.dispatchEvent(event);
  }
}

DynamicBootstrapper.register({ selector: 'main-menu-resizer', cls: MainMenuResizerComponent  });
