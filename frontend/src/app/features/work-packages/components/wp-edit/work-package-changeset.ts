import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackageSchemaProxy } from 'core-app/features/hal/schemas/work-package-schema-proxy';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

export class WorkPackageChangeset extends ResourceChangeset<WorkPackageResource> {
  public setValue(key:string, val:any) {
    super.setValue(key, val);

    if (key === 'project' || key === 'type') {
      this.updateForm();
    }

    // Emit event to notify Stimulus controller in activities tab in order to update the activities list
    // TODO: emit event when change is persisted
    // currently the event might be fired too early as it only reflects the client side change
    document.dispatchEvent(
      new CustomEvent('work-package-updated'),
    );
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
    if (key === 'description' && isNewResource(this.pristineResource)) {
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
    }
    return super.schema;
  }
}
