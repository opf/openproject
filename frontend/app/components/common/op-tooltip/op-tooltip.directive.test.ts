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
import IRootElementService = angular.IRootElementService;
import IAugmentedJQuery = angular.IAugmentedJQuery;

describe('opTooltip directive', () => {
  var mouseOver;
  var tooltips;
  var tooltip;

  beforeEach(angular.mock.module(openprojectModule.name));
  beforeEach(angular.mock.inject(function ($rootScope,
                                           $rootElement,
                                           $compile,
                                           $templateCache) {
    const html = `
      <div>
        <div op-tooltip="templateUrl"><span class="lonely-child"></span></div>
        <div op-tooltip="templateUrl"></div>
      </div>`;
    const scope: any = $rootScope.$new();

    scope.templateUrl = 'the-letter';
    scope.templateValue = 'the cake is a lie';

    $templateCache.put('the-letter', '{{ templateValue }}');

    tooltips = $compile(html)(scope).children();

    mouseOver = target => {
      const type = 'mouseover';

      $rootElement.triggerHandler({target, type});
      tooltip = angular.element('.op-tooltip');
    };
  }));

  function testTooltip() {
    it('should add a single tooltip to the dom', () => {
      expect(tooltip).to.have.length(1);
    });

    it('should compile the content of the tooltip', () => {
      expect(tooltip.html()).to.contain('the cake is a lie');
    });

    it('should have a z-index over 9000', () => {
      const over = power => expect(tooltip.css('z-index')).to.be.above(power);
      "it's" + over(9000);
    });

    describe('when moving the mouse somewhere else', () => {
      beforeEach(() => {
        mouseOver(document.body);
      });

      it('should be removed from the dom', () => {
        expect(tooltip).to.have.lengthOf(0);
      });
    });
  }

  describe('when moving the mouse over the first item', () => {
    beforeEach(() => {
      mouseOver(tooltips.get(0));
    });

    testTooltip();

    describe('when moving the mouse over the second item', () => {
      beforeEach(() => {
        mouseOver(tooltips.get(1));
      });

      testTooltip();
    });
  });

  describe('when moving the mouse over a child element of the tooltip directive', () => {
    beforeEach(() => {
      mouseOver(tooltips.find('.lonely-child').get(0));
    });

    testTooltip();
  });
});
