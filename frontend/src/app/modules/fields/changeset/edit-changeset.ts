import {SchemaResource} from "core-app/modules/hal/resources/schema-resource";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Injector} from '@angular/core';

export abstract class EditChangeset<T extends HalResource|{ [key:string]:unknown; }> {
  // The changeset to be applied to the resource
  public changes:{ [attribute:string]:any } = {};

  public form:FormResource|null;

  constructor(readonly injector:Injector,
              public resource:T,
              form?:FormResource) {
    this.form = form || null;
  }

  public get empty() {
    return _.isEmpty(this.changes);
  }

  /**
   * Get attributes
   * @returns {string[]}
   */
  public get changedAttributes() {
    return _.keys(this.changes);
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
      return this.resource[key];
    }
  }

  public setValue(key:string, val:any) {
    this.changes[key] = val;
  }

  public getSchemaName(attribute:string):string {
    return attribute;
  }

  public clear() {
   this.changes = {};
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
    return (this.form || this.resource).schema;
  }
}
