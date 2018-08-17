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


import {Component, HostListener, Input} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {CustomActionResource} from 'core-app/modules/hal/resources/custom-action-resource';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';

@Component({
  selector: 'wp-custom-action',
  templateUrl: './wp-custom-action.component.html'
})
export class WpCustomActionComponent {

  @Input() workPackage:WorkPackageResource;
  @Input() action:CustomActionResource;

  constructor(private halResourceService:HalResourceService,
              private wpCacheService:WorkPackageCacheService,
              private wpActivity:WorkPackagesActivityService,
              private wpNotificationsService:WorkPackageNotificationService) { }

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
        this.wpNotificationsService.showSave(savedWp, false);
        this.workPackage = savedWp;
        this.wpActivity.clear(this.workPackage.id);
        this.wpCacheService.updateWorkPackage(savedWp);
      }).catch((errorResource:any) => {
        this.wpNotificationsService.handleRawError(errorResource, this.workPackage);
      });
  }

  @HostListener('mouseenter') onMouseEnter() {
    this.fetchAction();
  }
}

