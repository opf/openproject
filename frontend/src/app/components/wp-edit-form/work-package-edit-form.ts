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

import {Injector} from '@angular/core';
import {ErrorResource} from 'core-app/modules/hal/resources/error-resource';
import {FormResource} from 'core-app/modules/hal/resources/form-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {Subscription} from 'rxjs';
import {States} from '../states.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../wp-edit/wp-notification.service';
import {WorkPackageTableRefreshService} from '../wp-table/wp-table-refresh-request.service';
import {WorkPackageChangeset} from './work-package-changeset';
import {WorkPackageEditContext} from './work-package-edit-context';
import {WorkPackageEditFieldHandler} from './work-package-edit-field-handler';
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {IFieldSchema} from "core-app/modules/fields/field.base";

export const activeFieldContainerClassName = 'wp-inline-edit--active-field';
export const activeFieldClassName = 'wp-inline-edit--field';

export class WorkPackageEditForm {
  // Injections
  public states:States = this.injector.get(States);
  public wpCacheService = this.injector.get(WorkPackageCacheService);
  public wpEditing = this.injector.get(IWorkPackageEditingServiceToken);
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

  public static createInContext(injector:Injector,
                                editContext:WorkPackageEditContext,
                                wp:WorkPackageResource,
                                editMode:boolean = false) {

    const form = new WorkPackageEditForm(injector, wp, editMode);
    form.editContext = editContext;

    return form;
  }

  constructor(readonly injector:Injector,
              public workPackage:WorkPackageResource,
              public editMode:boolean = false) {

    this.wpSubscription = this.wpCacheService.state(workPackage.id)
      .values$()
      .subscribe((wp:WorkPackageResource) => {
        this.workPackage = wp;
      });
  }

  /**
   * Return whether this form has any active fields
   */
  public hasActiveFields():boolean {
    return !_.isEmpty(this.activeFields);
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
    return this.loadFieldSchema(fieldName)
      .then((schema:IFieldSchema) => {
        if (!schema.writable && !noWarnings) {
          this.wpNotificationsService.showEditingBlockedError(schema.name || fieldName);
          return Promise.reject();
        }

        return this.renderField(fieldName, schema);
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

    return this.editContext.requireVisible(fieldName).then(() => {
      return this.activate(fieldName, true);
    });
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
  public async submit():Promise<WorkPackageResource> {
    const isInitial = this.workPackage.isNew;

    if (this.changeset.empty && !isInitial) {
      this.closeEditFields();
      return Promise.resolve(this.workPackage);
    }

    // Reset old error notifcations
    this.errorsPerAttribute = {};

    // Notify all fields of upcoming save
    const openFields = _.keys(this.activeFields);

    // Call onSubmit handlers
    await Promise.all(_.map(this.activeFields, (handler:WorkPackageEditFieldHandler) => handler.onSubmit()));

    return new Promise<WorkPackageResource>((resolve, reject) => {
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
          this.wpNotificationsService.handleRawError(error, this.workPackage);

          if (error instanceof ErrorResource) {
            this.handleSubmissionErrors(error);
            reject();
          }
        });
    });
  }

  /**
   * Close all fields and unsubscribe the observers on this form.
   */
  public destroy() {
    // Unsubscribe changes
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
    });
  }

  protected handleSubmissionErrors(error:any) {
    // Process single API errors
    this.handleErroneousAttributes(error);
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

  /**
   * Load the work package form to get the current field schema with all
   * values loaded.
   * @param fieldName
   */
  private loadFieldSchema(fieldName:string):Promise<IFieldSchema> {
    return this.changeset.getForm()
      .then((form:FormResource) => {
        const schemaName = this.changeset.getSchemaName(fieldName);
        const fieldSchema:IFieldSchema = form.schema[schemaName];

        if (!fieldSchema) {
          throw new Error();
        }

        return fieldSchema;
      })
      .catch((error) => {
        console.error('Failed to build edit field: %o', error);
        this.wpNotificationsService.handleRawError(error, this.workPackage);
        throw new Error();
      });
  }

  private renderField(fieldName:string, schema:IFieldSchema):Promise<WorkPackageEditFieldHandler> {
    const promise:Promise<WorkPackageEditFieldHandler> = this.editContext.activateField(this,
      schema,
      fieldName,
      this.errorsPerAttribute[fieldName] || []);

    return promise
      .then((fieldHandler:WorkPackageEditFieldHandler) => {
        this.activeFields[fieldName] = fieldHandler;
        return fieldHandler;
      })
      .catch((error) => {
        console.error('Failed to render edit field:' + error);
        this.wpNotificationsService.handleRawError(error);
      });
  }
}
