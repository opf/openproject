import {Injector} from "@angular/core";
import {Constructor} from "@angular/cdk/table";
import {SimpleResource, SimpleResourceCollection} from "core-app/modules/apiv3/paths/path-resources";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Observable} from "rxjs";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";

export class APIv3ResourcePath<T extends HalResource = HalResource> extends SimpleResource {
  @InjectField() halResourceService:HalResourceService;

  constructor(readonly injector:Injector,
              readonly basePath:string,
              readonly id:string|number,
              protected parent?:APIv3ResourcePath|APIv3ResourceCollection<any, any>) {
    super(basePath, id);
  }

  /**
   * Perform a request to the HalResourceService with the current path
   */
  public get():Observable<T> {
    return this
      .halResourceService
      .get<T>(this.path);
  }

  /**
   * Build a singular resource from the current segment
   *
   * @param segment Additional segment to add to the current path
   */
  protected subResource<V extends HalResource = HalResource>(segment:string):APIv3ResourcePath<V> {
    return new APIv3ResourcePath<V>(this.injector, this.path, segment, this);
  }
}

export class APIv3ResourceCollection<V extends HalResource, T extends APIv3ResourcePath<V>> extends SimpleResourceCollection {
  @InjectField() halResourceService:HalResourceService;

  constructor(readonly injector:Injector,
              protected basePath:string,
              segment:string,
              protected resource?:Constructor<T>) {
    super(basePath, segment);
  }

  /**
   * Returns an instance of T for the given singular resource ID.
   *
   * @param id
   */
  public id(id:string|number):T {
    return new (this.resource || APIv3ResourcePath)(this.injector, this.path, id, this) as T;
  }


  public withOptionalId(id?:string|number):this|T {
    if (_.isNil(id)) {
      return this;
    } else {
      return this.id(id);
    }
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
   */
  public filtered<R extends HalResource = V>(filters:ApiV3FilterBuilder):APIv3ResourcePath<R> {
    return this.subResource<R>('/?' + filters.toParams());
  }

  /**
   * Build a singular resource from the current segment
   *
   * @param segment Additional segment to add to the current path
   */
  protected subResource<R extends HalResource = V>(segment:string):APIv3ResourcePath<R> {
    return new APIv3ResourcePath<R>(this.injector, this.path, segment);
  }
}