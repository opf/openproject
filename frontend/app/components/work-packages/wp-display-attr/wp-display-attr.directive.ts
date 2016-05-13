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

import {HalResource} from "../../api/api-v3/hal-resources/hal-resource.service";
import {wpDirectivesModule} from "../../../angular-modules";
import {WorkPackageEditFieldController} from "../../wp-edit/wp-edit-field/wp-edit-field.directive";

export class WorkPackageDisplayAttributeController {
  public wpEditField:WorkPackageEditFieldController;
  public displayText:string;
  public isDisplayAsHtml:boolean = false;
  public displayType:string;
  public displayLink:string;
  public attribute:string;
  public placeholder:string;
  public placeholderOptional:string;
  public workPackage:any;
  public schema:HalResource;

  constructor(protected $scope:ng.IScope,
              protected I18n:op.I18n,
              protected PathHelper:any,
              protected WorkPackagesHelper:any) {

    this.placeholder = this.placeholderOptional ||
                         I18n.t('js.work_packages.placeholders.default');
    this.displayText = this.placeholder;

    $scope.$watch('$ctrl.workPackage.' + this.attribute, (newValue) => {
      if (angular.isDefined(newValue)) {
        this.updateAttribute();
      }
    });
  }

  public activateIfEditable(event) {
    if (this.wpEditField.isEditable) {
      this.wpEditField.handleUserActivate();
    }
    event.stopImmediatePropagation();
  }

  public isEditable() {
    return this.wpEditField && this.wpEditField.isEditable;
  };

  public get labelId():string {
    return 'wp-' + this.workPackage.id + '-display-attr-' + this.attribute + '-aria-label';
  }

  protected setDisplayType() {
    // TODO: alter backend so that percentageDone has the type 'Percent' already
    if (this.attribute === 'percentageDone') {
      this.displayType = 'Percent';
    }
    else if (this.attribute === 'id') {
      // Show a link to the work package for the ID
      this.displayType = 'SelfLink';
      this.displayLink = this.PathHelper.workPackagePath(this.workPackage.id);
    }
    else {
      this.displayType = this.schema[this.attribute].type;
    }
  }

  protected updateAttribute() {
    this.schema.$load().then(() => {
      const wpAttr:any = this.workPackage[this.attribute];

      if (this.workPackage.isNew && this.attribute === 'id') {
        this.displayText = '';
        return;
      }

      if (!wpAttr) {
        this.displayText = this.placeholder;
        return;
      }

      this.setDisplayType();

      var text = wpAttr.value || wpAttr.name || wpAttr;

      if (wpAttr.hasOwnProperty('html')) {
        this.isDisplayAsHtml = true;

        if (wpAttr.html.length > 0) {
          text = wpAttr.html;
        }
        else {
          text = this.placeholder;
        }
      }

      this.displayText = this.WorkPackagesHelper.formatValue(text, this.displayType);
    });
  }
}

function wpDisplayAttrDirective() {

  function wpTdLink(
    scope,
    element,
    attr,
    controllers) {

    scope.$ctrl.wpEditField = controllers[0];
  }

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/work-packages/wp-display-attr/wp-display-attr.directive.html',
    require: ['^?wpEditField'],
    link: wpTdLink,

    scope: {
      schema: '=',
      workPackage: '=',
      attribute: '=',
      label: '=',
      placeholderOptional: '=placeholder'
    },

    bindToController: true,
    controller: WorkPackageDisplayAttributeController,
    controllerAs: '$ctrl'
  };
}

wpDirectivesModule.directive('wpDisplayAttr', wpDisplayAttrDirective);
