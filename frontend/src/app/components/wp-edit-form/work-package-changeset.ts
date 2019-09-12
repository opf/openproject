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
import {EditChangeset} from 'core-app/modules/fields/changeset/edit-changeset';

export class WorkPackageChangeset extends EditChangeset<WorkPackageResource> {
  // Injections
  public wpNotificationsService:WorkPackageNotificationService = this.injector.get(WorkPackageNotificationService);
  public schemaCacheService:SchemaCacheService = this.injector.get(SchemaCacheService);
  public wpCacheService:WorkPackageCacheService = this.injector.get(WorkPackageCacheService);
  public wpCreate:IWorkPackageCreateService = this.injector.get(IWorkPackageCreateServiceToken);
  public wpEditing:IWorkPackageEditingService = this.injector.get(IWorkPackageEditingServiceToken);
  public wpActivity:WorkPackagesActivityService = this.injector.get(WorkPackagesActivityService);
  public halResourceService:HalResourceService = this.injector.get(HalResourceService);

  public inFlight:boolean = false;

  private wpFormPromise:Promise<FormResource>|null;

  public reset(key:string) {
    delete this.changes[key];
  }

  public isChanged(attribute:string) {
    return this.changes[attribute];
  }


  public clear() {
    this.changes = {};
    this.resetForm();
    this.buildResource();
  }

  /**
   * Remove some of the changes by key
   * @param changes
   */
  public clearSome(...changes:string[]) {
    changes.forEach((key) => {
      delete this.changes[key];
    });
  }

  private resetForm() {
    this.form = null;
  }

  public setValue(key:string, val:any) {
    super.setValue(key, val);

    // Update the form for fields that may alter the form itself
    // when the work package is new. Otherwise, the save request afterwards
    // will update the form automatically.
    if (this.resource.isNew && (key === 'project' || key === 'type')) {
      this.updateForm();
    }
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
  public updateForm():Promise<FormResource<WorkPackageResource>> {
    let payload = this.buildPayloadFromChanges();

    if (!this.wpFormPromise) {
      this.wpFormPromise = this.resource.$links
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
    const wasNew = this.resource.isNew;

    let promise = new Promise<WorkPackageResource>((resolve, reject) => {
      this.updateForm()
        .then((form) => {
          const payload = this.buildPayloadFromChanges();

          // Reject errors when occurring in form validation
          const errors = form.getErrors();
          if (errors !== null) {
            return reject(errors);
          }

          this.resource.$links.updateImmediately(payload)
            .then((savedWp:WorkPackageResource) => {
              // Ensure the schema is loaded before updating
              this.schemaCacheService.ensureLoaded(savedWp).then(() => {

                // Clear any previous activities
                this.wpActivity.clear(this.resource.id!);

                // Initialize any potentially new HAL values
                savedWp.retainFrom(this.resource);
                this.inFlight = false;
                this.resource = savedWp;
                this.wpCacheService.updateWorkPackage(this.resource, true);

                if (wasNew) {
                  this.resource.overriddenSchema = undefined;
                  this.wpCreate.newWorkPackageCreated(this.resource);
                }

                // If there is a parent, its view has to be updated as well
                if (this.resource.parent) {
                  this.wpCacheService.loadWorkPackage(this.resource.parent.id.toString(), true);
                }
                this.clear();
                this.wpEditing.stopEditing(this.resource.id!);
                resolve(this.resource);
              });
            })
            .catch((error:any) => {
              // Update the resource anyway
              this.buildResource();
              reject(error);
            })
            .catch(reject);
        });
    });

    promise
      .catch(() => this.inFlight = false);

    return promise;
  }

  /**
   * Merge the current changes into the payload resource.
   *
   * @param {FormResource} form
   * @return {any}
   */
  private applyChanges(plainPayload:any) {
    // Fall back to the last known state of the work package should the form not be loaded.
    let reference = this.resource.$source;
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

    if (this.resource.isNew) {
      // If the work package is new, we need to pass the entire form payload
      // to let all default values be transmitted (type, status, etc.)
      if (this.form) {
        payload = this.form.payload.$source;
      } else {
        payload = this.resource.$source;
      }

      // Add attachments to be assigned.
      // They will already be created on the server but now
      // we need to claim them for the newly created work package.
      payload['_links']['attachments'] = this.resource
        .attachments
        .elements
        .map((a:HalResource) => { return { href: a.href }; });

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
    return {lockVersion: this.resource.lockVersion, _links: {}};
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

  /**
   * Check whether the given attribute is writable.
   * @param attribute
   */
  public isWritable(attribute:string):boolean {
    const schemaName = this.getSchemaName(attribute);
    const fieldSchema = this.schema[schemaName] as IFieldSchema;
    return fieldSchema && fieldSchema.writable;
  }

  public humanName(attribute:string):string {
    const fieldSchema = this.schema[attribute] as IFieldSchema;
    return fieldSchema.name || attribute;
  }

  public getSchemaName(attribute:string):string {
    if (this.schema.hasOwnProperty('date') && (attribute === 'startDate' || attribute === 'dueDate')) {
      return 'date';
    } else {
      return super.getSchemaName(attribute);
    }
  }

  private buildResource() {
    let payload = this.sourceFromResourceAndForm();

    if (!payload) {
      return;
    }

    const resource = this.halResourceService.createHalResourceOfType('WorkPackage', this.applyChanges(payload));

    if (resource.isNew && this.form) {
      resource.initializeNewResource(this.form);
    }

    if (resource.isNew) {
      resource.attachments = this.resource.attachments;
    }
    resource.overriddenSchema = this.schema;

    resource.__initialized_at = this.resource.__initialized_at;

    this.resource = (resource as WorkPackageResource);
    this.wpEditing.updateValue(this.resource.id!, this);
  }

  /**
   * Constructs the source from a combination of the resource
   * and the form payload. The payload takes precedences.
   * That way, values, that stem from the backend take precedence.
   */
  private sourceFromResourceAndForm() {
    if (!this.wpCacheService.state(this.resource.id!).value) {
      return null;
    }
    let payload =  _.merge({},
                           this.wpCacheService.state(this.resource.id!).value!.$source);

    if (this.form) {
      _.merge(payload, this.form.payload.$source);
    }

    return payload;
  }
}
