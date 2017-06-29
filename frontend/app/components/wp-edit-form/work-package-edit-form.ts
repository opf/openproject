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

import {Subscription} from "rxjs/Subscription";
import {injectorBridge} from "../angular/angular-injector-bridge.functions";
import {SimpleTemplateRenderer} from "../angular/simple-template-renderer";
import {ErrorResource} from "../api/api-v3/hal-resources/error-resource.service";
import {SchemaResource} from "../api/api-v3/hal-resources/schema-resource.service";
import {WorkPackageResourceInterface} from "../api/api-v3/hal-resources/work-package-resource.service";
import {States} from "../states.service";
import {WorkPackageCacheService} from "../work-packages/work-package-cache.service";
import {EditField} from "../wp-edit/wp-edit-field/wp-edit-field.module";
import {WorkPackageEditFieldService} from "../wp-edit/wp-edit-field/wp-edit-field.service";
import {WorkPackageNotificationService} from "../wp-edit/wp-notification.service";
import {WorkPackageEditContext} from "./work-package-edit-context";
import {WorkPackageEditFieldHandler} from "./work-package-edit-field-handler";

export class WorkPackageEditForm {
  // Injections
  public $q:ng.IQService;
  public $timeout:ng.ITimeoutService;
  public $rootScope:ng.IRootScopeService;
  public states:States;
  public wpCacheService:WorkPackageCacheService;
  public wpEditField:WorkPackageEditFieldService;
  public templateRenderer:SimpleTemplateRenderer;
  public wpNotificationsService:WorkPackageNotificationService;

  // The edit context for this current edit
  public editContext:WorkPackageEditContext;

  // Other fields
  public workPackage:WorkPackageResourceInterface;

  // All current active (open) edit fields
  public activeFields:{ [fieldName: string]: WorkPackageEditFieldHandler } = {};

  // Errors of the last operation (required when adding opening fields afterwards)
  public errorsPerAttribute:{ [fieldName: string]: string[] } = {};

  // The last field that got activated
  public lastActiveField:string;

  // The work package cache service subscription
  protected subscription:Subscription;

  constructor(public workPackageId:string,
              public editMode = false) {
    injectorBridge(this);

    this.subscription = this.wpCacheService.loadWorkPackage(workPackageId).values$()
      .takeUntil(this.states.table.stopAllSubscriptions)
      .subscribe((wp: WorkPackageResourceInterface) => {
        this.workPackage = wp;
      });
  }

  /**
   * Active the edit field upon user's request.
   * @param fieldName
   */
  public activate(fieldName:string):ng.IPromise<ng.IAugmentedJQuery> {
    return this.workPackage.loadFormSchema().then((schema:SchemaResource) => {
      const field = this.wpEditField.getField(
        this.workPackage,
        fieldName,
        schema[fieldName]
      ) as EditField;

      if (!field.writable) {
        this.wpNotificationsService.showEditingBlockedError(field.displayName);
        return this.$q.reject();
      }

      this.workPackage.storePristine(fieldName);
      return this.buildField(fieldName, field);
    });
  }

  /**
   * Activate the field unless it is marked active already
   * (e.g., already being activated).
   */
  public activateWhenNeeded(fieldName:string) {
    const activeField = this.activeFields[fieldName];
    if (activeField) {
      return this.$q.when(activeField.element);
    }

    return this.activate(fieldName);
  }

  /**
   * Activate all fields that are returned in validation errors
   */
  public activateMissingFields() {
    this.workPackage.getForm().then((form:any) => {
      _.each(form.validationErrors, (val:any, key:string) => {
        this.activateWhenNeeded(key);
      });
    });
  }

  public submit() {
    if (!(this.workPackage.dirty || this.workPackage.isNew)) {
      this.stopEditing();
      return this.$q.when(this.workPackage);
    }

    const deferred = this.$q.defer();
    const isInitial = this.workPackage.isNew;

    // Reset old error notifcations
    this.errorsPerAttribute = {};

    // Close all current fields
    this.closeAllEditFields();

    this.workPackage.save()
      .then(savedWorkPackage => {
        _.each(this.activeFields, (handler:WorkPackageEditFieldHandler) => {
          handler.deactivate();
        });
        deferred.resolve(savedWorkPackage);

        this.wpNotificationsService.showSave(savedWorkPackage, isInitial);
        this.editContext.onSaved(savedWorkPackage);

        this.stopEditing();

     })
      .catch((error) => {
        this.wpNotificationsService.handleErrorResponse(error, this.workPackage);
        if (error instanceof ErrorResource) {
          this.handleSubmissionErrors(error, deferred);
        }
      });

    return deferred.promise;
  }

  protected stopEditing() {
    // Close all edit fields
    this.closeAllEditFields();

    // Unsubscribe changes
    this.subscription.unsubscribe();

    // Destroy this form
    this.states.editing.get(this.workPackageId.toString()).clear('Editing completed');
  }

  protected closeAllEditFields() {
    _.each(this.activeFields, (handler:WorkPackageEditFieldHandler) => {
      handler.deactivate();
    });
  }

  protected handleSubmissionErrors(error: any, deferred: any) {
    // Process single API errors
    this.handleErroneousAttributes(error);
    return deferred.reject();
  }

  protected handleErroneousAttributes(error: any) {
    const attributes = error.getInvolvedAttributes();
    // Save erroneous fields for when new fields appear
    this.errorsPerAttribute = error.getMessagesPerAttribute()
    if (attributes.length === 0) {
      return;
    }

    // Iterate all erroneous fields and close these that are valid
    const validFields = _.keys(this.activeFields);

    // Accumulate errors for the given response
    _.each(attributes, (fieldName:string) => {
      this.editContext.requireVisible(fieldName).then(() => {
        this.activateWhenNeeded(fieldName);
      });
    });

    // Now close remaining fields (valid)
    _.each(validFields, (fieldName:string) => {
      this.activeFields[fieldName].deactivate();
    });

    // Focus the first field that are still remaining
    let firstActiveField =  this.lastActiveField || this.editContext.firstField(_.keys(this.activeFields));

    if (this.activeFields[firstActiveField]) {
      this.activeFields[firstActiveField].focus();
    }
  }

  private buildField(fieldName:string, field:EditField):ng.IPromise<ng.IAugmentedJQuery> {

    // Let the context find the element
    const cell = this.editContext.findContainer(fieldName);

    // Create a field handler for the newly active field
    const fieldHandler = new WorkPackageEditFieldHandler(
      this,
      field,
      cell,
      this.errorsPerAttribute[fieldName] || []
    );

    fieldHandler.$scope = this.templateRenderer.createRenderScope();
    const promise = this.templateRenderer.renderIsolated(
      // Replace the current cell
      cell[0],
      fieldHandler.$scope,
      '/components/wp-edit-form/wp-edit-form.template.html',
      {
        vm: fieldHandler,
      }
    );

    this.activeFields[fieldName] = fieldHandler;
    this.lastActiveField = fieldName;
    return promise.then((element) => {
      // Assure the element is visible
      return this.$timeout(() => element);
    });
  }
}

WorkPackageEditForm.$inject = [
  'wpCacheService', '$timeout', '$q', '$rootScope',
  'wpEditField', 'templateRenderer', 'wpNotificationsService',
  'states'
];
