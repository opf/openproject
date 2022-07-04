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

import {
  EntityStore,
  ID,
  QueryEntity,
} from '@datorama/akita';
import { Observable } from 'rxjs';
import {
  filter,
  map,
  switchMap,
} from 'rxjs/operators';
import { CollectionState } from 'core-app/core/state/collection-store';
import { omit } from 'lodash';
import isDefinedEntity from 'core-app/core/state/is-defined-entity';

export type CollectionStore<T> = EntityStore<CollectionState<T>>;

export abstract class ResourceCollectionService<T> {
  protected store:CollectionStore<T> = this.createStore();

  protected query = new QueryEntity(this.store);

  /**
   * Retrieve a collection from the store
   *
   * @param key The collection key to fetch
   */
  collection(key:string):Observable<T[]> {
    return this
      .query
      .select()
      .pipe(
        map((state) => state.collections[key]?.ids),
        switchMap((fileLinkIds) => this.query.selectMany(fileLinkIds)),
      );
  }

  /**
   * Lookup a single entity from the store
   * @param id
   */
  lookup(id:ID):Observable<T> {
    return this
      .query
      .selectEntity(id)
      .pipe(filter(isDefinedEntity));
  }

  /**
   * Lookup multiple entities from the store
   */
  lookupMany(ids:ID[]):Observable<T[]> {
    return this
      .query
      .selectMany(ids);
  }

  /**
   * Checks, if the store already has a resource loaded by id.
   * @param id
   */
  exists(id:ID):boolean {
    return this.query.hasEntity(id);
  }

  /**
   * Clear a collection key
   * @param key Collection key to clear
   */
  clear(key:string):void {
    this
      .store
      .update(
        ({ collections }) => ({
          collections: omit(collections, key),
        }),
      );
  }

  /**
   * Update a single entity in the store
   *
   * @param id The id to update
   * @param entity A section of the entity to update
   */
  update(id:ID, entity:Partial<T>):void {
    this.store.update(id, entity);
  }

  /**
   * Create a new instance of this resource service's underyling store.
   * @protected
   */
  protected abstract createStore():CollectionStore<T>;
}
