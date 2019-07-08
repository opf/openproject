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

import {ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnDestroy, OnInit} from '@angular/core';
import {MainMenuToggleService} from './main-menu-toggle.service';
import {distinctUntilChanged} from 'rxjs/operators';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {DeviceService} from "app/modules/common/browser/device.service";

@Component({
  selector: 'main-menu-toggle',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div *ngIf="this.currentProject.id !== null || this.deviceService.isMobile" id="main-menu-toggle"
        aria-haspopup="true"
        [attr.title]="toggleTitle"
        (accessibleClick)="toggleService.toggleNavigation($event)"
        tabindex="0">
      <a icon="icon-hamburger">
        <i class="icon-hamburger" aria-hidden="true"></i>
      </a>
    </div>
  `
})

export class MainMenuToggleComponent implements OnInit, OnDestroy {
  toggleTitle:string = "";
  currentProject:CurrentProjectService = this.injector.get(CurrentProjectService);

  constructor(readonly toggleService:MainMenuToggleService,
              readonly cdRef:ChangeDetectorRef,
              readonly deviceService:DeviceService,
              protected injector:Injector) {
  }

  ngOnInit() {
    this.toggleService.initializeMenu();

    this.toggleService.titleData$
      .pipe(
        distinctUntilChanged(),
        untilComponentDestroyed(this)
      )
      .subscribe( setToggleTitle => {
        this.toggleTitle = setToggleTitle;
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy() {
    // Nothing to do
  }
}

DynamicBootstrapper.register({ selector: 'main-menu-toggle', cls: MainMenuToggleComponent  });
