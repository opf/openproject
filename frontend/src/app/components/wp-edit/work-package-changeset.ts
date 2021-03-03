import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { ResourceChangeset } from "core-app/modules/fields/changeset/resource-changeset";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { WorkPackageSchemaProxy } from 'core-app/modules/hal/schemas/work-package-schema-proxy';

export class WorkPackageChangeset extends ResourceChangeset<WorkPackageResource> {

  public setValue(key:string, val:any) {
    super.setValue(key, val);

    if (key === 'project' || key === 'type') {
      this.updateForm();
    }
  }

  protected applyChanges(payload:any):any {
    // Explicitly delete the description if it was not set by the user.
    // if it was set by the user, #applyChanges will set it again.
    // Otherwise, the backend will set it for us.
    delete payload.description;

    return super.applyChanges(payload);
  }

  protected setNewDefaultFor(key:string, val:unknown) {
    // Special handling for taking over the description
    // to the pristine resource
    if (key === 'description' && this.pristineResource.isNew) {
      this.pristineResource.description = val;
      return;
    }

    super.setNewDefaultFor(key, val);
  }

  /**
   * Get the best schema currently available, either the default resource schema (must exist).
   * If loaded, return the form schema, which provides better information on writable status
   * and contains available values.
   */
  public get schema():SchemaResource {
    if (this.form$.hasValue()) {
      return WorkPackageSchemaProxy.create(super.schema, this.projectedResource);
    } else {
      return super.schema;
    }
  }
}
