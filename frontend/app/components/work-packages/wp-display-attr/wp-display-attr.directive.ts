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
import {WorkPackageCacheService} from "../work-package-cache.service";
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {WorkPackageResource} from "../../api/api-v3/hal-resources/work-package-resource.service";

export class WorkPackageDisplayAttributeController {
  public wpEditField:WorkPackageEditFieldController;
  public displayText:string;
  public displayType:string;
  public displayLink:string;
  public attribute:string;
  public placeholder:string;
  public placeholderOptional:string;
  public workPackage:any;

  constructor(protected $scope:ng.IScope,
              protected I18n:op.I18n,
              protected wpCacheService:WorkPackageCacheService,
              protected PathHelper:any,
              protected WorkPackagesHelper:any) {

    this.placeholder = this.placeholderOptional ||
                         I18n.t('js.work_packages.placeholders.default');
    this.displayText = this.placeholder;

    // Update the attribute initially
    if (this.workPackage) {
      this.updateAttribute(this.workPackage);
    }
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

  public shouldFocus() {
    return this.wpEditField && this.wpEditField.shouldFocus();
  }

  public get labelId():string {
    return 'wp-' + this.workPackage.id + '-display-attr-' + this.attribute + '-aria-label';
  }

  public get isEmpty(): boolean {
    var value = this.getValue();
    return !(value === false || value)
  }

  public get isDisplayAsHtml(): boolean {
    return this.workPackage[this.attribute] && this.workPackage[this.attribute].hasOwnProperty('html');
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
    else if (!this.schema[this.attribute]) {
      this.displayType = 'Text';
    }
    else {
      this.displayType = this.workPackage.schema[this.attribute].type;
    }
  }

  protected updateAttribute(wp) {
    this.workPackage = wp;

    wp.schema.$load().then(() => {
      const wpAttr:any = wp[this.attribute];

      if (this.workPackage.isNew && this.attribute === 'id') {
        this.displayText = '';
        return;
      }

      this.setDisplayType();

      var text = this.WorkPackagesHelper.formatValue(this.getValue(), this.displayType);

      text = this.WorkPackagesHelper.formatValue(text, this.displayType);
      if (this.displayText !== text) {
        this.$scope.$evalAsync(() => {
          this.displayText = text || this.placeholder;
        });
      }
    });
  }

  protected getValue() {
    const wpAttr:any = this.workPackage[this.attribute];

    if (wpAttr == null) {
      return null;
    }

    var value = wpAttr.value || wpAttr.name || wpAttr;

    if (wpAttr.hasOwnProperty('html')) {
      value = wpAttr.html;
    }
    return value;
  }
}

function wpDisplayAttrDirective() {

  function wpTdLink(
    scope,
    element,
    attr,
    controllers) {

    scope.$ctrl.wpEditField = controllers[0];

    // Listen for changes to the work package on the form ctrl
    var formCtrl = controllers[1];
    formCtrl.onWorkPackageUpdated('wp-display-attr-' + scope.$ctrl.attribute, (wp) => {
      scope.$evalAsync(() => scope.$ctrl.updateAttribute(wp));
    });
  }

  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/work-packages/wp-display-attr/wp-display-attr.directive.html',
    require: ['^?wpEditField', '^?wpEditForm'],
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
