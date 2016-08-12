//-- copyright
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
//++

import {HalResource} from './hal-resource.service';
import {opApiModule} from '../../../../angular-modules';
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import {ApiWorkPackagesService} from '../../api-work-packages/api-work-packages.service';
import IQService = angular.IQService;
import {CollectionResourceInterface} from './collection-resource.service';

interface WorkPackageResourceEmbedded {
  activities:CollectionResourceInterface;
  assignee:HalResource|any;
  attachments:HalResource|any;
  author:HalResource|any;
  availableWatchers:HalResource|any;
  category:HalResource|any;
  children:WorkPackageResourceInterface[];
  parent:HalResource|any;
  priority:HalResource|any;
  project:HalResource|any;
  relations:CollectionResourceInterface;
  responsible:HalResource|any;
  schema:HalResource|any;
  status:HalResource|any;
  timeEntries:HalResource[]|any[];
  type:HalResource|any;
  version:HalResource|any;
  watchers:HalResource[]|any[];
}

interface WorkPackageResourceLinks extends WorkPackageResourceEmbedded {
  addAttachment(attachment:HalResource):ng.IPromise<any>;
  addChild(child:HalResource):ng.IPromise<any>;
  addComment(comment:HalResource):ng.IPromise<any>;
  addRelation(relation:any):ng.IPromise<any>;
  addWatcher(watcher:HalResource):ng.IPromise<any>;
  changeParent(params:any):ng.IPromise<any>;
  copy():ng.IPromise<WorkPackageResource>;
  delete():ng.IPromise<any>;
  logTime():ng.IPromise<any>;
  move():ng.IPromise<any>;
  removeWatcher():ng.IPromise<any>;
  self():ng.IPromise<any>;
  update(payload:any):ng.IPromise<any>;
  updateImmediately(payload:any):ng.IPromise<any>;
  watch():ng.IPromise<any>;
}

var $q:IQService;
var apiWorkPackages:ApiWorkPackagesService;
var wpCacheService:WorkPackageCacheService;
var NotificationsService:any;
var $stateParams:any;

export class WorkPackageResource extends HalResource {
  public static fromCreateForm(form) {
    var wp = new WorkPackageResource(form.payload.$plain(), true);

    wp.initializeNewResource(form);
    return wp;
  }

  /**
   * Create a copy resource from other and the new work package form
   * @param otherForm The work package form of another work package
   * @param form Work Package create form
   */
  public static copyFrom(otherForm, form) {
    var wp = new WorkPackageResource(otherForm.payload.$plain(), true);

    // Override values from form payload
    wp.lockVersion = form.payload.lockVersion;

    wp.initializeNewResource(form);

    return wp;
  }

  public $embedded:WorkPackageResourceEmbedded;
  public $links:WorkPackageResourceLinks;
  public id:number|string;
  public schema;
  public $pristine:{ [attribute:string]:any } = {};
  public parentId:number;
  public subject:string;
  public lockVersion:number;
  public description:any;
  public inFlight:boolean;
  public activities:CollectionResourceInterface;

  private form;

  public get isNew():boolean {
    return isNaN(Number(this.id));
  }

  public get isMilestone():boolean {
    /**
     * it would be better if this was not deduced but rather taken from the type
     */
    return this.hasOwnProperty('date');
  }

  /**
   * Returns true if any field is in edition in this resource.
   */
  public get dirty():boolean {
    return this.modifiedFields.length > 0;
  }

  public get modifiedFields():string[] {
    var modified = [];

    angular.forEach(this.$pristine, (value, key) => {
      var args = [this[key], value];

      if (this[key] instanceof HalResource) {
        args = args.map(arg => (arg ? arg.$source : arg));
      }

      if (!_.isEqual(args[0], args[1])) {
        modified.push(key);
      }
    });

    return modified;
  }

  public get isLeaf():boolean {
    var children = this.$links.children;
    return !(children && children.length > 0);
  }

  public get isEditable():boolean {
    return !!this.$links.update || this.isNew;
  }

  public requiredValueFor(fieldName):boolean {
    var fieldSchema = this.schema[fieldName];

    // The field schema may be undefined if a custom field
    // is used as a column, but not available for this type.
    if (angular.isUndefined(fieldSchema)) {
      return false;
    }

    return !this[fieldName] && fieldSchema.writable && fieldSchema.required;
  }

  public allowedValuesFor(field):ng.IPromise<HalResource[]> {
    var deferred = $q.defer();

    this.getForm().then(form => {
      const allowedValues = form.$embedded.schema[field].allowedValues;

      if (Array.isArray(allowedValues)) {
        deferred.resolve(allowedValues);
      }
      else {
        return allowedValues.$load().then(loadedValues => {
          deferred.resolve(loadedValues.elements);
        });
      }
    });

    return deferred.promise;
  }

  public setAllowedValueFor(field, href) {
    this.allowedValuesFor(field).then(allowedValues => {
      this[field] = _.find(allowedValues, entry => entry.href === href);
      wpCacheService.updateWorkPackage(this);
    });
  }

  public getForm() {
    if (!this.form) {
      this.updateForm(this.$source).catch(error => {
        NotificationsService.addError(error.message);
      });
    }

    return this.form;
  }

  public updateForm(payload) {
    // Always resolve form to the latest form
    // This way, we won't have to actively reset it.
    // But store the existing form in case of an error.
    // Because if we get an error, the object returned is not a form
    // and thus lacks the links the implementation depends upon.
    var oldForm = this.form;
    this.form = this.$links.update(payload);
    var deferred = $q.defer();

    this.form
      .then(form => {
        // Override the current schema with
        // the changes from API
        this.schema = form.$embedded.schema;

        // Take over new values from the form
        // this resource doesn't know yet.
        this.assignNewValues(form.$embedded.payload);

        deferred.resolve(form);
      })
      .catch(error => {
        this.form = oldForm;
        deferred.reject(error);
      });

    return deferred.promise;
  }

  public getSchema() {
    return this.getForm().then(form => {
      const schema = form.$embedded.schema;

      angular.forEach(schema, (field, name) => {
        // Assign only links from schema when an href is set
        // and field is writable.
        // (exclude plain properties and null values)
        const isHalField = field.writable && this[name] && this[name].href;

        // Assign only values from embedded schema that have an expanded
        // allowedValues set (type, status, custom field lists, etc.)
        const hasAllowedValues = Array.isArray(field.allowedValues) && field.allowedValues.length > 0;

        if (isHalField && hasAllowedValues) {
          this[name] = _.find(field.allowedValues, {href: this[name].href});
        }
      });

      return schema;
    });
  }

  public save() {
    var deferred = $q.defer();
    this.inFlight = true;
    const wasNew = this.isNew;

    this.updateForm(this.$source)
      .then(form => {
        var payload = this.mergeWithForm(form);

        this.saveResource(payload)
          .then(workPackage => {
            this.$initialize(workPackage);
            this.$pristine = {};
            this.updateActivities();
            deferred.resolve(this);
          })
          .catch(error => {
            deferred.reject(error);
            wpCacheService.updateWorkPackage(this);
          })
          .finally(() => {
            this.inFlight = false;
            if (wasNew) {
              wpCacheService.newWorkPackageCreated(this);
            }
          });
      })
      .catch(() => {
        this.inFlight = false;
        deferred.reject();
      });

    return deferred.promise;
  }

  public storePristine(attribute:string) {
    if (this.$pristine.hasOwnProperty(attribute)) {
      return;
    }

    this.$pristine[attribute] = angular.copy(this[attribute]);
  }

  public restoreFromPristine(attribute:string) {
    if (this.$pristine[attribute]) {
      this[attribute] = this.$pristine[attribute];
    }
  }

  public isParentOf(otherWorkPackage) {
    return otherWorkPackage.parent.$links.self.$link.href === this.$links.self.$link.href;
  }

  protected saveResource(payload):ng.IPromise<any> {
    if (this.isNew) {
      return apiWorkPackages.createWorkPackage(payload);
    }
    return this.$links.updateImmediately(payload);
  }

  private mergeWithForm(form) {
    var plainPayload = form.payload.$plain();
    var schema = form.$embedded.schema;

    // Merge embedded properties from form payload
    // Do not use properties on this, since they may be incomplete
    // e.g., when switching to a type that requires a custom field.
    Object.keys(plainPayload).forEach(key => {
      if (typeof(schema[key]) === 'object' && schema[key].writable === true) {
        plainPayload[key] = this[key];
      }
    });

    // Merged linked properties from form payload
    Object.keys(plainPayload._links).forEach(key => {
      if (typeof(schema[key]) === 'object' && schema[key].writable === true) {
        var value = this[key] ? this[key].href : null;
        plainPayload._links[key] = {href: value};
      }
    });

    return plainPayload;
  }

  private assignNewValues(formPayload) {
    Object.keys(formPayload.$source).forEach(key => {
      if (angular.isUndefined(this[key])) {
        this[key] = formPayload[key];
      }
    });
  }

  /**
   * Invalidate a set of linked resource in the given work package.
   * Inform the cache service about the work package update.
   */
  public updateLinkedResources(...resourceNames) {
    resourceNames.forEach(name => this[name].$update());
    wpCacheService.updateWorkPackage(this);
  }

  /**
   * Get updated activities from the server and inform the cache service about the work
   * package update.
   */
  public updateActivities() {
    this.updateLinkedResources('activities');
  }

  /**
   * Get updated attachments and activities from the server and inform the cache service
   * about the update.
   */
  public updateAttachments() {
    this.updateLinkedResources('activities', 'attachments');
  }

  /**
   * Assign values from the form for a newly created work package resource.
   * @param form
   */
  public initializeNewResource(form) {
    this.schema = form.schema;
    this.form = $q.when(form);
    this.id = 'new';

    // Set update link to form
    this['update'] = this.$links.update = form.$links.self;

    this.parentId = this.parentId || $stateParams.parent_id;
  }
}

export interface WorkPackageResourceInterface extends WorkPackageResourceLinks, WorkPackageResourceEmbedded, WorkPackageResource {
}

function wpResource(...args) {
  [$q, $stateParams, apiWorkPackages, wpCacheService, NotificationsService] = args;
  return WorkPackageResource;
}

wpResource.$inject = [
  '$q',
  '$stateParams',
  'apiWorkPackages',
  'wpCacheService',
  'NotificationsService'
];

opApiModule.factory('WorkPackageResource', wpResource);
