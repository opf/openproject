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
  public formCtrl:WorkPackageEditFormController;
  public fieldName:string;
  public field:Field;

  protected _active:boolean = false;

  constructor(protected wpEditField:WorkPackageEditFieldService, protected QueryService) {
  }

  public get workPackage() {
    return this.formCtrl.workPackage;
  }

  public get active() {
    return this._active;
  }

  public submit() {
    this.formCtrl.updateWorkPackage()
      .then(() => this.deactivate())
      .catch(missingFields => {
        var selected = this.QueryService.getSelectedColumnNames();
        missingFields.map(field => {
          var name = field.details.attribute;
          if (selected.indexOf(name) === -1) {
            selected.push(name);
          }
        })

        this.QueryService.setSelectedColumns(selected);
      });
  }

  public activate() {
    this.setupField().then(() => {
      this._active = this.field.schema.writable;
    });
  }

  public get isEditable():boolean {
    return this.isSupportedField && this.workPackage.isEditable;
  }

  public deactivate():boolean {
    return this._active = false;
  }

  protected setupField():ng.IPromise<any> {
    return this.formCtrl.loadSchema().then(schema => {
      this.field = this.wpEditField.getField(
        this.workPackage, this.fieldName, schema[this.fieldName]);
    });
  }

  // This method is temporarily needed to control which fields
  // we support for inline editing. Once all fields are supported,
  // the method is to be removed.
  private get isSupportedField():boolean {
    return ['subject',
        'priority',
        'type',
        'status',
        'assignee',
        'responsible',
        'version',
        'category'].indexOf(this.fieldName) !== -1
  }
}

function wpEditFieldLink(scope, element, attrs, controllers:[WorkPackageEditFormController, WorkPackageEditFieldController]) {

  controllers[1].formCtrl = controllers[0];

  element.click(event => {
    event.stopImmediatePropagation();
  });
}

function wpEditField() {
  return {
    restrict: 'A',
    templateUrl: '/components/wp-edit/wp-edit-field/wp-edit-field.directive.html',
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
