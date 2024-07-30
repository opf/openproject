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

import { applyTransaction } from '@datorama/akita';
import { Injectable } from '@angular/core';
import { HttpHeaders } from '@angular/common/http';
import {
  from,
  Observable,
  of,
} from 'rxjs';
import {
  groupBy,
  mergeMap,
  reduce,
  switchMap,
  tap,
} from 'rxjs/operators';

import {
  IFileLink,
  IFileLinkOriginData,
} from 'core-app/core/state/file-links/file-link.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { FileLinksStore } from 'core-app/core/state/file-links/file-links.store';
import {
  insertCollectionIntoState,
  removeEntityFromCollectionAndState,
} from 'core-app/core/state/resource-store';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Injectable()
export class FileLinksResourceService extends ResourceStoreService<IFileLink> {
  protected createStore():ResourceStore<IFileLink> {
    return new FileLinksStore();
  }

  protected basePath():string {
    return this.apiV3Service.file_links.path;
  }

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

  updateCollection(href:string):Observable<IHALCollection<IFileLink>> {
    return this.http
      .get<IHALCollection<IFileLink>>(href)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, href)),
      );
  }

  remove(collectionKey:string, fileLink:IFileLink):Observable<void> {
    if (!fileLink._links.delete) {
      return of();
    }

    const headers = new HttpHeaders({ 'Content-Type': 'application/json' });
    return this.http
      .delete<void>(fileLink._links.delete.href, { withCredentials: true, headers })
      .pipe(
        tap(() => removeEntityFromCollectionAndState(this.store, fileLink.id, collectionKey)),
      );
  }

  addFileLinks(
    collectionKey:string,
    addFileLinksHref:string,
    storage:IHalResourceLink,
    filesToLink:IFileLinkOriginData[],
  ):Observable<IHALCollection<IFileLink>> {
    const elements = filesToLink.map((file) => ({
      originData: { ...file },
      _links: { storage },
    }));

    return this.http
      .post<IHALCollection<IFileLink>>(addFileLinksHref, { _type: 'Collection', _embedded: { elements } })
      .pipe(
        tap((collection) => {
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
        }),
      );
  }
}
