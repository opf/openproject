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
import { forkJoin, Observable } from 'rxjs';
import { filter, map, switchMap } from 'rxjs/operators';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { StoragesStore } from 'core-app/core/state/storages/storages.store';
import { StoragesQuery } from 'core-app/core/state/storages/storages.query';
import { insertCollectionIntoState } from 'core-app/core/state/collection-store';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';

export function isIStorage(input:IStorage|undefined):input is IStorage {
  return input !== undefined;
}

@Injectable()
export class StoragesResourceService {
  private readonly store = new StoragesStore();

  private readonly query = new StoragesQuery(this.store);

  constructor(private readonly http:HttpClient) {}

  collection(key:string):Observable<IStorage[]> {
    return this
      .query
      .select()
      .pipe(
        map((state) => state.collections[key]?.ids),
        switchMap((ids) => this.query.selectMany(ids)),
      );
  }

  lookup(id:string):Observable<IStorage> {
    return this
      .query
      .selectEntity(id)
      .pipe(filter(isIStorage));
  }

  updateCollection(key:string, storageLinks:IHalResourceLink[]):void {
    forkJoin(
      storageLinks.map((link) => this.http.get<IStorage>(link.href)),
    ).subscribe((storages) => {
      const storageCollection = { _embedded: { elements: storages } } as IHALCollection<IStorage>;
      insertCollectionIntoState(this.store, storageCollection, key);
    });
  }
}
