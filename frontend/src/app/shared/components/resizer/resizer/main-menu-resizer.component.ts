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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit } from '@angular/core';
import { distinctUntilChanged } from 'rxjs/operators';

import { ResizeDelta } from 'core-app/shared/components/resizer/resizer.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { MainMenuToggleService } from 'core-app/core/main-menu/main-menu-toggle.service';


@Component({
  selector: 'opce-main-menu-resizer',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <op-resizer class="main-menu--resizer"
                [customHandler]="true"
                [cursorClass]="'col-resize'"
                (resizeFinished)="resizeEnd()"
                (resizeStarted)="resizeStart()"
                (move)="resizeMove($event)">
      <button
        class="spot-link main-menu--navigation-toggler"
        [attr.title]="toggleTitle"
        [class.open]="toggleService.showNavigation"
        (click)="toggleService.toggleNavigation($event)"
      >
        <span class="resize-handle"><svg op-resizer-vertical-lines-icon size="small"></svg></span>
        <span class="collapse-menu"><svg chevron-left-icon size="small"></svg></span>
        <span class="expand-menu"><svg chevron-right-icon size="small"></svg></span>
      </button>
    </op-resizer>
  `,
})

export class MainMenuResizerComponent extends UntilDestroyedMixin implements OnInit {
  public toggleTitle:string;

  private resizeEvent:string;

  private elementWidth:number;

  private mainMenu = jQuery('#main-menu')[0];

  public moving = false;

  constructor(
    readonly toggleService:MainMenuToggleService,
    readonly cdRef:ChangeDetectorRef,
    readonly elementRef:ElementRef,
  ) {
    super();
  }

  ngOnInit() {
    this.toggleService.titleData$
      .pipe(
        distinctUntilChanged(),
        this.untilDestroyed(),
      )
      .subscribe((setToggleTitle) => {
        this.toggleTitle = setToggleTitle;
        this.cdRef.detectChanges();
      });

    this.resizeEvent = 'main-menu-resize';
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
