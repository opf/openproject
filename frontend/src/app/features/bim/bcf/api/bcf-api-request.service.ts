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

import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Injector } from '@angular/core';
import { TypedJSON } from 'typedjson';
import { Constructor } from '@angular/cdk/table';
import { Observable, throwError } from 'rxjs';
import {
  HTTPClientHeaders,
  HTTPClientOptions,
  HTTPClientParamMap,
  HTTPSupportedMethods,
} from 'core-app/features/hal/http/http.interfaces';
import { catchError, map } from 'rxjs/operators';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { URLParamsEncoder } from 'core-app/features/hal/services/url-params-encoder';

export class BcfApiRequestService<T> {
  @InjectField() http:HttpClient;

  /**
   * Create a BCF api request service.
   * Optionally pass a resource map to map the resulting data to with TypedJson.
   *
   * @param injector Injector
   * @param resourceClass Optional mapped resource class with TypedJson annotations
   */
  constructor(readonly injector:Injector,
    readonly resourceClass?:Constructor<T>) {
  }

  /**
   * Request GET from the given BCF API 2.1 resource and map it to +resourceClass+.
   *
   * @param path API path to request
   * @param params Request query params
   * @param headers optional headers map
   */
  get(path:string, params:HTTPClientParamMap, headers:HTTPClientHeaders = {}):Observable<T> {
    const config:HTTPClientOptions = {
      headers,
      params: new HttpParams({ encoder: new URLParamsEncoder(), fromObject: params }),
      withCredentials: true,
      responseType: 'json',
    };

    return this._request('get', path, config);
  }

  /**
   * Request the given BCF API 2.1 resource and map it to +resourceClass+.
   *
   * @param method request method
   * @param path API path to request
   * @param data Request payload (URL params for get, JSON payload otherwise)
   * @param headers Request headers
   */
  public request(method:HTTPSupportedMethods, path:string, data:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}):Observable<T> {
    // HttpClient requires us to create HttpParams instead of passing data for get
    // so forward to that method instead.
    if (method === 'get') {
      return this.get(path, data, headers);
    }

    const config:HTTPClientOptions = {
      body: data || {},
      headers,
      withCredentials: true,
      responseType: 'json',
    };

    return this._request(method, path, config);
  }

  /**
   * Perform the request with httpClient and deserialize the result
   *
   * @param method Request method
   * @param path Request path
   * @param config HTTP client configuration
   *
   * @private
   */
  private _request(method:HTTPSupportedMethods, path:string, config:HTTPClientOptions):Observable<T> {
    return this
      .http
      .request<T>(method, path, config)
      .pipe(
        map((response:any) => this.deserialize(response)),
        catchError((error:HttpErrorResponse) => {
          console.error(`Failed to ${method} ${path}: ${error.name}`);
          return throwError(error);
        }),
      );
  }

  /**
   * Deserialize the JSON data into the mapped resource class, if given.
   * @param data JSON API response.
   */
  protected deserialize(data:any):T {
    if (this.resourceClass) {
      const serializer = new TypedJSON(this.resourceClass);
      return serializer.parse(data)!;
    }
    return data;
  }
}
