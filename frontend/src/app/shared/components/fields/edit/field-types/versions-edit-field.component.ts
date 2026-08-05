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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import {
  SingleOrMultiSelectEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/single-or-multi-select-edit-field.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';

/**
 * Edit field for the version collection attributes of work packages
 * (targetVersions, observedInVersions).
 *
 * The attributes always read and write a collection, but the schema may
 * restrict one to a single value (options.multiple) — targetVersions does so as
 * long as the multiple versions setting is inactive. In that mode the field
 * mimics the single select fields it stands in for: an explicit "-" option, no
 * save/cancel controls, saving right on selection.
 *
 * Versions can be created from within the field when the user is allowed to
 * (mirroring VersionAutocompleterComponent).
 */
@Component({
  templateUrl: './versions-edit-field.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class VersionsEditFieldComponent extends SingleOrMultiSelectEditFieldComponent implements OnInit {
  readonly apiV3Service = inject(ApiV3Service);
  readonly currentProject = inject(CurrentProjectService);
  readonly halNotification = inject(HalResourceNotificationService);

  /** Set to a version factory once the user is allowed to create versions in the project. */
  public createAllowed:false|((name:string) => Promise<VersionResource>) = false;

  public createLabel = this.I18n.t('js.label_create');

  groupByFn = (item:HalResource):string|null => {
    // Do not group the "-" (no value) option
    if (!item.href) return null;

    const project = item.definingProject as HalResource|undefined;
    return project?.name ?? this.I18n.t('js.project.not_available');
  };

  ngOnInit():void {
    super.ngOnInit();
    this.setupVersionCreation();
  }

  /**
   * Allow creating a version from within the field when the current project is
   * among the projects a version may be created in (mirroring
   * VersionAutocompleterComponent).
   */
  private setupVersionCreation():void {
    if (!this.currentProject.id) {
      return;
    }

    void firstValueFrom(this.apiV3Service.versions.available_projects.exists(this.currentProject.id))
      .catch(() => false)
      .then((allowed) => {
        if (allowed) {
          this.createAllowed = (name:string) => this.createNewVersion(name);
          this.cdRef.markForCheck();
        }
      });
  }

  private createNewVersion(name:string):Promise<VersionResource> {
    return firstValueFrom(this.apiV3Service.versions.post(this.versionPayload(name)))
      .then((version) => {
        // The new version must be an available option for the
        // selected option mapping to find it.
        this.availableOptions = [...(this.availableOptions as HalResource[]), version];
        return version;
      })
      .catch((error) => {
        this.halNotification.handleRawError(error);
        throw error;
      });
  }

  private versionPayload(name:string) {
    return {
      name,
      _links: {
        definingProject: {
          href: this.apiV3Service.projects.id(this.currentProject.id!).path,
        },
      },
    };
  }
}
