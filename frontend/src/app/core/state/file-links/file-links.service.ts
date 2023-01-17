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

import { applyTransaction } from '@datorama/akita';
import { Injectable } from '@angular/core';
import { HttpHeaders } from '@angular/common/http';
import { from, Observable } from 'rxjs';
import {
  groupBy,
  mergeMap,
  reduce,
  switchMap,
  tap,
} from 'rxjs/operators';

import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { FileLinksStore } from 'core-app/core/state/file-links/file-links.store';
import { insertCollectionIntoState, removeEntityFromCollectionAndState } from 'core-app/core/state/collection-store';
import { CollectionStore, ResourceCollectionService } from 'core-app/core/state/resource-collection.service';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Injectable()
export class FileLinksResourceService extends ResourceCollectionService<IFileLink> {
  @InjectField() toastService:ToastService;

  updateCollectionsForWorkPackage(fileLinksSelfLink:string):Observable<IFileLink[]> {
    return this.http
      .get<IHALCollection<IFileLink>>(fileLinksSelfLink)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, fileLinksSelfLink)),
        switchMap((collection) => from(collection._embedded.elements)),
        groupBy(
          (fileLink) => fileLink._links.storage.href,
          (fileLink) => fileLink,
        ),
        mergeMap((group$) => {
          const seed = { storage: group$.key, fileLinks: [] as IFileLink[] };
          return group$.pipe(reduce((acc, fileLink) => {
            acc.fileLinks = [...acc.fileLinks, fileLink];
            return acc;
          }, seed));
        }),
        tap((fileLinkCollections) => {
          const storageId = idFromLink(fileLinkCollections.storage);
          const collectionKey = `${fileLinksSelfLink}?filters=[{"storage":{"operator":"=","values":["${storageId}"]}}]`;
          const collection = { _embedded: { elements: fileLinkCollections.fileLinks } } as IHALCollection<IFileLink>;
          insertCollectionIntoState(this.store, collection, collectionKey);
        }),
        reduce((acc, group) => acc.concat(group.fileLinks), [] as IFileLink[]),
      );
  }

  protected createStore():CollectionStore<IFileLink> {
    return new FileLinksStore();
  }

  remove(collectionKey:string, fileLink:IFileLink):void {
    if (!fileLink._links.delete) {
      return;
    }

    const headers = new HttpHeaders({ 'Content-Type': 'application/json' });
    this.http
      .delete<void>(fileLink._links.delete.href, { withCredentials: true, headers })
      .subscribe(
        () => removeEntityFromCollectionAndState(this.store, fileLink.id, collectionKey),
        this.toastAndThrow.bind(this),
      );
  }

  addFileLinks(collectionKey:string, addFileLinksHref:string, storage:IHalResourceLink, filesToLink:IStorageFile[]):void {
    const elements = filesToLink.map((file) => ({
      originData: {
        id: file.id,
        name: file.name,
        mimeType: file.mimeType,
        size: file.size,
        createdAt: file.createdAt,
        lastModifiedAt: file.lastModifiedAt,
        createdByName: file.createdByName,
        lastModifiedByName: file.lastModifiedByName,
      },
      _links: { storage },
    }));

    this.http
      .post<IHALCollection<IFileLink>>(addFileLinksHref, { _type: 'Collection', _embedded: { elements } })
      .subscribe(
        (collection) => {
          applyTransaction(() => {
            const newFileLinks = collection._embedded.elements;
            this.store.add(newFileLinks);
            this.store.update(
              ({ collections }) => (
                {
                  collections: {
                    ...collections,
                    [collectionKey]: {
                      ...collections[collectionKey],
                      ids: (collections[collectionKey]?.ids || []).concat(newFileLinks.map((link) => link.id)),
                    },
                  },
                }
              ),
            );
          });
        },
        this.toastAndThrow.bind(this),
      );
  }

  protected basePath():string {
    return this.apiV3Service.file_links.path;
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private toastAndThrow(error:any):void {
    this.toastService.addError(error);
    throw error;
  }
}
