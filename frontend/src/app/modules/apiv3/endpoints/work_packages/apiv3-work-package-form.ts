import {APIv3FormResource} from "core-app/modules/apiv3/forms/apiv3-form-resource";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {Observable} from "rxjs";

export class APIv3WorkPackageForm extends APIv3FormResource {
  /**
   * Returns a promise to post `/api/v3/work_packages/form` where the
   * type has already been set to the one provided.
   *
   * @param typeId: The id of the type to initialize the form with
   * @returns An empty work package form resource.
   */
  public forType(typeId:number):Observable<FormResource> {

    const typeUrl = this.apiRoot.types.id(typeId).path;
    const request = { _links: { type: { href: typeUrl } } };

    return this.post(request);
  }
}

