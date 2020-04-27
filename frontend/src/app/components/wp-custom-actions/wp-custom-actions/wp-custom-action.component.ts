// -- copyright
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
// ++


import {Component, HostListener, Input} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {CustomActionResource} from 'core-app/modules/hal/resources/custom-action-resource';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";

@Component({
  selector: 'wp-custom-action',
  templateUrl: './wp-custom-action.component.html'
})
export class WpCustomActionComponent {

  @Input() workPackage:WorkPackageResource;
  @Input() action:CustomActionResource;

  constructor(private halResourceService:HalResourceService,
              private wpCacheService:WorkPackageCacheService,
              private wpSchemaCacheService:SchemaCacheService,
              private wpActivity:WorkPackagesActivityService,
              private notificationService:WorkPackageNotificationService,
              private halEditing:HalResourceEditingService,
              private halEvents:HalEventsService) {
  }

  private fetchAction() {
    this.halResourceService.get<CustomActionResource>(this.action.href!)
      .toPromise()
      .then((action) => {
        this.action = action;
      });
  }

  public update() {
    let payload = {
      lockVersion: this.workPackage.lockVersion,
      _links: {
        workPackage: {
          href: this.workPackage.href
        }
      }
    };

    this.halResourceService.post<WorkPackageResource>(this.action.href + '/execute', payload)
      .toPromise()
      .then((savedWp:WorkPackageResource) => {
        this.notificationService.showSave(savedWp, false);
        this.workPackage = savedWp;
        this.wpActivity.clear(this.workPackage.id!);
        // Loading the schema might be necessary in cases where the button switches
        // project or type.
        this.wpSchemaCacheService.ensureLoaded(savedWp).then(() => {
          this.wpCacheService.updateWorkPackage(savedWp, true);
          this.halEditing.stopEditing(savedWp);
          this.halEvents.push(savedWp, { eventType: "updated" });
        });
      }).catch((errorResource:any) => {
        this.notificationService.handleRawError(errorResource, this.workPackage);
      });
  }

  @HostListener('mouseenter') onMouseEnter() {
    this.fetchAction();
  }
}

