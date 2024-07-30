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

import {
  AfterViewInit,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Injector,
  Output,
} from '@angular/core';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CreateAutocompleterComponent } from 'core-app/shared/components/autocompleter/create-autocompleter/create-autocompleter.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { firstValueFrom } from 'rxjs';

@Component({
  templateUrl: '../create-autocompleter/create-autocompleter.component.html',
  selector: 'version-autocompleter',
})
export class VersionAutocompleterComponent extends CreateAutocompleterComponent implements AfterViewInit {
  @Output() public onCreate = new EventEmitter<VersionResource>();

  constructor(
    readonly injector:Injector,
    readonly I18n:I18nService,
    readonly currentProject:CurrentProjectService,
    readonly cdRef:ChangeDetectorRef,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly halNotification:HalResourceNotificationService,
  ) {
    super(injector);
  }

  ngAfterViewInit() {
    super.ngAfterViewInit();

    this.canCreateNewActionElements().then((val) => {
      if (val) {
        this.createAllowed = (input:string) => this.createNewVersion(input);
        this.cdRef.detectChanges();
      }
    });
  }

  /**
   * Checks for correct permissions
   * (whether the current project is in the list of allowed values in the version create form)
   * @returns {Promise<boolean>}
   */
  public canCreateNewActionElements():Promise<boolean> {
    if (!this.currentProject.id) {
      return Promise.resolve(false);
    }

    return firstValueFrom(
      this
        .apiV3Service
        .versions
        .available_projects
        .exists(this.currentProject.id),
    )
      .catch(() => false);
  }

  protected createNewVersion(name:string) {
    this
      .apiV3Service
      .versions
      .post(this.getVersionPayload(name))
      .subscribe(
        (version) => this.onCreate.emit(version),
        (error) => {
          this.closeSelect();
          this.halNotification.handleRawError(error);
        },
      );
  }

  private getVersionPayload(name:string) {
    const payload:any = {};
    payload.name = name;
    payload._links = {
      definingProject: {
        href: this.apiV3Service.projects.id(this.currentProject.id!).path,
      },
    };

    return payload;
  }
}
