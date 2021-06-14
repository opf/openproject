import { BcfResourcePath } from "core-app/modules/bim/bcf/api/bcf-path-resources";
import { BcfApiRequestService } from "core-app/modules/bim/bcf/api/bcf-api-request.service";
import { BcfProjectResource } from "core-app/modules/bim/bcf/api/projects/bcf-project.resource";
import { HTTPClientHeaders, HTTPClientParamMap } from "core-app/modules/hal/http/http.interfaces";
import { BcfTopicCollectionPath } from "core-app/modules/bim/bcf/api/topics/bcf-viewpoint-collection.paths";
import { BcfExtensionPaths } from "core-app/modules/bim/bcf/api/extensions/bcf-extension.paths";

export class BcfProjectPaths extends BcfResourcePath {
  readonly bcfProjectService = new BcfApiRequestService(this.injector, BcfProjectResource);

  /** /topics */
  public readonly topics = new BcfTopicCollectionPath(this.injector, this.path, 'topics');

  public readonly extensions = new BcfExtensionPaths(this.injector, this.path, 'extensions');

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}) {
    return this.bcfProjectService.get(this.toPath(), params, headers);
  }
}