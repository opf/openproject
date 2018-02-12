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

import {opUiComponentsModule} from '../../../angular-modules';
import {Component} from '@angular/core';
import {OnInit, Input} from '@angular/core';
import {downgradeComponent} from '@angular/upgrade/static';
import {HalRequestService} from 'core-components/api/api-v3/hal-request/hal-request.service';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';

interface CustomActionLink {
  href:string;
  title:string;
  method:string;
}

@Component({
  selector: 'wp-custom-action',
  template: require('!!raw-loader!./wp-custom-action.component.html')
})
export class WpCustomActionComponent {

  @Input() workPackage:WorkPackageResourceInterface;
  @Input() link:CustomActionLink;

  constructor(private halRequest:HalRequestService,
              private wpCacheService:WorkPackageCacheService,
              private wpNotificationsService:WorkPackageNotificationService) { }

  public update() {
    let payload = {
      lockVersion: this.workPackage.lockVersion
    };

    this.halRequest.post<WorkPackageResourceInterface>(this.link.href, payload)
      .then((savedWp:WorkPackageResourceInterface) => {
        this.wpNotificationsService.showSave(savedWp, false);
        this.workPackage = savedWp;
        this.wpCacheService.updateWorkPackage(savedWp);
      }).catch((errorResource:any) => {
        this.wpNotificationsService.handleErrorResponse(errorResource, this.workPackage);
      });
  }
}

opUiComponentsModule.directive(
  'wpCustomAction',
  downgradeComponent({component: WpCustomActionComponent})
);
