//-- copyright
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
//++

import {ChangeDetectorRef, Component, ElementRef, OnInit} from '@angular/core';
import {distinctUntilChanged} from 'rxjs/operators';
import {ResizeDelta} from "core-app/modules/common/resizer/resizer.component";
import {MainMenuToggleService} from "core-components/main-menu/main-menu-toggle.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

export const mainMenuResizerSelector = 'main-menu-resizer';

@Component({
  selector: mainMenuResizerSelector,
  template: `
    <resizer class="main-menu--resizer"
             [customHandler]="true"
             [cursorClass]="'col-resize'"
             (end)="resizeEnd()"
             (start)="resizeStart()"
             (move)="resizeMove($event)">
      <div class="resizer-toggle-container">
        <i [attr.title]="toggleTitle"
            class="main-menu--navigation-toggler"
            [ngClass]="{'open': toggleService.showNavigation}"
            (accessibleClick)="toggleService.toggleNavigation($event)"></i>

        <i class="icon-resizer-vertical-lines"
           aria-hidden="true"></i>
      </div>
    </resizer>
  `
})

export class MainMenuResizerComponent extends UntilDestroyedMixin implements OnInit {
  public toggleTitle:string;
  private resizeEvent:string;
  private localStorageKey:string;

  private elementWidth:number;
  private mainMenu = jQuery('#main-menu')[0];

  public moving:boolean = false;

  constructor(readonly toggleService:MainMenuToggleService,
              readonly cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef) {
    super();
  }

  ngOnInit() {
    this.toggleService.titleData$
      .pipe(
        distinctUntilChanged(),
        this.untilDestroyed()
      )
      .subscribe(setToggleTitle => {
        this.toggleTitle = setToggleTitle;
        this.cdRef.detectChanges();
      });

    this.resizeEvent = "main-menu-resize";
    this.localStorageKey = "openProject-mainMenuWidth";
  }

  public resizeStart() {
    this.elementWidth = this.mainMenu.clientWidth;
  }

  public resizeMove(deltas:ResizeDelta) {
    this.toggleService.saveWidth(this.elementWidth + deltas.absolute.x);
  }

  public resizeEnd() {
    const event = new Event(this.resizeEvent);
    window.dispatchEvent(event);
  }
}
