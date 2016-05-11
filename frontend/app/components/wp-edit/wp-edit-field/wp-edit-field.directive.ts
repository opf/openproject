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


export class WorkPackageEditFieldController {
  public formCtrl: WorkPackageEditFormController;
  public fieldForm:ng.IFormController;
  public fieldName:string;
  public fieldType:string;
  public fieldIndex:number;
  public field:Field;
  public errorenous:boolean;
  protected pristineValue:any;

  protected _active:boolean = false;
  protected _forceFocus:boolean = false;

  // Since we load the schema asynchronously
  // all fields are initially viewed as editable until it is loaded
  protected _editable:boolean = true;

  constructor(
    protected wpEditField:WorkPackageEditFieldService,
    protected $scope,
    protected $element,
    protected $timeout,
    protected FocusHelper,
    protected NotificationsService,
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
      return;
    }

    this.formCtrl.updateWorkPackage()
      .then(() => this.deactivate());
  }

  public activate() {
    if (this._active) {
      this.focusField();
      return;
    }

    this.expandField().then((active) => {
      // Display a generic error if the field turns out not to be editable,
      // despite the field being editable.
      if (this.isEditable && !active) {
        this.NotificationsService.addError(this.I18n.t(
          'js.work_packages.error_edit_prohibited',
          { attribute: this.field.schema.name }
        ));
      }

      this.focusField();
    });
  }

  public expandField() {
    return this.buildEditField().then(() => {
      this._active = this.field.schema.writable;
      return this._active;
    });
  }

  public activateIfEditable() {
    if (this.isEditable) {
      this.activate();
    }
  }

  public initializeField() {
    // Activate field when creating a work package
    // and the schema requires this field
    if (this.workPackage.isNew && this.workPackage.requiredValueFor(this.fieldName)) {
      this.activate();

      var activeField = this.formCtrl.firstActiveField;
      if (!activeField || this.formCtrl.fields[activeField].fieldIndex > this.fieldIndex) {
        this.formCtrl.firstActiveField = this.fieldName;
      }
    }

    // Mark the td field if it is inline-editable
    // We're resolving the non-form schema here since its loaded anyway for the table
    this.workPackage.schema.$load().then(schema => {
      var fieldSchema = schema[this.fieldName];

      this.editable = fieldSchema && fieldSchema.writable;
      this.fieldType = fieldSchema && this.wpEditField.fieldType(fieldSchema.type);
    });
  }

  public get isEditable():boolean {
    return this._editable && this.workPackage.isEditable;
  }

  public get inEditMode():boolean {
    return this.formCtrl.inEditMode;
  }

  public set editable(enabled:boolean) {
    this._editable = enabled;
    this.$element.toggleClass('-editable', !!enabled);
  }

  public shouldFocus() {
    return this._forceFocus ||
           !this.workPackage.isNew ||
           this.formCtrl.firstActiveField === this.fieldName;
  }

  public focusField() {
    this.$timeout(_ => this.$scope.$broadcast('updateFocus'));
  }

  public deactivate():boolean {
    if (this.inEditMode) {
      return true;
    }

    this._forceFocus = false;
    return this._active = false;
  }

  public setErrorState(error = true) {
    this.errorenous = error;
    this.$element.toggleClass('-error', error);
  }


  public reset(focus = false) {
    this.workPackage[this.fieldName] = this.pristineValue;
    this.fieldForm.$setPristine();
    this.deactivate();
    this.pristineValue = null;

    if (focus) {
      this.focusField();
    }
  }

  protected buildEditField():ng.IPromise<any> {
    return this.formCtrl.loadSchema().then(schema => {
      this.field = this.wpEditField.getField(
        this.workPackage, this.fieldName, schema[this.fieldName]);
        this.pristineValue = angular.copy(this.workPackage[this.fieldName]);
    });
  }

}

function wpEditFieldLink(
  scope,
  element,
  attrs,
  controllers: [WorkPackageEditFormController, WorkPackageEditFieldController],
  $timeout) {

  controllers[1].formCtrl = controllers[0];
  controllers[1].formCtrl.registerField(scope.vm);

  scope.vm.initializeField();

  element.addClass(scope.vm.fieldName);
  element.keyup(event => {
    if (event.keyCode === 27) {
      scope.$evalAsync(() => {
        scope.vm.reset(true);
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
      fieldLabel: '=wpEditFieldLabel',
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
