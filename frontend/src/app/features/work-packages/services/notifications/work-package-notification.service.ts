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

import { Injectable, Injector } from '@angular/core';
import { IToast } from 'core-app/shared/components/toaster/toast.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

@Injectable()
export class WorkPackageNotificationService extends HalResourceNotificationService {
  constructor(
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,
  ) {
    super(injector);
  }

  public showSave(resource:HalResource, isCreate = false) {
    const message:IToast = {
      message: this.I18n.t(`js.notice_successful_${isCreate ? 'create' : 'update'}`),
      type: 'success',
    };

    // The WorkPackageNotificationService is injected for the whole wpIsolatedQuerySpace as the notification service.
    // However, when logging time on a WP, the provided resource is a TimeEntryResource.
    // Thus, the link in the toast would link to the WP with the ID of the TimeEntryResource (see #50731).
    // That is why, we check for WorkPackageResources and show the link only for them.
    if (resource.$halType === 'WorkPackage') {
      this.addWorkPackageFullscreenLink(message, resource);
    }

    this.ToastService.addSuccess(message);
  }

  protected showCustomError(errorResource:any, resource:WorkPackageResource):boolean {
    if (errorResource.errorIdentifier === 'urn:openproject-org:api:v3:errors:UpdateConflict') {
      this.ToastService.addError({
        message: errorResource.message,
        type: 'error',
        link: {
          text: this.I18n.t('js.hal.error.update_conflict_refresh'),
          target: () => this.apiV3Service.work_packages.id(resource).refresh(),
        },
      });

      return true;
    }

    return super.showCustomError(errorResource, resource);
  }

  private addWorkPackageFullscreenLink(message:IToast, resource:HalResource) {
    // Don't show the 'Show in full screen' link  if we're there already
    if (!this.$state.includes('work-packages.show')) {
      message.link = {
        target: () => this.$state.go('work-packages.show.tabs', { tabIdentifier: 'activity', workPackageId: resource.id }),
        text: this.I18n.t('js.work_packages.message_successful_show_in_fullscreen'),
      };
    }
  }
}
