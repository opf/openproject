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
import {Injector} from '@angular/core';

export const activeFieldContainerClassName = 'wp-inline-edit--active-field';
export const activeFieldClassName = 'wp-inline-edit--field';

export class WorkPackageEditForm {
  // Injections
  public states:States = this.injector.get(States);
  public wpCacheService = this.injector.get(WorkPackageCacheService);
  public wpEditing = this.injector.get(WorkPackageEditingService);
  public wpEditField = this.injector.get(WorkPackageEditFieldService);
  public wpTableRefresh = this.injector.get(WorkPackageTableRefreshService);
  public wpNotificationsService = this.injector.get(WorkPackageNotificationService);

  // All current active (open) edit fields
  public activeFields:{ [fieldName:string]:WorkPackageEditFieldHandler } = {};

  // Errors of the last operation (required when adding opening fields afterwards)
  public errorsPerAttribute:{ [fieldName:string]:string[] } = {};

  // The current edit context to use the form with
  public editContext:WorkPackageEditContext;

  // Subscribe to changes to the temporary edit form
  protected wpSubscription:Subscription;
  protected resourceSubscription:Subscription;

  public static createInContext(injector:Injector,
                                editContext:WorkPackageEditContext,
                                wp:WorkPackageResourceInterface,
                                editMode:boolean = false) {

    const form = new WorkPackageEditForm(injector, wp, editMode);
    form.editContext = editContext;

    return form;
  }

  constructor(readonly injector:Injector,
              public workPackage:WorkPackageResourceInterface,
              public editMode:boolean = false) {

    this.wpSubscription = this.wpCacheService.state(workPackage.id)
      .values$()
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.workPackage = wp;
      });

    this.resourceSubscription = this.wpEditing.temporaryEditResource(workPackage.id)
      .values$()
      .subscribe(() => {
        if (!this.changeset.empty) {
          debugLog('Refreshing active edit fields after form update.');
          _.each(this.activeFields, (_handler, name) => this.refresh(name));
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
  public async activate(fieldName:string, noWarnings:boolean = false):Promise<WorkPackageEditFieldHandler> {
    return new Promise<WorkPackageEditFieldHandler>((resolve, reject) => {
      this.buildField(fieldName)
        .then((field:EditField) => {
          if (!field.writable && !noWarnings) {
            this.wpNotificationsService.showEditingBlockedError(field.displayName);
            reject();
          }

          this.renderField(fieldName, field)
            .then(resolve)
            .catch(reject);
        });
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
      return undefined;
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
      return Promise.resolve(activeField.element);
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
  public async submit():Promise<WorkPackageResourceInterface> {
    if (this.changeset.empty && !this.workPackage.isNew) {
      this.closeEditFields();
      return Promise.resolve(this.workPackage);
    }

    const isInitial = this.workPackage.isNew;

    // Reset old error notifcations
    this.errorsPerAttribute = {};

    // Notify all fields of upcoming save
    const openFields = _.keys(this.activeFields);
    _.each(this.activeFields, (handler:WorkPackageEditFieldHandler) => handler.field.onSubmit());

    return new Promise<WorkPackageResourceInterface>((resolve, reject) => {
      this.changeset.save()
        .then(savedWorkPackage => {
          // Close all current fields
          this.closeEditFields(openFields);

          resolve(savedWorkPackage);

          this.wpNotificationsService.showSave(savedWorkPackage, isInitial);
          this.editMode = false;
          this.editContext.onSaved(isInitial, savedWorkPackage);
          this.wpTableRefresh.request(`Saved work package ${savedWorkPackage.id}`);
        })
        .catch((error:ErrorResource|Object) => {
          this.wpNotificationsService.handleErrorResponse(error, this.workPackage);

          if (error instanceof ErrorResource) {
            this.handleSubmissionErrors(error, reject);
          }
        });
    });
  }

  /**
   * Close all fields and unsubscribe the observers on this form.
   */
  public destroy() {
    // Unsubscribe changes
    this.resourceSubscription.unsubscribe();
    this.wpSubscription.unsubscribe();

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
      delete(this.activeFields[name]);
    });
  }

  protected handleSubmissionErrors(error:any, reject:Function) {
    // Process single API errors
    this.handleErroneousAttributes(error);
    return reject();
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
    let promises:Promise<any>[] = erroneousFields.map(async (fieldName:string) => {
      return this.editContext.requireVisible(fieldName).then(() => {
        if (this.activeFields[fieldName]) {
          this.activeFields[fieldName].setErrors(this.errorsPerAttribute[fieldName] || []);
        }

        return this.activateWhenNeeded(fieldName) as any;
      });
    });

    Promise.all(promises)
      .then(() => {
        setTimeout(() => {
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

  private async buildField(fieldName:string):Promise<EditField> {
    return new Promise<EditField>((resolve, reject) => {
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
          );

          resolve(field);
        })
        .catch((error) => {
          console.error('Failed to build edit field: %o', error);
          this.wpNotificationsService.handleRawError(error);
        });
    });
  }

  private async renderField(fieldName:string, field:EditField):Promise<WorkPackageEditFieldHandler> {
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
