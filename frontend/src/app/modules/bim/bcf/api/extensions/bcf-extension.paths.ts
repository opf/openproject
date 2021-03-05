import { BcfResourcePath } from "core-app/modules/bim/bcf/api/bcf-path-resources";
import { BcfApiRequestService } from "core-app/modules/bim/bcf/api/bcf-api-request.service";
import { HTTPClientHeaders, HTTPClientParamMap } from "core-app/modules/hal/http/http.interfaces";
import { BcfExtensionResource } from "core-app/modules/bim/bcf/api/extensions/bcf-extension.resource";

export class BcfExtensionPaths extends BcfResourcePath {
  readonly bcfExtensionService = new BcfApiRequestService(this.injector, BcfExtensionResource);

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}) {
    return this.bcfExtensionService.get(this.toPath(), params, headers);
  }
}
