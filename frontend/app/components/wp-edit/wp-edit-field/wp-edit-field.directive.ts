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

import {WorkPackageEditFormController} from "./../wp-edit-form.directive";
import {WorkPackageEditFieldService} from "./wp-edit-field.service";
import {Field} from "./wp-edit-field.module";
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {WorkPackageCacheService} from "../../work-packages/work-package-cache.service";


export class WorkPackageEditFieldController {
  public formCtrl: WorkPackageEditFormController;
  public fieldForm: ng.IFormController;
  public fieldName: string;
  public fieldType: string;
  public fieldIndex: number;
  public fieldLabel: string;
  public field: Field;
  public errorenous: boolean;

  protected _active: boolean = false;
  protected _forceFocus: boolean = false;

  // Since we load the schema asynchronously
  // all fields are initially viewed as editable until it is loaded
  protected _editable: boolean = false;

  constructor(protected wpEditField: WorkPackageEditFieldService,
              protected $scope,
              protected $element,
              protected $timeout,
              protected $q,
              protected FocusHelper,
              protected NotificationsService,
              protected wpCacheService: WorkPackageCacheService,
              protected I18n) {

  }

  public get workPackage() {
    return this.formCtrl.workPackage;
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
    if (this.inEditMode) {
      return this.formCtrl.updateForm();
    }

    this.formCtrl.updateWorkPackage()
      .finally(() => this.deactivate());
  }

  public deactivate() {
    this._forceFocus = false;
    return this._active = false;
  }

  public activate(forceFocus = false) {
    this._forceFocus = forceFocus;

    return this.buildEditField().then(() => {
      this._active = this.field.schema.writable;
      if (this._active) {
        this.focusField();
      }
      return this._active;
    });
  }

  public initializeField(wp) {
    // Activate field when creating a work package
    // and the schema requires this field
    if (wp.isNew && this.workPackage.requiredValueFor(this.fieldName)) {
      this.activate();

      var activeField = this.formCtrl.firstActiveField;
      if (!activeField || this.formCtrl.fields[activeField].fieldIndex > this.fieldIndex) {
        this.formCtrl.firstActiveField = this.fieldName;
      }
    }

    // Mark the td field if it is inline-editable
    // We're resolving the non-form schema here since its loaded anyway for the table
    wp.schema.$load().then(schema => {
      var fieldSchema = schema[this.fieldName];

      this.editable = fieldSchema && fieldSchema.writable;
      this.fieldType = fieldSchema && this.wpEditField.fieldType(fieldSchema.type);

      if (fieldSchema) {
        this.fieldLabel = this.fieldLabel || fieldSchema.name;

        // Activate the field automatically when in editAllMode
        if (this.inEditMode && this.isEditable) {
          this.activate();
        }
      }
    });
  }

  public get isEditable(): boolean {
    return this._editable && this.workPackage.isEditable;
  }

  public get inEditMode(): boolean {
    return this.formCtrl.inEditMode;
  }

  public set editable(enabled: boolean) {
    this._editable = enabled;
    this.$element.toggleClass('-editable', !!enabled);
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
        this.NotificationsService.addError(this.I18n.t(
          'js.work_packages.error_edit_prohibited',
          {attribute: this.field.schema.name}
        ));
      }
    });
  }

  public handleUserBlur(): boolean {
    if (this.inEditMode) {
      return;
    }

    this.deactivate();

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
  public haltUserFormClick(event) {
    event.stopPropagation();
    return false;
  }

  public setErrorState(error = true) {
    this.errorenous = error;
    this.$element.toggleClass('-error', error);
  }

  public reset() {
    this.workPackage.restoreFromPristine(this.fieldName);
    this.fieldForm.$setPristine();
    this.deactivate();
  }

  protected buildEditField(): ng.IPromise<any> {
    return this.formCtrl.loadSchema().then(schema => {
      this.field = this.wpEditField.getField(this.workPackage, this.fieldName, schema[this.fieldName]);
      this.workPackage.storePristine(this.fieldName);
    });
  }

}

function wpEditFieldLink(scope,
                         element,
                         attrs,
                         controllers: [WorkPackageEditFormController, WorkPackageEditFieldController]) {

  var formCtrl = controllers[0];
  controllers[1].formCtrl = formCtrl;

  formCtrl.registerField(scope.vm);
  formCtrl.onWorkPackageUpdated('wp-edit-field-' + scope.vm.fieldName, (wp) => {
    scope.vm.initializeField(wp);
  });

  if (scope.vm.workPackage) {
    scope.vm.initializeField(scope.vm.workPackage);
  }

  element.addClass(scope.vm.fieldName);
  element.keyup(event => {
    if (event.keyCode === 27) {
      scope.$evalAsync(() => {
        scope.vm.handleUserCancel(true);
      });
    }
  });
}

function wpEditField() {
  return {
    restrict: 'A',
    templateUrl: '/components/wp-edit/wp-edit-field/wp-edit-field.directive.html',
    transclude: true,

    scope: {
      fieldName: '=wpEditField',
      fieldLabel: '=?wpEditFieldLabel',
      fieldIndex: '=',
      columns: '=',
      wrapperClasses: '=wpEditFieldWrapperClasses'
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
