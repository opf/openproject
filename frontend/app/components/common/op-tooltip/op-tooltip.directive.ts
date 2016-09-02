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
import {Tooltip} from './op-tooltip.service';
import IDirective = angular.IDirective;
import IScope = angular.IScope;

export class OpenProjectTooltipController {
  public tooltip: Tooltip;

  /**
   *  Instantiate the tooltip with the current element and scope.
   *  Use the content of the `opTooltip` attribute as content for the tooltip.
   */
  constructor(private $scope: IScope,
              private $element,
              private $attrs: any,
              private Tooltip) {
    this.tooltip = new this.Tooltip(this.$element, this.$scope, this.$attrs.opTooltip);
  }

  /**
   * Display the tooltip using the Tooltip service.
   */
  public show() {
    this.tooltip.show();
  }
}

function opTooltipDirective(): IDirective {
  return {
    restrict: 'A',
    controller: OpenProjectTooltipController
  };
}

openprojectModule.directive('opTooltip', opTooltipDirective);
