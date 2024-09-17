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

import { Injectable, Injector } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { catchError, map } from 'rxjs/operators';
import { Observable, throwError } from 'rxjs';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import * as Pako from 'pako';
import * as base64 from 'byte-base64';
import { whenDebugging } from 'core-app/shared/helpers/debug_output';
import {
  HTTPClientHeaders,
  HTTPClientOptions,
  HTTPClientParamMap,
  HTTPSupportedMethods,
} from 'core-app/features/hal/http/http.interfaces';
import { HalLink, HalLinkInterface } from 'core-app/features/hal/hal-link/hal-link';
import { URLParamsEncoder } from 'core-app/features/hal/services/url-params-encoder';
import { HalResource, HalResourceClass } from 'core-app/features/hal/resources/hal-resource';
import { initializeHalProperties } from '../helpers/hal-resource-builder';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { getPaginatedCollections } from 'core-app/core/apiv3/helpers/get-paginated-results';

export interface HalResourceFactoryConfigInterface {
  cls?:any;
  attrTypes?:{ [attrName:string]:string };
}

interface ErrorWithType {
  _type?:string;
}

@Injectable({ providedIn: 'root' })
export class HalResourceService {
  /**
   * List of all known hal resources, extendable.
   */
  private config:{ [typeName:string]:HalResourceFactoryConfigInterface } = {};

  constructor(
    readonly injector:Injector,
    readonly http:HttpClient,
  ) {
  }

  /**
   * Perform a HTTP request and return a HalResource promise.
   */
  public request<T extends HalResource>(method:HTTPSupportedMethods, href:string, data?:unknown, headers:HTTPClientHeaders = {}):Observable<T> {
    // HttpClient requires us to create HttpParams instead of passing data for get
    // so forward to that method instead.
    if (method === 'get') {
      return this.get(href, data as HTTPClientParamMap|undefined, headers);
    }

    const config:HTTPClientOptions = {
      body: data || {},
      headers,
      withCredentials: true,
      responseType: 'json',
    };

    return this.performRequest(method, href, config);
  }

  private performRequest<T extends HalResource>(method:HTTPSupportedMethods, href:string, config:HTTPClientOptions):Observable<T> {
    return this.http.request(method, href, config)
      .pipe(
        map((response:unknown) => this.createHalResource<T>(response)),
        catchError((error:HttpErrorResponse) => {
          whenDebugging(() => console.error(`Failed to ${method} ${href}: ${error.name}`));
          return this.createErrorObservable(error);
        }),
      );
  }

  /**
   * Perform a GET request and return a resource promise.
   *
   * @param href
   * @param params
   * @param headers
   * @returns {Promise<HalResource>}
   */
  public get<T extends HalResource>(href:string, params?:HTTPClientParamMap, headers?:HTTPClientHeaders):Observable<T> {
    const config:HTTPClientOptions = {
      headers,
      params: new HttpParams({ encoder: new URLParamsEncoder(), fromObject: params }),
      withCredentials: true,
      responseType: 'json',
    };

    return this.performRequest('get', href, config);
  }

  /**
   * Return all potential pages to the request, when the elements returned from API is smaller
   * than the expected.
   *
   * @param href The URL to request
   * @param params Parameters to pass to each paged request
   * @param headers Headers to pass to each paged request
   * @return {Observable<CollectionResource[]>}
   */
  public getAllPaginated<T extends CollectionResource>(
    href:string,
    params:Record<string, string|number|boolean> = {},
    headers:HTTPClientHeaders = {},
  ):Observable<T[]> {
    return getPaginatedCollections(
      (pageParams) => {
        const requestParams = { ...params, ...pageParams };
        return this.request<CollectionResource<T>>('get', href, this.toEprops(requestParams), headers);
      },
      (params.pageSize as number|undefined) || -1,
    ) as Observable<T[]>;
  }

  /**
   * Perform a PUT request and return a resource promise.
   * @param href
   * @param data
   * @param headers
   * @returns {Promise<HalResource>}
   */
  public put<T extends HalResource>(href:string, data?:any, headers?:HTTPClientHeaders):Observable<T> {
    return this.request('put', href, data, headers);
  }

  /**
   * Perform a POST request and return a resource promise.
   *
   * @param href
   * @param data
   * @param headers
   * @returns {Promise<HalResource>}
   */
  public post<T extends HalResource>(href:string, data?:any, headers?:HTTPClientHeaders):Observable<T> {
    return this.request('post', href, data, headers);
  }

  /**
   * Perform a PATCH request and return a resource promise.
   *
   * @param href
   * @param data
   * @param headers
   * @returns {Promise<HalResource>}
   */
  public patch<T extends HalResource>(href:string, data?:any, headers?:HTTPClientHeaders):Observable<T> {
    return this.request('patch', href, data, headers);
  }

  /**
   * Perform a DELETE request and return a resource promise
   *
   * @param href
   * @param data
   * @param headers
   * @returns {Promise<HalResource>}
   */
  public delete<T extends HalResource>(href:string, data?:any, headers?:HTTPClientHeaders):Observable<T> {
    return this.request('delete', href, data, headers);
  }

  /**
   * Register a HalResource for use with the API.
   * @param {HalResourceStatic} resource
   */
  public registerResource(key:string, entry:HalResourceFactoryConfigInterface) {
    this.config[key] = entry;
  }

  /**
   * Get the default class.
   * Initially, it's HalResource.
   *
   * @returns {HalResource}
   */
  public get defaultClass():HalResourceClass<HalResource> {
    const defaultCls:HalResourceClass = HalResource;
    return defaultCls;
  }

  /**
   * Create a HalResource from a source object.
   * If the APIv3 _type attribute is defined and the type is configured,
   * the respective class will be used for instantiation.
   *
   *
   * @param source
   * @returns {HalResource}
   */
  public createHalResource<T extends HalResource = HalResource>(source:any, loaded = true):T {
    if (_.isNil(source)) {
      source = HalResource.getEmptyResource();
    }

    const type = source._type || 'HalResource';
    return this.createHalResourceOfType<T>(type, source, loaded);
  }

  public createHalResourceOfType<T extends HalResource = HalResource>(type:string, source:any, loaded = false) {
    const resourceClass:HalResourceClass<T> = this.getResourceClassOfType(type);
    const initializer = (halResource:T) => initializeHalProperties(this, halResource);
    const resource = new resourceClass(this.injector, source, loaded, initializer, type);

    return resource;
  }

  /**
   * Create a resource class of the given class
   * @param resourceClass
   * @param source
   * @param loaded
   */
  public createHalResourceOfClass<T extends HalResource>(resourceClass:HalResourceClass<T>, source:any, loaded = false) {
    const initializer = (halResource:T) => initializeHalProperties(this, halResource);
    const type = source._type || 'HalResource';
    const resource = new resourceClass(this.injector, source, loaded, initializer, type);

    return resource;
  }

  /**
   * Create a linked HalResource from the given link.
   *
   * @param {HalLinkInterface} link
   * @returns {HalResource}
   */
  public fromLink(link:HalLinkInterface) {
    const resource = HalResource.getEmptyResource(HalLink.fromObject(this, link));
    return this.createHalResource(resource, false);
  }

  /**
   * Create an empty HAL resource with only the self link set.
   * @param href Self link of the HAL resource
   */
  public fromSelfLink(href:string|null) {
    const source = { _links: { self: { href } } };
    return this.createHalResource(source);
  }

  /**
   *
   * Get a linked resource from its HalLink with the correct type.
   */
  public createLinkedResource<T extends HalResource = HalResource>(halResource:T, linkName:string, link:HalLinkInterface) {
    const source = HalResource.getEmptyResource();
    const fromType = halResource.$halType;
    const toType = this.getResourceClassOfAttribute(fromType, linkName) || 'HalResource';

    source._links.self = link;

    return this.createHalResourceOfType(toType, source, false);
  }

  /**
   * Get the configured resource class of a type.
   *
   * @param type
   * @returns {HalResource}
   */
  protected getResourceClassOfType<T extends HalResource>(type:string):HalResourceClass<T> {
    const config = this.config[type];
    return (config && config.cls) ? config.cls : this.defaultClass;
  }

  /**
   * Get the hal type for an attribute
   *
   * @param type
   * @param attribute
   * @returns {any}
   */
  protected getResourceClassOfAttribute<T extends HalResource = HalResource>(type:string, attribute:string):string|null {
    const typeConfig = this.config[type];
    const types = (typeConfig && typeConfig.attrTypes) || {};
    return types[attribute];
  }

  protected toEprops(params:unknown):{ eprops:string } {
    const deflatedArray = Pako.deflate(JSON.stringify(params));

    const compressed = base64.bytesToBase64(deflatedArray);

    return { eprops: compressed };
  }

  private createErrorObservable(error:HttpErrorResponse):Observable<never> {
    let resource:ErrorResource|null = null;

    const body = error.error as string|ErrorWithType|unknown;
    // eslint-disable-next-line no-underscore-dangle
    if (typeof body === 'object' && (body as ErrorWithType)?._type) {
      resource = this.createHalResource<ErrorResource>(error.error);
    }

    return throwError(new HalError(error, resource));
  }
}
