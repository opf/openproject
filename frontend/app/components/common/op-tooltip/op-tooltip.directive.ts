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
import IScope = angular.IScope;
import IAugmentedJQuery = angular.IAugmentedJQuery;
import ICompileService = angular.ICompileService;

export class OpenProjectTooltipController {
  protected get template() {
    return `
      <div class="op-tooltip">
        <div class="inplace-edit--controls" ng-include="${ this.$attrs.opTooltip }">
        </div>
      </div>`;
  }

  constructor(protected $scope: IScope,
              protected $element,
              protected $attrs: any,
              protected $compile: ICompileService,
              protected opTooltipContainer: IAugmentedJQuery) {
  }

  /**
   * Display the tooltip.
   * Clear the container and append the new tooltip element.
   */
  public show() {
    const tooltip = this.$compile(this.template)(this.$scope);
    var {top, left} = this.$element.offset();

    top += this.$element.outerHeight();
    left += this.$element.outerWidth();

    tooltip.css({
      position: 'absolute',
      zIndex: 9999,
      top,
      left
    }).children().first().css('position', 'static');

    this.$scope.$apply();
    angular.element('.op-tooltip').remove();
    this.opTooltipContainer.append(tooltip);
  }
}

function opTooltipDirective(): IDirective {
  return {
    restrict: 'A',
    controller: OpenProjectTooltipController
  };
}

openprojectModule.directive('opTooltip', opTooltipDirective);
