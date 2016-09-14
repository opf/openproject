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
import IAugmentedJQuery = angular.IAugmentedJQuery;
import ICompileService = angular.ICompileService;
import IDocumentService = angular.IDocumentService;
import IScope = angular.IScope;
import IInjectorService = angular.auto.IInjectorService;

interface TooltipScope extends IScope {
  opTooltipTemplateUrl: string;
  opTooltipController: Function;
}

interface TooltipConfig {
  templateUrl?: string;
  controller?: Function;
}

var $compile: ICompileService;
var container: JQuery;

const template = `
      <div class="op-tooltip">
        <div class="inplace-edit--controls">
          <ng-include
            src="opTooltipTemplateUrl"
            ng-controller="opTooltipController"
          ></ng-include>
        </div>
      </div>
    `;

export class OpenProjectTooltipService {
  public delay: number = 1000;

  constructor(protected config: TooltipConfig = {}) {
  }

  public show(element: IAugmentedJQuery, scope: IScope): JQuery {
    const childScope: TooltipScope = <TooltipScope> scope.$new();
    childScope.opTooltipTemplateUrl = this.config.templateUrl;
    childScope.opTooltipController = this.config.controller || angular.noop;

    const tooltip = $compile(template)(childScope);
    childScope.$apply();
    container.empty();

    tooltip
      .appendTo(container)
      .on('$destroy', () => childScope.$destroy());

    var {top, left} = element.offset();
    top -= tooltip.outerHeight();
    left += element.outerWidth() - tooltip.outerWidth();

    tooltip.css({top, left});

    return tooltip;
  }
}

var $document: IDocumentService;
var $injector: IInjectorService;

function opTooltipService(...args) {
  [$document, $injector, $compile] = args;
  container = $document.find('#op-tooltip-container');

  if (!container.length) {
    container = angular
      .element('<div id="op-tooltip-container"></div>')
      .appendTo($document.find('body'));
  }

  const tooltipFactory: any = config => new OpenProjectTooltipService(config);
  tooltipFactory.get = name => {
    if ($injector.has(name)) {
      const service = $injector.get(name);

      if (service instanceof OpenProjectTooltipService) {
        return service;
      }
    }

    return null;
  };

  return tooltipFactory;
}
opTooltipService.$inject = ['$document', '$injector', '$compile'];

openprojectModule.factory('opTooltip', opTooltipService);
