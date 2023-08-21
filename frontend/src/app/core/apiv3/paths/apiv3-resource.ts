/* eslint-disable max-classes-per-file */

import { Constructor } from '@angular/cdk/table';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';

import {
  SimpleResource,
  SimpleResourceCollection,
} from 'core-app/core/apiv3/paths/path-resources';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { getPaginatedResults } from 'core-app/core/apiv3/helpers/get-paginated-results';
import { addFiltersToPath } from 'core-app/core/apiv3/helpers/add-filters-to-path';

export class ApiV3ResourcePath<T = HalResource> extends SimpleResource {
  readonly injector = this.apiRoot.injector;

  @InjectField() halResourceService:HalResourceService;

  constructor(
    protected apiRoot:ApiV3Service,
    readonly basePath:string,
    readonly id:string|number,
    protected parent?:ApiV3ResourcePath|ApiV3ResourceCollection<T, ApiV3GettableResource<T>>,
  ) {
    super(basePath, id);
  }

  /**
   * Build a singular resource from the current segment
   *
   * @param segment Additional segment to add to the current path
   * @param cls Class to use as return type
   */
  protected subResource<R = ApiV3GettableResource>(
    segment:string,
    // eslint-disable-next-line @typescript-eslint/no-use-before-define
    cls:Constructor<R> = ApiV3GettableResource as unknown as Constructor<R>,
  ):R {
    // eslint-disable-next-line new-cap
    return new cls(this.apiRoot, this.path, segment, this);
  }
}

export class ApiV3GettableResource<T = HalResource> extends ApiV3ResourcePath<T> {
  /**
   * Perform a request to the HalResourceService with the current path
   */
  public get():Observable<T> {
    return this
      .halResourceService
      .get(this.path) as unknown as Observable<T>;
  }
}

export class ApiV3GettableResourceCollection<T = HalResource, V = CollectionResource<T>> extends ApiV3GettableResource<V> {
  /**
   * Perform a request to the HalResourceService with the current path,
   * loading all pages into a single array
   */
  public getPaginatedResults():Observable<T[]> {
    return getPaginatedResults<T>(
      (pageParams) => this.halResourceService.request<CollectionResource<T>>('get', this.path, pageParams),
      -1,
    );
  }
}

export class ApiV3ResourceCollection<V, T extends ApiV3GettableResource<V>> extends SimpleResourceCollection {
  readonly injector = this.apiRoot.injector;

  @InjectField() http:HttpClient;

  @InjectField() halResourceService:HalResourceService;

  constructor(
    protected apiRoot:ApiV3Service,
    protected basePath:string,
    segment:string,
    protected resource?:Constructor<T>,
  ) {
    super(basePath, segment, resource);
  }

  /**
   * Returns an instance of T for the given singular resource ID.
   *
   * @param input Identifier of the resource, may be a string or number, or a HalResource with id property.
   */
  public id(input:string|number|{ id:string|null }):T {
    let id:string;
    if (typeof input === 'string' || typeof input === 'number') {
      id = input.toString();
    } else {
      id = input.id as string;
    }

    return new (this.resource || ApiV3GettableResource)(this.apiRoot, this.path, id, this) as T;
  }

  public withOptionalId(id?:string|number|null):this|T {
    if (_.isNil(id)) {
      return this;
    }
    return this.id(id);
  }

  /**
   * Returns the path string to the requested endpoint.
   */
  public toString():string {
    return this.path;
  }

  /**
   * Returns the path string to the requested endpoint.
   */
  public toPath():string {
    return this.path;
  }

  /**
   * Returns a new resource with the path extended with a URL query
   * to match the filters.
   *
   * @param filters filter object to filter with
   * @param params additional URL params to append
   * @param resourceClass The APIV3 resource class to instantiate
   */
  public filtered<R = ApiV3GettableResourceCollection<V>>(
    filters:ApiV3FilterBuilder,
    params:{ [key:string]:string } = {},
    resourceClass?:Constructor<R>,
  ):R {
    const url = addFiltersToPath(this.path, filters, params);
    const cls = resourceClass || ApiV3GettableResourceCollection;
    // eslint-disable-next-line new-cap
    return new cls(this.apiRoot, url.pathname, url.search, this) as R;
  }

  /**
   * Signal the endpoint with a given set of filters and select params.
   * Returns an observable response.
   *
   * @param filters filter object to filter with
   * @param select The signalling parameters to request
   * @param params additional URL params to append
   */
  public signalled<R>(filters:ApiV3FilterBuilder, select:string[], params:{ [key:string]:string } = {}):Observable<R> {
    const url = addFiltersToPath(this.path, filters, { ...params, select: select.join(',') });

    return this
      .http
      .get<R>(url.toString());
  }

  /**
   * Build a singular resource from the current segment
   *
   * @param segment Additional segment to add to the current path
   * @param cls Class to use as return type
   */
  protected subResource<R = ApiV3GettableResource>(
    segment:string,
    cls:Constructor<R> = ApiV3GettableResource as unknown as Constructor<R>,
  ):R {
    // eslint-disable-next-line new-cap
    return new cls(this.apiRoot, this.path, segment, this);
  }
}
