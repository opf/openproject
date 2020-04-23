import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {Constructor} from "@angular/cdk/table";

export class SimpleResourceCollection<T = SimpleResource> {
  // Base path
  public readonly path:string;

  constructor(protected basePath:string, readonly segment:string, protected resource?:Constructor<T>) {
    this.path = `${this.basePath}/${segment}`;
  }

  public id(id:string|number):T {
    return new (this.resource || SimpleResource)(this.path, id) as T;
  }

  public optionalId(id?:string|number):this|T {
    if (_.isNil(id)) {
      return this;
    } else {
      return this.id(id);
    }
  }

  public toString():string {
    return this.path;
  }

  public toPath():string {
    return this.path;
  }

  public filtered(filters:ApiV3FilterBuilder) {
    return this.toString() + '/?' + filters.toParams();
  }
}

export class SimpleResource {
  public readonly path:string;

  constructor(protected basePath:string, readonly id:string|number) {
    this.path = `${this.basePath}/${id}`;
  }

  public toString() {
    return this.path;
  }

  public toPath():string {
    return this.path;
  }
}
