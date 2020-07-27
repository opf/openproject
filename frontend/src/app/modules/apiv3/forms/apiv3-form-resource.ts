import {APIv3ResourcePath} from "core-app/modules/apiv3/paths/apiv3-resource";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {Observable} from "rxjs";
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {TimeEntryResource} from "core-app/modules/hal/resources/time-entry-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {PayloadDmService} from "core-app/modules/hal/dm-services/payload-dm.service";

export class APIv3FormResource<T extends FormResource = FormResource> extends APIv3ResourcePath<T> {
  @InjectField() private payloadDm:PayloadDmService;

  /**
   * POST to the form resource identified by this path
   * @param request The request payload
   */
  public post(request:Object, schema:SchemaResource|null = null):Observable<T> {
    return this
      .halResourceService
      .post<T>(this.path, this.extractPayload(request, schema));
  }

  /**
   * Extract payload from the given request with schema.
   * This will ensure we will only write writable attributes and so on.
   *
   * @param resource
   * @param schema
   */
  protected extractPayload(resource:HalResource|Object|null, schema:SchemaResource|null = null) {
    if (resource instanceof HalResource && schema) {
      return this.payloadDm.extract(resource, schema);
    } else if (!(resource instanceof HalResource)) {
      return resource;
    } else {
      return {};
    }
  }
}