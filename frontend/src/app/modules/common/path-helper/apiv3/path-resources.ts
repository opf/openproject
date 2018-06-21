export class SimpleResourceCollection<T extends SimpleResource = SimpleResource> {
  // Base path
  public readonly path:string;

  constructor(protected basePath:string, segment:string) {
    this.path = `${this.basePath}/${segment}`;
  }

  public id(id:string|number):T {
    return new SimpleResource(this.path, id) as T;
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
}

export class SimpleResource {
  public readonly path:string;

  constructor(protected basePath:string, id:string|number) {
    this.path = `${this.basePath}/${id}`;
  }

  public toString() {
    return this.path;
  }

  public toPath():string {
    return this.path;
  }
}
