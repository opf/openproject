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
  shareReplay,
  switchMap,
  tap,
} from 'rxjs/operators';
import {
  CollectionResponse,
  insertCollectionIntoState,
  removeResourceLoading,
  ResourceState,
  setResourceLoading,
} from 'core-app/core/state/resource-store';
import { omit } from 'lodash';
import isDefinedEntity from 'core-app/core/state/is-defined-entity';
import {
  ApiV3ListParameters,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
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
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

export type ResourceStore<T> = EntityStore<ResourceState<T>>;

export interface ResourceStoreLoadOptions {
  handleErrors:boolean;
}

export type ResourceKeyInput = ApiV3ListParameters|string;

@Injectable()
export abstract class ResourceStoreService<T extends { id:ID }> {
  protected store:ResourceStore<T> = this.createStore();

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
   * @param input List params to require, or href of the resource
   * @private
   */
  public requireCollection(input:ResourceKeyInput):Observable<T[]> {
    const href = this.buildResourceLink(input);
    if (this.collectionExists(href) || this.resourceLoading(href)) {
      return this.loadedCollection(href);
    }

    return this
      .fetchCollection(href)
      .pipe(
        switchMap(() => this.loadedCollection(href)),
      );
  }

  /**
   * Require a single entity to be loaded.
   * Returnes the cached entity if it was loaded already
   *
   * @param href {string}
   */
  public requireEntity(href:string):Observable<T> {
    const id = idFromLink(href);
    if (this.query.hasEntity(id) || this.resourceLoading(href)) {
      return this.lookup(id);
    }

    return this.fetchEntity(href);
  }

  /**
   * Retrieve a collection from the store
   *
   * @param input List params to require, or href of the resource
   */
  collection(input:ResourceKeyInput):Observable<T[]> {
    const href = this.buildResourceLink(input);

    return this
      .collectionState(href)
      .pipe(
        switchMap((collection) => this.query.selectMany(collection?.ids || [])),
      );
  }

  /**
   * Return a collection observable that triggers only when the collection is loaded.
   * @param input List params to require, or href of the resource
   */
  loadedCollection(input:ResourceKeyInput):Observable<T[]> {
    const href = this.buildResourceLink(input);

    return this
      .collectionState(href)
      .pipe(
        filter(isDefinedEntity),
        switchMap((collection:CollectionResponse) => this.query.selectMany(collection.ids)),
      );
  }

  /**
   * Return a collection observable that triggers only when the collection is loaded.
   * @param input List params to require, or href of the resource
   */
  collectionState(input:ResourceKeyInput):Observable<CollectionResponse|undefined> {
    const href = this.buildResourceLink(input);

    return this
      .query
      .select()
      .pipe(
        map((state) => state.collections[href]),
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
   *
   * @param input List params to require, or href of the resource
   */
  collectionExists(input:ResourceKeyInput):boolean {
    const href = this.buildResourceLink(input);

    return !!this
      .query
      .getValue()
      .collections[href];
  }

  /**
   * Checks, if the store already has a collection given the key
   *
   * @param input List params to require, or href of the resource
   */
  resourceLoading(input:ResourceKeyInput):boolean {
    const href = this.buildResourceLink(input);

    return this
      .query
      .getValue()
      .loadingResources[href] === true;
  }

  /**
   * Clear a collection key
   * @param input List params to require, or href of the resource
   */
  clear(input:ResourceKeyInput):void {
    const href = this.buildResourceLink(input);

    this
      .store
      .update(
        ({ collections }) => ({
          collections: omit(collections, href),
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
  fetchResults(params:ResourceKeyInput):Observable<T[]> {
    return this
      .fetchCollection(params)
      .pipe(
        map((collection) => collection._embedded.elements),
      );
  }

  /**
   * Fetch a given collection, ensuring it is being flagged as loaded
   *
   * @param params {ResourceKeyInput} collection key or list params to build collection key from
   * @param options {ResourceStoreLoadOptions} Handle collection loading errors within the resource service
   */
  fetchCollection(
    params:ResourceKeyInput,
    options:ResourceStoreLoadOptions = { handleErrors: true },
  ):Observable<IHALCollection<T>> {
    const href = this.buildResourceLink(params);

    setResourceLoading(this.store, href);

    return this
      .http
      .get<IHALCollection<T>>(href)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, href)),
        finalize(() => removeResourceLoading(this.store, href)),
        catchError((error:unknown) => {
          if (options.handleErrors) {
            this.handleResourceLoadingError(error as HttpErrorResponse, href);
          }

          throw error;
        }),
        shareReplay(1),
      );
  }

  /**
   * Fetch a single entity, ensuring it is being flagged as loaded
   *
   * @param href {string} of the resource to load
   * @param options {ResourceStoreLoadOptions} Handle loading errors within the resource service
   */
  fetchEntity(
    href:string,
    options:ResourceStoreLoadOptions = { handleErrors: true },
  ):Observable<T> {
    setResourceLoading(this.store, href);

    return this
      .http
      .get<T>(href)
      .pipe(
        tap((entity) => this.store.add(entity)),
        finalize(() => removeResourceLoading(this.store, href)),
        catchError((error:unknown) => {
          if (options.handleErrors) {
            this.handleResourceLoadingError(error as HttpErrorResponse, href);
          }

          throw error;
        }),
        shareReplay(1),
      );
  }

  protected buildResourceLink(input:ResourceKeyInput):string {
    if (typeof input === 'string') {
      return input;
    }

    return this.basePath() + listParamsString(input);
  }

  /**
   * Create a new instance of this resource service's underlying store.
   * @protected
   */
  protected abstract createStore():ResourceStore<T>;

  /**
   * Base path for this collection
   * @protected
   */
  protected abstract basePath():string;

  /**
   * By default, add a toast error in case of loading errors
   * @param error
   * @param _path
   * @protected
   */
  protected handleResourceLoadingError(error:HttpErrorResponse, _path:string):void {
    this.toastService.addError(error);
  }
}
