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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnInit } from '@angular/core';
import { distinctUntilChanged } from 'rxjs/operators';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { MainMenuToggleService } from './main-menu-toggle.service';
import { TopMenuService } from 'core-app/core/top-menu/top-menu.service';

@Component({
  selector: 'opce-main-menu-toggle',
  changeDetection: ChangeDetectionStrategy.OnPush,
  // eslint-disable-next-line @angular-eslint/no-host-metadata-property
  host: {
    class: 'op-app-menu op-main-menu-toggle',
  },
  templateUrl: './main-menu-toggle.component.html',
})
export class MainMenuToggleComponent extends UntilDestroyedMixin implements OnInit {
  toggleTitle = '';

  @InjectField() currentProject:CurrentProjectService;

  constructor(
    readonly topMenu:TopMenuService,
    readonly toggleService:MainMenuToggleService,
    readonly cdRef:ChangeDetectorRef,
    readonly injector:Injector,
  ) {
    super();
  }

  ngOnInit():void {
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

  toggle(event:Event):void {
    this.toggleService.toggleNavigation(event);
    this.topMenu.close();
  }
}
