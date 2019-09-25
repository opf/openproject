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
import {Subscription} from 'rxjs';
import {States} from 'core-components/states.service';
import {IFieldSchema} from "core-app/modules/fields/field.base";

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {EditFieldHandler} from "core-app/modules/fields/edit/editing-portal/edit-field-handler";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {ResourceChangeset} from "core-app/modules/fields/changeset/resource-changeset";
import {EditContext} from "core-app/modules/fields/edit/edit-form/edit-context";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";

export const activeFieldContainerClassName = 'wp-inline-edit--active-field';
export const activeFieldClassName = 'wp-inline-edit--field';

export class EditForm {
  // Injections
  public states:States = this.injector.get(States);
  public halEditing = this.injector.get(HalResourceEditingService);
  public halNotification = this.injector.get(HalResourceNotificationService);
  public wpEvents = this.injector.get(HalEventsService);

  // All current active (open) edit fields
  public activeFields:{ [fieldName:string]:EditFieldHandler } = {};

  // Errors of the last operation (required when adding opening fields afterwards)
  public errorsPerAttribute:{ [fieldName:string]:string[] } = {};

  // The current edit context to use the form with
  public editContext:EditContext;

  // Subscribe to changes to the temporary edit form
  protected subscription:Subscription;

  public static createInContext(injector:Injector,
                                editContext:EditContext,
                                resource:HalResource,
                                editMode:boolean = false) {

    const form = new EditForm(injector, resource, editMode);
    form.editContext = editContext;

    return form;
  }

  constructor(readonly injector:Injector,
              public resource:HalResource,
              public editMode:boolean = false) {

    if (this.resource.state) {
      this.subscription = this.resource.state
        .values$()
        .subscribe((resource:HalResource) => {
          this.resource = resource;
        });
    }
  }

  /**
   * Return whether this form has any active fields
   */
  public hasActiveFields():boolean {
    return !_.isEmpty(this.activeFields);
  }


  /**
   * Return the current or a new change object for the given resource.
   * This will always return a valid (potentially empty) change.
   *
   * @return {ResourceChangeset}
   */
  public get change():ResourceChangeset<HalResource> {
      // ToDo: correct type
    return this.halEditing.changeFor(this.resource as any);
  }

  /**
   * Active the edit field upon user's request.
   * @param fieldName
   * @param noWarnings Ignore warnings if the field cannot be opened
   */
  public activate(fieldName:string, noWarnings:boolean = false):Promise<EditFieldHandler> {
    return this.loadFieldSchema(fieldName, noWarnings)
      .then((schema:IFieldSchema) => {
        if (!schema.writable && !noWarnings) {
          this.halNotification.showEditingBlockedError(schema.name || fieldName);
          return Promise.reject();
        }

        return this.renderField(fieldName, schema);
      });
  }

  /**
   * Activate the field unless it is marked active already
   * (e.g., already being activated).
   */
  public activateWhenNeeded(fieldName:string):Promise<unknown> {
    const activeField = this.activeFields[fieldName];
    if (activeField) {
      return Promise.resolve();
    }

    return this.editContext.requireVisible(fieldName).then(() => {
      return this.activate(fieldName, true);
    });
  }

  /**
   * Activate all fields that are returned in validation errors
   */
  public activateMissingFields() {
    this.change.getForm().then((form:any) => {
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
  public async submit():Promise<HalResource> {
    if (this.change.isEmpty() && !this.resource.isNew) {
      this.closeEditFields();
      return Promise.resolve(this.resource);
    }

    // Reset old error notifcations
    this.errorsPerAttribute = {};

    // Notify all fields of upcoming save
    const openFields = _.keys(this.activeFields);

    // Call onSubmit handlers
    await Promise.all(_.map(this.activeFields, (handler:EditFieldHandler) => handler.onSubmit()));

    return new Promise<HalResource>((resolve, reject) => {
      this.halEditing.save(this.change)
        .then(result => {
          // Close all current fields
          this.closeEditFields(openFields);

          resolve(result.workPackage);

          this.halNotification.showSave(result.workPackage, result.wasNew);
          this.editMode = false;
          this.editContext.onSaved(result.wasNew, result.workPackage);
          this.wpEvents.push(result.workPackage, { eventType: 'updated' });
        })
        .catch((error:ErrorResource|Object) => {
          this.halNotification.handleRawError(error, this.resource);

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
    if (this.subscription) {
      // Unsubscribe changes
      this.subscription.unsubscribe();
    }

    // Kill all active fields
    // Without resetting the changeset, if, e.g., we're moving an active edit
    _.each(this.activeFields, (handler) => {
      handler && handler.deactivate(false);
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
      handler && handler.deactivate(false);
      this.change.reset(name);
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

    // ToDo: Replace by a real engineers solution ^^
    //  Make Global so that embedded tables do not interfere
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
   * Load the resource form to get the current field schema with all
   * values loaded.
   * @param fieldName
   */
  private loadFieldSchema(fieldName:string, noWarnings:boolean = false):Promise<IFieldSchema> {
    const schemaName = this.change.getSchemaName(fieldName);

    return new Promise((resolve, reject) => {
      this.loadFormAndCheck(schemaName, noWarnings);
      const fieldSchema:IFieldSchema = this.change.schema[schemaName];

      if (!fieldSchema) {
        throw new Error();
      }

      resolve(fieldSchema);
    });
  }

  /**
   * Ensure the form gets loaded and we show an error when the field cannot be opened
   * @param schemaName
   * @param noWarnings
   */
  private loadFormAndCheck(fieldName:string, noWarnings:boolean = false) {
    const schemaName = this.change.getSchemaName(fieldName);

    // Ensure the form is being loaded if necessary
    this.change
      .getForm()
      .then((form) => {
        // Look up whether we're actually editable
        const fieldSchema = form.schema[schemaName];
        if (!fieldSchema.writable && !noWarnings) {
          this.halNotification.showEditingBlockedError(fieldSchema.name || fieldName);
          this.closeEditFields([fieldName]);
        }
      })
      .catch((error:any) => {
        console.error('Failed to build edit field: %o', error);
        this.halNotification.handleRawError(error, this.resource);
        this.closeEditFields([fieldName]);
      });
  }

  private renderField(fieldName:string, schema:IFieldSchema):Promise<EditFieldHandler> {
    const promise:Promise<EditFieldHandler> = this.editContext.activateField(this,
      schema,
      fieldName,
      this.errorsPerAttribute[fieldName] || []);

    return promise
      .then((fieldHandler:EditFieldHandler) => {
        this.activeFields[fieldName] = fieldHandler;
        return fieldHandler;
      })
      .catch((error) => {
        console.error('Failed to render edit field:' + error);
        this.halNotification.handleRawError(error);
      });
  }
}
