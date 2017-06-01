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

import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {SchemaResource} from "../../api/api-v3/hal-resources/schema-resource.service";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {ContextMenuService} from "../../context-menus/context-menu.service";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";
import {WorkPackageEditFormController} from "./../wp-edit-form.directive";
import {EditField} from "./wp-edit-field.module";
import {WorkPackageEditFieldService} from "./wp-edit-field.service";
import {WorkPackageNotificationService} from '../wp-notification.service';

export class WorkPackageEditFieldController {
  public formCtrl: WorkPackageEditFormController;
  public fieldForm: ng.IFormController;
  public fieldName: string;
  public fieldType: string;
  public fieldIndex: number;
  public fieldLabel: string;
  public field: EditField;
  public errorenous: boolean;
  public errors: Array<string>;
  public workPackage: WorkPackageResource;

  protected _active: boolean = false;
  protected _activated_at:any;
  protected _hasFocus: boolean = false;
  protected _forceFocus: boolean = false;

  // Since we load the schema asynchronously
  // all fields are initially viewed as uneditable until it is loaded
  protected _editable: boolean = false;

  private __d__inplaceEditReadValue: JQuery;

  constructor(protected wpEditField: WorkPackageEditFieldService,
              protected $scope:ng.IScope,
              protected $element:ng.IAugmentedJQuery,
              protected $timeout:ng.ITimeoutService,
              protected $q:ng.IQService,
              protected FocusHelper:any,
              protected NotificationsService:any,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected ConfigurationService:any,
              protected contextMenu:ContextMenuService,
              protected wpCacheService: WorkPackageCacheService,
              protected ENTER_KEY:any,
              protected I18n:op.I18n) {

  }

  public get active() {
    return this._active;
  }

  public get htmlId() {
    return 'wp-' +
      this.formCtrl.workPackage.id +
      '-inline-edit--field-' +
      this.fieldName;
  }

  public submit() {
    this.formCtrl.onFieldSubmit()
      .finally(() => {
        this.deactivate();
        this._forceFocus = true;
        this.focusField();
      });
  }

  public deactivate() {
    this._forceFocus = false;
    this._activated_at = null;
    return this._active = false;
  }

  public activate(forceFocus = false) {
    this._forceFocus = forceFocus;

    let alreadyActive = this._active;

    return this.buildEditField().then(() => {

      // This timeout is necessary as the value is not always expanded otherwise
      this._active = this.field.schema.writable;

      if (this._active && (!alreadyActive || this.errorenous)) {
        this._activated_at = Date.now();
        this.focusField();
      }

      return this._active;
    });
  }

  public initializeField() {
    // Mark the td field if it is inline-editable
    // We're resolving the non-form schema here since its loaded anyway for the table
    const fieldSchema = this.workPackage.schema[this.fieldName];

    this.editable = fieldSchema && fieldSchema.writable && fieldSchema.visibility !== 'hidden';
    this.fieldType = fieldSchema && this.wpEditField.fieldType(fieldSchema.type);

    this.updateDisplayAttributes();

    if (fieldSchema) {
      this.fieldLabel = this.fieldLabel || fieldSchema.name;

      // Activate field when creating a work package
      // and the schema requires this field
      if (this.workPackage.isNew && this.isRequired() && !this.workPackage[this.fieldName]) {
        this.activate();

        var activeField = this.formCtrl.firstActiveField;
        if (!activeField || this.formCtrl.fields[activeField].fieldIndex > this.fieldIndex) {
          this.formCtrl.firstActiveField = this.fieldName;
        }
      }

      // Activate the field automatically when in editAllMode
      if (this.inEditMode && this.isEditable) {
        // Set focus on the first field
        if (this.fieldName === 'subject')
          this.activate(true);
          this.activate();
      }
    }
  }

  public activateIfEditable(event:JQueryEventObject) {
    if (this.isEditable) {
      this.handleUserActivate();
    }

    this.contextMenu.close();
    event.stopImmediatePropagation();
  }


  public get isEditable(): boolean {
    return this._editable && this.workPackage.isEditable;
  }

  public get inEditMode(): boolean {
    return this.formCtrl.inEditMode;
  }

  public isRequired(): boolean {
    return this.workPackage.schema[this.fieldName].required;
  }

  public isEmpty(): boolean {
    return !this.workPackage[this.fieldName];
  }

  public isChanged(): boolean {
    return this.workPackage.$pristine[this.fieldName] !== this.workPackage[this.fieldName];
  }

  public isErrorenous(): boolean {
    return this.errorenous;
  }

  public isSubmittable(): boolean {
    return !(this.inEditMode ||
             (this.isRequired() && this.isEmpty()) ||
             (this.isErrorenous() && !this.isChanged()) ||
             this.workPackage.inFlight);
  }

  public get errorMessageOnLabel(): string {
    if (_.isEmpty(this.errors)) {
      return '';
    }
    else {
      return this.I18n.t('js.inplace.errors.messages_on_field',
                         { messages: this.errors.join(' ') });
    }
  }

  public set editable(enabled: boolean) {
    this._editable = enabled;
  }

  public hasFocus() {
    return this.active && this._hasFocus;
  }

  public shouldFocus() {
    return this._forceFocus || this.formCtrl.firstActiveField === this.fieldName;
  }

  public focusField() {
    this.$timeout(_ => this.$scope.$broadcast('updateFocus'));
  }

  public handleUserActivate() {
    this.activate(true).then((active) => {
      // Display a generic error if the field turns out not to be editable,
      // despite the field being editable.
      if (this.isEditable && !active) {
        this.wpNotificationsService.showEditingBlockedError(this.field.displayName);
      }
    });
  }

  public handleUserSubmit() {
    if (this.inEditMode) {
      return this.formCtrl.updateForm();
    }

    return this.submit();
  }

  /**
   * Handle users pressing enter inside an edit mode.
   * Outside an edit mode, the regular save event is captured by handleUserSubmit (submit event).
   * In an edit mode, we can't derive from a submit event wheteher the user pressed enter
   * (and on what field he did that).
   */
  public handleUserSubmitOnEnter(event:JQueryEventObject) {
    if (this.inEditMode && event.which === this.ENTER_KEY) {
      return this.submit();
    }
  }

  public handleUserFocus() {
    this._hasFocus = true;
  }

  public handleUserBlur():void {
    // HACK: Firefox keeps emitting a blur event soon after an edit field has been opened
    if (this._activated_at && (Date.now() - this._activated_at) < 200) {
      console.log("Field received blur soon after opening. Ignoring.");
      return;
    }

    this._hasFocus = false;

    if (this.isSubmittable()) {
      this.deactivate();
      this.handleUserSubmit();
    }
  }

  public handleUserCancel() {
    if (!this.active || this.inEditMode) {
      return;
    }

    // Close the field
    this.reset();

    // Keep focus on read value
    this._forceFocus = true;
    this.focusField();
  }

  /**
   *  Avoid clicks within the form to bubble up to the row handler.
   *  Otherwise, clicks within wp-edit-fields may cause the split / full view to open.
   */
  public haltUserFormClick(event:JQueryEventObject) {
    event.stopPropagation();
    return false;
  }

  public setErrors(errors:any) {
    this.errorenous = !_.isEmpty(errors);
    this.errors = errors;
  }

  public reset() {
    this.workPackage.restoreFromPristine(this.fieldName);
    delete this.workPackage.$pristine[this.fieldName];
    this.fieldForm.$setPristine();
    this.deactivate();
  }

  public onlyInAccessibilityMode(callback:Function) {
    if (this.ConfigurationService.accessibilityModeEnabled()) {
      callback.apply(this);
    }
  }

  protected buildEditField(): ng.IPromise<any> {
    return this.workPackage.loadFormSchema().then((schema:SchemaResource) => {
      this.field = <EditField>this.wpEditField.getField(this.workPackage, this.fieldName, schema[this.fieldName]);
      this.workPackage.storePristine(this.fieldName);
    });
  }

  protected updateDisplayAttributes() {
    this.__d__inplaceEditReadValue = this.__d__inplaceEditReadValue || this.$element.find(".__d__inplace-edit--read-value");

    // Unfortunately, ID fields are Edit fields at the moment
    // and we need to treat them differently
    const isIDField = this.fieldName === 'id';

    // Usability: Highlight non-editable fields
    const readOnly = !(this.isEditable || isIDField );
    this.__d__inplaceEditReadValue.toggleClass("-read-only", readOnly);

    // Accessibility: Mark editable fields as button role
    const role = this.isEditable ? 'button' : '';
    this.__d__inplaceEditReadValue.attr("role", role);

    // Accessibility: Allow tab on all fields except id
    const tabIndex = isIDField ? -1 : 0;
    this.__d__inplaceEditReadValue.attr("tabindex", tabIndex);
  }
}

function wpEditField(wpCacheService: WorkPackageCacheService) {

  function wpEditFieldLink(scope:any,
                           element:ng.IAugmentedJQuery,
                           attrs:ng.IAttributes,
                           controllers: [WorkPackageEditFormController, WorkPackageEditFieldController]) {

    var formCtrl = controllers[0];
    controllers[1].formCtrl = formCtrl;

    formCtrl.registerField(scope.vm);
    scopedObservable(
      scope,
      wpCacheService.loadWorkPackage(formCtrl.workPackage.id).values$())
      .subscribe((wp: WorkPackageResource) => {
        scope.vm.workPackage = wp;
        scope.vm.initializeField();
      });

    element.addClass(scope.vm.fieldName);
    element.keyup(event => {
      if (event.keyCode === 27) {
        scope.$evalAsync(() => {
          scope.vm.handleUserCancel(true);
        });
      }
    });
  }

  return {
    restrict: 'A',
    templateUrl: '/components/wp-edit/wp-edit-field/wp-edit-field.directive.html',
    transclude: true,

    scope: {
      fieldName: '=wpEditField',
      fieldLabel: '=?wpEditFieldLabel',
      fieldIndex: '=',
      columns: '=',
      wrapperClasses: '=wpEditFieldWrapperClasses',
      displayPlaceholder: '=?',
      displayClasses: '=?',
    },

    require: ['^wpEditForm', 'wpEditField'],
    link: wpEditFieldLink,

    controller: WorkPackageEditFieldController,
    controllerAs: 'vm',
    bindToController: true
  };
}

//TODO: Use 'openproject.wpEdit' module
angular
  .module('openproject')
  .directive('wpEditField', wpEditField);
