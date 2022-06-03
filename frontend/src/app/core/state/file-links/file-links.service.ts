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
import { HttpClient } from '@angular/common/http';
import { QueryEntity } from '@datorama/akita';
import { from, Observable } from 'rxjs';
import {
  catchError, groupBy, map, mergeMap, reduce, switchMap, tap,
} from 'rxjs/operators';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { FileLinksStore } from 'core-app/core/state/file-links/file-links.store';
import { insertCollectionIntoState } from 'core-app/core/state/collection-store';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Injectable()
export class FileLinksResourceService {
  private store = new FileLinksStore();

  constructor(
    private readonly http:HttpClient,
    private readonly toastService:ToastService,
  ) {}

  updateCollectionsForWorkPackage(fileLinksSelfLink:string):void {
    this.http
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
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      )
      .subscribe((fileLinkCollections) => {
        const storageId = idFromLink(fileLinkCollections.storage);
        const collectionKey = `${fileLinksSelfLink}?filters=[{"storage":{"operator":"=","values":["${storageId}"]}}]`;
        const collection = { _embedded: { elements: fileLinkCollections.fileLinks } } as IHALCollection<IFileLink>;
        insertCollectionIntoState(this.store, collection, collectionKey);
      });
  }

  collection(key:string):Observable<IFileLink[]> {
    const query = new QueryEntity(this.store);
    return query
      .select()
      .pipe(
        map((state) => state.collections[key]?.ids),
        switchMap((fileLinkIds) => query.selectMany(fileLinkIds)),
      );
  }
}
