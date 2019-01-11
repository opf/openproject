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
import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {debugLog} from "core-app/helpers/debug_output";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {ChangeMap, ChangeSet} from "core-components/wp-edit/changeset";
import {InputState} from "reactivestates";

export class WorkPackageChange {

  /** Reference and load promise for the current form */
  private wpFormPromise:Promise<FormResource>|null;
  private _form:FormResource|null;

  /** Maintain a single change set while editing */
  private changeset = new ChangeSet();

  /** Flag whether this is currently being saved */
  public inFlight = false;

  /** The projected work package, which will proxy values from the change set */
  public projectedWorkPackage = new Proxy(
    this.base,
    {
      get: (_, key:string) => this.proxyGet(key),
      set: (_, key:string, val:any) => {
        this.setValue(key, val);
        return true;
      },
    }
  );

  constructor(public base:WorkPackageResource,
              private readonly state?:InputState<WorkPackageChange>,
              form?:FormResource) {
    this._form = form || null;
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
   * Return whether no changes were made to the work package
   */
  public isEmpty() {
    return this.changeset.changed.length === 0;
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
  private value(key:string) {
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
    return this.base[key];
  }

  private setValue(key:string, val:any) {
    this.changeset.set(key, val);

    // Update the form for fields that may alter the form itself
    // when the work package is new. Otherwise, the save request afterwards
    // will update the form automatically.
    if (this.base.isNew && (key === 'project' || key === 'type')) {
      this.updateForm().then(() => this.push());
    }
  }

  /**
   * Reset the given changed attribute
   * @param key
   */
  public reset(key:string) {
    this.changeset.reset(key);
  }

  /**
   * Revert all edits on the resource
   */
  public clear() {
    this.changeset.reset();
    this.state && this.state.clear();
    this._form = null;
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
   * Returns whether the given attribute was changed
   */
  public contains(key:string) {
    return this.changeset.contains(key);
  }

  /**
   * Returns the work package being edited
   */
  public get workPackageId():string {
    return this.base.id.toString();
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
    if (!this._form) {
      return this.updateForm();
    } else {
      return Promise.resolve(this._form);
    }
  }

  /**
   * Get the best schema currently available, either the default WP schema (must exist).
   * If loaded, return the form schema, which provides better information on writable status
   * and contains available values.
   */
  public get schema():SchemaResource {
    return (this._form || this.base).schema;
  }

  /**
   * Update the form resource from the API.
   */
  private updateForm():Promise<FormResource> {
    let payload = this.buildPayloadFromChanges();

    if (!this.wpFormPromise) {
      this.wpFormPromise = this.base.$links
        .update(payload)
        .then((form:FormResource) => {
          this.wpFormPromise = null;
          return this._form = form;
        })
        .catch((error:any) => {
          this.wpFormPromise = null;
          this._form = null;
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

    if (this.base.isNew) {
      // If the work package is new, we need to pass the entire form payload
      // to let all default values be transmitted (type, status, etc.)
      if (this._form) {
        payload = this._form.payload.$source;
      } else {
        payload = this.base.$source;
      }

      // Add attachments to be assigned.
      // They will already be created on the server but now
      // we need to claim them for the newly created work package.
      payload['_links']['attachments'] = this.base
        .attachments
        .elements
        .map((a:HalResource) => { return { href: a.href }; });
    } else {
      // Otherwise, simply use the bare minimum, which is the lock version.
      payload = this.minimalPayload;
    }

    return this.mergeWithPayload(payload);
  }

  private get minimalPayload() {
    return {lockVersion: this.base.lockVersion, _links: {}};
  }

  /**
   * Merge the current changes into the payload resource.
   *
   * @param {plainPayload:unknown} A set of attributes to merge into the payload
   * @return {any}
   */
  private mergeWithPayload(plainPayload:any) {
    // Fall back to the last known state of the work package should the form not be loaded.
    let reference = this.base.$source;
    if (this._form) {
      reference = this._form.payload.$source;
    }

    _.each(this.changeset.all, (val:unknown, key:string) => {
      const fieldSchema:IFieldSchema|undefined = this.schema[key];
      if (!(typeof(fieldSchema) === 'object' && fieldSchema.writable)) {
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
      return {href: null};
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
            links.push({href: link.href});
          }
        });
      }

      return links;
    } else {
      return {href: _.get(val, 'href', null)};
    }
  }

}
