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

import { Injectable, inject } from '@angular/core';
import { IToast } from 'core-app/shared/components/toaster/toast.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';

@Injectable()
export class WorkPackageNotificationService extends HalResourceNotificationService {
  readonly apiV3Service = inject(ApiV3Service);
  readonly turboRequests = inject(TurboRequestsService);

  public showSave(resource:HalResource, isCreate = false) {
    const message:IToast = {
      message: this.I18n.t(`js.notice_successful_${isCreate ? 'create' : 'update'}`),
      type: 'success',
    };

    this.ToastService.addSuccess(message);
  }

  protected showCustomError(errorResource:any, resource:WorkPackageResource):boolean {
    if (errorResource.errorIdentifier === 'urn:openproject-org:api:v3:errors:UpdateConflict') {
      // currently we do not have a programmatic way to show the primer flash messages
      // so we just do a request to the server to show it
      // should be refactored once we have a programmatic way to show the primer flash messages!
      void this.turboRequests.request('/work_packages/show_conflict_flash_message?scheme=danger', {
        method: 'GET',
      });

      return true;
    }

    return super.showCustomError(errorResource, resource);
  }
}
