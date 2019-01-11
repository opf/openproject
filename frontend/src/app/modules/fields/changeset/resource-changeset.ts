import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {ChangeMap, Changeset} from "core-app/modules/fields/changeset/changeset";

export abstract class ResourceChangeset<T extends HalResource|{ [key:string]:unknown; }> {
  /** Maintain a single change set while editing */
  protected changeset = new Changeset();

  /** The projected resource, which will proxy values from the change set */
  public projectedResource = new Proxy(
    this.pristineResource,
    {
      get: (_, key:string) => this.proxyGet(key),
      set: (_, key:string, val:any) => {
        this.setValue(key, val);
        return true;
      },
    }
  );

  public form:FormResource|null;

  constructor(public pristineResource:T, form?:FormResource) {
    this.form = form || null;
  }

  /**
   * Return whether no changes were made to the work package
   */
  public isEmpty() {
    return this.changeset.changed.length === 0;
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
    if (this.isOverridden(key)) {
      return this.changes[key];
    } else {
      return this.pristineResource[key];
    }
  }

  public setValue(key:string, val:any) {
    this.changes[key] = val;
  }

  public getSchemaName(attribute:string):string {
    return attribute;
  }

  public clear() {
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
}
