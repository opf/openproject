import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { Constructor } from "@angular/cdk/table";

/**
 * Simple resource collection to construct paths for RESTful resources.
 * Base class for APIV3 and BCF API helpers
 */
export class SimpleResourceCollection<T = SimpleResource> {
  // Base path
  public readonly path:string;

  constructor(protected basePath:string, readonly segment:string, protected resource?:Constructor<T>) {
    this.path = `${this.basePath}/${segment}`;
  }

  public id(id:string|number):T {
    return new (this.resource || SimpleResource)(this.path, id) as T;
  }

  /**
   * Returns either the collection itself, or the resource
   * located by the ID when present.
   *
   * TypeScript will reduce available endpoints to anything available
   * in this collection AND the resource.
   *
   * @param id
   */
  public withOptionalId(id?:string|number):this|T {
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
}

/**
 * Singular RESTful resource object identified by a base path and ID
 */
export class SimpleResource {
  public readonly path:string;

  constructor(readonly basePath:string, readonly segment:string|number) {
    const separator = segment.toString().startsWith('?') ? '' : '/';
    this.path = `${this.basePath}${separator}${segment}`;
  }

  public toString() {
    return this.path;
  }

  public toPath():string {
    return this.path;
  }
}
