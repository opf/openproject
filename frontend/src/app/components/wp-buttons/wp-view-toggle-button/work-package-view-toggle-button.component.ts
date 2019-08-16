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

import {AbstractWorkPackageButtonComponent} from '../wp-buttons.module';
import {ChangeDetectionStrategy, ChangeDetectorRef, Component, OnDestroy, OnInit} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";
import {StateService} from "@uirouter/core";
import {
  WorkPackageViewDisplayRepresentationService, wpDisplayCardRepresentation,
  wpDisplayListRepresentation
} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {untilComponentDestroyed} from "ng2-rx-componentdestroyed";


@Component({
  template: `    
      <button class="button"
              wpViewDropdown>
        <op-icon icon-classes="button--icon"></op-icon>
        <span class="button--text"
              aria-hidden="true"></span>
        <op-icon icon-classes="button--icon icon-small icon-pulldown"></op-icon>
      </button>
`,
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'wp-view-toggle-button',
})
export class WorkPackageViewToggleButton implements OnInit, OnDestroy {
  constructor(readonly I18n:I18nService,
              readonly cdRef:ChangeDetectorRef,
              readonly wpDisplayRepresentationService:WorkPackageViewDisplayRepresentationService) {
  }

  ngOnInit() {
    this.wpDisplayRepresentationService.live$()
      .pipe(
        untilComponentDestroyed(this)
      )
      .subscribe(() => {
        this.cdRef.detectChanges();
      });
  }

  ngOnDestroy() {
    // Nothing to do
  }
}

DynamicBootstrapper.register({ selector: 'wp-view-toggle-button', cls: WorkPackageViewToggleButton });
