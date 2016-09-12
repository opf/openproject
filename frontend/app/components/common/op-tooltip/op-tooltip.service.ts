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

import {opModelsModule} from '../../../angular-modules';

export class OpenProjectTooltipService {
  public delay: number = 1000;
  public container;

  private timeouts = [];

  constructor() {
    angular.element('#op-tooltip-container').remove();
    this.container = angular
      .element('<div id="op-tooltip-container"></div>')
      .css('visibility', 'hidden')
      .appendTo(document.body);
  }

  public show(tooltip, target) {
    angular.element('.op-tooltip').remove();
    this.container.append(tooltip);

    var {top, left} = target.offset();
    top -= tooltip.outerHeight();
    left += target.outerWidth() - tooltip.outerWidth();
    tooltip.css({top, left});

    this.visibilityTimeout('visible');
  }

  public hide() {
    this.visibilityTimeout('hidden');
  }

  private visibilityTimeout(visibility) {
    this.timeouts.forEach(clearTimeout);
    const timeout = setTimeout(() => this.container.css('visibility', visibility), this.delay);
    this.timeouts.push(timeout);
  }
}

opModelsModule.service('opTooltipService', OpenProjectTooltipService);
