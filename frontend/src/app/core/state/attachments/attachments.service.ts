// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
  HttpClient,
  HttpHeaders,
} from '@angular/common/http';
import {
  applyTransaction,
  QueryEntity,
} from '@datorama/akita';
import {
  from,
  Observable,
} from 'rxjs';
import {
  catchError,
  map,
  tap,
} from 'rxjs/operators';
import { AttachmentsStore } from 'core-app/core/state/attachments/attachments.store';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  OpenProjectFileUploadService,
  UploadFile,
} from 'core-app/core/file-upload/op-file-upload.service';
import { OpenProjectDirectFileUploadService } from 'core-app/core/file-upload/op-direct-file-upload.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalLink } from 'core-app/features/hal/hal-link/hal-link';
import isNewResource, { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { insertCollectionIntoState } from 'core-app/core/state/collection-store';

@Injectable()
export class AttachmentsResourceService {
  protected store = new AttachmentsStore();

  public query = new QueryEntity(this.store);

  constructor(
    private readonly I18n:I18nService,
    private readonly http:HttpClient,
    private readonly apiV3Service:ApiV3Service,
    private readonly fileUploadService:OpenProjectFileUploadService,
    private readonly directFileUploadService:OpenProjectDirectFileUploadService,
    private readonly configurationService:ConfigurationService,
    private readonly toastService:ToastService,
  ) { }

  /**
   * This method ensures that a specific collection is fetched, if not available.
   *
   * @param key The collection key, of the required collection.
   */
  requireCollection(key:string):void {
    if (this.store.getValue().collections[key]) {
      return;
    }

    this.fetchAttachments(key).subscribe();
  }

  /**
   * Fetches attachments by the attachment collection self link.
   * This link is used as key to store the result collection in the resource store.
   *
   * @param attachmentsSelfLink The self link of the attachment collection from the parent resource.
   */
  fetchAttachments(attachmentsSelfLink:string):Observable<IHALCollection<IAttachment>> {
    return this.http
      .get<IHALCollection<IAttachment>>(attachmentsSelfLink)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, attachmentsSelfLink)),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

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
        tap(() => {
          applyTransaction(() => {
            this.store.remove(attachment.id);
            this.store.update(({ collections }) => (
              {
                collections: {
                  ...collections,
                  [collectionKey]: {
                    ...collections[collectionKey],
                    ids: (collections[collectionKey]?.ids || []).filter((id) => id !== attachment.id),
                  },
                },
              }
            ));
          });
        }),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  /**
   * Sends an upload request and updates the store collection of attachments.
   *
   * @param resource The HAL resource to attach the files to
   * @param files The upload files to be attached.
   */
  attachFiles(resource:HalResource, files:UploadFile[]):Observable<IAttachment[]> {
    const identifier = AttachmentsResourceService.getAttachmentsSelfLink(resource) || HAL_NEW_RESOURCE_ID;
    const href = this.getUploadTarget(resource);
    const isDirectUpload = !!this.getDirectUploadLink(resource);

    return this
      .addAttachments(
        identifier,
        href,
        files,
        isDirectUpload,
      );
  }

  /**
   * Sends an upload request and updates the store collection of attachments.
   *
   * @param collectionKey The identifier of the current attachment collection.
   * @param uploadHref The API target to perform the call against.
   * @param files The upload files to be attached.
   * @param isDirectUpload whether the provided upload target is a direct upload URL.
   */
  addAttachments(
    collectionKey:string,
    uploadHref:string,
    files:UploadFile[],
    isDirectUpload = false,
  ):Observable<IAttachment[]> {
    return this
      .uploadAttachments(uploadHref, files, isDirectUpload)
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

  private uploadAttachments(href:string, files:UploadFile[], isDirectUpload:boolean):Observable<IAttachment[]> {
    const { uploads, finished } = isDirectUpload
      ? this.directFileUploadService.uploadAndMapResponse(href, files)
      : this.fileUploadService.uploadAndMapResponse(href, files);

    const message = this.I18n.t('js.label_upload_notification');
    const notification = this.toastService.addAttachmentUpload(message, uploads);

    return from(finished)
      .pipe(
        tap(() => {
          setTimeout(() => this.toastService.remove(notification), 700);
        }),
        map((result) => result.map(({ response }) => (response as HalResource).$source as IAttachment)),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
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
}
