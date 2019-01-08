// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {debugLog} from '../../helpers/debug_output';
import {SchemaCacheService} from '../schemas/schema-cache.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {Injector} from '@angular/core';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {FormResource} from 'core-app/modules/hal/resources/form-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {WorkPackagesActivityService} from 'core-components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {
  IWorkPackageCreateService,
  IWorkPackageCreateServiceToken
} from "core-components/wp-new/wp-create.service.interface";
import {
  IWorkPackageEditingService,
  IWorkPackageEditingServiceToken
} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {IFieldSchema} from "core-app/modules/fields/field.base";
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';

export class WorkPackageChangeset {
  // Injections
  public wpNotificationsService:WorkPackageNotificationService = this.injector.get(WorkPackageNotificationService);
  public schemaCacheService:SchemaCacheService = this.injector.get(SchemaCacheService);
  public wpCacheService:WorkPackageCacheService = this.injector.get(WorkPackageCacheService);
  public wpCreate:IWorkPackageCreateService = this.injector.get(IWorkPackageCreateServiceToken);
  public wpEditing:IWorkPackageEditingService = this.injector.get(IWorkPackageEditingServiceToken);
  public wpActivity:WorkPackagesActivityService = this.injector.get(WorkPackagesActivityService);
  public halResourceService:HalResourceService = this.injector.get(HalResourceService);

  // The changeset to be applied to the work package
  private changes:{ [attribute:string]:any } = {};
  public inFlight:boolean = false;

  private wpFormPromise:Promise<FormResource>|null;
  public form:FormResource|null;

  // The current editing resource
  public resource:WorkPackageResource|null;

  constructor(readonly injector:Injector,
              public workPackage:WorkPackageResource,
              form?:FormResource) {
    this.form = form || null;
  }

  public reset(key:string) {
    delete this.changes[key];
    this.buildResource();
  }

  public clear() {
    this.changes = {};
    this.resetForm();
  }

  public resetForm() {
    this.form = null;
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
      return this.workPackage[key];
    }
  }

  public setValue(key:string, val:any) {
    this.changes[key] = val;

    // Update the form for fields that may alter the form itself
    // when the work package is new. Otherwise, the save request afterwards
    // will update the form automatically.
    if (this.workPackage.isNew && (key === 'project' || key === 'type')) {
      this.updateForm();
    }
  }

  /**
   * Return whether a change value exist for the given attribute key.
   * @param {string} key
   * @return {boolean}
   */
  public isOverridden(key:string) {
    return this.changes.hasOwnProperty(key);
  }

  public getForm():Promise<FormResource> {
    if (!this.form) {
      return this.updateForm();
    } else {
      return Promise.resolve(this.form);
    }
  }

  /**
   * Update the form resource from the API.
   */
  public updateForm():Promise<FormResource> {
    let payload = this.buildPayloadFromChanges();

    if (!this.wpFormPromise) {
      this.wpFormPromise = this.workPackage.$links
        .update(payload)
        .then((form:FormResource) => {
          this.form = form;

          this.buildResource();

          this.wpFormPromise = null;
          return form;
        })
        .catch((error:any) => {
          this.resetForm();

          this.wpFormPromise = null;
          throw error;
        });
    }

    return this.wpFormPromise;
  }

  public save():Promise<WorkPackageResource> {
    this.inFlight = true;
    const wasNew = this.workPackage.isNew;

    let promise = new Promise<WorkPackageResource>((resolve, reject) => {
      this.updateForm()
        .then((form) => {
          const payload = this.buildPayloadFromChanges();

          // Reject errors when occurring in form validation
          const errors = form.getErrors();
          if (errors !== null) {
            return reject(errors);
          }

          this.workPackage.$links.updateImmediately(payload)
            .then((savedWp:WorkPackageResource) => {
              // Ensure the schema is loaded before updating
              this.schemaCacheService.ensureLoaded(savedWp).then(() => {

                // Initialize any potentially new HAL values
                savedWp.retainFrom(this.workPackage);
                this.workPackage = savedWp;

                if (wasNew) {
                  this.workPackage.overriddenSchema = undefined;
                  this.wpCreate.newWorkPackageCreated(this.workPackage);
                }

                this.wpActivity.clear(this.workPackage.id);

                // If there is a parent, its view has to be updated as well
                if (this.workPackage.parent) {
                  this.wpCacheService.loadWorkPackage(this.workPackage.parent.id.toString(), true);
                }
                this.wpCacheService.updateWorkPackage(this.workPackage);
                this.resource = null;
                this.clear();
                resolve(this.workPackage);
              });
            })
            .catch(error => {
              // Update the resource anyway
              this.buildResource();
              reject(error);
            })
            .catch(reject);
        });
    });

    promise
      .then(() => this.inFlight = false)
      .catch(() => this.inFlight = false);

    return promise;
  }

  /**
   * Merge the current changes into the payload resource.
   *
   * @param {FormResource} form
   * @return {any}
   */
  private mergeWithPayload(plainPayload:any) {
    // Fall back to the last known state of the work package should the form not be loaded.
    let reference = this.workPackage.$source;
    if (this.form) {
      reference = this.form.payload.$source;
    }

    _.each(this.changes, (val:any, key:string) => {
      const fieldSchema = this.schema[key];
      if (!(typeof(fieldSchema) === 'object' && fieldSchema.writable === true)) {
        debugLog(`Trying to write ${key} but is not writable in schema`);
        return;
      }

      // Override in _links if it is a linked property
      if (reference._links[key]) {
        plainPayload._links[key] = this.getLinkedValue(val, fieldSchema);
      } else {
        plainPayload[key] = this.changes[key];
      }
    });

    return plainPayload;
  }

  /**
   * Create the payload from the current changes, and extend it with the current lock version.
   * -- This is the place to add additional logic when the lockVersion changed in between --
   */
  private buildPayloadFromChanges() {
    let payload;

    if (this.workPackage.isNew) {
      // If the work package is new, we need to pass the entire form payload
      // to let all default values be transmitted (type, status, etc.)
      if (this.form) {
        payload = this.form.payload.$source;
      } else {
        payload = this.workPackage.$source;
      }

      // Add attachments to be assigned.
      // They will already be created on the server but now
      // we need to claim them for the newly created work package.
      payload['_links']['attachments'] = this.workPackage
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
    return {lockVersion: this.workPackage.lockVersion, _links: {}};
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
      var links:{ href:string }[] = [];

      if (val) {
        var elements = (val.forEach && val) || val.elements;

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

  /**
   * Get the best schema currently available, either the default WP schema (must exist).
   * If loaded, return the form schema, which provides better information on writable status
   * and contains available values.
   */
  public get schema():SchemaResource {
    return (this.form || this.workPackage).schema;
  }

  public getSchemaName(attribute:string):string {
    if (this.schema.hasOwnProperty('date') && (attribute === 'startDate' || attribute === 'dueDate')) {
      return 'date';
    } else {
      return attribute;
    }
  }

  private buildResource() {
    if (this.empty) {
      this.resource = null;
      this.wpEditing.updateValue(this.workPackage.id, this);
      return;
    }

    let payload:any = this.workPackage.$source;

    const resource = this.halResourceService.createHalResourceOfType('WorkPackage', this.mergeWithPayload(payload));

    resource.overriddenSchema = this.schema;
    this.resource = (resource as WorkPackageResource);
    this.wpEditing.updateValue(this.workPackage.id, this);
  }
}
