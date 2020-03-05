import {Injectable} from "@angular/core";
import {OpenprojectBcfModule} from "core-app/modules/bim/bcf/openproject-bcf.module";
import {BcfTopicResource} from "core-app/modules/bim/bcf/api/resources/bcf-topic.resource";
import {Observable} from "rxjs";
import {map} from "rxjs/operators";
import {BcfApiServiceBase} from "core-app/modules/bim/bcf/api/endpoints/bcf-api-service.base";

@Injectable({ providedIn: OpenprojectBcfModule })
export class BcfTopicApiService extends BcfApiServiceBase<BcfTopicResource> {

  resourceClass = BcfTopicResource;

  get(projectIdentifier:string, uuid:string):Observable<BcfTopicResource> {
    return this
      .http
      .get(this.topicPath(projectIdentifier, uuid))
      .pipe(
        map(this.fromJson.bind(this))
      );
  }

  private topicPath(projectIdentifier:string, uuid:string) {
    return this.paths.projects.id(projectIdentifier).topics.id(uuid).toString();
  }
}