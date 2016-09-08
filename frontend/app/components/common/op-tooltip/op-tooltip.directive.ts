//-- copyright
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
//++

import {openprojectModule} from '../../../angular-modules';
import IDirective = angular.IDirective;
import IAugmentedJQuery = angular.IAugmentedJQuery;
import IScope = angular.IScope;
import ICompileService = angular.ICompileService;

export class OpenProjectTooltipController {
  protected get templateUrl(): string {
    return this.$scope.$eval(this.$attrs.opTooltip);
  }

  protected get template() {
    return `
      <div class="op-tooltip">
        <div class="inplace-edit--controls" ng-include="${ this.$attrs.opTooltip }"></div>
      </div>`;
  }

  constructor(public $element: IAugmentedJQuery,
              protected $scope: IScope,
              protected $attrs: {opTooltip: string},
              protected $compile: ICompileService) {
  }

  public hasTemplate(): boolean {
    return !!this.templateUrl;
  }

  public create(): IAugmentedJQuery {
    const scope = this.$scope.$new();
    const tooltip = this.$compile(this.template)(scope);

    this.$scope.$apply();
    tooltip.on('$destroy', () => scope.$destroy());

    return tooltip;
  }
}

function opTooltipDirective(): IDirective {
  return {
    restrict: 'A',
    controller: OpenProjectTooltipController
  };
}

openprojectModule.directive('opTooltip', opTooltipDirective);
