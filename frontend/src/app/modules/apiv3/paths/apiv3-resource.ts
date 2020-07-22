import {Injector} from "@angular/core";
import {Constructor} from "@angular/cdk/table";
import {SimpleResource, SimpleResourceCollection} from "core-app/modules/apiv3/paths/path-resources";

export class APIv3ResourcePath extends SimpleResource {
  constructor(readonly injector:Injector,
              basePath:string,
              id:string|number) {
    super(basePath, id);
  }

  protected subResource(segment:string) {
    return new APIv3ResourcePath(this.injector, this.path, segment);
  }

  protected subCollection(segment:string, resource?:Constructor<APIv3ResourcePath>) {
    return new APIv3ResourceCollection(this.injector, this.path, segment, resource);
  }
}

export class APIv3ResourceCollection<T extends APIv3ResourcePath> extends SimpleResourceCollection<T> {
  constructor(readonly injector:Injector,
              protected basePath:string,
              segment:string,
              protected resource?:Constructor<T>) {
    super(basePath, segment, resource);
  }

  public id(id:string|number):T {
    return new (this.resource || APIv3ResourcePath)(this.injector, this.path, id) as T;
  }

  protected subResource(segment:string) {
    return new APIv3ResourcePath(this.injector, this.path, segment);
  }

  protected subCollection(segment:string, resource?:Constructor<APIv3ResourcePath>) {
    return new APIv3ResourceCollection(this.injector, this.path, segment, resource);
  }
}