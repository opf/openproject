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

import HalResource from "../../api/api-v3/hal-resources/hal-resource.service";

export default class WorkPackageDisplayAttributeController {
  public displayText:string;
  public isDisplayAsHtml:boolean = false;
  public displayType:string;
  public displayLink:string;
  public attribute:string;
  public workPackage:any;
  public schema:HalResource;

  constructor(protected $scope:ng.IScope,
              protected I18n:op.I18n,
              protected PathHelper:any,
              protected WorkPackagesHelper:any) {
    this.displayText = I18n.t('js.work_packages.placeholders.default');

    $scope.$watch('$ctrl.workPackage.' + this.attribute, () => {
      this.updateAttribute();
    });
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
      if (this.workPackage.isNew && this.attribute === 'id') {
        this.displayText = 'text';
        this.displayText = '';
        return;
      }

      if (!this.workPackage[this.attribute]) {
        this.displayText = this.I18n.t('js.work_packages.placeholders.default');
        return;
      }

      this.setDisplayType();

      var text = this.workPackage[this.attribute].value ||
        this.workPackage[this.attribute].name ||
        this.workPackage[this.attribute];

      if(this.workPackage[this.attribute].hasOwnProperty('html')){
        this.isDisplayAsHtml = true;
        if(this.attribute == "description"){
          text = (this.workPackage[this.attribute].html.length > 0) ? this.workPackage[this.attribute].html : this.I18n.t('js.work_packages.placeholders.description');
        }else{
          text = this.workPackage[this.attribute].html;
        }
      }

      this.displayText = this.WorkPackagesHelper.formatValue(text, this.displayType);
    });
  }
}

function wpDisplayAttr() {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/work-packages/wp-display-attr/wp-display-attr.directive.html',

    scope: {
      schema: '=',
      workPackage: '=',
      attribute: '='
    },

    bindToController: true,
    controller: WorkPackageDisplayAttributeController,
    controllerAs: '$ctrl'
  };
}

angular
  .module('openproject.workPackages.directives')
  .directive('wpDisplayAttr', wpDisplayAttr);
