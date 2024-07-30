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

import { Injectable } from '@angular/core';
import {
  HttpErrorResponse,
  HttpEvent,
  HttpHeaders,
} from '@angular/common/http';
import { applyTransaction } from '@datorama/akita';
import { Observable } from 'rxjs';
import {
  catchError,
  map,
  tap,
} from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { AttachmentsStore } from 'core-app/core/state/attachments/attachments.store';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  IUploadFile,
  OpUploadService,
} from 'core-app/core/upload/upload.service';
import { removeEntityFromCollectionAndState } from 'core-app/core/state/resource-store';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import isNewResource, { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import waitForUploadsFinished from 'core-app/core/upload/wait-for-uploads-finished';
import isNotNull from 'core-app/core/state/is-not-null';

@Injectable()
export class AttachmentsResourceService extends ResourceStoreService<IAttachment> {
  @InjectField() I18n:I18nService;

  @InjectField() uploadService:OpUploadService;

  @InjectField() configurationService:ConfigurationService;

  @InjectField() toastService:ToastService;

  /**
   * Sends deletion request and updates the store collection of attachments.
   *
   * @param collectionKey The identifier of the current attachment collection.
   * @param attachment The attachment to be deleted.
   */
  removeAttachment(collectionKey:string, attachment:IAttachment):Observable<void> {
    const headers = new HttpHeaders({ 'Content-Type': 'application/json' });

    return this.http
      .delete<void>(attachment._links.delete.href, { withCredentials: true, headers })
      .pipe(
        tap(() => removeEntityFromCollectionAndState(this.store, attachment.id, collectionKey)),
        catchError((error:HttpErrorResponse) => {
          this.toastService.addError(error);
          throw new Error(error.message);
        }),
      );
  }

  /**
   * Sends an upload request and updates the store collection of attachments.
   *
   * @param resource The HAL resource to attach the files to
   * @param files The upload files to be attached.
   */
  attachFiles(resource:HalResource, files:File[]):Observable<IAttachment[]> {
    const identifier = AttachmentsResourceService.getAttachmentsSelfLink(resource) || HAL_NEW_RESOURCE_ID;
    const href = this.getUploadTarget(resource);
    const uploadFiles = files.map((file) => ({ file }));

    return this
      .addAttachments(
        identifier,
        href,
        uploadFiles,
      );
  }

  /**
   * Sends an upload request and updates the store collection of attachments.
   *
   * @param collectionKey The identifier of the current attachment collection.
   * @param uploadHref The API target to perform the call against.
   * @param files The upload files to be attached.
   */
  addAttachments(
    collectionKey:string,
    uploadHref:string,
    files:IUploadFile[],
  ):Observable<IAttachment[]> {
    return this
      .uploadAttachments(uploadHref, files)
      .pipe(
        tap((attachments) => {
          applyTransaction(() => {
            this.store.add(attachments);
            this.store.update(({ collections }) => (
              {
                collections: {
                  ...collections,
                  [collectionKey]: {
                    ...collections[collectionKey],
                    ids: (collections[collectionKey]?.ids || []).concat(attachments.map((a) => a.id)),
                  },
                },
              }
            ));
          });
        }),
      );
  }

  private uploadAttachments(href:string, files:IUploadFile[]):Observable<IAttachment[]> {
    const observables = this.uploadService.upload<IAttachment>(href, files);
    const uploads = files.map((f, i):[File, Observable<HttpEvent<unknown>>] => [f.file, observables[i]]);

    this.toastService.addUpload(this.I18n.t('js.label_upload_notification'), uploads);

    return waitForUploadsFinished(observables)
      .pipe(
        map((responses) =>
          responses
            .map((response) => response.body)
            .filter(isNotNull)),
      );
  }

  /**
   * Get the upload target for a HAL resource, depending on its
   * persisted state and available links.
   *
   * This will be one of the following:
   *   - The direct upload PREPARE URL endpoint for the resource (if direct upload active + resource persisted)
   *   - The generic prepare URL endpoint (if direct upload active)
   *   - The resource's own upload HAL link (if persisted)
   *   - The generic APIv3 attachments endpoint (new resource, no direct upload)
   *
   * @param resource The resource we're uploading attachments for.
   * @returns {string} The API target URL to perform the upload against.
   * @private
   */
  private getUploadTarget(resource:HalResource):string {
    return this.getDirectUploadLink(resource)
      || AttachmentsResourceService.getAttachmentsSelfLink(resource)
      || this.apiV3Service.attachments.path;
  }

  private getDirectUploadLink(resource:HalResource):string|null {
    const links = resource.$links as unknown&{ prepareAttachment:HalLink };

    if (links.prepareAttachment) {
      return links.prepareAttachment.href as string;
    }

    if (isNewResource(resource)) {
      return this.configurationService.prepareAttachmentURL as string|null;
    }

    return null;
  }

  private static getAttachmentsSelfLink(resource:HalResource):string|null {
    const attachments = resource.attachments as unknown&{ href?:string };
    return attachments?.href || null;
  }

  protected createStore():ResourceStore<IAttachment> {
    return new AttachmentsStore();
  }

  protected basePath():string {
    return this.apiV3Service.attachments.path;
  }
}
