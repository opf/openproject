import { HttpClient, HttpErrorResponse, HttpParams } from "@angular/common/http";
import { Injector } from "@angular/core";
import { TypedJSON } from "typedjson";
import { Constructor } from "@angular/cdk/table";
import { Observable, throwError } from "rxjs";
import {
  HTTPClientHeaders,
  HTTPClientOptions,
  HTTPClientParamMap,
  HTTPSupportedMethods
} from "core-app/modules/hal/http/http.interfaces";
import { URLParamsEncoder } from "core-app/modules/hal/services/url-params-encoder";
import { catchError, map } from "rxjs/operators";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

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
      headers: headers,
      params: new HttpParams({ encoder: new URLParamsEncoder(), fromObject: params }),
      withCredentials: true,
      responseType: 'json'
    };

    return this._request('get', path, config);
  }

  /**
   * Request the given BCF API 2.1 resource and map it to +resourceClass+.
   *
   * @param method request method
   * @param path API path to request
   * @param data Request payload (URL params for get, JSON payload otherwise)
   * @param data Request payload (URL params for get, JSON payload otherwise)
   */
  public request(method:HTTPSupportedMethods, path:string, data:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}):Observable<T> {

    // HttpClient requires us to create HttpParams instead of passing data for get
    // so forward to that method instead.
    if (method === 'get') {
      return this.get(path, data, headers);
    }

    const config:HTTPClientOptions = {
      body: data || {},
      headers: headers,
      withCredentials: true,
      responseType: 'json'
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
        })
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
    } else {
      return data;
    }
  }
}