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

import {Subscription} from 'rxjs/Subscription';
import {$injectFields, injectorBridge} from '../angular/angular-injector-bridge.functions';
import {ErrorResource} from '../api/api-v3/hal-resources/error-resource.service';
import {States} from '../states.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {EditField} from '../wp-edit/wp-edit-field/wp-edit-field.module';
import {WorkPackageEditFieldService} from '../wp-edit/wp-edit-field/wp-edit-field.service';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {WorkPackageEditContext} from './work-package-edit-context';
import {WorkPackageEditFieldHandler} from './work-package-edit-field-handler';
import {debugLog} from '../../helpers/debug_output';
import {WorkPackageChangeset} from './work-package-changeset';
import {FormResourceInterface} from '../api/api-v3/hal-resources/form-resource.service';
import {WorkPackageEditingService} from './work-package-editing-service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTableRefreshService} from '../wp-table/wp-table-refresh-request.service';

export const activeFieldContainerClassName = 'wp-inline-edit--active-field';
export const activeFieldClassName = 'wp-inline-edit--field';

export class WorkPackageEditForm {
  // Injections
  public $q:ng.IQService;
  public $timeout:ng.ITimeoutService;
  public $rootScope:ng.IRootScopeService;
  public states:States;
  public wpCacheService:WorkPackageCacheService;
  public wpEditing:WorkPackageEditingService;
  public wpEditField:WorkPackageEditFieldService;
  public wpTableRefresh:WorkPackageTableRefreshService;
  public wpNotificationsService:WorkPackageNotificationService;

  // All current active (open) edit fields
  public activeFields:{ [fieldName:string]:WorkPackageEditFieldHandler } = {};

  // Errors of the last operation (required when adding opening fields afterwards)
  public errorsPerAttribute:{ [fieldName:string]:string[] } = {};

  // The current edit context to use the form with
  public editContext:WorkPackageEditContext;

  // Subscribe to changes to the temporary edit form
  protected resourceSubscription:Subscription;

  public static createInContext(editContext:WorkPackageEditContext,
                                wp:WorkPackageResourceInterface,
                                editMode:boolean = false) {

    const form = new WorkPackageEditForm(wp, editMode);
    form.editContext = editContext;

    return form;
  }

  constructor(public workPackage:WorkPackageResourceInterface, public editMode:boolean = false) {
    $injectFields(this,
      'wpCacheService', '$timeout', '$q', '$rootScope',
      'wpEditField', 'wpNotificationsService',
      'wpEditing', 'states', 'wpTableRefresh'
    );

    this.resourceSubscription = this.wpEditing.temporaryEditResource(workPackage.id)
      .values$()
      .subscribe(() => {
        if (!this.changeset.empty) {
          debugLog('Refreshing active edit fields after form update.');
          _.each(this.activeFields, (_handler, name) => this.refresh(name!));
        }
      });
  }

  /**
   * Return the current or a new changeset for the given work package.
   * This will always return a valid (potentially empty) changeset.
   *
   * @return {WorkPackageChangeset}
   */
  public get changeset():WorkPackageChangeset {
    return this.wpEditing.changesetFor(this.workPackage);
  }

  /**
   * Active the edit field upon user's request.
   * @param fieldName
   * @param noWarnings Ignore warnings if the field cannot be opened
   */
  public activate(fieldName:string, noWarnings:boolean = false):Promise<WorkPackageEditFieldHandler> {
    return this.buildField(fieldName).then((field:EditField) => {
      if (!field.writable && !noWarnings) {
        this.wpNotificationsService.showEditingBlockedError(field.displayName);
        return this.$q.reject();
      }

      return this.renderField(fieldName, field);
    });
  }

  /**
   * Refreshes an active field by simply updating the fieldHandler $scope.
   * @param {string} fieldName
   * @return {Promise<any>}
   */
  public refresh(fieldName:string) {
    const handler = this.activeFields[fieldName];
    if (!handler) {
      debugLog(`Trying to refresh ${fieldName}, but is not an active field.`);
      return;
    }

    return this.buildField(fieldName).then((field:EditField) => {
      this.editContext.refreshField(field, handler);
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

    return this.activate(fieldName, true);
  }

  /**
   * Activate all fields that are returned in validation errors
   */
  public activateMissingFields() {
    this.changeset.getForm().then((form:any) => {
      _.each(form.validationErrors, (val:any, key:string) => {
        if (key === 'id') {
          return;
        }
        this.activateWhenNeeded(key);
      });
    });
  }

  /**
   * Save the active changeset.
   * @return {any}
   */
  public submit():ng.IPromise<WorkPackageResourceInterface> {
    if (this.changeset.empty && !this.workPackage.isNew) {
      this.closeEditFields();
      return this.$q.when(this.workPackage);
    }

    const deferred = this.$q.defer();
    const isInitial = this.workPackage.isNew;

    // Reset old error notifcations
    this.errorsPerAttribute = {};

    const openFields = _.keys(this.activeFields);

    this.changeset.save()
      .then(savedWorkPackage => {
        // Close all current fields
        this.closeEditFields(openFields);

        deferred.resolve(savedWorkPackage);

        this.wpNotificationsService.showSave(savedWorkPackage, isInitial);
        this.editMode = false;
        this.wpTableRefresh.request(false, `Saved work package ${savedWorkPackage.id}`);
      })
      .catch((error:ErrorResource|Object) => {
        this.wpNotificationsService.handleErrorResponse(error, this.workPackage);

        if (error instanceof ErrorResource) {
          this.handleSubmissionErrors(error, deferred);
        }
      });

    return deferred.promise;
  }

  /**
   * Close all fields and unsubscribe the observers on this form.
   */
  public destroy() {
    // Unsubscribe changes
    this.resourceSubscription.unsubscribe();

    // Kill all active fields
    // Without resetting the changeset, if, e.g., we're moving an active edit
    _.each(this.activeFields, (handler) => {
      handler && handler.deactivate();
    });
  }

  /**
   * Close the given or all open fields.
   *
   * @param {string[]} fields
   */
  public closeEditFields(fields?:string[]) {
    if (!fields) {
      fields = _.keys(this.activeFields);
    }

    fields.forEach((name:string) => {
      const handler = this.activeFields[name];
      handler && handler.deactivate();
      this.changeset.reset(name);
    });
  }

  protected handleSubmissionErrors(error:any, deferred:any) {
    // Process single API errors
    this.handleErroneousAttributes(error);
    return deferred.reject();
  }

  protected handleErroneousAttributes(error:any) {
    // Get attributes withe errors
    const erroneousAttributes = error.getInvolvedAttributes();

    // Save erroneous fields for when new fields appear
    this.errorsPerAttribute = error.getMessagesPerAttribute();
    if (erroneousAttributes.length === 0) {
      return;
    }

    return this.setErrorsForFields(erroneousAttributes);
  }

  private setErrorsForFields(erroneousFields:string[]) {
    // Accumulate errors for the given response
    let promises:Promise<any>[] = erroneousFields.map((fieldName:string) => {
      return this.editContext.requireVisible(fieldName).then(() => {
        if (this.activeFields[fieldName]) {
          this.activeFields[fieldName].setErrors(this.errorsPerAttribute[fieldName] || []);
        }

        return this.activateWhenNeeded(fieldName) as any;
      });
    });

    Promise.all(promises)
      .then(() => {
        this.$timeout(() => {
          // Focus the first field that is erroneous
          jQuery(`.${activeFieldContainerClassName}.-error .${activeFieldClassName}`)
            .first()
            .focus();
        });
      })
      .catch(() => {
        console.error('Failed to activate all erroneous fields.');
      });
  }

  private buildField(fieldName:string):Promise<EditField> {
    return new Promise((resolve, reject) => {
      this.changeset.getForm()
        .then((form:FormResourceInterface) => {
          const schemaName = this.changeset.getSchemaName(fieldName);
          const fieldSchema = form.schema[schemaName];

          if (!fieldSchema) {
            return reject();
          }

          const field = this.wpEditField.getField(
            this.changeset,
            schemaName,
            fieldSchema
          ) as EditField;

          resolve(field);
        })
        .catch((error) => {
          console.error('Failed to build edit field: %o', error);
          this.wpNotificationsService.handleRawError(error);
        });
    });
  }

  private renderField(fieldName:string, field:EditField):Promise<WorkPackageEditFieldHandler> {
    const promise = this.editContext.activateField(this,
      field,
      fieldName,
      this.errorsPerAttribute[fieldName] || []);
    return promise
      .then((fieldHandler) => {
        this.activeFields[fieldName] = fieldHandler;
        return fieldHandler;
      })
      .catch((error) => {
        console.error('Failed to render edit field:' + error);
        this.wpNotificationsService.handleRawError(error);
      });
  }
}
