import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {ChangeMap, Changeset} from "core-app/modules/fields/changeset/changeset";
import {InputState} from "reactivestates";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {debugLog} from "core-app/helpers/debug_output";

/**
 * Temporary class living while a resource is being edited
 * Maintains references to:
 *  - The source resource (a pristine base)
 *  - The open set of changes (a changeset object)
 *  - The current form (due to temporary type/project changes)
 *
 * Provides access to:
 *  - The projected resource with all changes applied as properties
 */
export class ResourceChangeset<T extends HalResource|{ [key:string]:unknown; } = HalResource> {
  /** Maintain a single change set while editing */
  protected changeset = new Changeset();

  /** Reference and load promise for the current form */
  private formPromise:Promise<FormResource>|null;

  /** Flag whether this is currently being saved */
  public inFlight = false;

  /** The projected resource, which will proxy values from the change set */
  public projectedResource:T = new Proxy(
    this.pristineResource,
    {
      get: (_, key:string) => this.proxyGet(key),
      set: (_, key:string, val:any) => {
        this.setValue(key, val);
        return true;
      },
    }
  );

  constructor(public pristineResource:T,
              public readonly state?:InputState<ResourceChangeset<T>>,
              public form:FormResource|null = null) {
  }

  /**
   * Push the change to the editing state to notify others.
   * This will happen internally on resource wide changes
   */
  public push() {
    if (this.state) {
      this.state.putValue(this);
    }
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
    if (this.projectedResource.getSchemaName) {
      return this.projectedResource.getSchemaName(attribute);
    } else {
      return attribute;
    }
  }

  /**
   * Update the form resource from the API.
   */
  protected updateForm():Promise<FormResource> {
    let payload = this.buildPayloadFromChanges();

    if (!this.formPromise) {
      this.formPromise = this.pristineResource.$links
        .update(payload)
        .then((form:FormResource) => {
          this.formPromise = null;
          this.form = form;
          this.setNewDefaults(form);
          this.push();
          return form;
        })
        .catch((error:any) => {
          this.formPromise = null;
          this.form = null;
          throw error;
        }) as Promise<FormResource>;
    }

    return this.formPromise;
  }

  /**
   * Return whether no changes were made to the work package
   */
  public isEmpty() {
    return this.changeset.changed.length === 0;
  }

  /**
   * Return the ID of the resource we're editing
   */
  public get id():string {
    return this.pristineResource.id as string;
  }

  /**
   * Return the HAL href of the resource we're editing
   */
  public get href():string {
    return this.pristineResource.href as string;
  }

  /**
   * Return a shallow copy of the changes
   */
  public get changes():ChangeMap {
    return { ...this.changeset.all };
  }

  /**
   * Return the changed attributes in this change;
   */
  public get changedAttributes():string[] {
    return this.changeset.changed;
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
   * Returns whether the given attribute was changed
   */
  public contains(key:string) {
    return this.changeset.contains(key);
  }

  /**
   * Proxy getters to base or changeset.
   * Special case for schema , which is overridden.
   * @param key
   */
  private proxyGet(key:string) {
    if (key === 'schema') {
      return this.schema;
    }

    return this.value(key);
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

    // Return whatever is on the base.
    return this.pristineResource[key];
  }

  /**
   * Return whether the given value exists,
   * even if its undefined.
   *
   * @param key
   */
  public valueExists(key:string):boolean {
    return this.changeset.contains(key) || this.pristineResource.hasOwnProperty(key);
  }

  public setValue(key:string, val:any) {
    this.changeset.set(key, val);
  }

  public clear() {
   this.state && this.state.clear();
   this.changeset.clear();
   this.form = null;
  }

  /**
   * Reset the given changed attribute
   * @param key
   */
  public reset(key:string) {
    this.changeset.reset(key);
  }

  /**
   * Return whether a change value exist for the given attribute key.
   * @param {string} key
   * @return {boolean}
   */
  public isOverridden(key:string) {
    return this.changes.hasOwnProperty(key);
  }

  /**
   * Get the best schema currently available, either the default resource schema (must exist).
   * If loaded, return the form schema, which provides better information on writable status
   * and contains available values.
   */
  public get schema():SchemaResource {
    return (this.form || this.pristineResource).schema;
  }

  protected get minimalPayload() {
    return { lockVersion: this.pristineResource.lockVersion, _links: {} };
  }

  /**
   * Merge the current changes into the payload resource.
   *
   * @param {plainPayload:unknown} A set of attributes to merge into the payload
   * @return {any}
   */
  protected applyChanges(plainPayload:any) {
    // Fall back to the last known state of the HalResource should the form not be loaded.
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
   * Create the payload from the current changes, and extend it with the current lock version.
   * -- This is the place to add additional logic when the lockVersion changed in between --
   */
  protected buildPayloadFromChanges() {
    let payload;

    if (this.pristineResource.isNew) {
      // If the resource is new, we need to pass the entire form payload
      // to let all default values be transmitted (type, status, etc.)
      if (this.form) {
        payload = this.form.payload.$source;
      } else {
        payload = this.pristineResource.$source;
      }

      // Add attachments to be assigned.
      // They will already be created on the server but now
      // we need to claim them for the newly created work package.
      if (this.pristineResource.attachments) {
        payload['_links']['attachments'] = this.pristineResource
          .attachments
          .elements
          .map((a:HalResource) => {
            return {href: a.href};
          });
      }

    } else {
      // Otherwise, simply use the bare minimum
      payload = this.minimalPayload;
    }

    return this.applyChanges(payload);
  }

  /**
   * Extract the link(s) in the given changed value
   */
  protected getLinkedValue(val:any, fieldSchema:IFieldSchema) {
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

  /**
   * When changing type or project, new custom fields may be present
   * that we need to set.
   */
  protected setNewDefaults(form:FormResource) {
    _.each(form.payload, (val:unknown, key:string) => {
      const fieldSchema:IFieldSchema|undefined = this.schema[key];
      if (!(typeof (fieldSchema) === 'object' && fieldSchema.writable)) {
        return;
      }

      this.setNewDefaultFor(key, val);
    });
  }

  /**
   * Set the default for the given attribute
   */
  protected setNewDefaultFor(key:string, val:unknown) {
    if (!this.valueExists(key)) {
      debugLog("Taking over default value from form for " + key);
      this.setValue(key, val);
    }
  }
}
