import { BcfResourceCollectionPath } from "core-app/modules/bim/bcf/api/bcf-path-resources";
import { BcfApiRequestService } from "core-app/modules/bim/bcf/api/bcf-api-request.service";
import { BcfViewpointInterface } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.interface";
import { HTTPClientHeaders, HTTPClientParamMap } from "core-app/modules/hal/http/http.interfaces";
import { Observable } from "rxjs";
import { BcfViewpointPaths } from "core-app/modules/bim/bcf/api/viewpoints/bcf-viewpoint.paths";

export class BcfViewpointCollectionPath extends BcfResourceCollectionPath<BcfViewpointPaths> {
  readonly bcfTopicService = new BcfApiRequestService<BcfViewpointInterface>(this.injector);

  get(params:HTTPClientParamMap = {}, headers:HTTPClientHeaders = {}) {
    throw new Error("Not implemented");
  }

  post(viewpoint:BcfViewpointInterface):Observable<BcfViewpointInterface> {
    return this
      .bcfTopicService
      .request(
        'post',
        this.toPath(),
        viewpoint
      );
  }
}