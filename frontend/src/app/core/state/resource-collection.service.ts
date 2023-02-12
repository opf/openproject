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

import {
  EntityStore,
  ID,
  QueryEntity,
} from '@datorama/akita';
import { Observable } from 'rxjs';
import {
  catchError,
  filter,
  finalize,
  map,
  switchMap,
  tap,
} from 'rxjs/operators';
import {
  collectionKey,
  CollectionResponse,
  CollectionState,
  insertCollectionIntoState,
  removeCollectionLoading,
  setCollectionLoading,
} from 'core-app/core/state/collection-store';
import { omit } from 'lodash';
import isDefinedEntity from 'core-app/core/state/is-defined-entity';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import {
  HttpClient,
  HttpErrorResponse,
} from '@angular/common/http';
import {
  Injectable,
  Injector,
} from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

export type CollectionStore<T> = EntityStore<CollectionState<T>>;

export interface ResourceCollectionLoadOptions {
  handleErrors:boolean;
}

@Injectable()
export abstract class ResourceCollectionService<T extends { id:ID }> {
  protected store:CollectionStore<T> = this.createStore();

  protected query = new QueryEntity(this.store);

  constructor(
    readonly injector:Injector,
    readonly http:HttpClient,
    readonly apiV3Service:ApiV3Service,
    readonly toastService:ToastService,
  ) {
  }

  /**
   * Require the results for the given filter params
   * Returns a cached set if it was loaded already.
   *
   * @param params List params to require
   * @private
   */
  public require(params:ApiV3ListParameters):Observable<T[]> {
    const key = collectionKey(params);
    if (this.collectionExists(key) || this.collectionLoading(key)) {
      return this.loadedCollection(key);
    }

    return this
      .fetchCollection(params)
      .pipe(
        switchMap(() => this.loadedCollection(key)),
      );
  }

  /**
   * Retrieve a collection from the store
   *
   * @param key The collection key to fetch
   */
  collection(key:string):Observable<T[]> {
    return this
      .collectionState(key)
      .pipe(
        switchMap((collection) => this.query.selectMany(collection?.ids || [])),
      );
  }

  /**
   * Return a collection observable that triggers only when the collection is loaded.
   * @param key
   */
  loadedCollection(key:string):Observable<T[]> {
    return this
      .collectionState(key)
      .pipe(
        filter((collection) => !!collection),
        switchMap((collection:CollectionResponse) => this.query.selectMany(collection.ids)),
      );
  }

  /**
   * Return a collection observable that triggers only when the collection is loaded.
   * @param key
   */
  collectionState(key:string):Observable<CollectionResponse|undefined> {
    return this
      .query
      .select()
      .pipe(
        map((state) => state.collections[key]),
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
   * Checks, if the store already has a collection given the key
   */
  collectionExists(input:string|ApiV3ListParameters):boolean {
    const key = typeof input === 'string' ? input : collectionKey(input);
    return !!this
      .query
      .getValue()
      .collections[key];
  }

  /**
   * Checks, if the store already has a collection given the key
   */
  collectionLoading(input:string|ApiV3ListParameters):boolean {
    const key = typeof input === 'string' ? input : collectionKey(input);
    return this
      .query
      .getValue()
      .loadingCollections[key] === true;
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
   * Fetch a given collection, returning only its results
   */
  fetchResults(params:ApiV3ListParameters|string):Observable<T[]> {
    return this
      .fetchCollection(params)
      .pipe(
        map((collection) => collection._embedded.elements),
      );
  }

  /**
   * Fetch a given collection, ensuring it is being flagged as loaded
   *
   * @param params {ApiV3ListParameters|string} collection key or list params to build collection key from
   * @param options {ResourceCollectionLoadOptions} Handle collection loading errors within the resource service
   */
  fetchCollection(
    params:ApiV3ListParameters|string,
    options:ResourceCollectionLoadOptions = { handleErrors: true },
  ):Observable<IHALCollection<T>> {
    const key = typeof params === 'string' ? params : collectionKey(params);

    setCollectionLoading(this.store, key);

    return this
      .http
      .get<IHALCollection<T>>(this.basePath() + key)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, key)),
        finalize(() => removeCollectionLoading(this.store, key)),
        catchError((error:unknown) => {
          if (options.handleErrors) {
            this.handleCollectionLoadingError(error as HttpErrorResponse, key);
          }

          throw error;
        }),
      );
  }

  /**
   * Create a new instance of this resource service's underlying store.
   * @protected
   */
  protected abstract createStore():CollectionStore<T>;

  /**
   * Base path for this collection
   * @protected
   */
  protected abstract basePath():string;

  /**
   * By default, add a toast error in case of loading errors
   * @param error
   * @param _collectionKey
   * @protected
   */
  protected handleCollectionLoadingError(error:HttpErrorResponse, _collectionKey:string):void {
    this.toastService.addError(error);
  }
}
