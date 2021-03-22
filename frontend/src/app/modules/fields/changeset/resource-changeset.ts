import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { FormResource } from "core-app/modules/hal/resources/form-resource";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { ChangeItem, ChangeMap, Changeset } from "core-app/modules/fields/changeset/changeset";
import { input, InputState } from "reactivestates";
import { IFieldSchema } from "core-app/modules/fields/field.base";
import { debugLog } from "core-app/helpers/debug_output";
import { take } from "rxjs/operators";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { Injector } from '@angular/core';
import { SchemaProxy } from "core-app/modules/hal/schemas/schema-proxy";

export const PROXY_IDENTIFIER = '__is_changeset_proxy';

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
export class ResourceChangeset<T extends HalResource = HalResource> {
  /** Maintain a single change set while editing */
  protected changeset = new Changeset();

  /** Reference and load promise for the current form */
  protected form$ = input<FormResource>();

  /** Request cache for objects within the changeset for the current form */
  protected cache:{ [key:string]:Promise<unknown> } = {};

  /** Flag whether this is currently being saved */
  public inFlight = false;

  /** Keep a reference to the original resource */
  protected _pristineResource:T;

  /** The projected resource, which will proxy values from the changeset */
  public projectedResource:T;

  /** The cache to all the schemas. Used to maintain the schema of the projectedResource which does not stem from a form.
   * The schema of the form is kept inside the changeset.
   * */
  protected schemaCache:SchemaCacheService;

  constructor(pristineResource:T,
              public readonly state?:InputState<ResourceChangeset<T>>,
              loadedForm:FormResource|null = null) {
    this.updatePristineResource(pristineResource);

    this.schemaCache = (pristineResource.injector as Injector).get(SchemaCacheService);

    if (loadedForm) {
      this.form$.putValue(loadedForm);
    }
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
  public buildRequestPayload():Promise<Object> {
    return this
      .getForm()
      .then(() => this.buildPayloadFromChanges());
  }

  /**
   * Update the pristine resource in case it changed
   *
   * @param attribute
   */
  public updatePristineResource(resource:T) {
    // Ensure we're not passing in a proxy
    if ((resource as any)[PROXY_IDENTIFIER]) {
      throw "You're trying to pass proxy object as a pristine resource. This will cause errors";
    }

    this._pristineResource = resource;
    this.projectedResource = new Proxy(
      this._pristineResource,
      {
        get: (_, key:string) => this.proxyGet(key),
        set: (_, key:string, val:any) => {
          this.setValue(key, val);
          return true;
        },
      }
    );
  }

  public get pristineResource():T {
    return this._pristineResource;
  }

  /**
   * Returns the cached form or loads it if necessary.
   */
  public getForm():Promise<FormResource> {
    if (this.form$.isPristine() && !this.form$.hasActivePromiseRequest()) {
      return this.updateForm();
    }

    return this
      .form$
      .values$()
      .pipe(take(1))
      .toPromise();
  }

  /**
   * Cache some promised value in the course of this changeset.
   * Will get cleared automatically by the changeset on destroy/submission
   */

  /**
   * Posts to the form with the current changes
   * to get the up to date projected object.
   */
  protected updateForm():Promise<FormResource> {
    const payload = this.buildPayloadFromChanges();

    const promise = this.pristineResource
      .$links
      .update(payload)
      .then((form:FormResource) => {
        this.cache = {};
        this.form$.putValue(form);
        this.setNewDefaults(form);
        this.push();
        return form;
      });

    this.form$.putFromPromiseIfPristine(() => promise);
    return promise;
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
    return this.pristineResource.id!.toString();
  }

  /**
   * Return the HAL href of the resource we're editing
   */
  public get href():string {
    return this.pristineResource.href as string;
  }

  /**
   * Returns the changed `to` values of the ChangeMap
   */
  public get changes():{ [key:string]:unknown } {
    const changes:{ [key:string]:unknown } = {};

    _.each(this.changeset.all, (item, key) => {
      changes[key] = item.to;
    });

    return changes;
  }

  /**
   * Returns the change map with from and to values
   */
  public get changeMap():ChangeMap {
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
  public isWritable(key:string):boolean {
    const fieldSchema = this.schema.ofProperty(key) as IFieldSchema|null;
    return !!(fieldSchema && fieldSchema.writable);
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
   * @param key
   */
  private proxyGet(key:string) {
    if (key === '__is_proxy') {
      return true;
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
      return this.changeset.getValue(key);
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

  /**
   * Change the value of the projected resource to some value
   *
   * @param key
   * @param val
   */
  public setValue(key:string, val:any) {
    this.changeset.set(key, val, this.pristineResource[key]);
  }

  /**
   * Clear the changed value of the projected resource
   *
   * @param keys A set of keys to reset
   */
  public clearValue(...keys:string[]) {
    this.changeset.reset(...keys);
  }

  public clear() {
    this.state && this.state.clear();
    this.changeset.clear();
    this.cache = {};
    this.form$.clear();
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
    if (this.form$.hasValue()) {
      return SchemaProxy.create(this.form$.value!.schema, this.projectedResource);
    } else {
      return this.schemaCache.of(this.pristineResource);
    }
  }

  /**
   * Access some promised value
   * that should be cached for the lifetime duration of the form.
   */
  public cacheValue<T>(key:string, request:() => Promise<T>):Promise<T> {
    if (this.cache[key]) {
      return this.cache[key] as Promise<T>;
    }

    return this.cache[key] = request();
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
    if (this.form$.value) {
      reference = this.form$.value.payload.$source;
    }

    _.each(this.changeset.all, (val:ChangeItem, key:string) => {
      if (!this.schema.isAttributeEditable(key)) {
        debugLog(`Trying to write ${key} but is not writable in schema`);
        return;
      }

      const fieldSchema:IFieldSchema|null = this.schema.ofProperty(key);
      // Override in _links if it is a linked property
      if (fieldSchema && reference._links[key]) {
        plainPayload._links[key] = this.getLinkedValue(val.to, fieldSchema);
      } else {
        plainPayload[key] = val.to;
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
      // We clone the object to avoid later manipulations to affect the original resource.
      if (this.form$.value) {
        payload = _.cloneDeep(this.form$.value.payload.$source);
      } else {
        payload = _.cloneDeep(this.pristineResource.$source);
      }

      // Add attachments to be assigned.
      // They will already be created on the server but now
      // we need to claim them for the newly created work package.
      if (this.pristineResource.attachments) {
        payload['_links']['attachments'] = this.pristineResource
          .attachments
          .elements
          .map((a:HalResource) => {
            return { href: a.href };
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
    const isArrayType = (fieldSchema.type || '').startsWith('[]');
    let isArray = false;

    if (val.forEach || val.elements) {
      isArray = true;
    }

    if (isArray && isArrayType) {
      const links:{ href:string }[] = [];

      if (val) {
        const elements = (val.forEach && val) || val.elements;

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
      const fieldSchema:IFieldSchema|null = this.schema.ofProperty(key);
      if (!fieldSchema?.writable) {
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
