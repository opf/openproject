import { Constructor } from '@angular/cdk/table';
import { SimpleResource, SimpleResourceCollection } from 'core-app/core/apiv3/paths/path-resources';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { Observable } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

export class ApiV3ResourcePath<T = HalResource> extends SimpleResource {
  readonly injector = this.apiRoot.injector;

  @InjectField() halResourceService:HalResourceService;

  constructor(protected apiRoot:ApiV3Service,
    readonly basePath:string,
    readonly id:string|number,
    protected parent?:ApiV3ResourcePath|ApiV3ResourceCollection<any, any>) {
    super(basePath, id);
  }

  /**
   * Build a singular resource from the current segment
   *
   * @param segment Additional segment to add to the current path
   */
  protected subResource<R = ApiV3GettableResource>(segment:string, cls:Constructor<R> = ApiV3GettableResource as any):R {
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
      .get(this.path) as any;
  }
}

export class ApiV3ResourceCollection<V, T extends ApiV3GettableResource<V>> extends SimpleResourceCollection {
  readonly injector = this.apiRoot.injector;

  @InjectField() halResourceService:HalResourceService;

  constructor(protected apiRoot:ApiV3Service,
    protected basePath:string,
    segment:string,
    protected resource?:Constructor<T>) {
    super(basePath, segment, resource);
  }

  /**
   * Returns an instance of T for the given singular resource ID.
   *
   * @param id Identifier of the resource, may be a string or number, or a HalResource with id property.
   */
  public id(input:string|number|{ id:string|null }):T {
    let id:string;
    if (typeof input === 'string' || typeof input === 'number') {
      id = input.toString();
    } else {
      id = input.id!;
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
   */
  public filtered<R = ApiV3GettableResource<CollectionResource<V>>>(filters:ApiV3FilterBuilder, params:{ [key:string]:string } = {}, resourceClass?:Constructor<R>):R {
    return this.subResource<R>(`?${filters.toParams(params)}`, resourceClass);
  }

  /**
   * Build a singular resource from the current segment
   *
   * @param segment Additional segment to add to the current path
   */
  protected subResource<R = ApiV3GettableResource<HalResource>>(segment:string, cls:Constructor<R> = ApiV3GettableResource as any):R {
    return new cls(this.apiRoot, this.path, segment, this);
  }
}
