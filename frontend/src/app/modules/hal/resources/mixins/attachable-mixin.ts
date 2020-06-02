//-- copyright
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
//++

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {AttachmentCollectionResource} from 'core-app/modules/hal/resources/attachment-collection-resource';
import {OpenProjectFileUploadService, UploadFile} from 'core-components/api/op-file-upload/op-file-upload.service';
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {HttpErrorResponse} from "@angular/common/http";

type Constructor<T = {}> = new (...args:any[]) => T;

export function Attachable<TBase extends Constructor<HalResource>>(Base:TBase) {
  return class extends Base {
    public attachments:AttachmentCollectionResource;

    private NotificationsService:NotificationsService;
    private halNotification:HalResourceNotificationService;
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
     *
     */
    public get hasAttachments():boolean {
      return _.get(this.attachments, 'elements.length', 0) > 0;
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
            this.halNotification.handleRawError(error, this as any);
            this.attachments.elements.push(attachment);
          });
      }
      return Promise.resolve();
    }

    /**
     * Get updated attachments from the server and push the state
     *
     * Return a promise that returns the attachments. Reject, if the work package has
     * no attachments.
     */
    public updateAttachments():Promise<HalResource> {
      return this
        .attachments
        .updateElements()
        .then(() => {
          this.updateState();
          return this.attachments;
        });
    }

    /**
     * Upload the given attachments, update the resource and notify the user.
     * Return an updated AttachmentCollectionResource.
     */
    public uploadAttachments(files:UploadFile[]):Promise<{ response:HalResource, uploadUrl:string }[]> {
      const {uploads, finished} = this.performUpload(files);

      const message = I18n.t('js.label_upload_notification');
      const notification = this.NotificationsService.addAttachmentUpload(message, uploads);

      return finished
        .then((result:{ response:HalResource, uploadUrl:string }[]) => {
          setTimeout(() => this.NotificationsService.remove(notification), 700);

          this.attachments.count += result.length;
          result.forEach(r => {
            this.attachments.elements.push(r.response);
          });
          this.updateState();

          return result;
        })
        .catch((error:HttpErrorResponse) => {
          let message:undefined|string;
          console.error("Error while uploading: %O", error);

          if (error.error instanceof ErrorEvent) {
            // A client-side or network error occurred.
            message = this.I18n.t('js.error_attachment_upload', {error: error});
          } else if (_.get(error, 'error._type') === 'Error') {
            message = error.error.message;
          } else {
            // The backend returned an unsuccessful response code.
            message = error.error;
          }

          this.halNotification.handleRawError(message);
          return message || I18n.t('js.error.internal');
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

    private updateState() {
      if (this.state) {
        this.state.putValue(this as any);
      }
    }

    public $initialize(source:any) {
      if (!this.NotificationsService) {
        this.NotificationsService = this.injector.get(NotificationsService);
      }
      if (!this.halNotification) {
        this.halNotification = this.injector.get(HalResourceNotificationService);
      }
      if (!this.opFileUpload) {
        this.opFileUpload = this.injector.get(OpenProjectFileUploadService);
      }

      if (!this.pathHelper) {
        this.pathHelper = this.injector.get(PathHelperService);
      }

      super.$initialize(source);

      let attachments = this.attachments || {$source: {}, elements: []};
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
