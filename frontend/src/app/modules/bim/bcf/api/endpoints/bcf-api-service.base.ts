import {BcfApiPathsService} from "core-app/modules/bim/bcf/api/paths/bcf-api-paths.service";
import {HttpClient} from "@angular/common/http";
import {Injectable, Injector} from "@angular/core";
import {OpenprojectBcfModule} from "core-app/modules/bim/bcf/openproject-bcf.module";
import {BcfTopicResource} from "core-app/modules/bim/bcf/api/resources/bcf-topic.resource";
import {Observable} from "rxjs";
import {TypedJSON} from "typedjson";
import {map} from "rxjs/operators";
import {Constructor} from "@angular/cdk/table";

export abstract class BcfApiServiceBase<T> {

  /** Mapped resource class to parse JSON response */
  protected abstract resourceClass:Constructor<T>;

  constructor(protected injector:Injector,
              protected paths:BcfApiPathsService,
              protected http:HttpClient) {
  }

  protected fromJson(data:any):T {
    const serializer = new TypedJSON(this.resourceClass);
    return serializer.parse(data)!;
  }
}