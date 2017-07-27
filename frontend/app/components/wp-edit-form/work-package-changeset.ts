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

import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {FormResourceInterface} from '../api/api-v3/hal-resources/form-resource.service';
import {$injectFields} from '../angular/angular-injector-bridge.functions';
import {debugLog} from '../../helpers/debug_output';
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';
import {SchemaCacheService} from '../schemas/schema-cache.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageCreateService} from '../wp-create/wp-create.service';
import {input, InputState} from 'reactivestates';

export class WorkPackageChangeset {
  // Injections
  public $q:ng.IQService;
  public NotificationsService:any;
  public schemaCacheService:SchemaCacheService;
  public wpCacheService:WorkPackageCacheService;
  public wpCreate:WorkPackageCreateService;

  // The changeset to be applied to the work package
  private changes:{[attribute:string]:any} = {};
  public inFlight:boolean = false;

  // The current work package form
  public wpForm:FormResourceInterface|null;

  // The current editing resource state
  public resource:InputState<HalResource> = input<HalResource>();

  constructor(public workPackage:WorkPackageResourceInterface) {
    $injectFields(
      this, 'NotificationsService', '$q', 'schemaCacheService',
      'wpCacheService', 'wpCreate'
    );

    // Start with a resource from the current work package knowledge.
    const payload = this.mergeWithPayload(workPackage.$plain);
    this.buildResource(payload);
  }

  public startEditing(key:string) {
    this.changes[key] = _.cloneDeep(this.workPackage[key]);
  }

  public reset(key:string) {
    delete this.changes[key];
  }

  public clear() {
    this.changes = {};
  }

  public get empty() {
    return _.isEmpty(this.changes);
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
  }

  /**
   * Return whether a change value exist for the given attribute key.
   * @param {string} key
   * @return {boolean}
   */
  public isOverridden(key:string) {
    return this.changes.hasOwnProperty(key);
  }

  public getForm():ng.IPromise<FormResourceInterface> {
    if (this.wpForm) {
      return this.$q.when(this.wpForm);
    }

    return this.updateForm().catch(error => {
      this.NotificationsService.addError(error.message);
    });
  }

  /**
   * Update the form resource from the API.
   * @return {angular.IPromise<any>}
   */
  public updateForm():ng.IPromise<FormResourceInterface> {
    // Always resolve form to the latest form
    // This way, we won't have to actively reset it.
    // But store the existing form in case of an error.
    // Because if we get an error, the object returned is not a form
    // and thus lacks the links the implementation depends upon.
    const oldForm = this.wpForm;

    // Create the payload from the current changes,
    // and extend it with the current lock version
    // -- This is the place to add additional logic when the lockVersion changed in between --
    let payload = { lockVersion: this.workPackage.lockVersion, _links: {} };
    this.mergeWithPayload(payload)

    var deferred = this.$q.defer();

    this.workPackage.$links.update(payload)
      .then((form) => {
        this.wpForm = form;
        const payload = this.mergeWithPayload(form.payload.$source);
        this.buildResource(payload);
        deferred.resolve(form);
      })
      .catch((error:any) => {
        this.wpForm = oldForm;
        deferred.reject(error);
      });

    return deferred.promise;
  }


  public save():ng.IPromise<WorkPackageResourceInterface> {
    const deferred = this.$q.defer();

    this.inFlight = true;
    const wasNew = this.workPackage.isNew;
    this.updateForm()
      .then((form) => {
        const payload = this.resource.value!.$source;

        this.workPackage.$links.updateImmediately(payload)
          .then((savedWp:WorkPackageResourceInterface) => {
            // Remove the current form and schema, otherwise old form data
            // might still be used for the next edit field to be edited
            this.wpForm = null;

            // Initialize any potentially new HAL values
            this.workPackage.$initialize(savedWp);

            // Ensure the schema is loaded before updating
            this.schemaCacheService.ensureLoaded(this.workPackage).then(() => {
              this.workPackage.updateActivities();

              if (wasNew) {
                this.workPackage.uploadAttachmentsAndReload();
                this.wpCreate.newWorkPackageCreated(this.workPackage);
              }

              this.wpCacheService.updateWorkPackage(this.workPackage);
              deferred.resolve(this.workPackage);
            });
          })
          .catch(error => {
            // Update the resource anyway
            this.buildResource(payload);
            deferred.reject(error);
          });
      })
      .catch(deferred.reject);

    return deferred.promise.finally(() => this.inFlight = false);
  }

  /**
   * Merge the current changes into the payload resource.
   *
   * @param {FormResourceInterface} form
   * @return {any}
   */
  private mergeWithPayload(plainPayload:any) {
    const reference = this.wpForm ? this.wpForm.payload.$source : this.workPackage.$source;

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
   * Extract the link(s) in the given changed value
   */
  private getLinkedValue(val:any, fieldSchema:op.FieldSchema) {
    var isArray = (fieldSchema.type || '').startsWith('[]');

    if (isArray) {
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
      return { href: _.get(val, 'href', null) };
    }
  }

  /**
   * Get the best schema currently available, either the default WP schema (must exist).
   * If loaded, return the form schema, which provides better information on writable status
   * and contains available values.
   */
  public get schema() {
    return this.wpForm ? this.wpForm.schema : this.workPackage.schema;
  }

  private buildResource(payload:any) {
    const resource = new HalResource(payload, true);
    resource.schema = this.schema;

    this.resource.putValue(resource);
  }
}

