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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApplicationRef, Injector } from '@angular/core';
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
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { HalResourceEditFieldHandler } from 'core-app/shared/components/fields/edit/field-handler/hal-resource-edit-field-handler';
import { EditActivationCancelled } from './edit-activation-cancelled';
import { ISchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';

export const activeFieldContainerClassName = 'inline-edit--active-field';
export const activeFieldClassName = 'inline-edit--field';

export abstract class EditForm<T extends HalResource = HalResource> {
  // Injections
  @LazyInject() states:States;

  @LazyInject() halEditing:HalResourceEditingService;

  @LazyInject() halNotification:HalResourceNotificationService;

  @LazyInject() halEvents:HalEventsService;

  // All current active (open) edit fields
  public activeFields:Record<string, EditFieldHandler> = {};

  // Errors of the last operation (required when adding opening fields afterwards)
  public errorsPerAttribute:Record<string, string[]> = {};

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

  // eslint-disable-next-line @typescript-eslint/class-literal-property-style -- Forms override this lifetime check.
  protected get activationCancelled():boolean {
    return false;
  }

  protected assertActivationActive():void {
    if (this.activationCancelled) throw new EditActivationCancelled();
  }

  /**
   * Return whether this form has any active fields
   */
  public hasActiveFields():boolean {
    return Object.keys(this.activeFields).length > 0;
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
  public async activate(fieldName:string, noWarnings = false):Promise<void|EditFieldHandler> {
    try {
      this.assertActivationActive();
      const notification = this.halNotification;
      const schema = await this.loadFieldSchema(fieldName, noWarnings);
      this.assertActivationActive();
      if (!schema.writable && !noWarnings) {
        notification.showEditingBlockedError(schema.name || fieldName);
        throw new Error(`Field ${fieldName} is not writable`);
      }
      return await this.renderField(fieldName, schema);
    } catch (error:unknown) {
      if (error instanceof EditActivationCancelled) return;
      throw error;
    }
  }

  /**
   * Activate the field unless it is marked active already
   * (e.g., already being activated).
   */
  public async activateWhenNeeded(fieldName:string):Promise<unknown> {
    try {
      this.assertActivationActive();
      if (this.activeFields[fieldName]) return;
      await this.requireVisible(fieldName);
      this.assertActivationActive();
      return await this.activate(fieldName, true);
    } catch (error:unknown) {
      if (error instanceof EditActivationCancelled) return;
      throw error;
    }
  }

  /**
   * Activate all fields that are returned in validation errors
   */
  public async activateMissingFields():Promise<unknown[]> {
    if (this.activationCancelled) return [];
    return this.change.getForm().then((form:FormResource) => {
      if (this.activationCancelled) return [];
      const activateFields:Promise<unknown>[] = [];

      Object.entries(form.validationErrors ?? {}).forEach(([key]) => {
        if (key === 'id') {
          return;
        }
        activateFields.push(this.activateWhenNeeded(key));
      });

      return Promise.all(activateFields);
    });
  }

  /**
   * Save the active changeset.
   * @return {any}
   */
  public async submit():Promise<T> {
    const change = this.change;
    const resource = this.resource;
    if (change.isEmpty() && !isNewResource(resource)) {
      if (!this.activationCancelled) this.closeEditFields();
      return resource;
    }

    // Retain request dependencies before any field or submission await.
    const editing = this.halEditing;
    const notification = this.halNotification;
    const application = this.injector.get(ApplicationRef);

    change.inFlight = true;
    this.notifyActiveFieldStateChanged();
    change.validateCustomFields = true;
    this.errorsPerAttribute = {};
    const openFields = Object.keys(this.activeFields);
    await Promise.all(Object.values(this.activeFields).map((handler:EditFieldHandler) => handler.onSubmit()));

    return new Promise<T>((resolve, reject) => {
      editing.save<T, ResourceChangeset<T>>(change)
        .then((result) => {
          if (!this.activationCancelled) this.closeEditFields(openFields);
          resolve(result.resource);
          notification.showSave(result.resource, result.wasNew);
          if (!this.activationCancelled) {
            this.editMode = false;
            this.onSaved(result);
          }
          change.inFlight = false;
        })
        .catch((error:unknown) => {
          change.inFlight = false;
          change.validateCustomFields = false;
          this.notifyActiveFieldStateChanged();
          notification.handleRawError(error, resource);
          if (!this.activationCancelled) {
            if (error instanceof HalError && error.resource) this.handleSubmissionErrors(error.resource);
            application.tick();
          }
          reject(error instanceof Error ? error : new Error('Edit form submission failed.'));
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
      fields = Object.keys(this.activeFields);
    }

    fields.forEach((name:string) => {
      const handler = this.activeFields[name];
      handler?.deactivate(false);

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
    if (this.activationCancelled) return;
    const application = this.injector.get(ApplicationRef);
    // Immediately set errors on already-active fields (synchronous, no polling needed).
    // This handles the common case where the field is already open when the 422 arrives.
    erroneousFields.forEach((fieldName:string) => {
      if (this.activeFields[fieldName]) {
        this.activeFields[fieldName].setErrors(this.errorsPerAttribute[fieldName] || []);
      }
    });

    // Activate any fields that are not yet visible / open (e.g. required custom fields).
    const promises:Promise<unknown>[] = erroneousFields.map((fieldName:string) => this.activateWhenNeeded(fieldName));

    Promise.all(promises)
      .then(() => {
        // Run CD again after any newly required fields are activated so their
        // portal bindings reflect the reset inFlight state in zoneless mode.
        queueMicrotask(() => {
          if (this.activationCancelled) return;
          application.tick();
          this.focusOnFirstError();
        });
      })
      .catch((error:unknown) => {
        if (error instanceof EditActivationCancelled) return;
        console.error('Failed to activate all erroneous fields.');
      });
  }

  /**
   * Load the resource form to get the current field schema with all
   * values loaded.
   * @param fieldName
   */
  protected loadFieldSchema(fieldName:string, noWarnings = false):Promise<IFieldSchema> {
    const notification = this.halNotification;
    return this.getFormFieldSchema(fieldName).then((fieldSchema) => {
      this.assertActivationActive();
      if (!fieldSchema) {
        this.closeEditFields([fieldName]);

        throw new Error();
      }

      if (!fieldSchema.writable && !noWarnings) {
        notification.showEditingBlockedError(fieldSchema.name || fieldName);
        this.closeEditFields([fieldName]);
      }

      return fieldSchema;
    });
  }

  /**
   * Load the form and return the field schema, reloading the form once if the schema is
   * not present in the cached version (e.g. after a type change).
   * Returns null if the schema is still absent after a forced reload.
   * @param fieldName
   */
  private getFormFieldSchema(fieldName:string):Promise<IFieldSchema|null> {
    const change = this.change;
    const notification = this.halNotification;
    // Sync fast path: whatever schema the changeset currently exposes (form-derived if
    // loaded, otherwise the pristine resource's cached schema) usually contains the
    // field. Returning it synchronously lets the field activate without waiting on the
    // form request — required by Capybara specs whose activate! check has a tight
    // timeout, and by tests that intentionally disable AJAX before activating a field.
    const cachedSchema = (change.schema as ISchemaProxy).ofProperty(fieldName);
    if (cachedSchema) {
      // Still kick off the form load (or piggy-back on an in-flight one) so the form's
      // defaults, allowed values, and projected payload are populated for subsequent
      // edits/submissions. We don't await it, but we do surface any error (e.g. a 409
      // lock-version conflict when the resource was modified elsewhere) through the
      // same notification path the awaited code-path uses — otherwise the user would
      // open the editor without ever being told their copy is stale.
      change.getForm().catch((error:unknown) => {
        console.error('Background form load failed for %s: %o', fieldName, error);
        notification.handleRawError(error, this.resource);
      });
      return Promise.resolve(cachedSchema);
    }

    // Cached schema doesn't know about this field. Either the form hasn't been loaded
    // at all, or the cached form is stale (e.g. the work package type was just changed
    // and the new type's custom fields aren't in the cached form yet). Load the form,
    // then retry; if still missing, force a full reload once.
    return change.getForm()
      .then(():Promise<IFieldSchema|null> => {
        this.assertActivationActive();
        const fieldSchema:IFieldSchema|null = (change.schema as ISchemaProxy).ofProperty(fieldName);
        if (fieldSchema) {
          return Promise.resolve(fieldSchema);
        }

        return change.getForm(true).then(
          ():IFieldSchema|null => {
            this.assertActivationActive();
            return (change.schema as ISchemaProxy).ofProperty(fieldName);
          },
        );
      })
      .catch((error:unknown) => {
        if (error instanceof EditActivationCancelled) throw error;
        console.error('Failed to build edit field: %o', error);
        notification.handleRawError(error, this.resource);
        return null;
      });
  }

  private renderField(fieldName:string, schema:IFieldSchema):Promise<void|EditFieldHandler> {
    this.assertActivationActive();
    const notification = this.halNotification;
    const promise:Promise<EditFieldHandler> = this.activateField(this,
      schema,
      fieldName,
      this.errorsPerAttribute[fieldName] || []);

    return promise
      .then((fieldHandler:EditFieldHandler) => {
        this.assertActivationActive();
        this.activeFields[fieldName] = fieldHandler;
        return fieldHandler;
      })
      .catch((error:unknown) => {
        if (error instanceof EditActivationCancelled) return;
        console.error(`Failed to render edit field:${String(error)}`);
        notification.handleRawError(error);
      });
  }

  private notifyActiveFieldStateChanged():void {
    if (this.activationCancelled) return;
    Object.values(this.activeFields).forEach((handler) => {
      if (handler instanceof HalResourceEditFieldHandler) {
        handler.notifyStateChanged();
      }
    });
  }
}
