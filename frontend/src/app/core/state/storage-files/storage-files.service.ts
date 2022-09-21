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
import {
  CollectionStore,
  ResourceCollectionService,
} from 'core-app/core/state/resource-collection.service';
import { StorageFilesStore } from 'core-app/core/state/storage-files/storage-files.store';
import { Observable, of } from 'rxjs';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { insertCollectionIntoState } from 'core-app/core/state/collection-store';
import { map } from 'rxjs/operators';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';

@Injectable()
export class StorageFilesResourceService extends ResourceCollectionService<IStorageFile> {
  constructor(private readonly http:HttpClient) {
    super();
  }

  protected createStore():CollectionStore<IStorageFile> {
    return new StorageFilesStore();
  }

  // fetch(link:IHalResourceLink):void {
  fetch():void {
    // this.http
    //   .get<[IStorageFile]>(link.href)
    this.mockedFileList()
      .pipe(map((fileList) => ({ _embedded: { elements: fileList } } as unknown as IHALCollection<IStorageFile>)))
      .subscribe((fileList) => insertCollectionIntoState(this.store, fileList, 'root'));
  }

  files():Observable<IStorageFile[]> {
    return this.collection('root');
  }

  private mockedFileList():Observable<IStorageFile[]> {
    return of([
      {
        id: 1,
        name: 'image.png',
        mimeType: 'image/png',
        lastModifiedAt: '2022-09-16T12:00Z',
        lastModifiedByName: 'Leia Organa',
        location: '/data',
      },
      {
        id: 2,
        name: 'Readme.md',
        mimeType: 'text/markdown',
        lastModifiedAt: '2022-09-16T13:00Z',
        lastModifiedByName: 'Anakin Skywalker',
        location: '/data',
      },
      {
        id: 3,
        name: 'folder',
        mimeType: 'application/x-op-directory',
        location: '/data',
      },
      {
        id: 4,
        name: 'directory',
        mimeType: 'application/x-op-directory',
        location: '/data',
      },
    ]);
  }
}
