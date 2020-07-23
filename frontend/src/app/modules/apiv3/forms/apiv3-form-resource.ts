import {APIv3ResourcePath} from "core-app/modules/apiv3/paths/apiv3-resource";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {Observable} from "rxjs";

export class APIv3FormResource extends APIv3ResourcePath<FormResource> {

  /**
   * POST to the form resource identified by this path
   * @param request The request payload
   */
  public post(request:Object):Observable<FormResource> {
    return this
      .halResourceService
      .post<FormResource>(this.path, request);
  }
}