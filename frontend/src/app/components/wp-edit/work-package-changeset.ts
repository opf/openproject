/**
 * Temporary class living while a work package is being edited
 * Maintains references to:
 *  - The source work package (a pristine base)
 *  - The open set of changes (a changeset object)
 *  - The current form (due to temporary type/project changes)
 *
 * Provides access to:
 *  - A projected work package resource with all changes applied
 */
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {debugLog} from "core-app/helpers/debug_output";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {InputState} from "reactivestates";
import {ResourceChangeset} from "core-app/modules/fields/changeset/resource-changeset";

export class WorkPackageChangeset extends ResourceChangeset<WorkPackageResource> {

  /** Reference and load promise for the current form */
  private wpFormPromise:Promise<FormResource>|null;

  /** Flag whether this is currently being saved */
  public inFlight = false;

  constructor(public pristineResource:WorkPackageResource,
              public readonly state?:InputState<WorkPackageChangeset>,
              form?:FormResource) {
    super(pristineResource, form);
  }

  /**
   * Push the change to the editing state to notify others.
   * This will happen internally on work-package wide changes
   *
   * (type, project changes)
   */
  public push() {
    if (this.state) {
      this.state.putValue(this);
    }
  }

  /**
   * Retrieve the editing value for the given attribute
   *
   * @param {string} key The attribute to read
   * @return {any} Either the value from the overriden change, or the default value
   */
  public value(key:string) {
    // Overridden value by user?
    if (this.changeset.contains(key)) {
      return this.changeset.get(key);
    }

    // TODO we might need values from the form (default values on type change?)
    // Default value from the form?
    // const payloadValue = _.get(this._form, ['payload', key]);
    // if (payloadValue !== undefined) {
    //   return payloadValue;
    // }

    // Return whatever is on the base.
    return this.pristineResource[key];
  }

  public setValue(key:string, val:any) {
    this.changeset.set(key, val);

    // Update the form for fields that may alter the form itself
    // when the work package is new. Otherwise, the save request afterwards
    // will update the form automatically.
    if (this.pristineResource.isNew && (key === 'project' || key === 'type')) {
      this.updateForm().then(() => this.push());
    }
  }

  /**
   * Revert all edits on the resource
   */
  public clear() {
    super.clear();
    this.state && this.state.clear();
  }

  /**
   * Returns the work package being edited
   */
  public get workPackageId():string {
    return this.pristineResource.id!.toString();
  }

  /**
   * Return whether the element is writable
   * given the current best schema.
   *
   * @param key
   */
  public isWritable(key:string) {
    const fieldSchema = this.schema[key] as IFieldSchema|null;
    return fieldSchema && fieldSchema.writable;
  }

  /**
   * Return the best humanized name for this attribute
   * @param attribute
   */
  public humanName(attribute:string):string {
    return _.get(this.schema, `${attribute}.name`, attribute);
  }


  /**
   * Build the request attributes against the fresh form
   */
  public buildRequestPayload():Promise<[FormResource, Object]> {
    return this
      .updateForm()
      .then(form => [form, this.buildPayloadFromChanges()]) as Promise<[FormResource, Object]>;
  }

  /**
   * Returns the current work package form.
   * This may be different from the base form when project or type is changed.
   */
  public getForm():Promise<FormResource> {
    if (!this.form) {
      return this.updateForm();
    } else {
      return Promise.resolve(this.form);
    }
  }

  public getSchemaName(attribute:string):string {
    return this.projectedResource.getSchemaName(attribute);
  }

  /**
   * Update the form resource from the API.
   */
  private updateForm():Promise<FormResource> {
    let payload = this.buildPayloadFromChanges();

    if (!this.wpFormPromise) {
      this.wpFormPromise = this.pristineResource.$links
        .update(payload)
        .then((form:FormResource) => {
          this.wpFormPromise = null;
          this.form = form;
          this.push();
          return form;
        })
        .catch((error:any) => {
          this.wpFormPromise = null;
          this.form = null;
          throw error;
        }) as Promise<FormResource>;
    }

    return this.wpFormPromise;
  }

  /**
   * Create the payload from the current changes, and extend it with the current lock version.
   * -- This is the place to add additional logic when the lockVersion changed in between --
   */
  private buildPayloadFromChanges() {
    let payload;

    if (this.pristineResource.isNew) {
      // If the work package is new, we need to pass the entire form payload
      // to let all default values be transmitted (type, status, etc.)
      if (this.form) {
        payload = this.form.payload.$source;
      } else {
        payload = this.pristineResource.$source;
      }

      // Add attachments to be assigned.
      // They will already be created on the server but now
      // we need to claim them for the newly created work package.
      payload['_links']['attachments'] = this.pristineResource
        .attachments
        .elements
        .map((a:HalResource) => {
          return { href: a.href };
        });


      // Explicitly delete the description if it was not set by the user.
      // if it was set by the user, #applyChanges will set it again.
      // Otherwise, the backend will set it for us.
      delete payload.description;

    } else {
      // Otherwise, simply use the bare minimum, which is the lock version.
      payload = this.minimalPayload;
    }

    return this.applyChanges(payload);
  }

  private get minimalPayload() {
    return { lockVersion: this.pristineResource.lockVersion, _links: {} };
  }

  /**
   * Merge the current changes into the payload resource.
   *
   * @param {plainPayload:unknown} A set of attributes to merge into the payload
   * @return {any}
   */
  private applyChanges(plainPayload:any) {
    // Fall back to the last known state of the work package should the form not be loaded.
    let reference = this.pristineResource.$source;
    if (this.form) {
      reference = this.form.payload.$source;
    }

    _.each(this.changeset.all, (val:unknown, key:string) => {
      const fieldSchema:IFieldSchema|undefined = this.schema[key];
      if (!(typeof (fieldSchema) === 'object' && fieldSchema.writable)) {
        debugLog(`Trying to write ${key} but is not writable in schema`);
        return;
      }

      // Override in _links if it is a linked property
      if (reference._links[key]) {
        plainPayload._links[key] = this.getLinkedValue(val, fieldSchema);
      } else {
        plainPayload[key] = val;
      }
    });

    return plainPayload;
  }

  /**
   * Extract the link(s) in the given changed value
   */
  private getLinkedValue(val:any, fieldSchema:IFieldSchema) {
    // Links should always be nullified as { href: null }, but
    // this wasn't always the case, so ensure null values are returned as such.
    if (_.isNil(val)) {
      return { href: null };
    }

    // Test if we either have a CollectionResource or a HAL array,
    // or a single hal value.
    let isArrayType = (fieldSchema.type || '').startsWith('[]');
    let isArray = false;

    if (val.forEach || val.elements) {
      isArray = true;
    }

    if (isArray && isArrayType) {
      let links:{ href:string }[] = [];

      if (val) {
        let elements = (val.forEach && val) || val.elements;

        elements.forEach((link:{ href:string }) => {
          if (link.href) {
            links.push({ href: link.href });
          }
        });
      }

      return links;
    } else {
      return { href: _.get(val, 'href', null) };
    }
  }

}
