//-- copyright
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { AfterViewInit, ChangeDetectorRef, Component, EventEmitter, Input, Output } from '@angular/core';
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { VersionResource } from "core-app/modules/hal/resources/version-resource";
import { CreateAutocompleterComponent } from "core-app/modules/autocompleter/create-autocompleter/create-autocompleter.component.ts";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

@Component({
  templateUrl: '../create-autocompleter/create-autocompleter.component.html',
  selector: 'version-autocompleter'
})
export class VersionAutocompleterComponent extends CreateAutocompleterComponent implements AfterViewInit {
  @Output() public onCreate = new EventEmitter<VersionResource>();

  constructor(readonly I18n:I18nService,
              readonly currentProject:CurrentProjectService,
              readonly cdRef:ChangeDetectorRef,
              readonly pathHelper:PathHelperService,
              readonly apiV3Service:APIV3Service,
              readonly halNotification:HalResourceNotificationService) {
    super(I18n, cdRef, currentProject, pathHelper);
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

    return this
      .apiV3Service
      .versions
      .available_projects
      .exists(this.currentProject.id!)
      .toPromise()
      .catch(() => false);
  }

  protected createNewVersion(name:string) {
    this
      .apiV3Service
      .versions
      .post(this.getVersionPayload(name))
      .subscribe(
        version => this.onCreate.emit(version),
        error => {
          this.closeSelect();
          this.halNotification.handleRawError(error);
        });
  }

  private getVersionPayload(name:string) {
    const payload:any = {};
    payload['name'] = name;
    payload['_links'] = {
      definingProject: {
        href: this.apiV3Service.projects.id(this.currentProject.id!).path
      }
    };

    return payload;
  }
}
