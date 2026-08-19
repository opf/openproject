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
import { tap } from 'rxjs/operators';
import {
  forkJoin,
  Observable,
} from 'rxjs';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { StoragesStore } from 'core-app/core/state/storages/storages.store';
import { insertCollectionIntoState } from 'core-app/core/state/resource-store';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';

@Injectable()
export class StoragesResourceService extends ResourceStoreService<IStorage> {
  updateCollection(key:string, storageLinks:IHalResourceLink[]):Observable<IStorage[]> {
    return forkJoin(storageLinks.map((link) => this.http.get<IStorage>(link.href)))
      .pipe(
        tap((storages) => {
          const storageCollection = { _embedded: { elements: storages } } as IHALCollection<IStorage>;
          insertCollectionIntoState(this.store, storageCollection, key);
        }),
      );
  }

  protected createStore():ResourceStore<IStorage> {
    return new StoragesStore();
  }

  protected basePath():string {
    return this.apiV3Service.storages.path;
  }
}
