import { HTTPClientHeaders, HTTPClientParamMap } from "core-app/modules/hal/http/http.interfaces";
import { BcfResourceCollectionPath, BcfResourcePath } from "core-app/modules/bim/bcf/api/bcf-path-resources";
import { BcfTopicResource } from "core-app/modules/bim/bcf/api/topics/bcf-topic.resource";
import { BcfApiRequestService } from "core-app/modules/bim/bcf/api/bcf-api-request.service";
import { BcfViewpointPaths } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.paths";
import { BcfViewpointCollectionPath } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint-collection.paths";

export class BcfTopicPaths extends BcfResourcePath {
  readonly bcfTopicService = new BcfApiRequestService(this.injector, BcfTopicResource);

  /** /comments */
  public readonly comments = new BcfResourceCollectionPath(this.injector, this.path, 'comments');

  /** /viewpoints */
  public readonly viewpoints = new BcfViewpointCollectionPath(this.injector, this.path, 'viewpoints', BcfViewpointPaths);

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}) {
    return this.bcfTopicService.get(this.toPath(), params, headers);
  }
}