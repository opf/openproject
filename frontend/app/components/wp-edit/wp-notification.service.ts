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

import {
  WorkPackageResourceInterface,
  WorkPackageResource
} from '../api/api-v3/hal-resources/work-package-resource.service';
import {ErrorResource} from '../api/api-v3/hal-resources/error-resource.service';
import {wpServicesModule} from '../../angular-modules';

export class WorkPackageNotificationService {
  constructor(protected I18n:op.I18n,
              protected $state:ng.ui.IStateService,
              protected NotificationsService:any,
              protected loadingIndicator:any) {
  }

  public showSave(workPackage: WorkPackageResourceInterface, isCreate:boolean = false) {
    var message:any = {
      message: this.I18n.t('js.notice_successful_' + (isCreate ? 'create' : 'update')),
    };

    // Don't show the 'Show in full screen' link  if we're there already
    if (!this.$state.includes('work-packages.show')) {
      message.link = this.showInFullScreenLink(workPackage);
    }

    this.NotificationsService.addSuccess(message);
  }

  public handleRawError(response:any, workPackage?:WorkPackageResourceInterface) {
    if (response && response.data && response.data._type === 'Error') {
      const resource = new ErrorResource(response.data);
      return this.handleErrorResponse(resource, workPackage);
    }

    this.showGeneralError();
  }

  public handleErrorResponse(errorResource:any, workPackage?:WorkPackageResourceInterface) {
    if (!(errorResource instanceof ErrorResource)) {
      return this.showGeneralError();
    }

    if (workPackage) {
      return this.showError(errorResource, workPackage);
    }

    this.showApiErrorMessages(errorResource);
  }

  public showError(errorResource:any, workPackage:WorkPackageResourceInterface) {
    this.showCustomError(errorResource, workPackage) || this.showApiErrorMessages(errorResource);
  }

  public showGeneralError() {
    this.NotificationsService.addError(this.I18n.t('js.error.internal'));
  }

  public showEditingBlockedError(attribute:string) {
    this.NotificationsService.addError(this.I18n.t(
      'js.work_packages.error.edit_prohibited',
      { attribute: attribute }
    ));
  }

  private showCustomError(errorResource:any, workPackage:WorkPackageResourceInterface) {
    if (errorResource.errorIdentifier === 'urn:openproject-org:api:v3:errors:PropertyFormatError') {

      let attributeName = workPackage.schema[errorResource.details.attribute].name;
      let attributeType = workPackage.schema[errorResource.details.attribute].type.toLowerCase();
      let i18nString = 'js.work_packages.error.format.' + attributeType;

      if (this.I18n.lookup(i18nString) === undefined) {
        return false;
      }

      this.NotificationsService.addError(this.I18n.t(i18nString,
        {attribute: attributeName}));

      return true;
    }
    return false;
  }

  private showApiErrorMessages(errorResource:any) {
    var messages = errorResource.errorMessages;

    if (messages.length > 1) {
      this.NotificationsService.addError('', messages);
    }
    else {
      this.NotificationsService.addError(messages[0]);
    }

    return true;
  }

  private showInFullScreenLink(workPackage:WorkPackageResourceInterface) {
    return {
      target: () => {
        this.loadingIndicator.mainPage =
          this.$state.go('work-packages.show.activity', { workPackageId: workPackage.id });
      },
      text: this.I18n.t('js.work_packages.message_successful_show_in_fullscreen')
    };
  }
}

wpServicesModule.service('wpNotificationsService', WorkPackageNotificationService);
