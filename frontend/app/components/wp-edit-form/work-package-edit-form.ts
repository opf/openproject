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

import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageResource} from '../api/api-v3/hal-resources/work-package-resource.service';
import {injectorBridge} from '../angular/angular-injector-bridge.functions';
import {WorkPackageEditContext} from './work-package-edit-context';
import {EditField} from '../wp-edit/wp-edit-field/wp-edit-field.module';
import {WorkPackageEditFieldService} from '../wp-edit/wp-edit-field/wp-edit-field.service';
import {SimpleTemplateRenderer} from '../angular/simple-template-renderer';
import {WorkPackageEditFieldHandler} from './work-package-edit-field-handler';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {ErrorResource} from '../api/api-v3/hal-resources/error-resource.service';
import {States} from '../states.service';

export class WorkPackageEditForm {
  // Injections
  public $q:ng.IQService;
  public $rootScope:ng.IRootScopeService;
  public states:States;
  public wpCacheService:WorkPackageCacheService;
  public wpEditField:WorkPackageEditFieldService;
  public templateRenderer:SimpleTemplateRenderer;
  public wpNotificationsService:WorkPackageNotificationService;

  // The edit context for this current edit
  public editContext:WorkPackageEditContext | null;

  // Other fields
  public workPackage;

  // All current active (open) edit fields
  public activeFields:{ [fieldName: string]: WorkPackageEditFieldHandler } = {};

  // Errors of the last operation (required when adding opening fields afterwards)
  public errorsPerAttribute:{ [fieldName: string]: string[] } = {};

  // The last field that got activated
  public lastActiveField:string;

  constructor(public workPackageId:number,
              public editMode = false) {
    injectorBridge(this);

    this.wpCacheService.loadWorkPackage(workPackageId).observe(null)
      .subscribe((wp: WorkPackageResource) => {
        this.workPackage = wp;
      });
  }

  /**
   * Active the edit field upon user's request.
   * @param fieldName
   */
  public activate(fieldName:string) {
    if (this.activeFields[fieldName]) {
      return;
    }

    this.workPackage.loadFormSchema().then(schema => {
      let field = <EditField> this.wpEditField.getField(
        this.workPackage,
        fieldName,
        schema[fieldName]
      );
      this.workPackage.storePristine(fieldName);
      this.buildField(fieldName, field);
    });
  }

 public submit() {
    if (!(this.workPackage.dirty || this.workPackage.isNew)) {
      return this.$q.when(this.workPackage);
    }

    let deferred = this.$q.defer();
    let isInitial = this.workPackage.isNew;

    // Reset old error notifcations
    this.errorsPerAttribute = {};

    this.workPackage.save()
      .then(() => {
        _.each(this.activeFields, (handler:WorkPackageEditFieldHandler) => {
          handler.deactivate();
        });
        deferred.resolve(this.workPackage);

        this.wpNotificationsService.showSave(this.workPackage, isInitial);
        // TODO do in subform
        // this.successHandler({workPackage: this.workPackage, fields: this.fields});

        // TODO destroy this form
        this.states.editing.get(this.workPackageId.toString()).clear('Editing completed');
     })
      .catch((error) => {
        this.wpNotificationsService.handleErrorResponse(error, this.workPackage);
        if (error instanceof ErrorResource) {
          this.handleSubmissionErrors(error, deferred);
        }
      });

    return deferred.promise;
  }

  protected handleSubmissionErrors(error: any, deferred: any) {
    // Process single API errors
    this.handleErroneousAttributes(error);
    return deferred.reject();
  }

  protected handleErroneousAttributes(error: any) {
    let attributes = error.getInvolvedAttributes();
    // Save erroneous fields for when new fields appear
    this.errorsPerAttribute = error.getMessagesPerAttribute()
    if (attributes.length === 0) {
      return;
    }

    // Allow additional error handling
    // this.firstActiveField = this.errorHandler({
    //   workPackage: this.worPackage,
    //   fields: this.fields,
    //   attributes: attributes
    // });

    // Iterate all erroneous fields and close these that are valid
    let validFields = _.keys(this.activeFields);

    // Accumulate errors for the given response
    _.each(attributes, (fieldName:string) => {
      let activeField = this.activeFields[fieldName];
      if (activeField !== undefined) {
        // currently active, set errors
        activeField.setErrors(this.errorsPerAttribute[fieldName] || []);
        _.pull(validFields, fieldName);
      } else {
        // Field does not exist, show it (e.g, add column in table)
        this.editContext.requireVisible(fieldName);
        this.activate(fieldName);
      }
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

  private buildField(fieldName:string, field:EditField) {

    // Let the context find the element
    let cell = this.editContext.find(fieldName);

    // Create a field handler for the newly active field
    let fieldHandler = new WorkPackageEditFieldHandler(
      this,
      field,
      cell,
      this.errorsPerAttribute[fieldName] || []
    );

    this.templateRenderer.renderIsolated(
      // Replace the current cell
      cell[0],
      '/components/wp-edit-form/wp-edit-form.template.html',
      {
        vm: fieldHandler,
      }
    );

    this.activeFields[fieldName] = fieldHandler;
    this.lastActiveField = fieldName;
  }
}

WorkPackageEditForm.$inject = [
  'wpCacheService', '$q', '$rootScope',
  'wpEditField', 'templateRenderer', 'wpNotificationsService',
  'states'
];
