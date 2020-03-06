import {BcfResourceCollectionPath, BcfResourcePath} from "core-app/modules/bim/bcf/api/bcf-path-resources";
import {BcfTopicPaths} from "core-app/modules/bim/bcf/api/topics/bcf-topic.paths";
import {BcfApiRequestService} from "core-app/modules/bim/bcf/api/bcf-api-request.service";
import {BcfProjectResource} from "core-app/modules/bim/bcf/api/projects/bcf-project.resource";
import {HTTPClientHeaders, HTTPClientParamMap} from "core-app/modules/hal/http/http.interfaces";

export class BcfProjectPaths extends BcfResourcePath {
  readonly bcfProjectService = new BcfApiRequestService(this.injector, BcfProjectResource);

  /** /topics */
  public readonly topics = new BcfResourceCollectionPath(this.injector, this.path, 'topics', BcfTopicPaths);

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}) {
    return this.bcfProjectService.get(this.toPath(), params, headers);
  }
}