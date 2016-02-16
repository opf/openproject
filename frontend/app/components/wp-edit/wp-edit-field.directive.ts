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

import {FieldFactory} from "./wp-edit-field.module";
import {WorkPackageEditFormController} from "./wp-edit-form.directive";


export class WorkPackageEditFieldController {
  public formCtrl: WorkPackageEditFormController;
  public fieldName:string;
  public field:op.EditField;

  protected _workPackage:op.WorkPackage;
  protected _active:boolean = false;

  public get workPackage() {
    return this.formCtrl.workPackage;
  }

  public get active() {
    return this._active;
  }

  public submit() {
    this.deactivate();
    this.formCtrl.updateWorkPackage();
  }

  public activate() {
    this.setupField().then(() => {
      this._active = this.field.schema.writable;
    });
  }

  public deactivate():boolean {
    return this._active = false;
  }

  protected setupField():ng.IPromise {
    return this.formCtrl.loadSchema().then(schema =>  {
      this.field = FieldFactory.create(
        this.workPackage, this.fieldName, schema[this.fieldName]);
    });
  }
}

function wpEditFieldLink(scope:ng.IScope,
                         element:ng.IAugmentedJQueryStatic,
                         attrs:ng.IAttributes,
                         controllers:
                           [WorkPackageEditFormController, WorkPackageEditFieldController]) {

  controllers[1].formCtrl = controllers[0];
}

function wpEditField() {
  return {
    restrict: 'A',
    templateUrl: '/components/wp-edit/wp-edit-field.directive.html',
    transclude: true,

    scope: {
      fieldName: '=wpEditField'
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
