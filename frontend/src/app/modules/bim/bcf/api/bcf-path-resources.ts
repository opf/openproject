import { Injector } from "@angular/core";
import { Constructor } from "@angular/cdk/table";
import { SimpleResource, SimpleResourceCollection } from "core-app/modules/apiv3/paths/path-resources";

export class BcfResourcePath extends SimpleResource {
  constructor(readonly injector:Injector,
    basePath:string,
              readonly id:string|number) {
    super(basePath, id);
  }
}

export class BcfResourceCollectionPath<T extends BcfResourcePath> extends SimpleResourceCollection<T> {
  constructor(readonly injector:Injector,
              protected basePath:string,
              segment:string,
              protected resource?:Constructor<T>) {
    super(basePath, segment, resource);
  }

  public id(id:string|number):T {
    return new (this.resource || BcfResourcePath)(this.injector, this.path, id) as T;
  }

}