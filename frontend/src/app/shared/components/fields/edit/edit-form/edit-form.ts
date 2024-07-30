//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injector } from '@angular/core';
import { States } from 'core-app/core/states/states.service';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import {
  HalResourceEditingService,
  ResourceChangesetCommit,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ResourceChangeset } from 'core-app/shared/components/fields/changeset/resource-changeset';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { HalError } from 'core-app/features/hal/services/hal-error';

export const activeFieldContainerClassName = 'inline-edit--active-field';
export const activeFieldClassName = 'inline-edit--field';

export abstract class EditForm<T extends HalResource = HalResource> {
  // Injections
  @InjectField() states:States;

  @InjectField() halEditing:HalResourceEditingService;

  @InjectField() halNotification:HalResourceNotificationService;

  @InjectField() halEvents:HalEventsService;

  // All current active (open) edit fields
  public activeFields:{ [fieldName:string]:EditFieldHandler } = {};

  // Errors of the last operation (required when adding opening fields afterwards)
  public errorsPerAttribute:{ [fieldName:string]:string[] } = {};

  // Reference to the changeset used in this form
  public resource:T;

  // Whether this form exists in edit mode
  public editMode = false;

  protected constructor(public injector:Injector) {
  }

  /**
   * Activate the field, returning the element and associated field handler
   */
  protected abstract activateField(form:EditForm, schema:IFieldSchema, fieldName:string, errors:string[]):Promise<EditFieldHandler>;

  /**
   * Show this required field. E.g., add the necessary column
   */
  protected abstract requireVisible(fieldName:string):Promise<void>;

  /**
   * Reset the field and re-render the current resource's value
   */
  abstract reset(fieldName:string, focus?:boolean):void;

  /**
   * Optional callback when the form is being saved
   */
  protected onSaved(commit:ResourceChangesetCommit):void {
    // Does nothing by default
  }

  protected abstract focusOnFirstError():void;

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
  public get change():ResourceChangeset<T> {
    return this.halEditing.changeFor(this.resource);
  }

  /**
   * Active the edit field upon user's request.
   * @param fieldName
   * @param noWarnings Ignore warnings if the field cannot be opened
   */
  public activate(fieldName:string, noWarnings = false):Promise<void|EditFieldHandler> {
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

    return this.requireVisible(fieldName).then(() => this.activate(fieldName, true));
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
  public async submit():Promise<T> {
    if (this.change.isEmpty() && !isNewResource(this.resource)) {
      this.closeEditFields();
      return Promise.resolve(this.resource);
    }

    // Mark changeset as in flight
    this.change.inFlight = true;

    // Reset old error notifications
    this.errorsPerAttribute = {};

    // Notify all fields of upcoming save
    const openFields = _.keys(this.activeFields);

    // Call onSubmit handlers
    await Promise.all(_.map(this.activeFields, (handler:EditFieldHandler) => handler.onSubmit()));

    return new Promise<T>((resolve, reject) => {
      this.halEditing.save<T, ResourceChangeset<T>>(this.change)
        .then((result) => {
          // Close all current fields
          this.closeEditFields(openFields);

          resolve(result.resource);

          this.halNotification.showSave(result.resource, result.wasNew);
          this.editMode = false;
          this.onSaved(result);
          this.change.inFlight = false;
        })
        .catch((error:ErrorResource|unknown) => {
          this.halNotification.handleRawError(error, this.resource);

          if (error instanceof HalError && error.resource) {
            this.handleSubmissionErrors(error.resource);
            reject();
          }

          this.change.inFlight = false;

          return Promise.reject(error);
        });
    });
  }

  /**
   * Close the given or all open fields.
   *
   * @param {string[]} fields
   * @param resetChange whether to undo any changes made
   */
  public closeEditFields(fields:string[]|'all' = 'all', resetChange = true) {
    if (fields === 'all') {
      fields = _.keys(this.activeFields);
    }

    fields.forEach((name:string) => {
      const handler = this.activeFields[name];
      handler && handler.deactivate(false);

      if (resetChange) {
        this.change.reset(name);
      }
    });
  }

  protected handleSubmissionErrors(error:ErrorResource):void {
    // Process single API errors
    this.handleErroneousAttributes(error);
  }

  protected handleErroneousAttributes(error:ErrorResource):void {
    // Get attributes with errors
    const erroneousAttributes = error.getInvolvedAttributes();

    // Save erroneous fields for when new fields appear
    this.errorsPerAttribute = error.getMessagesPerAttribute();
    if (erroneousAttributes.length === 0) {
      return;
    }

    this.setErrorsForFields(erroneousAttributes);
  }

  private setErrorsForFields(erroneousFields:string[]) {
    // Accumulate errors for the given response
    const promises:Promise<any>[] = erroneousFields.map((fieldName:string) => this.requireVisible(fieldName).then(() => {
      if (this.activeFields[fieldName]) {
        this.activeFields[fieldName].setErrors(this.errorsPerAttribute[fieldName] || []);
      }

      return this.activateWhenNeeded(fieldName) as any;
    }));

    Promise.all(promises)
      .then(() => {
        setTimeout(() => this.focusOnFirstError());
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
  protected loadFieldSchema(fieldName:string, noWarnings = false):Promise<IFieldSchema> {
    return new Promise((resolve, reject) => {
      this.loadFormAndCheck(fieldName, noWarnings);
      const fieldSchema:IFieldSchema = this.change.schema.ofProperty(fieldName);

      if (!fieldSchema) {
        throw new Error();
      }

      resolve(fieldSchema);
    });
  }

  /**
   * Ensure the form gets loaded and we show an error when the field cannot be opened
   * @param fieldName
   * @param noWarnings
   */
  private loadFormAndCheck(fieldName:string, noWarnings = false) {
    // Ensure the form is being loaded if necessary
    this.change
      .getForm()
      .then(() => {
        // Look up whether we're actually editable
        const fieldSchema = this.change.schema.ofProperty(fieldName);
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

  private renderField(fieldName:string, schema:IFieldSchema):Promise<void|EditFieldHandler> {
    const promise:Promise<EditFieldHandler> = this.activateField(this,
      schema,
      fieldName,
      this.errorsPerAttribute[fieldName] || []);

    return promise
      .then((fieldHandler:EditFieldHandler) => {
        this.activeFields[fieldName] = fieldHandler;
        return fieldHandler;
      })
      .catch((error) => {
        console.error(`Failed to render edit field:${error}`);
        this.halNotification.handleRawError(error);
      });
  }
}
