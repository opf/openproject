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

import {WorkPackageEditFieldGroupController} from './wp-edit-field-group.directive';
export class WorkPackageReplacementLabelController {
  public wpEditFieldGroup:WorkPackageEditFieldGroupController;
  public fieldName:string;

  constructor(protected $scope:ng.IScope,
              protected $element:ng.IAugmentedJQuery) {
  }

  public activate(evt:JQueryEventObject) {
    // Skip clicks on help texts
    const target = jQuery(evt.target);
    if (target.closest('.help-text--entry').length) {
      return true;
    }

    this.wpEditFieldGroup.fields[this.fieldName].handleUserActivate(null);
    return false;
  }
}

function wpReplacementLabelLink(scope:ng.IScope,
                                element:ng.IAugmentedJQuery,
                                attrs:ng.IAttributes,
                                controllers:[WorkPackageEditFieldGroupController, WorkPackageReplacementLabelController]) {

  controllers[1].wpEditFieldGroup = controllers[0];
}

function wpReplacementLabel() {
  return {
    restrict: 'A',
    templateUrl: '/components/wp-edit/wp-edit-field/wp-replacement-label.directive.html',
    transclude: true,

    scope: {
      fieldName: '=wpReplacementLabel',
    },

    require: ['^wpEditFieldGroup', 'wpReplacementLabel'],
    link: wpReplacementLabelLink,

    controller: WorkPackageReplacementLabelController,
    controllerAs: 'vm',
    bindToController: true
  };
}

angular
  .module('openproject')
  .directive('wpReplacementLabel', wpReplacementLabel);
