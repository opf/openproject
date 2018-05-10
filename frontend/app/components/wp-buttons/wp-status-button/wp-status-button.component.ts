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

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageEditingService} from 'core-components/wp-edit-form/work-package-editing-service';
import {Component, Inject, Input} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {States} from 'core-components/states.service';
import {ColorContrast} from 'core-components/a11y/color-contrast.functions';
import {StatusCacheService} from 'core-app/components/status/status-cache.service';
import {StatusResource} from 'core-app/modules/hal/resources/status-resource';
import {OnInit, OnDestroy} from '@angular/core';
import {takeUntil} from 'rxjs/operators';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';

@Component({
  template: require('!!raw-loader!./wp-status-button.html'),
  selector: 'wp-status-button',
})
export class WorkPackageStatusButtonComponent implements OnInit, OnDestroy {
  @Input('workPackage') public workPackage:WorkPackageResource;
  @Input('allowed') public allowed:boolean;

  public status:StatusResource;

  public text = {
    explanation: this.I18n.t('js.label_edit_status')
  };

  constructor(@Inject(I18nToken) readonly I18n:op.I18n,
              readonly states:States,
              readonly statusCache:StatusCacheService,
              protected wpEditing:WorkPackageEditingService) {
  }

  public ngOnInit() {
    this.status = this.workPackage.status;
    this.wpEditing
      .state(this.workPackage.id)
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe(async (changeset) => {
        const status:StatusResource = changeset.value('status');
        this.status = await this.statusCache.require(status.idFromLink);
      });
  }

  public ngOnDestroy() {
    // Nothing to do.
  }

  public isDisabled() {
    let changeset = this.wpEditing.changesetFor(this.workPackage);
    return !this.allowed || changeset.inFlight;
  }

  public get fgColor() {
    return ColorContrast.getContrastingColor(this.bgColor);
  }

  public get bgColor() {
    return this.status.color;
  }
}
