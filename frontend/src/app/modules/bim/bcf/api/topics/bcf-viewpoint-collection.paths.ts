import {BcfResourceCollectionPath} from "core-app/modules/bim/bcf/api/bcf-path-resources";
import {BcfApiRequestService} from "core-app/modules/bim/bcf/api/bcf-api-request.service";
import {HTTPClientHeaders, HTTPClientParamMap} from "core-app/modules/hal/http/http.interfaces";
import {Observable} from "rxjs";
import {BcfTopicPaths} from "core-app/modules/bim/bcf/api/topics/bcf-topic.paths";
import {Injector} from "@angular/core";
import {BcfTopicResource} from "core-app/modules/bim/bcf/api/topics/bcf-topic.resource";

export class BcfTopicCollectionPath extends BcfResourceCollectionPath<BcfTopicPaths> {
  readonly bcfTopicService = new BcfApiRequestService<BcfTopicResource>(this.injector, BcfTopicResource);

  constructor(readonly injector:Injector,
              protected basePath:string,
              segment:string) {
    super(injector, basePath, segment, BcfTopicPaths);
  }

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}) {
    throw new Error("Not implemented");
  }

  /**
   * Create a topic from its to-be-associated work package
   */
  post(payload:any):Observable<BcfTopicResource> {
    return this
      .bcfTopicService
      .request(
        'post',
        this.toPath(),
        payload
      );
  }
}