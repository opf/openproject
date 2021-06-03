import { APIv3ResourcePath } from "core-app/modules/apiv3/paths/apiv3-resource";
import { FormResource } from "core-app/modules/hal/resources/form-resource";
import { Observable } from "rxjs";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { HalPayloadHelper } from "core-app/modules/hal/schemas/hal-payload.helper";

export class APIv3FormResource<T extends FormResource = FormResource> extends APIv3ResourcePath<T> {
  /**
   * POST to the form resource identified by this path
   * @param request The request payload
   */
  public post(request:Object = {}, schema:SchemaResource|null = null):Observable<T> {
    return this
      .halResourceService
      .post<T>(
        this.path,
        this.extractPayload(request, schema)
      );
  }

  /**
   * Extract payload for the form from the request and optional schema.
   *
   * @param request
   * @param schema
   */
  public extractPayload(request:T|Object, schema:SchemaResource|null = null) {
    return HalPayloadHelper.extractPayload(request, schema);
  }
}