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

import {wpServicesModule} from '../../../angular-modules.ts';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {
  CollectionResource,
  CollectionResourceInterface
} from '../../api/api-v3/hal-resources/collection-resource.service';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';

export class WpAttachmentsService {

  public pendingAttachments:File[] = [];

  constructor(protected $q:ng.IQService,
              protected $timeout:ng.ITimeoutService,
              protected $http:ng.IHttpService,
              protected Upload,
              protected I18n,
              protected NotificationsService,
              protected wpNotificationsService:WorkPackageNotificationService) {
  }

  public upload(workPackage:WorkPackageResourceInterface, files:File[]):ng.IPromise<any> {
    const uploads = this.asNgUpload(files, workPackage.attachments.href);
    const notification = this.addUploadNotification(workPackage, uploads);

    return this.$q.all(uploads).then(() => {
      this.pendingAttachments.length = 0;
      this.dismissNotification(notification);
    }).catch(error => {
      this.wpNotificationsService.handleErrorResponse(error, workPackage);
    });
  }

  public uploadPendingAttachments(workPackage:WorkPackageResourceInterface) {
    return this.upload(workPackage, this.pendingAttachments);
  }

  /**
   * Transform the given files to the ng-file-uploader parameters.
   */
  protected asNgUpload(files:File[], uploadPath:string) {
    return _.map(files, (file:File) => {
      var options:Object = {
        fields: {
          metadata: {
            description: (file as any).description,
            fileName: file.name,
          }
        },
        file: file,
        url: uploadPath
      };
      return this.Upload.upload(options);
    });
  }

  /**
   * Add a temporary notification for the current work package upload process
   */
  protected addUploadNotification(workPackage, uploads) {
    const message = this.I18n.t('js.label_upload_notification', {
      id: workPackage.id,
      subject: workPackage.subject
    });

    return this.NotificationsService.addWorkPackageUpload(message, uploads);
  }

  /**
   * Remove the temporary upload notification after some time.
   */
  protected dismissNotification(notification) {
    this.$timeout(() => {
      this.NotificationsService.remove(notification);
    }, 700);
  }
}

wpServicesModule.service('wpAttachments', WpAttachmentsService);
