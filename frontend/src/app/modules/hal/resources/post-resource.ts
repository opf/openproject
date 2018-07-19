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
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {AttachmentCollectionResource} from 'core-app/modules/hal/resources/attachment-collection-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {TypeResource} from 'core-app/modules/hal/resources/type-resource';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {
  OpenProjectFileUploadService,
  UploadFile,
  UploadResult
} from 'core-components/api/op-file-upload/op-file-upload.service';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {States} from 'core-components/states.service';
import {ApiWorkPackagesService} from 'core-components/api/api-work-packages/api-work-packages.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {WorkPackageCreateService} from 'core-components/wp-new/wp-create.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";

export interface PostResourceLinks {
  addAttachment(attachment:HalResource):Promise<any>;
}

export class PostResource extends HalResource {
  public $links:PostResourceLinks;
  public attachments:AttachmentCollectionResource;

  private readonly NotificationsService:NotificationsService = this.injector.get(NotificationsService);
  private readonly wpNotificationsService:WorkPackageNotificationService = this.injector.get(
    WorkPackageNotificationService);
  private readonly opFileUpload:OpenProjectFileUploadService = this.injector.get(OpenProjectFileUploadService);
  private readonly pathHelper:PathHelperService = this.injector.get(PathHelperService);

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

        result.forEach(r => {
          this.attachments.elements.push(r.response);
        });

        return result;
      })
      .catch((error:any) => {
        this.wpNotificationsService.handleRawError(error);
        return;
      });
  }

  private performUpload(files:UploadFile[]) {
    let href = '';

    if (!this.id) {
      href = this.pathHelper.api.v3.attachments.path;
    } else {
      href = this.addAttachment.$link.href;
    }

    return this.opFileUpload.uploadAndMapResponse(href, files);
  }

  public $initialize(source:any) {
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

}

export interface PageResource extends PostResourceLinks {
}
