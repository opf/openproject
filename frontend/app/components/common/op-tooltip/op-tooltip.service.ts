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
import ICompileService = angular.ICompileService;
import IAugmentedJQuery = angular.IAugmentedJQuery;
import IScope = angular.IScope;

var $compile: ICompileService;

export class Tooltip {
  /**
   * Tooltips that are appended to the DOM.
   * With the current implementation, there should always be only one active tooltip.
   */
  public static active: Tooltip[] = [];

  /**
   * Remove all tooltips (should always be one currently).
   * @see Tooltip#destroy
   */
  public static clear() {
    this.active.forEach(tooltip => tooltip.remove());
  }

  /**
   * The tooltip html element.
   */
  protected element: IAugmentedJQuery;

  constructor(protected parent: IAugmentedJQuery,
              protected scope: IScope,
              protected templateUrl: string) {
  }

  /**
   * Display the tooltip.
   *
   * Compile the tooltip element and append it to its parent.
   * Clear previous active tooltips and push this one to the active ones.
   *
   * Use ngInclude to display the content of the tooltip.
   * The templateUrl is a regular scope variable, that returns a string.
   */
  public show() {
    Tooltip.clear();
    Tooltip.active.push(this);

    const template = `
      <div class="op-tooltip">
        <ng-include src="${ this.templateUrl }"></ng-include>
      </div>`;
    this.element = $compile(template)(this.scope);

    this.scope.$apply();
    this.parent.append(this.element);
  }

  /**
   * Remove the tooltip from the DOM and destroy the child scope.
   * Remove the tooltip from the active tooltips.
   */
  public remove() {
    this.element.remove();
    _.pull(Tooltip.active, this);
  }
}

function tooltipService(...args) {
  [$compile] = args;
  return Tooltip;
}
tooltipService.$inject = ['$compile'];

openprojectModule.factory('Tooltip', tooltipService);
