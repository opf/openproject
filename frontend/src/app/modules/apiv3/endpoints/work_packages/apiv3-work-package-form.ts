import { APIv3FormResource } from "core-app/modules/apiv3/forms/apiv3-form-resource";
import { FormResource } from "core-app/modules/hal/resources/form-resource";
import { Observable } from "rxjs";
import { HalSource } from "core-app/modules/hal/resources/hal-resource";

export class APIv3WorkPackageForm extends APIv3FormResource {
  /**
   * Returns a promise to post `/api/v3/work_packages/form` with only the type part of the
   * provided payload being sent to the backend.
   *
   * @param payload: The payload to be sent to the backend
   * @returns A work package form resource prefilled with the provided payload.
   */
  public forTypePayload(payload:HalSource):Observable<FormResource> {
    const typePayload = payload._links['type'] ? { _links: { type: payload['_links']['type'] } } : { _links: {} } ;

    return this.post(payload);
  }
  /**
   * Returns a promise to post `/api/v3/work_packages/form` where the
   * payload sent to the backend has been provided.
   *
   * @param payload: The payload to be sent to the backend
   * @returns A work package form resource prefilled with the provided payload.
   */
  public forPayload(payload:HalSource):Observable<FormResource> {
    return this.post(payload);
  }
}

