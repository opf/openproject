//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {Injectable} from '@angular/core';
import {HttpClient} from '@angular/common/http';
import {tap} from 'rxjs/operators';
import {Observable} from 'rxjs';
import {HalResourceFactoryService} from 'core-app/modules/hal/services/hal-resource-factory.service';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';

export type HTTPSupportedMethods = 'get'|'post'|'put'|'patch'|'delete';

@Injectable()
export class HalRequestService {
  constructor(readonly http:HttpClient,
              readonly halResourceFactory:HalResourceFactoryService) {
  }

  /**
   * Perform a HTTP request and return a HalResource promise.
   */
  public request<T extends HalResource>(method:HTTPSupportedMethods, href:string, data?:any, headers:any = {}):Observable<T> {
    const config:any = {
      method: method,
      url: href,
      body: data || {},
      headers: headers,
      withCredentials: true,
      responseType: 'json'
    };

    const createResource = (response:any) => {
      if (!response.data) {
        return response;
      }

      return this.halResourceFactory.createHalResource(response.data);
    };

    return this.http.request<T>(method, href, config)
      .pipe(
        tap(
          data => createResource(data),
          error => createResource(error)
        )
      ) as Observable<T>;
  }

  /**
   * Perform a GET request and return a resource promise.
   *
   * @param href
   * @param params
   * @param headers
   * @returns {Promise<HalResource>}
   */
  public get<T extends HalResource>(href:string, params?:any, headers?:any):Observable<T> {
    return this.request('get', href, params, headers);
  }

  /**
   * Return all potential pages to the request, when the elements returned from API is smaller
   * than the expected.
   *
   * @param href
   * @param expected The expected number of elements
   * @param params
   * @param headers
   * @return {Promise<CollectionResource[]>}
   */
  public async getAllPaginated<T extends HalResource[]>(href:string, expected:number, params:any = {}, headers:any = {}) {
    // Total number retrieved
    let retrieved = 0;
    // Current offset page
    let page = 1;
    // Accumulated results
    const allResults:CollectionResource[] = [];
    // If possible, request all at once.
    params.pageSize = expected;

    while (retrieved < expected) {
      params.offset = page;

      const promise = this.request<CollectionResource>('get', href, params, headers).toPromise();
      const results = await promise;

      if (results.count === 0) {
        throw 'No more results for this query, but expected more.';
      }

      allResults.push(results as CollectionResource);

      retrieved += results.count;
      page += 1;
    }

    return allResults;
  }

  /**
   * Perform a PUT request and return a resource promise.
   * @param href
   * @param data
   * @param headers
   * @returns {Promise<HalResource>}
   */
  public put<T extends HalResource>(href:string, data?:any, headers?:any):Observable<T> {
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
  public post<T extends HalResource>(href:string, data?:any, headers?:any):Observable<T> {
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
  public patch<T extends HalResource>(href:string, data?:any, headers?:any):Observable<T> {
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
  public delete<T extends HalResource>(href:string, data?:any, headers?:any):Observable<T> {
    return this.request('delete', href, data, headers);
  }
}

