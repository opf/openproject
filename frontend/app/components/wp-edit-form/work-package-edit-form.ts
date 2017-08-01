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
import {injectorBridge} from '../angular/angular-injector-bridge.functions';
import {ErrorResource} from '../api/api-v3/hal-resources/error-resource.service';
import {SchemaResource} from '../api/api-v3/hal-resources/schema-resource.service';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
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
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';
import {derive, InputState, State} from 'reactivestates';
import {Observable} from 'rxjs';

export const activeFieldContainerClassName = 'wp-inline-edit--active-field';
export const activeFieldClassName = 'wp-inline-edit--field';

export class WorkPackageEditForm {
  // Injections
  public $q:ng.IQService;
  public $timeout:ng.ITimeoutService;
  public $rootScope:ng.IRootScopeService;
  public states:States;
  public wpCacheService:WorkPackageCacheService;
  public wpEditField:WorkPackageEditFieldService;
  public wpNotificationsService:WorkPackageNotificationService;

  // All current active (open) edit fields
  public activeFields:{ [fieldName:string]:WorkPackageEditFieldHandler } = {};

  // Errors of the last operation (required when adding opening fields afterwards)
  public errorsPerAttribute:{ [fieldName:string]:string[] } = {};

  public editContext:WorkPackageEditContext;
  public editMode:boolean = false;

  // The work package cache service subscription
  protected wpSubscription:Subscription;
  protected formSubscription:Subscription;

  public static continue(state:InputState<WorkPackageEditForm>,
                         workPackage:WorkPackageResourceInterface,
                         editContext:WorkPackageEditContext,
                         editMode:boolean = false,
                         changeset?:WorkPackageChangeset) {
    if (!changeset) {
      changeset = new WorkPackageChangeset(workPackage);
    }

    let form:WorkPackageEditForm = state.value || new WorkPackageEditForm(workPackage, changeset);

    form.editContext = editContext;
    form.editMode = editMode;
    state.putValue(form);

    return form;
  }

  constructor(public workPackage:WorkPackageResourceInterface,
              public changeset:WorkPackageChangeset) {
    injectorBridge(this);

    this.wpSubscription = this.states.workPackages.get(workPackage.id)
      .values$()
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.workPackage = wp;
        this.changeset.workPackage = wp;
      });

    this.formSubscription = this.editState.values$().subscribe(() => {
      debugLog("Refreshing active edit fields after form update.");
      _.each(this.activeFields, (_handler, name) => this.refresh(name!));
    });
  }

  /**
   * Active the edit field upon user's request.
   * @param fieldName
   */
  public activate(fieldName:string, noWarnings:boolean = false):Promise<WorkPackageEditFieldHandler> {
    this.changeset.startEditing(fieldName);

    return this.buildField(fieldName).then((field:EditField) => {
      if (!field.writable && !noWarnings) {
        this.wpNotificationsService.showEditingBlockedError(field.displayName);
        return this.$q.reject();
      }

      return this.renderField(fieldName, field);
    });
  }

  public get editState():State<WorkPackageResourceInterface> {
    return derive(this.changeset.resource, $ =>
      $.map((v) => v || this.workPackage)
    );
  }

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
        this.activateWhenNeeded(key);
      });
    });
  }

  public submit() {
    if (this.changeset.empty) {
      return this.$q.when(this.workPackage);
    }

    const deferred = this.$q.defer();
    const isInitial = this.workPackage.isNew;

    // Reset old error notifcations
    this.errorsPerAttribute = {};

    const openFields = _.keys(this.activeFields);

    this.changeset.save()
      .then(savedWorkPackage => {
        this.workPackage = savedWorkPackage;

        // Close all current fields
        this.closeEditFields(openFields);

        deferred.resolve(savedWorkPackage);

        this.wpNotificationsService.showSave(savedWorkPackage, isInitial);
        this.editMode = false;
        this.editContext.onSaved(savedWorkPackage, isInitial);
      })
      .catch((error) => {
        this.wpNotificationsService.handleErrorResponse(error, this.workPackage);
        if (error instanceof ErrorResource) {
          this.handleSubmissionErrors(error, deferred);
        }
      });

    return deferred.promise;
  }

  public destroy() {
    // Close all edit fields
    this.closeEditFields();

    // Unsubscribe changes
    this.wpSubscription.unsubscribe();
    this.formSubscription.unsubscribe();

    // Destroy this form
    this.states.editing.get(this.workPackage.id).clear('Editing completed');
  }

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

    // Accumulate errors for the given response
    let promises:ng.IPromise<any>[] = erroneousAttributes.map((fieldName:string) => {
      return this.editContext.requireVisible(fieldName).then(() => {
        if (this.activeFields[fieldName]) {
          this.activeFields[fieldName].setErrors(this.errorsPerAttribute[fieldName] || []);
        }

        return this.activateWhenNeeded(fieldName) as any;
      });
    });

    this.$q.all(promises)
      .then(() => {
        // Focus the first field that is erroneous
        jQuery(`.${activeFieldContainerClassName}.-error .${activeFieldClassName}`)
          .first()
          .focus();
      })
      .catch(() => {
        console.error("Failed to activate all erroneous fields.");
      })
  }

  private buildField(fieldName:string):Promise<EditField> {
    return new Promise((resolve, reject) => {
      this.changeset.getForm()
        .then((form:FormResourceInterface) => {
            const fieldSchema = form.schema[fieldName];

            if (!fieldSchema) {
              return reject();
            }

            const field = this.wpEditField.getField(
              this.changeset,
              fieldName,
              fieldSchema
            ) as EditField;

            resolve(field);
          })
        .catch((error) => {
          console.error("Failed to build edit field:" + error);
          this.wpNotificationsService.handleRawError(error);
        });
    });
  }

  private renderField(fieldName:string, field:EditField):Promise<WorkPackageEditFieldHandler> {
    const promise = this.editContext.activateField(this,
      field,
      this.errorsPerAttribute[fieldName] || []);
    return promise
      .then((fieldHandler) => {
        this.activeFields[fieldName] = fieldHandler;
        return fieldHandler;
      })
      .catch((error) => {
        console.error("Failed to render edit field:" + error);
        this.wpNotificationsService.handleRawError(error);
      });
  }
}

WorkPackageEditForm.$inject = [
  'wpCacheService', '$timeout', '$q', '$rootScope',
  'wpEditField', 'wpNotificationsService',
  'states'
];
