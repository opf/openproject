// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
import { Observable } from 'rxjs';
import { map, take, tap } from 'rxjs/operators';

import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { StorageFilesStore } from 'core-app/core/state/storage-files/storage-files.store';
import { insertCollectionIntoState } from 'core-app/core/state/collection-store';
import { IUploadLink } from 'core-app/core/state/storage-files/upload-link.model';
import { IPrepareUploadLink } from 'core-app/core/state/storages/storage.model';

@Injectable()
export class StorageFilesResourceService extends ResourceCollectionService<IStorageFile> {
  protected createStore():CollectionStore<IStorageFile> {
    return new StorageFilesStore();
  }

  files(link:IHalResourceLink):Observable<IStorageFile[]> {
    if (this.collectionExists(link.href)) {
      return this.collection(link.href);
    }

    return this.http
      .get<IHALCollection<IStorageFile>>(link.href)
      .pipe(
        tap((collection) => {
          insertCollectionIntoState(this.store, collection, link.href);
        }),
        map((collection) => collection._embedded.elements),
        take(1),
      );
  }

  uploadLink(link:IPrepareUploadLink):Observable<IUploadLink> {
    return this.http.request<IUploadLink>(link.method, link.href, { body: link.payload });
  }

  reset():void {
    this.store.reset();
  }

  protected basePath():string {
    return this.apiV3Service.storages.files.path;
  }
}
