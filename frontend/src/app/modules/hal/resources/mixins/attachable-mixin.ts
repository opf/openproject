//-- copyright
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
//++

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {AttachmentCollectionResource} from 'core-app/modules/hal/resources/attachment-collection-resource';
import {OpenProjectFileUploadService, UploadFile} from 'core-components/api/op-file-upload/op-file-upload.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {HttpErrorResponse} from "@angular/common/http";

type Constructor<T = {}> = new (...args:any[]) => T;

export function Attachable<TBase extends Constructor<HalResource>>(Base:TBase) {
  return class extends Base {
    public attachments:AttachmentCollectionResource;

    private NotificationsService:NotificationsService;
    private wpNotificationsService:WorkPackageNotificationService;
    private opFileUpload:OpenProjectFileUploadService;
    private pathHelper:PathHelperService;

    /**
     * Can be used in the mixed in class to disable
     * attempts to upload attachments right away.
     */
    private attachmentsBackend:boolean|null;

    /**
     * Return whether the user is able to upload an attachment.
     *
     * If either the `addAttachment` link is provided or the resource is being created,
     * adding attachments is allowed.
     */
    public get canAddAttachments():boolean {
      return !!this.$links.addAttachment || this.isNew;
    }

    /**
     * Try to find an existing file's download URL given its filename
     * @param file
     */
    public lookupDownloadLocationByName(file:string):string|null {
      if (!(this.attachments && this.attachments.elements)) {
        return null;
      }

      const match = _.find(this.attachments.elements, (res:HalResource) => res.name === file);
      return _.get(match, 'staticDownloadLocation.href', null);
    }

    /**
     * Remove the given attachment either from the pending attachments or from
     * the attachment collection, if it is a resource.
     *
     * Removing it from the elements array assures that the view gets updated immediately.
     * If an error occurs, the user gets notified and the attachment is pushed to the elements.
     */
    public removeAttachment(attachment:any):Promise<any> {
      _.pull(this.attachments.elements, attachment);

      if (attachment.$isHal) {
        return attachment.delete()
          .then(() => {
            if (!!this.attachmentsBackend) {
              this.updateAttachments();
            } else {
              this.attachments.count = Math.max(this.attachments.count - 1, 0);
            }
          })
          .catch((error:any) => {
            this.wpNotificationsService.handleRawError(error, this as any);
            this.attachments.elements.push(attachment);
          });
      }
      return Promise.resolve();
    }

    /**
     * Upload the given attachments, update the resource and notify the user.
     * Return an updated AttachmentCollectionResource.
     */
    public uploadAttachments(files:UploadFile[]):Promise<{ response:HalResource, uploadUrl:string }[]> {
      const { uploads, finished } = this.performUpload(files);

      const message = I18n.t('js.label_upload_notification', this);
      const notification = this.NotificationsService.addAttachmentUpload(message, uploads);

      return finished
        .then((result:{response:HalResource, uploadUrl:string }[]) => {
          setTimeout(() => this.NotificationsService.remove(notification), 700);

          if (!!this.attachmentsBackend && !this.isNew) {
            this.updateAttachments();
          } else {
            this.attachments.count += result.length;
            result.forEach(r => {
              this.attachments.elements.push(r.response);
            });
          }

          return result;
        })
        .catch((error:HttpErrorResponse) => {
          this.wpNotificationsService.handleRawError(error);
          return _.get(error, 'message', I18n.t('js.error.internal'));
        });
    }

    private performUpload(files:UploadFile[]) {
      let href = '';

      if (this.isNew || !this.id || !this.attachmentsBackend) {
        href = this.pathHelper.api.v3.attachments.path;
      } else {
        href = this.addAttachment.$link.href;
      }

      return this.opFileUpload.uploadAndMapResponse(href, files);
    }

    public $initialize(source:any) {
      this.NotificationsService = this.injector.get(NotificationsService);
      this.wpNotificationsService = this.injector.get( WorkPackageNotificationService);
      this.opFileUpload = this.injector.get(OpenProjectFileUploadService);
      this.pathHelper = this.injector.get(PathHelperService);

      super.$initialize(source);

      let attachments = this.attachments || { $source: {}, elements: [] };
      this.attachments = new AttachmentCollectionResource(
        this.injector,
        attachments,
        false,
        this.halInitializer,
        'HalResource'
      );
    }
  };
}
