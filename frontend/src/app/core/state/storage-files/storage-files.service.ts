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
import { combineLatest, Observable } from 'rxjs';
import {
  filter, map, take, tap,
} from 'rxjs/operators';

import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { StorageFilesStore } from 'core-app/core/state/storage-files/storage-files.store';
import { IUploadLink } from 'core-app/core/state/storage-files/upload-link.model';
import { IPrepareUploadLink } from 'core-app/core/state/storages/storage.model';
import { IStorageFiles } from 'core-app/core/state/storage-files/storage-files.model';
import { HttpClient } from '@angular/common/http';
import { ID, QueryEntity } from '@datorama/akita';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import isDefinedEntity from 'core-app/core/state/is-defined-entity';

@Injectable()
export class StorageFilesResourceService {
  private readonly store:StorageFilesStore = new StorageFilesStore();

  private readonly query = new QueryEntity(this.store);

  constructor(private readonly httpClient:HttpClient) {}

  files(link:IHalResourceLink):Observable<IStorageFiles> {
    const value = this.store.getValue().files[link.href];
    if (value !== undefined) {
      return combineLatest([this.lookupMany(value.files), this.lookup(value.parent)])
        .pipe(
          map(([files, parent]):IStorageFiles => ({
            files, parent, _type: 'StorageFiles', _links: { self: link },
          })),
          take(1),
        );
    }

    return this.httpClient
      .get<IStorageFiles>(link.href)
      .pipe(tap((storageFiles) => this.insert(storageFiles, link.href)));
  }

  uploadLink(link:IPrepareUploadLink):Observable<IUploadLink> {
    return this.httpClient.request<IUploadLink>(link.method, link.href, { body: link.payload });
  }

  reset():void {
    this.store.reset();
  }

  private lookup(id:ID):Observable<IStorageFile> {
    return this
      .query
      .selectEntity(id)
      .pipe(filter(isDefinedEntity));
  }

  private lookupMany(ids:ID[]):Observable<IStorageFile[]> {
    return this.query.selectMany(ids);
  }

  private insert(storageFiles:IStorageFiles, link:string):void {
    this.store.upsertMany([...storageFiles.files, storageFiles.parent]);

    const fileIds = storageFiles.files.map((file) => file.id);
    const parentId = storageFiles.parent.id;

    this.store.update(({ files }) => ({
      files: {
        ...files,
        [link]: {
          files: fileIds,
          parent: parentId,
        },
      },
    }));
  }
}
