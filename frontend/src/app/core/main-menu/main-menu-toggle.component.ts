// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnInit,
} from '@angular/core';
import { distinctUntilChanged } from 'rxjs/operators';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { MainMenuToggleService } from './main-menu-toggle.service';

export const mainMenuToggleSelector = 'main-menu-toggle';

@Component({
  selector: mainMenuToggleSelector,
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'op-app-menu op-main-menu-toggle',
  },
  template: `
    <button
      *ngIf="this.currentProject.id !== null || this.deviceService.isMobile"
      class="op-app-menu--item-action"
      id="main-menu-toggle"
      aria-haspopup="true"
      type="button"
      [attr.title]="toggleTitle"
      (click)="toggleService.toggleNavigation($event)"
    >
      <op-icon class="icon-hamburger" aria-hidden="true"></op-icon>
      <op-icon class="icon-close" aria-hidden="true"></op-icon>
    </button>
  `,
})

export class MainMenuToggleComponent extends UntilDestroyedMixin implements OnInit {
  toggleTitle = '';

  @InjectField() currentProject:CurrentProjectService;

  constructor(readonly toggleService:MainMenuToggleService,
    readonly cdRef:ChangeDetectorRef,
    readonly deviceService:DeviceService,
    readonly injector:Injector) {
    super();
  }

  ngOnInit() {
    this.toggleService.initializeMenu();

    this.toggleService.titleData$
      .pipe(
        distinctUntilChanged(),
        this.untilDestroyed(),
      )
      .subscribe((setToggleTitle) => {
        this.toggleTitle = setToggleTitle;
        this.cdRef.detectChanges();
      });
  }
}
